import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart' show required;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web_socket_support_platform_interface/method_channel_web_socket_support.dart';
import 'package:web_socket_support_platform_interface/web_socket_connection.dart';
import 'package:web_socket_support_platform_interface/web_socket_listener.dart';
import 'package:web_socket_support_platform_interface/web_socket_options.dart';

/// The interface that implementations of web_socket_support must implement.
///
/// Platform implementations should extend this class rather than implement it as `web_socket_support`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [WebSocketSupportPlatform] methods.
class WebSocketSupportPlatform extends PlatformInterface {
  ///
  /// Constructs a WebSocketSupportPlatform.
  WebSocketSupportPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Default instance uses DummyListener so concrete platform implementation
  /// must set correct instance or client code will be useless.
  static WebSocketSupportPlatform _instance =
      MethodChannelWebSocketSupport(DummyWebSocketListener._());

  /// The default instance of [WebSocketSupportPlatform] to use.
  ///
  /// Defaults to [MethodChannelWebSocketSupport].
  static WebSocketSupportPlatform get instance => _instance;

  // https://github.com/flutter/flutter/issues/43368
  static set instance(WebSocketSupportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize ws connection to specified server url.
  /// If connection was successful, [onWsOpened] will be invoked.
  Future<void> connect(
    String serverUrl, {
    @required WebSocketOptions options,
  }) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Initialize ws connection close by client.
  /// When connection is successfully closed, [onWsClosed] will be invoked.
  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }
}

/// This is Dummy WebSocketListener implementation which only logs events
/// received from underlying platform WebSocket. It's really useless :-S
class DummyWebSocketListener extends WebSocketListener {
  /// Prevent outside instantiation/extension
  /// (but unfortunately it can be implemented anyway..)
  DummyWebSocketListener._();

  @override
  void onByteMessage(Uint8List message) {
    print('Byte message received. Size: ${message.length}');
  }

  @override
  void onError(Exception exception) {
    print('Platform exception occurred: $exception');
  }

  @override
  void onTextMessage(String message) {
    print('Text message received. Content: $message');
  }

  @override
  void onWsClosed(int code, String reason) {
    print('WebSocket connection closed. Code:$code, Reason:$reason:');
  }

  @override
  void onWsClosing(int code, String reason) {
    print('WebSocket connection is closing. Code:$code, Reason:$reason:');
  }

  @override
  void onWsOpened(WebSocketConnection webSocketConnection) {
    print('WebSocket connection opened. Ws:$webSocketConnection');
  }
}
