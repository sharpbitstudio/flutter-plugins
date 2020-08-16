import 'dart:typed_data';

import 'package:web_socket_support_platform_interface/web_socket_connection.dart';

/// Client code should implement this interface in order to receive async calls from
/// WebSocket implementation from underlying OS.
abstract class WebSocketListener {
  ///
  /// Invoked when a web socket has been accepted by the remote peer and may begin transmitting
  /// messages. Only after this method is invoked, client is able to send/receive ws messages.
  /// Returned WebSocketConnection can be used to send text/byte messages to server as long
  /// as connection is still active (unless [onWsClosing] or [onWsClosed] are called)
  void onWsOpened(WebSocketConnection webSocketConnection);

  /// Invoked when the remote peer has indicated that no more incoming messages will be transmitted.
  /// All resources like [WebSocketConnection] should be released after this.
  void onWsClosing(int code, String reason);

  /// Invoked when both peers have indicated that no more messages will be transmitted and the
  /// connection has been successfully released. No further send/receive calls is possible.
  /// All resources like [WebSocketConnection] should be released after this.
  void onWsClosed(int code, String reason);

  /// Invoked when a text (type `0x1`) message has been received.
  void onTextMessage(String message);

  /// Invoked when a binary (type `0x2`) message has been received.
  void onByteMessage(Uint8List message);

  /// Invoked when error occurs in transport between dart and platform.
  void onError(Exception exception);
}
