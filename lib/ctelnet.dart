import 'package:ctelnet/ctelnet.dart';

typedef LoginCallback = void Function(bool success);
typedef LogCallback = void Function(LogItem);

class LogItem {
  final int id;
  final String log;

  static int _id = 0;
  static int get _nextId => _id++;

  LogItem(this.id, this.log);
  factory LogItem.fromString(String log) {
    return LogItem(_nextId, log);
  }
}

class MyTelnetClient {
  final String user;
  final String password;
  final String host;
  final int port;
  final Duration timeout;
  final ConnectionCallback onConnect;
  final ConnectionCallback onDisconnect;
  final ErrorCallback onError;
  //final DataCallback onData;
  final LoginCallback? onLogin;
  final LogCallback? onLog;
  bool _hasLogin = false;
  late ITelnetClient _client;

  MyTelnetClient({
    required this.user,
    required this.password,
    required this.host,
    required this.port,
    this.timeout = const Duration(seconds: 10),
    required this.onConnect,
    required this.onDisconnect,
    //required this.onData,
    required this.onError,
    required this.onLog,
    this.onLogin,
  }) {
    _client = CTelnetClient(
        host: host,
        port: port,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onData: _onData,
        onError: onError);
  }

  void _onData(Message msg) {
    if (msg.isText) {
      final text = msg.text.toLowerCase();
      final splits = text.split('\r\n');
      for (var element
          in splits.where((element) => element.isNotEmpty && element != '\r')) {
        onLog?.call(LogItem.fromString("[READ] $element"));
      }
      final item = LogItem.fromString('[Read] $text');
      onLog?.call(item);
      if (text.contains('login incorrect')) {
        onLogin?.call(false);
      } else if (text.contains('#')) {
        _hasLogin = true;
        onLogin?.call(true);
      } else if (text.contains("login:") || text.contains("username:")) {
        // Write [username].
        _client.send("$user\r\n");
      } else if (text.contains("password:")) {
        // Write [password].
        _client.send("$password\r\n");
      }
    }
  }

  Future connect() async {
    await _client.connect();
  }

  void write(String command) {
    if (_hasLogin) {
      _client.send(command);
    }
  }

  void writeline(String command) {
    if (_hasLogin) {
      write('$command \r\n');
    }
  }

  Future<void> writeMultipleLines(List<String> commands) async {
    for (var cmd in commands) {
      writeline(cmd);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void terminate() {
    _client.disconnect();
  }
}
