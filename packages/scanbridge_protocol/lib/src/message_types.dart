/// Message `type` values for protocol v1. See docs/PROTOCOL.md.
abstract final class MessageType {
  static const serverHello = 'server.hello';
  static const pairRequest = 'pair.request';
  static const pairAccept = 'pair.accept';
  static const pairReject = 'pair.reject';
  static const deviceStatus = 'device.status';
  static const deviceHeartbeat = 'device.heartbeat';
  static const deviceRevoke = 'device.revoke';
  static const scanSubmit = 'scan.submit';
  static const scanAck = 'scan.ack';
  static const scanReject = 'scan.reject';
  static const sessionUpdate = 'session.update';
  static const templateList = 'template.list';
  static const deliveryStatus = 'delivery.status';
  static const serverError = 'server.error';

  static const all = {
    serverHello, pairRequest, pairAccept, pairReject, deviceStatus, deviceHeartbeat, deviceRevoke,
    scanSubmit, scanAck, scanReject, sessionUpdate, templateList, deliveryStatus, serverError,
  };
}

/// Key id used when a message is signed with the one-time pairing token.
const pairingKeyId = 'pairing';
