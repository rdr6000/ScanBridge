import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';

import 'host_link.dart';

enum LinkStatus { notPaired, disconnected, connecting, awaitingApproval, connected, reconnecting, error }

class LinkState {
  const LinkState(this.status, {this.serverName, this.failure, this.address});
  final LinkStatus status;
  final String? serverName;
  final AppFailure? failure;
  final String? address;
  bool get connected => status == LinkStatus.connected;
}

/// WebSocket transport with pairing, per-message HMAC and auto-reconnect.
class ConnectionManager {
  ConnectionManager(this.credentials, {required this.deviceName, required this.platform});

  final CredentialStore credentials;
  String Function() deviceName;
  final String platform;

  final _states = StreamController<LinkState>.broadcast();
  final _messages = StreamController<Envelope>.broadcast();
  final _backoff = const Backoff(max: Duration(seconds: 30));
  LinkState _state = const LinkState(LinkStatus.notPaired);
  WebSocket? _socket;
  HostLink? _link;
  String? _deviceId;
  Timer? _retry;
  Timer? _heartbeat;
  var _attempt = 0;
  var _wanted = false;

  LinkState get state => _state;
  Stream<LinkState> get states => _states.stream;

  /// Verified messages from the paired host.
  Stream<Envelope> get messages => _messages.stream;
  HostLink? get link => _link;
  String get deviceId => _deviceId!;

  void _emit(LinkState s) {
    _state = s;
    _states.add(s);
  }

  Future<void> init() async {
    _deviceId = await credentials.deviceId();
    _link = await credentials.link();
    if (_link == null) return _emit(const LinkState(LinkStatus.notPaired));
    _emit(LinkState(LinkStatus.disconnected, serverName: _link!.serverName));
    // Do not block app startup on the network.
    unawaited(connect());
  }

  /// Tries each advertised address; returns the open socket and the address used.
  Future<(WebSocket, String)> _open(List<String> hosts, int port) async {
    Object? last;
    for (final h in hosts) {
      try {
        final ws = await WebSocket.connect('ws://$h:$port/ws').timeout(const Duration(seconds: 4));
        ws.pingInterval = ProtocolLimits.heartbeatInterval;
        return (ws, h);
      } on Object catch (e) {
        last = e;
      }
    }
    throw AppFailure(
      FailureCode.networkUnavailable,
      'Could not reach the computer at ${hosts.join(', ')}:$port ($last).',
      nextStep: 'Check both devices are on the same Wi-Fi, the desktop server is running in LAN mode, and the firewall allows it.',
      retryable: true,
    );
  }

  /// Pairs with a host from a scanned/typed offer. Returns null on success.
  Future<AppFailure?> pair(PairingOffer offer) async {
    await disconnect();
    _emit(LinkState(LinkStatus.connecting, serverName: offer.serverName));
    WebSocket? ws;
    try {
      final (socket, address) = await _open(offer.hosts, offer.port);
      ws = socket;
      final incoming = _decoded(socket);
      final hello = ServerHello.fromJson((await incoming.next(MessageType.serverHello, const Duration(seconds: 6))).payload);
      final key = utf8.encode(offer.token);
      final clientNonce = Signer.randomNonce();
      socket.add(EnvelopeCodec.encode(Envelope(
        type: MessageType.pairRequest,
        deviceId: _deviceId,
        payload: PairRequest(deviceName: deviceName(), platform: platform, clientNonce: clientNonce).toJson(),
      ).signed(pairingKeyId, key)));
      _emit(LinkState(LinkStatus.awaitingApproval, serverName: hello.serverName, address: address));
      final reply = await incoming.nextOf({MessageType.pairAccept, MessageType.pairReject, MessageType.serverError}, const Duration(minutes: 3));
      if (reply.type != MessageType.pairAccept) {
        final err = ErrorPayload.fromJson(reply.payload);
        throw AppFailure(err.code, err.message, nextStep: 'Show a new pairing QR on the computer and try again.');
      }
      if (!reply.verify(key)) throw const AppFailure(FailureCode.authenticationFailed, 'The computer could not prove it knows the pairing code.');
      final accept = PairAccept.fromJson(reply.payload);
      final secret = Signer.deriveDeviceSecret(pairingToken: offer.token, deviceId: _deviceId!, clientNonce: clientNonce, serverNonce: accept.serverNonce);
      _link = HostLink(
        serverId: accept.serverId,
        serverName: accept.serverName,
        hosts: [address, ...offer.hosts.where((h) => h != address)],
        port: offer.port,
        secret: secret,
      );
      await credentials.saveLink(_link!);
      await socket.close();
      await connect();
      return null;
    } on AppFailure catch (f) {
      await ws?.close();
      _emit(LinkState(_link == null ? LinkStatus.notPaired : LinkStatus.error, failure: f));
      return f;
    } on TimeoutException {
      await ws?.close();
      const f = AppFailure(FailureCode.pairingExpired, 'No answer from the computer in time.', nextStep: 'Approve the phone on the computer, or show a new QR code.');
      _emit(const LinkState(LinkStatus.notPaired, failure: f));
      return f;
    }
  }

