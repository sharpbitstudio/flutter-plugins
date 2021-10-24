import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Concrete implementation of this class is returned to client by every successful
/// WebSocket connection initialized by [connect] call.
abstract class WebSocketConnection {
  /// Call this method when you want to send Text message to server.
  Future<bool?> sendStringMessage(String message);

  /// Call this method when you want to send Byte message to server.
  Future<bool?> sendByteArrayMessage(Uint8List message);
}

class DefaultWebSocketConnection implements WebSocketConnection {
  final MethodChannel _methodChannel;

  DefaultWebSocketConnection(this._methodChannel);

  @override
  Future<bool?> sendStringMessage(String stringMessage) {
    return _methodChannel.invokeMethod('sendStringMessage', stringMessage);
  }

  @override
  Future<bool?> sendByteArrayMessage(Uint8List byteArrayMessage) {
    return _methodChannel.invokeMethod(
        'sendByteArrayMessage', byteArrayMessage);
  }
}
