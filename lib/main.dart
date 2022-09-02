import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reset/telnet.dart';

enum DeviceType { oldModel, newModel, otherModel }

final counterProvider = StateProvider((ref) => 0);
final deviceTypeProvider = StateProvider((_) => DeviceType.oldModel);
final isLoggedinProvider = StateProvider((_) => false);

void main() async {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  final ipAddressExp = RegExp(
      r'\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))\b');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final counter = ref.watch(counterProvider);
    final deviceType = ref.watch(deviceTypeProvider);
    final isLoginButtonEnabled = useState(false);
    final ipAddressController = useTextEditingController();
    final isLoggedIn = ref.watch(isLoggedinProvider);
    final isLogging = useState(false);
    final passwordController = useTextEditingController();
    final telnet = useState<Telnet?>(null);
    final logs = useState(<LogItem>[]);
    final scrollController = useScrollController();
    bool enableLogin() {
      var enabled = !isLogging.value;
      enabled = enabled && ipAddressExp.hasMatch(ipAddressController.text);
      var dt = ref.read(deviceTypeProvider.notifier);
      if (dt.state == DeviceType.otherModel) {
        enabled = enabled && passwordController.text.isNotEmpty;
      }
      return enabled;
    }

    ref.listen(
      deviceTypeProvider,
      (previous, next) {
        //isLoginButtonEnabled.value = enableLogin();
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: ipAddressController,
                decoration: const InputDecoration(
                  label: Text("Ip Address:"),
                ),
                onChanged: (value) {
                  isLoginButtonEnabled.value = enableLogin();
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        label: Text("Password:"),
                      ),
                      onChanged: (value) {
                        isLoginButtonEnabled.value = enableLogin();
                      },
                      enabled: deviceType == DeviceType.otherModel,
                      obscureText: true,
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Text("Device Type:"),
                    const SizedBox(
                      width: 32,
                    ),
                    ...DeviceType.values.map(
                      (e) => Expanded(
                        child: Row(
                          children: [
                            Radio(
                              value: e,
                              groupValue: deviceType,
                              onChanged: (value) {
                                ref.read(deviceTypeProvider.notifier).state =
                                    value!;
                                isLoginButtonEnabled.value = enableLogin();
                              },
                            ),
                            Text(
                              e.name,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: enableLogin()
                    ? () async {
                        if (isLoggedIn) {
                          telnet.value?.terminate();
                          ref.read(isLoggedinProvider.notifier).state = false;
                        } else {
                          isLogging.value = true;
                          var pwd = passwordController.text;
                          var dt = ref.read(deviceTypeProvider.notifier);
                          if (dt.state != DeviceType.otherModel) {
                            pwd = dt.state == DeviceType.oldModel
                                ? 'antslq'
                                : 'haantslq';
                          }

                          telnet.value = Telnet(
                            ipAddressController.text,
                            23,
                            'root',
                            pwd,
                            echoEnabled: false,
                            onLog: (log) {
                              final maskedLog = log.log
                                  .replaceAll(RegExp(r'antslq'), '******');
                              logs.value = [
                                ...logs.value,
                                LogItem(log.id, maskedLog)
                              ];
                            },
                            onLogin: () {
                              ref.read(isLoggedinProvider.notifier).state =
                                  true;
                            },
                          );
                          await telnet.value?.startConnect();
                          isLogging.value = false;
                        }
                      }
                    : null,
                icon: isLogging.value
                    ? const SizedBox.square(
                        dimension: 16.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.login),
                label: !isLoggedIn
                    ? Text(isLogging.value ? 'Logging...' : 'Login')
                    : const Text("Logout"),
              ),
              const SizedBox(
                height: 8.0,
              ),
              ElevatedButton.icon(
                onPressed: isLoggedIn
                    ? () {
                        telnet.value?.write("reboot \r\n");
                      }
                    : null,
                icon: const Icon(Icons.restore),
                label: const Text("Reset Config"),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("日志"),
                        IconButton(
                          onPressed: () {
                            logs.value = [];
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: logs.value.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = logs.value[index];
                          return ListTile(
                            dense: true,
                            key: ValueKey(
                              item.id,
                            ),
                            title: Text(item.log),
                          );
                        },
                        controller: scrollController,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
