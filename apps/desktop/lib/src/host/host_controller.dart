import 'dart:async';
import 'dart:io';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import 'client_connection.dart';
import 'host_settings.dart';
import 'host_state.dart';
import 'output_service.dart';
import 'secret_store.dart';

/// Local WebSocket server: pairing, authentication, scan ingest, acks.
class HostController implements ConnectionHost {
  HostController({
    required this.settings,
    required this.secrets,
    required this.devices,
    required this.scans,
    required this.sessions,
    required this.templates,
    required this.audit,
    required this.output,
  }) {
    output.onStatus = _onOutputStatus;
  }

  final HostSettingsStore settings;
  final SecretStore secrets;
  final DeviceRepository devices;
  final ScanRepository scans;
  final SessionRepository sessions;
  final TemplateRepository templates;
  final AuditRepository audit;
  final OutputService output;

  @override
  final replay = ReplayGuard();

  final _states = StreamController<HostState>.broadcast();
  final _connections = <ClientConnection>{};
  final _authFailures = <DateTime>[];
  HostState _state = const HostState();
  HttpServer? _server;
  late String _serverId;
  StreamSubscription<List<OutputTemplate>>? _templateSub;

  HostState get state => _state;
  Stream<HostState> get states => _states.stream;

  Future<void> init() async {
    _serverId = await secrets.serverId();
    await scans.markInterruptedOutput();
    _templateSub = templates.watchAll().skip(1).listen((_) => _broadcastTemplates());
    if (settings.current.autoStart) await start();
  }

  void _emit(HostState s) {
    _state = s;
    _states.add(s);
  }

  @override
  String get serverId => _serverId;

  @override
  String get serverName => settings.current.serverName;

  Future<void> start() async {
    if (_server != null) return;
    final s = settings.current;
    _emit(_state.copyWith(status: ServerStatus.starting, error: () => null));
    try {
      final address = s.lanMode ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
      final server = await HttpServer.bind(address, s.port, shared: false);
      _server = server;
      server.listen(_onRequest, onError: (Object e) => recordError('Server error: $e'));
      _emit(_state.copyWith(status: ServerStatus.running, port: server.port, lanMode: s.lanMode, addresses: await localAddresses(s.lanMode)));
      await audit.log('server', 'start', details: 'port ${server.port}, lan ${s.lanMode}');
    } on SocketException catch (e) {
      final msg = 'Port ${s.port} is unavailable: ${e.osError?.message ?? e.message}';
      _emit(_state.copyWith(status: ServerStatus.error, error: () => msg));
      recordError(msg);
    }
  }

  Future<void> stop() async {
    for (final c in _connections.toList()) {
      await c.close(WebSocketStatus.goingAway);
    }
    await _server?.close(force: true);
    _server = null;
    _emit(_state.copyWith(status: ServerStatus.stopped, clients: const {}, offer: () => null));
    await audit.log('server', 'stop');
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  static Future<List<String>> localAddresses(bool lan) async {
    if (!lan) return ['127.0.0.1'];
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return [
      for (final i in list)
        for (final a in i.addresses)
          if (!a.isLoopback && !a.isLinkLocal) a.address,
    ];
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (req.uri.path != '/ws' || !WebSocketTransformer.isUpgradeRequest(req)) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('ScanBridge host');
      await req.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(req);
      socket.pingInterval = ProtocolLimits.heartbeatInterval;
      ClientConnection(socket, req.connectionInfo?.remoteAddress.address ?? '?', this).start();
    } on Object catch (e) {
      recordError('WebSocket upgrade failed: ${e.runtimeType}');
    }
  }

  // ---- Pairing ----

  PairingOffer newOffer() {
    final offer = PairingOffer(
      serverId: _serverId,
      serverName: serverName,
      hosts: _state.addresses,
      port: _state.port,
      token: PairingOffer.generateToken(),
      expiresAt: nowUtc().add(ProtocolLimits.pairingTokenTtl),
    );
    _emit(_state.copyWith(offer: () => offer));
    return offer;
  }

