import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web_socket_support_platform_interface/method_channel_web_socket_support.dart';
import 'package:web_socket_support_platform_interface/web_socket_connection.dart';
import 'package:web_socket_support_platform_interface/web_socket_listener.dart';
import 'package:web_socket_support_platform_interface/web_socket_options.dart';
import 'package:web_socket_support_platform_interface/web_socket_support_platform_interface.dart';

void main() {
  group('$WebSocketSupportPlatform', () {
    test('$MethodChannelWebSocketSupport() is the default instance', () {
      expect(WebSocketSupportPlatform.instance,
          isInstanceOf<MethodChannelWebSocketSupport>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        WebSocketSupportPlatform.instance =
            ImplementsWebSocketSupportPlatform();
      }, throwsA(isInstanceOf<AssertionError>()));
    });

    test('Can be mocked with `implements`', () {
      final WebSocketSupportPlatform mock = WebSocketSupportPlatformMock();
      WebSocketSupportPlatform.instance = mock;
    });

    test('Can be extended', () {
      WebSocketSupportPlatform.instance =
          ExtendsWebSocketSupportPlatform(TestWebSocketListener());
    });
  });

  group('$MethodChannelWebSocketSupport calls TO platform', () {
    WidgetsFlutterBinding.ensureInitialized();

    //
    // mock channels
    MethodChannel _methodChannel;
    EventChannel _textMessages;
    EventChannel _byteMessages;
    MethodChannelWebSocketSupport _webSocketSupport;
    WebSocketConnection _webSocketConnection;

    // MethodChannel calls
    final calledMethodsLog = <MethodCall>[];

    // EventChannel
    StreamController<String> textMessagesController;
    StreamController<Uint8List> byteMessagesController;

    setUp(() {
      // init variables
      _methodChannel = MethodChannel('web-socket-test');
      _textMessages = MockEventChannel();
      _byteMessages = MockEventChannel();

      _webSocketSupport = MethodChannelWebSocketSupport.private(
          TestWebSocketListener(),
          _methodChannel,
          _textMessages,
          _byteMessages);

      calledMethodsLog.clear();
      _methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        calledMethodsLog.add(methodCall); // add call to log
        if (methodCall.method == 'connect') {
          _webSocketConnection = DefaultWebSocketConnection(_methodChannel);
        }
      });

      // text EventChannel
      textMessagesController = StreamController<String>();
      when(_textMessages.receiveBroadcastStream())
          .thenAnswer((Invocation invoke) => textMessagesController.stream);

      // Byte EventChannel
      byteMessagesController = StreamController<Uint8List>();
      when(_byteMessages.receiveBroadcastStream())
          .thenAnswer((Invocation invoke) => byteMessagesController.stream);
    });

    tearDown(() {
      calledMethodsLog.clear();
      textMessagesController.close();
      byteMessagesController.close();
    });

    test('connect and send message', () async {
      await _webSocketSupport.connect('ws://example.com/',
          options: WebSocketOptions(
            autoReconnect: true,
          ));
      await _webSocketConnection.sendTextMessage('test-text-message');
      await _webSocketConnection
          .sendByteMessage(Uint8List.fromList('test-byte-message'.codeUnits));
      expect(
        calledMethodsLog,
        <Matcher>[
          isMethodCall('connect', arguments: <String, Object>{
            'serverUrl': 'ws://example.com/',
            'options': {
              'autoReconnect': true,
              'pingInterval': 0,
              'headers': {},
            },
          }),
          isMethodCall('sendTextMessage', arguments: <String, Object>{
            'textMessage': 'test-text-message',
          }),
          isMethodCall('sendByteMessage', arguments: <String, Object>{
            'byteMessage': 'test-byte-message'.codeUnits,
          }),
        ],
      );
    });

    test('disconnect', () async {
      await _webSocketSupport.disconnect(code: 3, reason: 'test');
      expect(
        calledMethodsLog,
        <Matcher>[
          isMethodCall('disconnect', arguments: <String, Object>{
            'code': 3,
            'reason': 'test'
          }),
        ],
      );
    });
  });

  group('$MethodChannelWebSocketSupport calls FROM platform', () {
    WidgetsFlutterBinding.ensureInitialized();

    //
    // mock channels
    MethodChannel _methodChannel;
    EventChannel textMessages;
    EventChannel byteMessages;
    MethodChannelWebSocketSupport _webSocketSupport;
    Function methodCallFunction;
    TestWebSocketListener _testWebSocketListener;

    // EventChannel
    StreamController<String> textMessagesController;
    StreamController<Uint8List> byteMessagesController;

    setUp(() {
      // init variables
      _methodChannel = MockMethodChannel();
      textMessages = MockEventChannel();
      byteMessages = MockEventChannel();

      // MethodChannel
      when(_methodChannel.setMethodCallHandler(any))
          .thenAnswer((realInvocation) {
        methodCallFunction = realInvocation.positionalArguments[0];
      });

      // text EventChannel
      textMessagesController = StreamController<String>();
      when(textMessages.receiveBroadcastStream())
          .thenAnswer((Invocation invoke) => textMessagesController.stream);

      // Byte EventChannel
      byteMessagesController = StreamController<Uint8List>();
      when(byteMessages.receiveBroadcastStream())
          .thenAnswer((Invocation invoke) => byteMessagesController.stream);

      // test web socket listener
      _testWebSocketListener = TestWebSocketListener();

      // init MethodChannelWebSocketSupport
      _webSocketSupport = MethodChannelWebSocketSupport.private(
          _testWebSocketListener, _methodChannel, textMessages, byteMessages);
    });

    tearDown(() {
      textMessagesController.close();
      byteMessagesController.close();
      _testWebSocketListener?.onWsClosed(0, '');
    });

    test('calls receiveBroadcastStream once', () {
      // connect
      _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );

      // verify
      verify(textMessages.receiveBroadcastStream()).called(1);
      verify(byteMessages.receiveBroadcastStream()).called(1);
    });

    test('onOpened', () async {
      // connect
      await _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );
      methodCallFunction.call(MethodCall('onOpened'));

      // verify
      expect(_testWebSocketListener.webSocketConnection, isNotNull);
    });

    test('onClosing', () async {
      // connect
      await _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );
      methodCallFunction
          .call(MethodCall('onClosing', {'code': 13, 'reason': 'testReason1'}));

      // verify
      expect(_testWebSocketListener.onClosingCalled, true);
      expect(_testWebSocketListener.closingCode, 13);
      expect(_testWebSocketListener.closingReason, 'testReason1');
    });

    test('onClosed', () async {
      // connect
      await _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );
      methodCallFunction
          .call(MethodCall('onClosed', {'code': 101, 'reason': 'testReason2'}));

      // verify
      expect(_testWebSocketListener.onClosedCalled, true);
      expect(_testWebSocketListener.closingCode, 101);
      expect(_testWebSocketListener.closingReason, 'testReason2');
    });

    test('onTextMessage', () async {
      // connect
      await _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );
      textMessagesController.add('test-text-message');

      // verify
      expect(
          await _testWebSocketListener.textQueue.next
              .timeout(Duration(seconds: 1)),
          'test-text-message');
    });

    test('onByteMessage', () async {
      // connect
      await _webSocketSupport.connect(
        'ws://example.com/',
        options: WebSocketOptions(),
      );
      byteMessagesController
          .add(Uint8List.fromList('test-byte-message'.codeUnits));

      // verify
      expect(
          await _testWebSocketListener.byteQueue.next
              .timeout(Duration(seconds: 1)),
          'test-byte-message'.codeUnits);
    });
  });
}

class WebSocketSupportPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements WebSocketSupportPlatform {}

class ImplementsWebSocketSupportPlatform extends Mock
    implements WebSocketSupportPlatform {}

class ExtendsWebSocketSupportPlatform extends WebSocketSupportPlatform {
  ExtendsWebSocketSupportPlatform(WebSocketListener listener);
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockEventChannel extends Mock implements EventChannel {}

class TestWebSocketListener extends WebSocketListener {
  final _textController = StreamController<String>();
  final _byteController = StreamController<Uint8List>();
  StreamQueue<String> textQueue;
  StreamQueue<Uint8List> byteQueue;
  WebSocketConnection webSocketConnection;
  bool onClosingCalled = false;
  bool onClosedCalled = false;
  int closingCode;
  String closingReason;

  TestWebSocketListener() {
    textQueue = StreamQueue(_textController.stream);
    byteQueue = StreamQueue(_byteController.stream);
  }

  @override
  void onByteMessage(Uint8List message) {
    _byteController.add(message);
  }

  @override
  void onError(Exception exception) {
    // TODO: implement onError
  }

  @override
  void onTextMessage(String message) {
    _textController.add(message);
  }

  @override
  void onWsClosed(int code, String reason) {
    onClosedCalled = true;
    closingCode = code;
    closingReason = reason;
    _textController.close();
    _byteController.close();
  }

  @override
  void onWsClosing(int code, String reason) {
    onClosingCalled = true;
    closingCode = code;
    closingReason = reason;
    _textController.close();
    _byteController.close();
  }

  @override
  void onWsOpened(WebSocketConnection webSocketConnection) {
    this.webSocketConnection = webSocketConnection;
  }
}
