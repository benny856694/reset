import 'package:flutter/material.dart';
import 'package:telnet/telnet.dart';


const host = "127.0.0.1";
const port = 23;
const username = "root";
const password = "admin";
const echoEnabled = true;


void main() async {
  runApp(const MyApp());

  final task = TelnetClient.startConnect(
    host: host,
    port: port,
    onEvent: _onEvent,
    onError: _onError,
    onDone: _onDone,
  );

  // Cancel the connection task.
  // task.cancel();

  // Wait the connection task finished.
  await task.waitDone();

  // Get the `TelnetClient` instance. It will be `null` if connect failed.
  final client = task.client;
  if (client == null) {
    print("Fail to connect to $host:$port");
  } else {
    print("Successfully connect to $host:$port");
  }

  await Future.delayed(const Duration(seconds: 10));

  // Close the Telnet connection.
  await client?.terminate();

}


var _hasLogin = false;
final _willReplyMap = <TLOpt, List<TLMsg>>{
  TLOpt.echo: [echoEnabled
      ? TLOptMsg(TLCmd.doIt, TLOpt.echo)                      // [IAC DO ECHO]
      : TLOptMsg(TLCmd.doNot, TLOpt.echo)],                   // [IAC DON'T ECHO]
  TLOpt.suppress: [TLOptMsg(TLCmd.doIt, TLOpt.suppress)],     // [IAC DO SUPPRESS_GO_AHEAD]
  TLOpt.logout: [],
};
final _doReplyMap = <TLOpt, List<TLMsg>>{
  TLOpt.echo: [echoEnabled
      ? TLOptMsg(TLCmd.will, TLOpt.echo)                      // [IAC WILL ECHO]
      : TLOptMsg(TLCmd.wont, TLOpt.echo)],                    // [IAC WONT ECHO]
  TLOpt.logout: [],
  TLOpt.tmlType: [
    TLOptMsg(TLCmd.will, TLOpt.tmlType),                      // [IAC WILL TERMINAL_TYPE]
    TLSubMsg(TLOpt.tmlType, [0x00, 0x41, 0x4E, 0x53, 0x49]),  // [IAC SB TERMINAL_TYPE IS ANSI IAC SE]
  ],
  TLOpt.windowSize: [
    TLOptMsg(TLCmd.will, TLOpt.windowSize),                   // [IAC WILL WINDOW_SIZE]
    TLSubMsg(TLOpt.windowSize, [0x00, 0x5A, 0x00, 0x18]),     // [IAC SB WINDOW_SIZE 90 24 IAC SE]
  ],
};

void _onEvent(TelnetClient? client, TLMsgEvent event) {
  if (event.type == TLMsgEventType.write) {
    print("[WRITE] ${event.msg}");

  } else if (event.type == TLMsgEventType.read) {
    print("[READ] ${event.msg}");

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
      if (text.contains("welcome")) {
        _hasLogin = true;
        print("[INFO] Login OK!");
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
  print("[ERROR] $error");
}

void _onDone(TelnetClient? client) {
  print("[DONE]");
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