  void clearOffer() => _emit(_state.copyWith(offer: () => null));

  @override
  String? takeOffer() {
    final offer = _state.offer;
    if (offer == null || offer.isExpired(nowUtc())) return null;
    clearOffer();
    return offer.token;
  }

  @override
  bool get authBlocked {
    final cutoff = nowUtc().subtract(const Duration(minutes: 1));
    _authFailures.removeWhere((t) => t.isBefore(cutoff));
    return _authFailures.length >= ProtocolLimits.maxFailedAuthPerMinute;
  }

  @override
  Future<bool> requestApproval(PendingPairing pending) async {
    _emit(_state.copyWith(pending: [..._state.pending, pending]));
    final ok = await pending.decision.future.timeout(const Duration(minutes: 2), onTimeout: () => false);
    _emit(_state.copyWith(pending: _state.pending.where((p) => p != pending).toList()));
    return ok;
  }

  void decide(PendingPairing pending, bool approve) {
    if (!pending.decision.isCompleted) pending.decision.complete(approve);
  }

  @override
  Future<void> completePairing(PendingPairing p, List<int> secret) async {
    final now = nowUtc();
    await secrets.setDeviceSecret(p.deviceId, secret);
    final existing = await devices.byId(p.deviceId);
    await devices.upsert(Device(
      id: p.deviceId,
      name: p.deviceName,
      platform: p.platform,
      createdAt: existing?.createdAt ?? now,
      pairedAt: now,
      lastSeenAt: now,
      status: DeviceStatus.paired,
    ));
    await audit.log('device', 'paired', entityId: p.deviceId, details: '${p.platform} from ${p.address}');
  }

  Future<void> revoke(String deviceId) async {
    await devices.setStatus(deviceId, DeviceStatus.revoked);
    await secrets.deleteDeviceSecret(deviceId);
    for (final c in _connections.where((c) => c.deviceId == deviceId).toList()) {
      c.send(Envelope(type: MessageType.deviceRevoke, payload: const {}));
      await c.close(WebSocketStatus.policyViolation);
    }
    await audit.log('device', 'revoked', entityId: deviceId);
  }

  Future<void> forget(String deviceId) async {
    await revoke(deviceId);
    await devices.delete(deviceId);
  }

  @override
  Future<Device?> device(String id) => devices.byId(id);

  @override
  Future<List<int>?> secret(String deviceId) => secrets.deviceSecret(deviceId);

  @override
  void attach(ClientConnection c) {
    _connections.add(c);
    _emit(_state.copyWith(clients: {
      ..._state.clients,
      c.deviceId!: ConnectedClient(deviceId: c.deviceId!, name: c.deviceName, address: c.address, connectedAt: nowUtc()),
    }));
  }

  @override
  void detach(ClientConnection c) {
    if (!_connections.remove(c) || c.deviceId == null) return;
    if (_connections.any((o) => o.deviceId == c.deviceId)) return;
    _emit(_state.copyWith(clients: {..._state.clients}..remove(c.deviceId)));
  }

  @override
  void recordError(String message, {bool authFailure = false}) {
    if (authFailure) _authFailures.add(nowUtc());
    final line = '${nowUtc().toIso8601String()} $message';
    _emit(_state.copyWith(recentErrors: [line, ..._state.recentErrors.take(49)]));
  }

  // ---- Authenticated messages ----

