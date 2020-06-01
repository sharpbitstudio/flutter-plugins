/// The class should hold values for further plugin options and features.
/// All fields must be optional so that we keep backward compatibility
class WebSocketOptions {
  final bool autoReconnect;
  final int pingInterval;
  final Map<String, String> headers;

  WebSocketOptions({
    this.autoReconnect = false,
    this.pingInterval = 0,
    this.headers = const {},
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'autoReconnect': autoReconnect,
        'pingInterval': pingInterval,
        'headers': headers,
      };
}
