import 'dart:async';

import 'package:meta/meta.dart' show required;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web_socket_support_platform_interface/method_channel_web_socket_support.dart';
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
  /// Constructs a WebSocketSupportPlatform with [WebSocketListener].
  WebSocketSupportPlatform(WebSocketListener listener) : super(token: _token);

  static final Object _token = Object();

  static WebSocketSupportPlatform _instance =
      MethodChannelWebSocketSupport(DefaultWebSocketListener());

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
