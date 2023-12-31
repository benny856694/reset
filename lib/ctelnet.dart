import 'package:ctelnet/ctelnet.dart';
import 'package:flutter/material.dart';
import 'package:reset/extensions.dart';

typedef LoginCallback = void Function(bool success);
typedef LogCallback = void Function(LogItem);

final _returnExp = RegExp(r'\r\n|\r|\n');
final _printableExp = RegExp(r'^[\x20-\x7E]+$');
final _unknownStringExp = RegExp(r'\[[0-9](;?[0-9]*)m');

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
  var _text = '';
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
        timeout: timeout,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onData: _onData,
        onError: onError);
  }

  void _onData(Message msg) {
    if (msg.isText) {
      final text = msg.text.toLowerCase();
      //text.characters.log();
      for (var c in text.characters) {
        //c.log();
        final isReturn = _returnExp.hasMatch(c);
        if (isReturn) {
          //'[return]'.log();
          final filtered = _text.trim().replaceAll(_unknownStringExp, '');
          filtered.log();
          if (filtered.isNotEmpty) {
            final item = LogItem.fromString('[READ] $filtered');
            onLog?.call(item);
          }
          _text = '';
        } else if (_printableExp.hasMatch(c)) {
          _text += c;
        }
      }
      if (text.contains('login incorrect')) {
        onLogin?.call(false);
      } else if (text.contains('#')) {
        if (!_hasLogin) {
          _hasLogin = true;
          onLogin?.call(true);
        }
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
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future terminate() async {
    await _client.disconnect();
  }
}
