class WebSocketException implements Exception {
  final String originType;
  final String message;
  final String causeMessage;

  WebSocketException(this.originType, this.message, this.causeMessage);

  @override
  String toString() =>
      'WebSocketException[type:$originType, message:$message, cause:$causeMessage]';
}
