# web_socket_support_platform_interface

A common platform interface for the web_socket_support plugin.

This interface allows platform-specific implementations of the web_socket_support plugin, as well as 
the plugin itself, to ensure they are supporting the same interface.

## Usage

To implement a new platform-specific implementation of web_socket_support, extend WebSocketSupportPlatform 
with an implementation that performs the platform-specific behavior, and when you register your plugin, 
set the default WebSocketSupportPlatform by calling WebSocketSupportPlatform.instance = MyWebSocketSupportPlatform().