  @override
  Future<List<Envelope>> onMessage(ClientConnection c, Device device, Envelope env) async {
    await devices.touch(device.id);
    switch (env.type) {
      case MessageType.deviceStatus:
        final status = DeviceStatusPayload.fromJson(env.payload);
        if (status.deviceName != device.name) await devices.rename(device.id, status.deviceName);
        c.deviceName = status.deviceName;
        return [
          Envelope(type: MessageType.deviceStatus, payload: {'serverName': serverName, 'accepted': true}),
          await _templateList(),
        ];
      case MessageType.deviceHeartbeat:
        return [Envelope(type: MessageType.deviceHeartbeat, payload: const {})];
      case MessageType.scanSubmit:
        return [await _ingest(device, env.payload)];
      case MessageType.sessionUpdate:
        final u = SessionUpdatePayload.fromJson(env.payload);
        await sessions.upsertName(u.sessionId, u.name, deviceId: device.id);
        return const [];
      case MessageType.templateList:
        return [await _templateList()];
      default:
        return [Envelope(type: MessageType.serverError, payload: ErrorPayload(code: FailureCode.unknownFailure, message: 'Unsupported ${env.type}').toJson())];
    }
  }

  Envelope _reject(String scanId, FailureCode code, String message) => Envelope(
    type: MessageType.scanReject,
    payload: ErrorPayload(code: code, message: message, scanId: scanId).toJson(),
  );

  /// Persist first, then ack; output runs asynchronously afterwards.
  Future<Envelope> _ingest(Device device, Map<String, Object?> payload) async {
    final scanId = payload['scanId'] as String? ?? '';
    if (!device.canSubmitScans) return _reject(scanId, FailureCode.permissionDenied, 'This phone may not submit scans.');
    final ScanSubmit submit;
    try {
      submit = ScanSubmit.fromJson(payload);
    } on PayloadException catch (e) {
      return _reject(scanId, FailureCode.invalidScan, e.message);
    }
    try {
      final now = nowUtc();
      final duplicate = await scans.valueExistsInSession(submit.sessionId, submit.rawValue, exceptId: submit.scanId);
      final record = ScanRecord(
        id: submit.scanId,
        sessionId: submit.sessionId,
        deviceId: device.id,
        rawValue: submit.rawValue,
        symbology: submit.symbology,
        quantity: submit.quantity,
        capturedAt: submit.capturedAt,
        receivedAt: now,
        source: submit.source,
        validationStatus: duplicate ? ValidationStatus.duplicate : ValidationStatus.valid,
        deliveryStatus: DeliveryStatus.received,
        templateId: submit.templateId,
        templateVersion: submit.templateVersion,
        values: submit.values,
      );
      final (stored, already) = await scans.receive(record, sessionName: submit.sessionName);
      if (!already) output.enqueue(stored.id);
      return Envelope(
        type: MessageType.scanAck,
        payload: ScanAck(scanId: stored.id, duplicateSubmit: already, receivedAt: stored.receivedAt ?? now).toJson(),
      );
    } on Object catch (e) {
      recordError('Storage failure while receiving a scan: ${e.runtimeType}');
      return _reject(scanId, FailureCode.storageFailure, 'Could not save the scan on the computer; it stays queued on the phone.');
    }
  }

  Future<Envelope> _templateList() async => Envelope(
    type: MessageType.templateList,
    payload: TemplateListPayload(
      templates: [for (final t in await templates.all()) t.toJson()],
      activeTemplateId: settings.current.activeTemplateId,
    ).toJson(),
  );

  Future<void> _broadcastTemplates() async {
    if (_connections.isEmpty) return;
    final list = await _templateList();
    for (final c in _connections.where((c) => c.authenticated)) {
      c.send(list);
    }
  }

  /// Settings change that phones should see (active template).
  Future<void> pushTemplates() => _broadcastTemplates();

  void _onOutputStatus(ScanRecord scan, OutputStatus status, String? error) {
    for (final c in _connections.where((c) => c.deviceId == scan.deviceId)) {
      c.send(Envelope(type: MessageType.deliveryStatus, payload: DeliveryStatusPayload(scanId: scan.id, outputStatus: status, error: error).toJson()));
    }
  }

  Future<void> dispose() async {
    await _templateSub?.cancel();
    await stop();
    await _states.close();
  }
}
