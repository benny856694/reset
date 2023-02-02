import 'package:i18n_extension/i18n_extension.dart';

const appTitle = "appTitle";
const ipAddress = "ipAddress";
const password = "password";
const deviceType = "deviceType";
const oldModel = "oldModel";
const oldModelDetails = 'oldModelDetails';
const newModel = "newModel";
const newModelDetails = 'newModelDetails';
const unknowModel = "unknownModel";
const unknownModelDetails = "unknownModelDetails";
const login = "login";
const loggingin = 'logging';
const logout = "logout";
const resetCfg = "resetCfg";
const log = "log";
const reboot = 'reboot';
const resetAndReboot = "rest&reboot";
const resetDingDing = 'resetCfgOfDingDing';
const areYouSure = 'areYouSure';
const resetPassword = 'resetPassword';
const success = 'success';
const fail = 'fail';
const startWatchDog = 'startWatchDog';
const clearLogs = 'clearLogs';
const autoRunScriptAfterLogin = 'autoRunScript';

extension Localization on String {
  static const _t = Translations.from("en_us", {
    appTitle: {
      "en_us": "Reset Tool v1.0",
      "zh": "设备重置工具 v1.0",
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
      "en_us": "Login...",
      "zh": "登录中...",
    },
    logout: {
      "en_us": "Logout",
      "zh": "退出登录",
    },
    resetCfg: {
      "en_us": "Reset Cfg",
      "zh": "重置",
    },
    resetAndReboot: {
      "en_us": "Reset & Reboot",
      "zh": "重置并重启",
    },
    log: {
      "en_us": "Logs",
      "zh": "日志",
    },
    reboot: {
      "en_us": "Reboot",
      "zh": "重启",
    },
    oldModelDetails: {
      "en_us": "EV300, DV300",
      //"zh": "重启",
    },
    newModelDetails: {
      "en_us": "DV350, EV500, DV350pro",
      //"zh": "重启",
    },
    unknownModelDetails: {
      "en_us": "Please input password",
      "zh": "请输入密码",
    },
    resetDingDing: {
      "en_us": "Reset DD",
      "zh": "重置钉钉",
    },
    areYouSure: {
      "en_us": "Send selected command?",
      "zh": "下发选定的命令？",
    },
    resetPassword: {
      "en_us": "Reset Password",
      "zh": "重置密码",
    },
    success: {
      "en_us": "Succeed",
      "zh": "成功",
    },
    fail: {
      "en_us": "Failed",
      "zh": "失败",
    },
    startWatchDog: {
      "en_us": "Start Watchdog",
      "zh": "启动看门狗",
    },
    clearLogs: {
      "en_us": "Clear",
      "zh": "清除日志",
    },
    autoRunScriptAfterLogin: {
      "en_us": "Auto run script",
      "zh": "自动执行脚本",
    },
  });

  String get i18n => localize(this, _t);
}
