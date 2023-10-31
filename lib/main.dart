// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:path/path.dart' as p;
import 'package:reset/ctelnet.dart';
import 'package:reset/device_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import 'package:reset/commands.dart';
import 'package:reset/extensions.dart';

import 'constants.dart';
import 'main.i18n.dart' as t;

typedef ScriptFile = Tuple2<String, String>;

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
  final ipAddressValid = ref.watch(ipAddressValidProvider);

  var result = false;
  switch (loginState) {
    case LoginState.idle:
      result = ipAddressValid && pwd.isNotEmpty;
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

final ipAddressValidProvider = Provider((ref) {
  final ipaddr = ref.watch(ipAddressProvider);
  return switch (ipaddr) {
    AsyncData(value: final ip) => ipAddressExp.hasMatch(ip),
    _ => false,
  };
});

final customScriptsProvider = StateProvider<List<ScriptFile>>(
  (ref) {
    return enumerateScripts();
  },
);

final selectedScriptsProvider = StateProvider<ScriptFile?>((ref) {
  return null;
});

//ipaddress

class AsyncPrefValueNotifier<T> extends AsyncNotifier<T> {
  late SharedPreferences _prefs;
  String key;
  AsyncPrefValueNotifier({
    required this.key,
  });

  Future<T> _fetch() async {
    _prefs = await SharedPreferences.getInstance();
    final value = switch (T) {
      String => _prefs.getString(key) ?? '',
      bool => _prefs.getBool(key) ?? false,
      _ => throw Exception('not supported type'),
    };

    final res = value as T;
    return res;
  }

  @override
  FutureOr<T> build() async {
    return _fetch();
  }

  Future<void> set(T value) async {
    final _ = switch (T) {
      String => await _prefs.setString(key, value as String),
      bool => await _prefs.setBool(key, value as bool),
      _ => throw Exception('not supported type'),
    };
    //await _prefs.setString(key, value);
    state = await AsyncValue.guard(() async {
      return _fetch();
    });
  }
}

final ipAddressProvider =
    AsyncNotifierProvider<AsyncPrefValueNotifier<String>, String>(
        () => AsyncPrefValueNotifier(key: 'last_ip_address'));

final autoExecScriptProvider =
    AsyncNotifierProvider<AsyncPrefValueNotifier<bool>, bool>(
        () => AsyncPrefValueNotifier(key: 'auto_exec_script_on_login'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
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

List<ScriptFile> enumerateScripts() {
  var customScripts = <ScriptFile>[];
  final executableDirectory = File(Platform.resolvedExecutable).parent.path;
  final scriptsDirctoryPath = p.join(executableDirectory, 'scripts');
  final scriptsDirectory = Directory(scriptsDirctoryPath);
  if (scriptsDirectory.existsSync()) {
    final scriptFiles = scriptsDirectory.listSync(followLinks: false).toList();
    for (var file in scriptFiles) {
      if (file.statSync().type == FileSystemEntityType.file) {
        final t = ScriptFile(p.basenameWithoutExtension(file.path), file.path);
        customScripts.add(t);
      }
    }
  }

  customScripts.log();
  return customScripts;
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
    final telnet = useState<MyTelnetClient?>(null);
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
    final selectedScripts = ref.watch(selectedScriptsProvider);
    final currentLocale =
        useState(I18n.localeStr.contains('zh') ? chinese : english);
    final customScripts = ref.watch(customScriptsProvider);
    final ipAddress = ref.watch(ipAddressProvider);
    final initalValue = switch (ipAddress) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final ipAddressEditController = useTextEditingController();

    useEffect(() {
      ipAddressEditController.text = initalValue ?? '';
      return null;
    }, [initalValue]);
    final autoExecScript = ref.watch(autoExecScriptProvider);

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
                    Text('重置双发平台'),
                    Text('清除广告文件'),
                    Text('启动看门狗命令'),
                    Text('登录后自动运行脚本(scripts目录)'),
                    Text('选择脚本功能'),
                    Text('重置触屏密码功能'),
                    Text('自动保存IP地址'),
                    Text('使用CTelnet'),
                    Text('搜索设备'),
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
                controller: ipAddressEditController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    label: Text(t.ipAddress.i18n),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (context.mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => const DeviceList()));
                        }
                      },
                    )),
                onChanged: (value) async {
                  value.log();
                  await ref.read(ipAddressProvider.notifier).set(value);
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
                        value: switch (autoExecScript) {
                          AsyncData(:final value) => value,
                          _ => false,
                        },
                        onChanged: (value) async {
                          await ref
                              .read(autoExecScriptProvider.notifier)
                              .set(value == true);
                        }),
                    Text(t.autoRunScriptAfterLogin.i18n),
                    const SizedBox(
                      width: 8,
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<ScriptFile>(
                          value: selectedScripts,
                          items: customScripts
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e.item1)))
                              .toList(),
                          onChanged: switch (autoExecScript) {
                            AsyncData(value: final autoExec) => autoExec
                                ? (value) {
                                    ref
                                        .read(selectedScriptsProvider.notifier)
                                        .state = value;
                                  }
                                : null,
                            _ => null,
                          }
                          // autoRunScript
                          //     ? null
                          //     : (value) {
                          //         ref
                          //             .read(selectedScriptsProvider.notifier)
                          //             .state = value;
                          //       },
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
                          child: Text(t.edit.i18n)),
                    const SizedBox(
                      width: 8,
                    ),
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
                            ipAddress.whenData((ip) async {
                              final suc = await resetPassword(ip);
                              logs.value = [
                                ...logs.value,
                                LogItem.fromString(
                                    "${t.resetPassword.i18n}: ${suc ? t.success : t.fail}")
                              ];
                            });
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
                        //await telnet.value?.terminate();
                        final state = ref.read(loginStateProvider.notifier);
                        if (state.state == LoginState.loggedIn) {
                          state.state = LoginState.idle;
                        } else if (state.state == LoginState.idle) {
                          logs.value = [];
                          state.state = LoginState.logging;
                          final pwd = ref.read(_passwordProvider);
                          ipAddress.whenData((ip) async {
                            final oldClient = telnet.value;
                            telnet.value = MyTelnetClient(
                              host: ip,
                              port: 23,
                              user: rootUserName,
                              password: pwd,
                              timeout: const Duration(seconds: 2),
                              onConnect: () {},
                              onDisconnect: () {
                                'disconnected'.log();
                                ref.read(loginStateProvider.notifier).state =
                                    LoginState.idle;
                              },
                              onError: (err) {
                                if (err is TimeoutException) {
                                  ref.read(loginStateProvider.notifier).state =
                                      LoginState.idle;
                                }
                              },
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
                                autoExecScript.whenData((autoExec) async {
                                  if (success &&
                                      autoExec &&
                                      selectedScripts != null) {
                                    final scripts = File(selectedScripts.item2)
                                        .readAsLinesSync();
                                    scripts.log();
                                    await telnet.value
                                        ?.writeMultipleLines(scripts);
                                  }
                                });
                              },
                            );
                            'begin connect'.log();
                            await telnet.value?.connect();
                            oldClient?.terminate();
                          });
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
