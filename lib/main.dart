import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const host = "127.0.0.1";
const port = 23;
const username = "root";
const password = "admin";
const echoEnabled = true;

enum DeviceType { oldModel, newModel }

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final counter = ref.watch(counterProvider);
    final deviceType = ref.watch(deviceTypeProvider);
    final isLoginButtonEnabled = useState(false);
    final ipAddressController = useTextEditingController();
    final isLoggedin = ref.watch(isLoggedinProvider);
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
                  isLoginButtonEnabled.value = value.isNotEmpty;
                },
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
                onPressed: isLoginButtonEnabled.value
                    ? () {
                        var v = ref.read(isLoggedinProvider.notifier).state;
                        ref.read(isLoggedinProvider.notifier).state = !v;
                      }
                    : null,
                icon: const Icon(Icons.login),
                label: !isLoggedin ? const Text('Login') : const Text("Logout"),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("日志"),
                    Expanded(
                      child: Text("logs"),
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
