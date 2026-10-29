import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';

import 'host_state.dart';

/// What a connection needs from the host; keeps protocol code testable.
abstract interface class ConnectionHost {
  String get serverId;
  String get serverName;
  ReplayGuard get replay;

  /// Returns the token if [offer] is still valid and consumes it (single use).
  String? takeOffer();
  /// True while too many auth failures happened in the last minute.
  bool get authBlocked;
  void recordError(String message, {bool authFailure = false});
  Future<bool> requestApproval(PendingPairing pending);
  Future<void> completePairing(PendingPairing pending, List<int> secret);
  Future<Device?> device(String id);
  Future<List<int>?> secret(String deviceId);
  void attach(ClientConnection c);
  void detach(ClientConnection c);

  /// Handles an authenticated message; returns replies to send (unsigned).
  Future<List<Envelope>> onMessage(ClientConnection c, Device device, Envelope env);
}

/// One phone WebSocket: hello -> (pair | authenticate) -> signed messages.
class ClientConnection {
  ClientConnection(this.socket, this.address, this.host);

  final WebSocket socket;
  final String address;
  final ConnectionHost host;
  final _serverNonce = Signer.randomNonce();

  String? deviceId;
  String deviceName = '';
  List<int>? _secret;
  StreamSubscription<dynamic>? _sub;

  bool get authenticated => _secret != null && deviceId != null;

  void start() {
    _sendRaw(Envelope(
      type: MessageType.serverHello,
      payload: ServerHello(serverId: host.serverId, serverName: host.serverName, nonce: _serverNonce, serverTime: nowUtc()).toJson(),
    ));
    _sub = socket.listen(_onFrame, onDone: () => host.detach(this), onError: (_) => host.detach(this), cancelOnError: true);
  }

  Future<void> _onFrame(dynamic frame) async {
    final decoded = EnvelopeCodec.decode(frame);
    final env = decoded.valueOrNull;
    if (env == null) return _fail(decoded.failureOrNull!, close: decoded.failureOrNull!.code == FailureCode.protocolVersionMismatch);
    if (!host.replay.admit(env.messageId)) return;
    if (env.type == MessageType.pairRequest) return _pair(env);
    final device = await _authenticate(env);
    if (device == null) return;
    for (final reply in await host.onMessage(this, device, env)) {
      send(reply);
    }
  }

  Future<Device?> _authenticate(Envelope env) async {
    AppFailure deny(String why) => AppFailure(FailureCode.authenticationFailed, why, nextStep: 'Pair this phone again.');
    if (host.authBlocked) {
      await _fail(deny('Too many failed attempts; try again in a minute.'), close: true);
      return null;
    }
    final id = env.deviceId;
    if (id == null || env.auth?.keyId != id || (deviceId != null && deviceId != id)) {
      await _fail(deny('Message is not signed by a paired device.'), close: true);
      return null;
    }
    final device = await host.device(id);
    final secret = await host.secret(id);
    if (device == null || device.status != DeviceStatus.paired || secret == null) {
      await _fail(deny('This phone is not paired or was revoked.'), close: true);
      return null;
    }
    if (!env.verify(secret) || !env.isFresh(nowUtc())) {
      host.recordError('Rejected message with bad signature or clock from $address', authFailure: true);
      await _fail(deny('Signature check failed.'), close: true);
      return null;
    }
    if (!authenticated) {
      deviceId = id;
      deviceName = device.name;
      _secret = secret;
      host.attach(this);
    }
    return device;
  }

  Future<void> _pair(Envelope env) async {
    final id = env.deviceId;
    PairRequest req;
    try {
      req = PairRequest.fromJson(env.payload);
    } on PayloadException catch (e) {
      return _pairReject(FailureCode.invalidScan, e.message);
    }
    if (id == null || env.auth?.keyId != pairingKeyId || host.authBlocked) {
      return _pairReject(FailureCode.authenticationFailed, 'Pairing request was not signed.');
    }
    final token = host.takeOffer();
    if (token == null) return _pairReject(FailureCode.pairingExpired, 'Pairing code expired or already used. Show a new QR code.');
    final key = utf8.encode(token);
    if (!env.verify(key)) {
      host.recordError('Wrong pairing code from $address', authFailure: true);
      return _pairReject(FailureCode.authenticationFailed, 'Wrong pairing code.');
    }
    final pending = PendingPairing(deviceId: id, deviceName: req.deviceName, platform: req.platform, address: address);
    if (!await host.requestApproval(pending)) {
      return _sendRaw(Envelope(
        type: MessageType.pairReject,
        payload: const ErrorPayload(code: FailureCode.permissionDenied, message: 'Pairing was declined on the computer.').toJson(),
      ).signed(pairingKeyId, key));
    }
    final secret = Signer.deriveDeviceSecret(pairingToken: token, deviceId: id, clientNonce: req.clientNonce, serverNonce: _serverNonce);
    await host.completePairing(pending, secret);
    _sendRaw(Envelope(
      type: MessageType.pairAccept,
      payload: PairAccept(serverId: host.serverId, serverName: host.serverName, serverNonce: _serverNonce).toJson(),
    ).signed(pairingKeyId, key));
  }

  Future<void> _pairReject(FailureCode code, String message) async {
    _sendRaw(Envelope(type: MessageType.pairReject, payload: ErrorPayload(code: code, message: message).toJson()));
    await close();
  }

  Future<void> _fail(AppFailure f, {bool close = false}) async {
    _sendRaw(Envelope(type: MessageType.serverError, payload: ErrorPayload(code: f.code, message: f.message).toJson()));
    if (close) await this.close();
  }

  /// Signs with the device secret once authenticated.
  void send(Envelope e) => _sendRaw(_secret == null ? e : e.signed('server', _secret!));

  void _sendRaw(Envelope e) {
    if (socket.readyState == WebSocket.open) socket.add(EnvelopeCodec.encode(e));
  }

  Future<void> close([int code = WebSocketStatus.normalClosure]) async {
    await _sub?.cancel();
    await socket.close(code);
    host.detach(this);
  }
}
