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
const edit = 'edit';
const resetTouchScreenPwds = 'resetTouchScreenPwds';

extension Localization on String {
  static const _t = Translations.from("zh", {
    appTitle: {
      "en": "Reset Tool v1.0",
      "zh": "设备重置工具 v1.0",
    },
    ipAddress: {
      "en": "IP Address",
      "zh": "IP地址",
    },
    password: {
      "en": "Password",
      "zh": "密码",
    },
    deviceType: {
      "en": "Device Type:",
      "zh": "设备类型：",
    },
    oldModel: {
      "en": "Old",
      "zh": "旧型号",
    },
    newModel: {
      "en": "New",
      "zh": "新型号",
    },
    unknowModel: {
      "en": "Unknown",
      "zh": "其他型号",
    },
    login: {
      "en": "Login",
      "zh": "登录",
    },
    loggingin: {
      "en": "Login...",
      "zh": "登录中...",
    },
    logout: {
      "en": "Logout",
      "zh": "退出登录",
    },
    resetCfg: {
      "en": "Reset Cfg",
      "zh": "重置",
    },
    resetAndReboot: {
      "en": "Reset & Reboot",
      "zh": "重置并重启",
    },
    log: {
      "en": "Logs",
      "zh": "日志",
    },
    reboot: {
      "en": "Reboot",
      "zh": "重启",
    },
    oldModelDetails: {
      "en": "EV300, DV300",
      "zh": "EV300, DV300",
    },
    newModelDetails: {
      "en": "DV350, EV500, DV350pro",
      "zh": "DV350, EV500, DV350pro",
    },
    unknownModelDetails: {
      "en": "Please input password",
      "zh": "请输入密码",
    },
    resetDingDing: {
      "en": "Reset DD",
      "zh": "重置钉钉",
    },
    areYouSure: {
      "en": "Send selected command?",
      "zh": "下发选定的命令？",
    },
    resetPassword: {
      "en": "Reset Password",
      "zh": "重置密码",
    },
    success: {
      "en": "Succeed",
      "zh": "成功",
    },
    fail: {
      "en": "Failed",
      "zh": "失败",
    },
    startWatchDog: {
      "en": "Start Watchdog",
      "zh": "启动看门狗",
    },
    clearLogs: {
      "en": "Clear",
      "zh": "清除日志",
    },
    autoRunScriptAfterLogin: {
      "en": "Auto run script",
      "zh": "自动执行脚本",
    },
    edit: {
      "en": "Edit",
      "zh": "编辑",
    },
    resetTouchScreenPwds: {
      "en": "Reset Touch Pwds",
      "zh": "重置触屏密码",
    },
  });

  String get i18n => localize(this, _t);
}
