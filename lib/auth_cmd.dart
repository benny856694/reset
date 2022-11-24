// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

class AuthCmd {
  const AuthCmd({
    this.cmd = "update app params",
    this.auth = const Auth(),
  });

  final String cmd;
  final Auth auth;

  factory AuthCmd.fromRawJson(String str) => AuthCmd.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AuthCmd.fromJson(Map<String, dynamic> json) => AuthCmd(
        cmd: json["cmd"],
        auth: json["auth"],
      );

  Map<String, dynamic> toJson() => {
        "cmd": cmd,
        "auth": auth.toJson(),
      };
}

class Auth {
  const Auth({
    this.enable = false,
    this.username = 'admin',
    this.password = 'admin',
  });

  final bool enable;
  final String username;
  final String password;

  factory Auth.fromRawJson(String str) => Auth.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Auth.fromJson(Map<String, dynamic> json) => Auth(
        enable: json["enable"],
        username: json["username"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "enable": enable,
        "username": username,
        "password": password,
      };
}
