import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reset/commands.dart';
import 'package:reset/telnet.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'main.i18n.dart' as t;

enum DeviceType { oldModel, newModel, unknownModel }

enum LoginState { idle, logging, loggedIn }

const rootUserName = 'root';
final ipAddressExp = RegExp(
    r'\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))\b');

final deviceTypeProvider = StateProvider((_) => DeviceType.oldModel);
final _currentCustomPasswordProvider = StateProvider((_) => '');
final _passwordProvider = Provider<String>((ref) {
  final dt = ref.watch(deviceTypeProvider);
  final currentCustomPassword = ref.watch(_currentCustomPasswordProvider);
  final m = {
    DeviceType.oldModel: 'antslq',
    DeviceType.newModel: 'haantslq',
    DeviceType.unknownModel: currentCustomPassword,
  };
  return m[dt]!;
});

final deviceTypeDescProvider = Provider((ref) {
  final dt = ref.watch(deviceTypeProvider);
  final m = {
    DeviceType.newModel: t.newModelDetails.i18n,
    DeviceType.oldModel: t.oldModelDetails.i18n,
    DeviceType.unknownModel: t.unknownModelDetails.i18n
  };

  return m[dt] ?? '';
});

final loginStateProvider = StateProvider((_) => LoginState.idle);

final loginEnabledProvider = Provider((ref) {
  final loginState = ref.watch(loginStateProvider);
  final ipAddress = ref.watch(_ipAddressProvider);
  final pwd = ref.watch(_passwordProvider);

  var result = false;
  switch (loginState) {
    case LoginState.idle:
      result = ipAddressExp.hasMatch(ipAddress) && pwd.isNotEmpty;
      break;
    case LoginState.logging:
      result = false;
      break;
    case LoginState.loggedIn:
      result = true;
      break;
  }

  return result;
});

final _ipAddressProvider = StateProvider((_) => '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 700),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("en", "US"),
        Locale("zh", "CN"),
      ],
      home: I18n(
        //initialLocale: const Locale('zh'),
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  //final String title = t.appTitle.i18n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = ref.watch(deviceTypeProvider);
    final loginState = ref.watch(loginStateProvider);
    final telnet = useState<Telnet?>(null);
    final logs = useState(<LogItem>[]);
    final scrollController = useScrollController();
    final deviceTypeDetails = ref.watch(deviceTypeDescProvider);
    final loginEnabled = ref.watch(loginEnabledProvider);

    ref.listen(
      deviceTypeProvider,
      (previous, next) {
        //isLoginButtonEnabled.value = enableLogin();
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle.i18n),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  label: Text(t.ipAddress.i18n),
                ),
                onChanged: (value) {
                  ref.read(_ipAddressProvider.notifier).state = value;
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
                        ref
                            .read(_currentCustomPasswordProvider.notifier)
                            .state = value;
                      },
                      enabled: deviceType == DeviceType.unknownModel,
                      obscureText: true,
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: LayoutBuilder(
                  builder: (buildContext, constraints) {
                    //const isLargeScreen = true;
                    // MediaQuery.of(ctx).size.width < 600;
                    final options = DeviceType.values
                        .map(
                          (e) => Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Radio(
                                visualDensity: VisualDensity.compact,
                                key: ValueKey(e.name),
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
                        )
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${t.deviceType.i18n} $deviceTypeDetails'),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: options,
                        ),
                      ],
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: loginEnabled
                    ? () async {
                        telnet.value?.terminate();
                        final state = ref.read(loginStateProvider.notifier);
                        if (state.state == LoginState.loggedIn) {
                          state.state = LoginState.idle;
                        } else {
                          logs.value = [];
                          state.state = LoginState.logging;
                          final pwd = ref.read(_passwordProvider);
                          telnet.value = Telnet(
                            ref.read(_ipAddressProvider.notifier).state,
                            23,
                            rootUserName,
                            pwd,
                            echoEnabled: false,
                            onLog: (log) {
                              final maskedLog =
                                  log.log.replaceAll(pwd, '*' * pwd.length);
                              logs.value = [
                                ...logs.value,
                                LogItem(log.id, maskedLog)
                              ];
                            },
                            onLogin: (success) {
                              ref.read(loginStateProvider.notifier).state =
                                  success
                                      ? LoginState.loggedIn
                                      : LoginState.idle;
                            },
                          );
                          await telnet.value?.startConnect();
                        }
                      }
                    : null,
                icon: loginState == LoginState.logging
                    ? const SizedBox.square(
                        dimension: 16.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : Icon(loginState == LoginState.loggedIn
                        ? Icons.logout
                        : Icons.login),
                label: Text(
                  loginState == LoginState.idle
                      ? t.login.i18n
                      : (loginState == LoginState.logging
                          ? t.loggingin.i18n
                          : t.logout.i18n),
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Wrap(
                spacing: 4.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: loginState == LoginState.loggedIn
                        ? () async {
                            var res = await showOkCancelAlertDialog(
                              context: context,
                              title: t.areYouSure.i18n,
                            );
                            if (res == OkCancelResult.ok) {
                              telnet.value?.writeline(resetCfgCmd(true));
                              await Future.delayed(const Duration(seconds: 2));
                              telnet.value?.writeline(rebootCmd);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.restore),
                    label: Text(t.resetAndReboot.i18n),
                  ),
                  ElevatedButton.icon(
                    onPressed: loginState == LoginState.loggedIn
                        ? () async {
                            var res = await showOkCancelAlertDialog(
                              context: context,
                              title: t.areYouSure.i18n,
                            );
                            if (res == OkCancelResult.ok) {
                              telnet.value?.writeline(resetCfgCmd(true));
                            }
                          }
                        : null,
                    icon: const Icon(Icons.restore),
                    label: Text(t.resetCfg.i18n),
                  ),
                  ElevatedButton.icon(
                    onPressed: loginState == LoginState.loggedIn
                        ? () async {
                            var res = await showOkCancelAlertDialog(
                              context: context,
                              title: t.areYouSure.i18n,
                            );
                            if (res == OkCancelResult.ok) {
                              telnet.value?.writeline(resetDingDingCmd);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.restore),
                    label: Text(t.resetDingDing.i18n),
                  ),
                  ElevatedButton.icon(
                    onPressed: loginState == LoginState.loggedIn
                        ? () async {
                            var res = await showOkCancelAlertDialog(
                              context: context,
                              title: t.areYouSure.i18n,
                            );
                            if (res == OkCancelResult.ok) {
                              telnet.value?.writeline(rebootCmd);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      t.reboot.i18n,
                    ),
                  ),
                ],
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              key: ValueKey(item.id),
                              item.log,
                            ),
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
