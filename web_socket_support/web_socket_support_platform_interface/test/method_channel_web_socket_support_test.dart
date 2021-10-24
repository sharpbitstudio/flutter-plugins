import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_support_platform_interface/method_channel_web_socket_support.dart';
import 'package:web_socket_support_platform_interface/web_scoket_exception.dart';
import 'package:web_socket_support_platform_interface/web_socket_options.dart';

import 'event_channel_mock.dart';
import 'method_channel_mock.dart';
import 'test_web_socket_listener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // MethodChannel calls
  final calledMethodsLog = <MethodCall>[];

  // clear log before any test
  setUp(() => calledMethodsLog.clear());

  group('$MethodChannelWebSocketSupport calls TO platform', () {
    test('Send `connect` event before we is established', () async {
      final _testWsListener = TestWebSocketListener();
      final _webSocketSupport = MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      final _completer = Completer();
      final _methodChannel = MethodChannelMock(
        channelName: MethodChannelWebSocketSupport.methodChannelName,
        methodMocks: [
          MethodMock(
              method: 'connect',
              action: () {
                _sendMessageFromPlatform(
                    MethodChannelWebSocketSupport.methodChannelName,
                    MethodCall('onOpened'));
                _completer.complete();
              }),
        ],
      );

      // Act
      await _webSocketSupport.connect('ws://example.com/',
          options: WebSocketOptions(
            autoReconnect: true,
          ));

      // await completer
      await _completer.future;

      // Assert
      // correct event sent to platform
      expect(
        _methodChannel.log,
        <Matcher>[
          isMethodCall('connect', arguments: <String, Object>{
            'serverUrl': 'ws://example.com/',
            'options': {
              'autoReconnect': true,
              'pingInterval': 0,
              'headers': {},
            },
          }),
        ],
      );

      // platform response 'onOpened' created wsConnection
      expect(_testWsListener.webSocketConnection, isNotNull);

      // clean up
      await _testWsListener.destroy();
    });

    test('Send `text` message after ws is established', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // method channel mock
      final _methodChannel = MethodChannelMock(
        channelName: MethodChannelWebSocketSupport.methodChannelName,
        methodMocks: [
          MethodMock(
            method: 'sendStringMessage',
            result: true,
          ),
        ],
      );

      // Act - send text message
      await _testWsListener.webSocketConnection!
          .sendStringMessage('test payload 1');

      // Assert
      // correct event sent to platform
      expect(
        _methodChannel.log,
        <Matcher>[
          isMethodCall('sendStringMessage', arguments: 'test payload 1'),
        ],
      );

      // clean up
      await _testWsListener.destroy();
    });

    test('Send `binary` message after ws is established', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // method channel mock
      final _methodChannel = MethodChannelMock(
        channelName: MethodChannelWebSocketSupport.methodChannelName,
        methodMocks: [
          MethodMock(
            method: 'sendByteArrayMessage',
            result: true,
          ),
        ],
      );

      // Act - send text message
      await _testWsListener.webSocketConnection!
          .sendByteArrayMessage(Uint8List.fromList('test payload 2'.codeUnits));

      // Assert
      // correct event sent to platform
      expect(
        _methodChannel.log,
        <Matcher>[
          isMethodCall('sendByteArrayMessage',
              arguments: 'test payload 2'.codeUnits),
        ],
      );

      // clean up
      await _testWsListener.destroy();
    });

    test('Send `disconnect` event after we is established', () async {
      final _testWsListener = TestWebSocketListener();
      final _webSocketSupport = MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      final _completer = Completer();
      final _methodChannel = MethodChannelMock(
        channelName: MethodChannelWebSocketSupport.methodChannelName,
        methodMocks: [
          MethodMock(
              method: 'disconnect',
              action: () {
                _sendMessageFromPlatform(
                    MethodChannelWebSocketSupport.methodChannelName,
                    MethodCall('onClosed', <String, Object>{
                      'code': 123,
                      'reason': 'test reason'
                    }));
                _completer.complete();
              }),
        ],
      );

      // Act -> disconnect
      await _webSocketSupport.disconnect(code: 123, reason: 'test reason');

      // await completer
      await _completer.future;

      // Assert
      // correct event sent to platform
      expect(
        _methodChannel.log,
        <Matcher>[
          isMethodCall('disconnect', arguments: <String, Object>{
            'code': 123,
            'reason': 'test reason',
          }),
        ],
      );

      // platform response 'onOpened' created wsConnection
      expect(_testWsListener.webSocketConnection, isNotNull);

      // clean up
      await _testWsListener.destroy();
    });
  });

  group('$MethodChannelWebSocketSupport calls FROM platform', () {
    test('Receive `onOpened` event from platform', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // action
      // execute methodCall from platform
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive `onClosing` event from platform', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // action
      // execute methodCall from platform
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onClosing',
              <String, Object>{'code': 234, 'reason': 'test reason 2'}));

      // verify
      expect(_testWsListener.onClosingCalled, true);
      expect(_testWsListener.closingCode, 234);
      expect(_testWsListener.closingReason, 'test reason 2');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive `onClosed` event from platform', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // action
      // execute methodCall from platform
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onClosed',
              <String, Object>{'code': 345, 'reason': 'test reason 3'}));

      // verify
      expect(_testWsListener.onClosedCalled, true);
      expect(_testWsListener.closingCode, 345);
      expect(_testWsListener.closingReason, 'test reason 3');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive `onFailure` event from platform', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // action
      // execute methodCall from platform
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onFailure', <String, Object>{
            'throwableType': 'TestType',
            'errorMessage': 'TestErrMsg',
            'causeMessage': 'TestErrCause'
          }));

      // verify
      expect(_testWsListener.onErrorCalled, true);
      expect(_testWsListener.exception, isInstanceOf<WebSocketException>());
      expect(_testWsListener.exception.toString(),
          'WebSocketException[type:TestType, message:TestErrMsg, cause:TestErrCause]');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive event from platform via textEventChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // prepare
      // text message channel mock (before we is opened)
      final _streamController = StreamController<String>.broadcast();
      EventChannelMock(
        channelName: MethodChannelWebSocketSupport.textEventChannelName,
        stream: _streamController.stream,
      );

      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // action
      // emit test event
      _streamController.add('Text message 1');

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);
      expect(await _testWsListener.textQueue.next.timeout(Duration(seconds: 1)),
          'Text message 1');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive error event from platform via textEventChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // prepare
      // text message channel mock (before we is opened)
      final _streamController = StreamController<String>.broadcast();
      EventChannelMock(
        channelName: MethodChannelWebSocketSupport.textEventChannelName,
        stream: _streamController.stream,
      );

      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // action
      // emit test error event
      _streamController.addError(
        PlatformException(
            code: 'ERROR_CODE_3', message: 'errMsg3', details: null),
      );

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);

      await _testWsListener.errorCompleter.future.timeout(Duration(seconds: 1));
      expect(_testWsListener.onErrorCalled, true);
      expect(_testWsListener.exception, isInstanceOf<PlatformException>());
      expect(_testWsListener.exception.toString(),
          'PlatformException(ERROR_CODE_3, errMsg3, null, null)');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive event from platform via byteEventChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // prepare
      // text message channel mock (before we is opened)
      final _streamController = StreamController<Uint8List>.broadcast();
      EventChannelMock(
        channelName: MethodChannelWebSocketSupport.byteEventChannelName,
        stream: _streamController.stream,
      );

      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // action
      // emit test event
      _streamController.add(Uint8List.fromList('Binary message 1'.codeUnits));

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);
      expect(await _testWsListener.byteQueue.next.timeout(Duration(seconds: 1)),
          'Binary message 1'.codeUnits);

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive error event from platform via byteEventChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // prepare
      // text message channel mock (before we is opened)
      final _streamController = StreamController<Uint8List>.broadcast();
      EventChannelMock(
        channelName: MethodChannelWebSocketSupport.byteEventChannelName,
        stream: _streamController.stream,
      );

      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // action
      // emit error test event
      _streamController.addError(
        PlatformException(
            code: 'ERROR_CODE_4', message: 'errMsg4', details: null),
      );

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);

      await _testWsListener.errorCompleter.future.timeout(Duration(seconds: 1));
      expect(_testWsListener.onErrorCalled, true);
      expect(_testWsListener.exception, isInstanceOf<PlatformException>());
      expect(_testWsListener.exception.toString(),
          'PlatformException(ERROR_CODE_4, errMsg4, null, null)');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive `onStringMessage` event via MethodChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // Act -> onStringMessage
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onStringMessage', 'Fallback message 1'));

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);
      expect(await _testWsListener.textQueue.next.timeout(Duration(seconds: 1)),
          'Fallback message 1');

      // clean up
      await _testWsListener.destroy();
    });

    test('Receive `onByteArrayMessage` event via MethodChannel', () async {
      final _testWsListener = TestWebSocketListener();
      MethodChannelWebSocketSupport(_testWsListener);

      // Arrange
      // open ws
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onOpened'));

      // Act -> onByteArrayMessage
      await _sendMessageFromPlatform(
          MethodChannelWebSocketSupport.methodChannelName,
          MethodCall('onByteArrayMessage',
              Uint8List.fromList('Fallback message 2'.codeUnits)));

      // verify
      expect(_testWsListener.webSocketConnection, isNotNull);
      expect(await _testWsListener.byteQueue.next.timeout(Duration(seconds: 1)),
          'Fallback message 2'.codeUnits);

      // clean up
      await _testWsListener.destroy();
    });
  });
}

Future<ByteData?> _sendMessageFromPlatform(
    String channelName, MethodCall methodCall) {
  final envelope = const StandardMethodCodec().encodeMethodCall(methodCall);
  return TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
      .handlePlatformMessage(channelName, envelope, (data) {});
}
