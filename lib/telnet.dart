import 'package:telnet/telnet.dart';

class LogItem {
  final int id;
  final String log;

  LogItem(this.id, this.log);
}

class Telnet {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool? echoEnabled;
  final void Function(bool success)? onLogin;
  final void Function(bool success)? onConnect;
  final void Function(LogItem msg)? onLog;
  late final ITLConnectionTask _task;
  late final ITelnetClient? _client;
  bool _hasLogin = false;
  var id = 0;
  final Map<TLOpt, List<TLMsg>> _doReplyMap;
  final Map<TLOpt, List<TLMsg>> _willReplyMap;

  Telnet(
    this.host,
    this.port,
    this.username,
    this.password, {
    this.echoEnabled = true,
    this.onLogin,
    this.onConnect,
    this.onLog,
  })  : _doReplyMap = <TLOpt, List<TLMsg>>{
          TLOpt.echo: [
            echoEnabled == true
                ? TLOptMsg(TLCmd.will, TLOpt.echo) // [IAC WILL ECHO]
                : TLOptMsg(TLCmd.wont, TLOpt.echo)
          ], // [IAC WONT ECHO]
          TLOpt.logout: [],
          TLOpt.tmlType: [
            TLOptMsg(TLCmd.will, TLOpt.tmlType), // [IAC WILL TERMINAL_TYPE]
            TLSubMsg(TLOpt.tmlType, [
              0x00,
              0x41,
              0x4E,
              0x53,
              0x49
            ]), // [IAC SB TERMINAL_TYPE IS ANSI IAC SE]
          ],
          TLOpt.windowSize: [
            TLOptMsg(TLCmd.will, TLOpt.windowSize), // [IAC WILL WINDOW_SIZE]
            TLSubMsg(TLOpt.windowSize,
                [0x00, 0x5A, 0x00, 0x18]), // [IAC SB WINDOW_SIZE 90 24 IAC SE]
          ],
        },
        _willReplyMap = <TLOpt, List<TLMsg>>{
          TLOpt.echo: [
            echoEnabled == true
                ? TLOptMsg(TLCmd.doIt, TLOpt.echo) // [IAC DO ECHO]
                : TLOptMsg(TLCmd.doNot, TLOpt.echo)
          ], // [IAC DON'T ECHO]
          TLOpt.suppress: [
            TLOptMsg(TLCmd.doIt, TLOpt.suppress)
          ], // [IAC DO SUPPRESS_GO_AHEAD]
          TLOpt.logout: [],
        };

  Future startConnect() async {
    _task = TelnetClient.startConnect(
      host: host,
      port: port,
      onEvent: _onEvent,
      onError: _onError,
      onDone: _onDone,
    );
    await _task.waitDone();
    _client = _task.client;
    onConnect?.call(
      _client == null ? false : true,
    );
  }

  void write(String command) {
    if (_hasLogin) {
      _client?.write(TLTextMsg(command));
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

  void terminate() async {
    await _client?.terminate();
  }

  void _onEvent(TelnetClient? client, TLMsgEvent event) {
    if (event.type == TLMsgEventType.write &&
        event.msg.runtimeType != TLOptMsg) {
      //  onLog?.call(LogItem(id++, "[WRITE] ${event.msg}"));
    } else if (event.type == TLMsgEventType.read) {
      if (event.msg.runtimeType != TLOptMsg) {
        onLog?.call(LogItem(id++, "[READ] ${event.msg}"));
      }

      if (event.msg is TLOptMsg) {
        final cmd = (event.msg as TLOptMsg).cmd; // Telnet Negotiation Command.
        final opt = (event.msg as TLOptMsg).opt; // Telnet Negotiation Option.

        if (cmd == TLCmd.wont) {
          // Write [IAC DO opt].
          client?.write(TLOptMsg(TLCmd.doNot, opt));
        } else if (cmd == TLCmd.doNot) {
          // Write [IAC WON'T opt].
          client?.write(TLOptMsg(TLCmd.wont, opt));
        } else if (cmd == TLCmd.will) {
          if (_willReplyMap.containsKey(opt)) {
            // Reply the option.
            for (var msg in _willReplyMap[opt]!) {
              client?.write(msg);
            }
          } else {
            // Write [IAC DON'T opt].
            client?.write(TLOptMsg(TLCmd.doNot, opt));
          }
        } else if (cmd == TLCmd.doIt) {
          // Reply the option.
          if (_doReplyMap.containsKey(opt)) {
            for (var msg in _doReplyMap[opt]!) {
              client?.write(msg);
            }
          } else {
            // Write [IAC WON'T opt].
            client?.write(TLOptMsg(TLCmd.wont, opt));
          }
        }
      } else if (!_hasLogin && event.msg is TLTextMsg) {
        final text = (event.msg as TLTextMsg).text.toLowerCase();
        if (text.contains('login incorrect')) {
          client!.terminate();
          onLogin?.call(false);
        } else if (text.contains('#')) {
          _hasLogin = true;
          onLog?.call(LogItem(id++, "[INFO] Login OK!"));
          onLogin?.call(true);
        } else if (text.contains("login:") || text.contains("username:")) {
          // Write [username].
          client!.write(TLTextMsg("$username\r\n"));
        } else if (text.contains("password:")) {
          // Write [password].
          client!.write(TLTextMsg("$password\r\n"));
        }
      }
    }
  }

  void _onError(TelnetClient? client, dynamic error) {
    onLog?.call(LogItem(id++, "[ERROR] $error"));
    if (!_hasLogin) {
      onLogin?.call(false);
    }
  }

  void _onDone(TelnetClient? client) {
    onLog?.call(LogItem(id++, "[DONE]"));
  }
}
