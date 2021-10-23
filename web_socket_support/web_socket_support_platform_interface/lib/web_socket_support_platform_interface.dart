import 'dart:async';
import 'dart:typed_data';

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
abstract class WebSocketSupportPlatform extends PlatformInterface {
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
    WebSocketOptions options = const WebSocketOptions(),
  }) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Initialize ws connection close by client.
  /// When connection is successfully closed, [onWsClosed] will be invoked.
  Future<void> disconnect({
    int code = 1000,
    String reason = 'Client done.',
  }) {
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
  void onByteArrayMessage(Uint8List message) {
    throw UnimplementedError(
        'onByteArrayMessage(Uint8List message) has not been implemented.');
  }

  @override
  void onError(Exception exception) {
    throw UnimplementedError(
        'onError(Exception exception) has not been implemented.');
  }

  @override
  void onStringMessage(String message) {
    throw UnimplementedError(
        'onStringMessage(String message) has not been implemented.');
  }

  @override
  void onWsClosed(int code, String reason) {
    throw UnimplementedError(
        'onWsClosed(int code, String reason) has not been implemented.');
  }

  @override
  void onWsClosing(int code, String reason) {
    throw UnimplementedError(
        'onWsClosing(int code, String reason) has not been implemented.');
  }

  @override
  void onWsOpened(WebSocketConnection webSocketConnection) {
    throw UnimplementedError(
        'onWsOpened(WebSocketConnection webSocketConnection) has not been implemented.');
  }
}
