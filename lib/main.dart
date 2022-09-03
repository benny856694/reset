import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reset/telnet.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'main.i18n.dart' as t;

enum DeviceType { oldModel, newModel, unknownModel }

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
      supportedLocales: const [
        Locale("en", "US"),
        Locale("zh", "CN"),
      ],
      home: I18n(
        initialLocale: const Locale('zh'),
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  MyHomePage({super.key});

  final String title = t.appTitle.i18n;

  final ipAddressExp = RegExp(
      r'\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))\b');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = ref.watch(deviceTypeProvider);
    final isLoggedIn = ref.watch(isLoggedinProvider);
    final isLogging = useState(false);
    final telnet = useState<Telnet?>(null);
    final logs = useState(<LogItem>[]);
    final customPassword = useState('');
    final ipAddress = useState('');
    final scrollController = useScrollController();
    bool enableLogin() {
      var enabled = !isLogging.value;
      enabled = enabled && ipAddressExp.hasMatch(ipAddress.value);
      var dt = ref.read(deviceTypeProvider.notifier);
      if (dt.state == DeviceType.unknownModel) {
        enabled = enabled && customPassword.value.isNotEmpty;
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
                decoration: InputDecoration(
                  label: Text(t.ipAddress.i18n),
                ),
                onChanged: (value) {
                  ipAddress.value = value;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        label: Text(t.password.i18n),
                      ),
                      onChanged: (value) {
                        customPassword.value = value;
                      },
                      enabled: deviceType == DeviceType.unknownModel,
                      obscureText: true,
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Text(t.deviceType.i18n),
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
                              },
                            ),
                            Text(
                              e.name.i18n,
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
                          var pwd = customPassword.value;
                          var dt = ref.read(deviceTypeProvider.notifier);
                          if (dt.state != DeviceType.unknownModel) {
                            pwd = dt.state == DeviceType.oldModel
                                ? 'antslq'
                                : 'haantslq';
                          }

                          telnet.value = Telnet(
                            ipAddress.value,
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
                    ? Text(isLogging.value ? t.loggingin.i18n : t.login.i18n)
                    : Text(t.logout.i18n),
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
                label: Text(t.resetCfg.i18n),
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
                        Text(t.log.i18n),
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
