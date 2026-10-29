/// Stable error codes shared by all layers and shown to users.
enum FailureCode {
  networkUnavailable,
  pairingExpired,
  authenticationFailed,
  protocolVersionMismatch,
  invalidScan,
  duplicateScan,
  storageFailure,
  outputTargetUnavailable,
  keyboardInjectionUnavailable,
  permissionDenied,
  templateValidationFailure,
  integrationTimeout,
  exportFailure,
  unknownFailure,
}

class AppFailure {
  const AppFailure(this.code, this.message, {this.nextStep, this.retryable = false, this.correlationId});

  final FailureCode code;
  final String message;
  final String? nextStep;
  final bool retryable;
  final String? correlationId;

  @override
  String toString() => '${code.name}: $message';
}

/// Typed result so failures do not cross layers as exceptions.
sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  T? get valueOrNull => switch (this) { Ok<T>(:final value) => value, Err<T>() => null };
  AppFailure? get failureOrNull => switch (this) { Ok<T>() => null, Err<T>(:final failure) => failure };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
