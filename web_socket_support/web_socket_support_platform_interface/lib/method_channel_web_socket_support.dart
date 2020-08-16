import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_support_platform_interface/web_scoket_exception.dart';
import 'package:web_socket_support_platform_interface/web_socket_connection.dart';
import 'package:web_socket_support_platform_interface/web_socket_listener.dart';
import 'package:web_socket_support_platform_interface/web_socket_options.dart';
import 'package:web_socket_support_platform_interface/web_socket_support_platform_interface.dart';

class MethodChannelWebSocketSupport extends WebSocketSupportPlatform {
  //
  // locals
  final WebSocketListener _listener;
  final MethodChannel _methodChannel;
  final EventChannel _textMessages;
  final EventChannel _byteMessages;

  MethodChannelWebSocketSupport(this._listener)
      : _methodChannel = MethodChannel(
          'tech.sharpbitstudio.web_socket_support/methods',
        ),
        _textMessages = EventChannel(
          'tech.sharpbitstudio.web_socket_support/text-messages',
        ),
        _byteMessages = EventChannel(
          'tech.sharpbitstudio.web_socket_support/binary-messages',
        );

  /// This constructor is only used for testing and shouldn't be accessed by
  /// users of the plugin. It may break or change at any time.
  @visibleForTesting
  MethodChannelWebSocketSupport.private(this._listener, this._methodChannel,
      this._textMessages, this._byteMessages);

  /// obtain WebSocketListener implementation
  @visibleForTesting
  WebSocketListener get listener => _listener;

  @override
  Future<void> connect(
    String serverUrl, {
    @required WebSocketOptions options,
  }) {
    // method listener
    _methodChannel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case 'onOpened':
          _listener.onWsOpened(DefaultWebSocketConnection(_methodChannel));
          break;
        case 'onClosing':
          var args = call.arguments as Map;
          _listener.onWsClosing(args['code'], args['reason']);
          break;
        case 'onClosed':
          var args = call.arguments as Map;
          _listener.onWsClosed(args['code'], args['reason']);
          break;
        case 'onFailure':
          var args = call.arguments as Map;
          _listener.onError(WebSocketException(args['throwableType'],
              args['errorMessage'], args['causeMessage']));
          break;
        default:
          print('Unexpected method name: ${call.method}');
      }
      return;
    });

    // text message listener
    _textMessages.receiveBroadcastStream().listen((message) {
      _listener.onTextMessage(message as String);
    }, onError: (e) {
      _listener.onError(e);
    });

    // byte messages listener
    _byteMessages.receiveBroadcastStream().listen((message) {
      _listener.onByteMessage(message as Uint8List);
    }, onError: (e) {
      _listener.onError(e);
    });

    // connect to server
    return _methodChannel.invokeMethod<void>(
      'connect',
      <String, Object>{
        'serverUrl': serverUrl,
        'options': options.toMap(),
      },
    );
  }

  @override
  Future<void> disconnect() {
    return _methodChannel.invokeMethod('disconnect');
  }
}
