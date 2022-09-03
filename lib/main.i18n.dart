import 'package:i18n_extension/i18n_extension.dart';

const appTitle = "appTitle";
const ipAddress = "ipAddress";
const password = "password";
const deviceType = "deviceType";
const oldModel = "oldModel";
const newModel = "newModel";
const unknowModel = "unknownModel";
const login = "login";
const loggingin = 'logging';
const logout = "logout";
const resetCfg = "resetCfg";
const log = "log";

extension Localization on String {
  static const _t = Translations.from("en_us", {
    appTitle: {
      "en_us": "Reset Tool",
      "zh": "设备重置工具",
    },
    ipAddress: {
      "en_us": "IP Address",
      "zh": "IP地址",
    },
    password: {
      "en_us": "Password",
      "zh": "密码",
    },
    deviceType: {
      "en_us": "Device Type:",
      "zh": "设备类型：",
    },
    oldModel: {
      "en_us": "Old",
      "zh": "旧型号",
    },
    newModel: {
      "en_us": "New",
      "zh": "新型号",
    },
    unknowModel: {
      "en_us": "Unknown",
      "zh": "其他型号",
    },
    login: {
      "en_us": "Login",
      "zh": "登录",
    },
    loggingin: {
      "en_us": "Logging...",
      "zh": "登录中...",
    },
    logout: {
      "en_us": "Logout",
      "zh": "退出登录",
    },
    resetCfg: {
      "en_us": "Reset Config",
      "zh": "重置设置",
    },
    log: {
      "en_us": "Logs",
      "zh": "日志",
    },
  });

  String get i18n => localize(this, _t);
}