  Future<void> connect() async {
    final link = _link;
    if (link == null) return;
    _wanted = true;
    _retry?.cancel();
    if (_socket != null) return;
    _emit(LinkState(_attempt == 0 ? LinkStatus.connecting : LinkStatus.reconnecting, serverName: link.serverName));
    try {
      final (socket, address) = await _open(link.hosts, link.port);
      final incoming = _decoded(socket);
      await incoming.next(MessageType.serverHello, const Duration(seconds: 6));
      _socket = socket;
      // Forward before the handshake so replies sent right after it are not dropped.
      incoming.forward(_messages, link.secret);
      send(Envelope(type: MessageType.deviceStatus, payload: DeviceStatusPayload(deviceName: deviceName(), platform: platform).toJson()));
      final reply = await incoming.nextOf({MessageType.deviceStatus, MessageType.serverError}, const Duration(seconds: 8));
      if (reply.type == MessageType.serverError || !reply.verify(link.secret)) {
        final err = reply.type == MessageType.serverError ? ErrorPayload.fromJson(reply.payload) : null;
        throw AppFailure(err?.code ?? FailureCode.authenticationFailed, err?.message ?? 'The computer failed authentication.',
            nextStep: 'Pair this phone again from the Connect screen.');
      }
      _attempt = 0;
      _emit(LinkState(LinkStatus.connected, serverName: link.serverName, address: address));
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) => send(Envelope(type: MessageType.deviceHeartbeat, payload: const {})));
      unawaited(socket.done.then((_) => _onClosed(socket)));
    } on Object catch (e) {
      await _dropSocket();
      final failure = e is AppFailure ? e : AppFailure(FailureCode.networkUnavailable, '$e', retryable: true);
      _emit(LinkState(LinkStatus.error, serverName: link.serverName, failure: failure));
      if (failure.code != FailureCode.authenticationFailed) _scheduleRetry();
    }
  }

  void _onClosed(WebSocket socket) {
    if (_socket != socket) return;
    _socket = null;
    _heartbeat?.cancel();
    if (!_wanted) return;
    _emit(LinkState(LinkStatus.reconnecting, serverName: _link?.serverName));
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_wanted) return;
    _retry?.cancel();
    _retry = Timer(_backoff.delayFor(_attempt++), connect);
  }

  /// Resume after app foregrounding or network change.
  void reconnectNow() {
    if (_link == null || _socket != null) return;
    _attempt = 0;
    unawaited(connect());
  }

  /// Signs with the device secret; returns false when not connected.
  bool send(Envelope e) {
    final s = _socket;
    final link = _link;
    if (s == null || link == null || s.readyState != WebSocket.open) return false;
    s.add(EnvelopeCodec.encode(Envelope(type: e.type, payload: e.payload, deviceId: _deviceId).signed(_deviceId!, link.secret)));
    return true;
  }

  Future<void> _dropSocket() async {
    _heartbeat?.cancel();
    final s = _socket;
    _socket = null;
    await s?.close();
  }

  Future<void> disconnect() async {
    _wanted = false;
    _retry?.cancel();
    await _dropSocket();
    if (_link != null) _emit(LinkState(LinkStatus.disconnected, serverName: _link!.serverName));
  }

  Future<void> forget() async {
    await disconnect();
    await credentials.forgetLink();
    _link = null;
    _emit(const LinkState(LinkStatus.notPaired));
  }

  _Incoming _decoded(WebSocket socket) => _Incoming(socket);
}

/// Decodes frames and lets callers await specific message types.
class _Incoming {
  _Incoming(WebSocket socket) {
    socket.listen((frame) {
      final env = EnvelopeCodec.decode(frame).valueOrNull;
      if (env != null) _controller.add(env);
    }, onDone: _controller.close, onError: (_) => _controller.close());
  }

  final _controller = StreamController<Envelope>.broadcast();
  StreamSubscription<Envelope>? _forward;

  Future<Envelope> next(String type, Duration timeout) => nextOf({type}, timeout);

  Future<Envelope> nextOf(Set<String> types, Duration timeout) =>
      _controller.stream.firstWhere((e) => types.contains(e.type)).timeout(timeout);

  /// After authentication, pass only correctly signed messages through.
  void forward(StreamController<Envelope> sink, List<int> secret) {
    _forward = _controller.stream.listen((e) {
      if (e.verify(secret)) sink.add(e);
    }, onDone: () => _forward?.cancel());
  }
}
