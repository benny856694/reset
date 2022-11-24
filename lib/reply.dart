// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

class Reply {
  Reply({
    this.cmd = '',
    this.code = 0,
    this.deviceSn = '',
    this.reply = '',
  });

  final String cmd;
  final int code;
  final String deviceSn;
  final String reply;

  factory Reply.fromRawJson(String str) => Reply.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
        cmd: json["cmd"],
        code: json["code"],
        deviceSn: json["device_sn"],
        reply: json["reply"],
      );

  Map<String, dynamic> toJson() => {
        "cmd": cmd,
        "code": code,
        "device_sn": deviceSn,
        "reply": reply,
      };
}
