/// Hard protocol limits enforced on both ends.
abstract final class ProtocolLimits {
  static const version = 1;
  static const defaultPort = 57900;
  static const maxFrameBytes = 64 * 1024;
  static const maxValueLength = 4096;
  static const maxNameLength = 128;
  static const maxPromptValues = 64;
  static const pairingTokenTtl = Duration(minutes: 3);
  static const heartbeatInterval = Duration(seconds: 15);
  static const clockSkew = Duration(hours: 24);
  static const replayCacheSize = 10000;
  static const maxFailedAuthPerMinute = 10;
}
