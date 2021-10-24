import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web_socket_support_platform_interface/method_channel_web_socket_support.dart';
import 'package:web_socket_support_platform_interface/web_socket_connection.dart';
import 'package:web_socket_support_platform_interface/web_socket_listener.dart';
import 'package:web_socket_support_platform_interface/web_socket_support_platform_interface.dart';

import 'test_web_socket_listener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test(
        '$MethodChannelWebSocketSupport dummy listener throws exception on any call',
        () {
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onByteArrayMessage(Uint8List.fromList(List.empty())),
        throwsUnimplementedError,
      );
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onError(Exception()),
        throwsUnimplementedError,
      );
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onStringMessage(''),
        throwsUnimplementedError,
      );
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onWsClosed(1, ''),
        throwsUnimplementedError,
      );
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onWsClosing(1, ''),
        throwsUnimplementedError,
      );
      expect(
        () =>
            (WebSocketSupportPlatform.instance as MethodChannelWebSocketSupport)
                .listener
                .onWsOpened(WebSocketConnectionMock()),
        throwsUnimplementedError,
      );
    });

    test('Can be mocked with `implements`', () {
      final WebSocketSupportPlatform mock = WebSocketSupportPlatformMock();
      WebSocketSupportPlatform.instance = mock;
    });

    test('Can be extended', () {
      WebSocketSupportPlatform.instance =
          ExtendsWebSocketSupportPlatform(TestWebSocketListener());
    });

    test('Default implementation of `connect` should throw unimplemented error',
        () {
      // Arrange
      final webSocketSupport =
          ExtendsWebSocketSupportPlatform(TestWebSocketListener());

      // Act & Assert
      expect(
        () => webSocketSupport.connect('ws.test.com'),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of `disconnect` should throw unimplemented error',
        () {
      // Arrange
      final webSocketSupport =
          ExtendsWebSocketSupportPlatform(TestWebSocketListener());

      // Act & Assert
      expect(
        () => webSocketSupport.disconnect(),
        throwsUnimplementedError,
      );
    });
  });
}

class WebSocketConnectionMock extends Mock implements WebSocketConnection {}

class WebSocketSupportPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements WebSocketSupportPlatform {}

class ImplementsWebSocketSupportPlatform extends Mock
    implements WebSocketSupportPlatform {}

class ExtendsWebSocketSupportPlatform extends WebSocketSupportPlatform {
  ExtendsWebSocketSupportPlatform(WebSocketListener listener);
}
