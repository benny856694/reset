import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reset/commands.dart';
import 'package:reset/telnet.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'constants.dart';
import 'main.i18n.dart' as t;
import 'package:path/path.dart' as p;

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
  final pwd = ref.watch(_passwordProvider);

  var result = false;
  switch (loginState) {
    case LoginState.idle:
      result = ref.watch(ipAddressValidProvider) && pwd.isNotEmpty;
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

final ipAddressValidProvider = Provider((ref) {
  final ipaddr = ref.watch(_ipAddressProvider);
  return ipAddressExp.hasMatch(ipaddr);
});

final autoRunScriptProvider = StateProvider<bool>((ref) {
  return true;
});

List<Tuple3<String, String, List<String>>> customScripts = [];

final selectedScriptsProvider =
    StateProvider<Tuple3<String, String, List<String>>?>((ref) {
  return null;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    enumerateScripts();
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(500, 800),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

void enumerateScripts() {
  final executableDirectory = File(Platform.resolvedExecutable).parent.path;
  final scriptsDirctoryPath = p.join(executableDirectory, 'scripts');
  final scriptsDirectory = Directory(scriptsDirctoryPath);
  if (scriptsDirectory.existsSync()) {
    final scriptFiles = scriptsDirectory.listSync(followLinks: false).toList();
    for (var file in scriptFiles) {
      if (file.statSync().type == FileSystemEntityType.file) {
        final scripts = File(file.path).readAsLinesSync();
        if (scripts.isNotEmpty) {
          final t =
              Tuple3(p.basenameWithoutExtension(file.path), file.path, scripts);
          customScripts.add(t);
        }
      }
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        //useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("en"),
        Locale("zh"),
      ],
      home: I18n(
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  //final String title = t.appTitle.i18n;

  List<String> buildResetCmds(DeviceType currentModel) {
    var cmds = [
      resetCfgCmd(true),
      if (currentModel == DeviceType.newModel) resetMultipleSendCmd,
      if (currentModel == DeviceType.oldModel) clearADFilesCmd,
    ];
    return cmds;
  }

  List<String> buildStartWatchdogCmds(DeviceType currentModel) {
    var cmds = [
      cdHome,
      if (currentModel == DeviceType.newModel) startWatchDogOther,
      if (currentModel == DeviceType.oldModel) startWatchDogDV300,
    ];
    return cmds;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = ref.watch(deviceTypeProvider);
    final loginState = ref.watch(loginStateProvider);
    final telnet = useState<Telnet?>(null);
    final logs = useState(<LogItem>[]);
    final scrollController = useScrollController();
    final deviceTypeDetails = ref.watch(deviceTypeDescProvider);
    final loginEnabled = ref.watch(loginEnabledProvider);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    );
    final animationControllerPwd = useAnimationController(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    );
    final autoRunScript = ref.watch(autoRunScriptProvider);
    final selectedScripts = ref.watch(selectedScriptsProvider);
    final currentLocale =
        useState(I18n.localeStr.contains('zh') ? chinese : english);

    ref.listen(
      deviceTypeProvider,
      (previous, next) {
        //isLoginButtonEnabled.value = enableLogin();
        next == DeviceType.unknownModel
            ? animationControllerPwd.forward()
            : animationControllerPwd.reverse();
      },
    );

    ref.listen(loginStateProvider, (previous, next) {
      next == LoginState.loggedIn
          ? animationController.forward()
          : animationController.reverse();
    });

    Future<void> confirmCmds(Future<void> Function() onConfirmed) async {
      var res = await showOkCancelAlertDialog(
        context: context,
        title: t.areYouSure.i18n,
      );
      if (res == OkCancelResult.ok) {
        await onConfirmed();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(t.appTitle.i18n),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: t.appTitle.i18n,
                  children: const [
                    Text('增加重置双发平台'),
                    Text('增加清除广告文件'),
                    Text('增加启动看门狗命令'),
                    Text('增加登录后自动运行脚本(scripts目录)功能'),
                    Text('增加选择脚本功能'),
                    Text('增加重置触屏密码功能'),
                  ],
                );
              },
            )
          ],
        ),
        actions: [
          Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(
                width: 8,
              ),
              InkWell(
                child: Text(currentLocale.value),
                onTap: () {
                  final v = currentLocale.value == chinese ? english : chinese;
                  currentLocale.value = v;
                  I18n.of(context).locale = Locale(v == chinese ? 'zh' : 'en');
                },
              ),
              const SizedBox(
                width: 16,
              ),
            ],
          ),
        ],
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
              SizeTransition(
                sizeFactor: animationControllerPwd,
                axisAlignment: -1,
                child: TextField(
                  decoration: InputDecoration(
                    label: Text(t.password.i18n),
                  ),
                  onChanged: (value) {
                    ref.read(_currentCustomPasswordProvider.notifier).state =
                        value;
                  },
                  enabled: deviceType == DeviceType.unknownModel,
                  obscureText: true,
                ),
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
              if (customScripts.isNotEmpty)
                Row(
                  children: [
                    Checkbox(
                        value: autoRunScript,
                        onChanged: (value) => {
                              ref.read(autoRunScriptProvider.notifier).state =
                                  value == true
                            }),
                    Text(t.autoRunScriptAfterLogin.i18n),
                    const SizedBox(
                      width: 8,
                    ),
                    DropdownButtonHideUnderline(
                      child:
                          DropdownButton2<Tuple3<String, String, List<String>>>(
                        value: selectedScripts,
                        items: customScripts
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.item1)))
                            .toList(),
                        onChanged: !autoRunScript
                            ? null
                            : (value) {
                                ref
                                    .read(selectedScriptsProvider.notifier)
                                    .state = value;
                              },
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    if (selectedScripts != null)
                      OutlinedButton(
                          onPressed: () async {
                            Process.run("explorer", [selectedScripts.item2]);
                          },
                          child: Text(t.edit.i18n))
                  ],
                ),
              SizeTransition(
                sizeFactor: animationController,
                axisAlignment: -1,
                child: Center(
                  child: Wrap(
                    spacing: 4.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: loginState == LoginState.loggedIn
                            ? () async {
                                var res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: t.areYouSure.i18n,
                                );
                                if (res == OkCancelResult.ok) {
                                  var cmds = [
                                    ...buildResetCmds(ref
                                        .read(deviceTypeProvider.notifier)
                                        .state),
                                    rebootCmd,
                                  ];
                                  await telnet.value?.writeMultipleLines(cmds);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.restore),
                        label: Text(t.resetAndReboot.i18n),
                      ),
                      OutlinedButton.icon(
                        onPressed: loginState == LoginState.loggedIn
                            ? () async {
                                var res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: t.areYouSure.i18n,
                                );
                                if (res == OkCancelResult.ok) {
                                  var cmds = buildResetCmds(ref
                                      .read(deviceTypeProvider.notifier)
                                      .state);
                                  await telnet.value?.writeMultipleLines(cmds);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.restore),
                        label: Text(t.resetCfg.i18n),
                      ),
                      OutlinedButton.icon(
                        onPressed: loginState == LoginState.loggedIn
                            ? () async {
                                var res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: t.areYouSure.i18n,
                                );
                                if (res == OkCancelResult.ok) {
                                  var cmds = resetTouchScreenPasswordCmds;
                                  await telnet.value?.writeMultipleLines(cmds);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.restore),
                        label: Text(t.resetTouchScreenPwds.i18n),
                      ),
                      OutlinedButton.icon(
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
                      OutlinedButton.icon(
                        onPressed: loginState == LoginState.loggedIn
                            ? () async {
                                final cmds = buildStartWatchdogCmds(deviceType);
                                await confirmCmds(() async {
                                  telnet.value?.writeMultipleLines(cmds);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_red_eye),
                        label: Text(
                          t.startWatchDog.i18n,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: loginState == LoginState.loggedIn
                            ? () async {
                                await confirmCmds(() async {
                                  telnet.value?.writeline(rebootCmd);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          t.reboot.i18n,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              if (kDebugMode) ...[
                OutlinedButton.icon(
                  onPressed: ref.watch(ipAddressValidProvider)
                      ? () async {
                          await confirmCmds(() async {
                            final suc = await resetPassword(
                                ref.watch(_ipAddressProvider));
                            logs.value = [
                              ...logs.value,
                              LogItem.fromString(
                                  "${t.resetPassword.i18n}: ${suc ? t.success : t.fail}")
                            ];
                          });
                        }
                      : null,
                  icon: const Icon(Icons.password_outlined),
                  label: Text(t.resetPassword.i18n),
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
              OutlinedButton.icon(
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
                              if (success &&
                                  autoRunScript &&
                                  selectedScripts != null) {
                                telnet.value
                                    ?.writeMultipleLines(selectedScripts.item3);
                              }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t.log.i18n,
                            style: Theme.of(context).textTheme.bodySmall),
                        TextButton(
                          onPressed: () {
                            logs.value = [];
                          },
                          child: Text(t.clearLogs.i18n),
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
