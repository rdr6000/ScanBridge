import 'dart:async';

import 'package:scanbridge_protocol/scanbridge_protocol.dart';

enum ServerStatus { stopped, starting, running, error }

class ConnectedClient {
  const ConnectedClient({required this.deviceId, required this.name, required this.address, required this.connectedAt});
  final String deviceId;
  final String name;
  final String address;
  final DateTime connectedAt;
}

/// A phone waiting for the operator to approve pairing.
class PendingPairing {
  PendingPairing({required this.deviceId, required this.deviceName, required this.platform, required this.address});
  final String deviceId;
  final String deviceName;
  final String platform;
  final String address;
  final decision = Completer<bool>();
}

class HostState {
  const HostState({
    this.status = ServerStatus.stopped,
    this.error,
    this.port = 0,
    this.addresses = const [],
    this.lanMode = false,
    this.offer,
    this.pending = const [],
    this.clients = const {},
    this.recentErrors = const [],
  });

  final ServerStatus status;
  final String? error;
  final int port;
  final List<String> addresses;
  final bool lanMode;
  final PairingOffer? offer;
  final List<PendingPairing> pending;
  final Map<String, ConnectedClient> clients;

  /// Redacted, newest first; never includes secrets or barcode values.
  final List<String> recentErrors;

  bool get running => status == ServerStatus.running;

  HostState copyWith({
    ServerStatus? status,
    String? Function()? error,
    int? port,
    List<String>? addresses,
    bool? lanMode,
    PairingOffer? Function()? offer,
    List<PendingPairing>? pending,
    Map<String, ConnectedClient>? clients,
    List<String>? recentErrors,
  }) => HostState(
    status: status ?? this.status,
    error: error != null ? error() : this.error,
    port: port ?? this.port,
    addresses: addresses ?? this.addresses,
    lanMode: lanMode ?? this.lanMode,
    offer: offer != null ? offer() : this.offer,
    pending: pending ?? this.pending,
    clients: clients ?? this.clients,
    recentErrors: recentErrors ?? this.recentErrors,
  );
}
