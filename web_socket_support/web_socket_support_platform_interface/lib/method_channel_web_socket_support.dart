import 'dart:async';
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
  // constants
  static const methodChannelName =
      'tech.sharpbitstudio.web_socket_support/methods';
  static const textEventChannelName =
      'tech.sharpbitstudio.web_socket_support/text-messages';
  static const byteEventChannelName =
      'tech.sharpbitstudio.web_socket_support/binary-messages';

  //
  // locals
  final WebSocketListener _listener;
  final MethodChannel _methodChannel;
  final EventChannel _textMessagesChannel;
  final EventChannel _byteMessagesChannel;

  // stream subscriptions
  StreamSubscription? _textStreamSubscription;
  StreamSubscription? _binaryStreamSubscription;

  MethodChannelWebSocketSupport(this._listener)
      : _methodChannel = MethodChannel(methodChannelName),
        _textMessagesChannel = EventChannel(textEventChannelName),
        _byteMessagesChannel = EventChannel(byteEventChannelName) {
    // set method channel listener
    _methodChannel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case 'onOpened':
          // ws established
          _listener.onWsOpened(DefaultWebSocketConnection(_methodChannel));
          _addStreamEventListeners();
          break;
        case 'onClosing':
          var args = call.arguments as Map;
          _listener.onWsClosing(args['code'], args['reason']);
          break;
        case 'onClosed':
          // ws closed
          var args = call.arguments as Map;
          _listener.onWsClosed(args['code'], args['reason']);
          _removeStreamEventListeners();
          break;
        case 'onFailure':
          var args = call.arguments as Map;
          _listener.onError(WebSocketException(args['throwableType'],
              args['errorMessage'], args['causeMessage']));
          break;
        case 'onStringMessage':
          _listener.onStringMessage(call.arguments as String);
          break;
        case 'onByteArrayMessage':
          _listener.onByteArrayMessage(call.arguments as Uint8List);
          break;
        default:
          print('Unexpected method name: ${call.method}');
      }
      return Future.value(null);
    });
  }

  /// This constructor is only used for testing and shouldn't be accessed by
  /// users of the plugin. It may break or change at any time.
  @visibleForTesting
  MethodChannelWebSocketSupport.private(this._listener, this._methodChannel,
      this._textMessagesChannel, this._byteMessagesChannel);

  /// obtain WebSocketListener implementation
  @visibleForTesting
  WebSocketListener get listener => _listener;

  @override
  Future<void> connect(
    String serverUrl, {
    WebSocketOptions options = const WebSocketOptions(),
  }) {
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
  Future<void> disconnect({int code = 1000, String reason = 'Client done.'}) {
    return _methodChannel.invokeMethod<void>(
      'disconnect',
      <String, Object>{
        'code': code,
        'reason': reason,
      },
    );
  }

  void _addStreamEventListeners() {
    // add text message listener
    _textStreamSubscription =
        _textMessagesChannel.receiveBroadcastStream().listen((message) {
      _listener.onStringMessage(message as String);
    }, onError: (e) {
      _listener.onError(e);
    });

    // add byte messages listener
    _binaryStreamSubscription =
        _byteMessagesChannel.receiveBroadcastStream().listen((message) {
      _listener.onByteArrayMessage(message as Uint8List);
    }, onError: (e) {
      _listener.onError(e);
    });
  }

  void _removeStreamEventListeners() {
    // remove text message listener
    _textStreamSubscription!.cancel();
    _textStreamSubscription = null;

    // remove byte messages listener
    _binaryStreamSubscription!.cancel();
    _binaryStreamSubscription = null;
  }
}
