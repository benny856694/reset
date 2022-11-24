/* 
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/
class Reply {
  String? cmd;
  int? code;
  String? devicesn;
  String? reply;

  Reply({this.cmd, this.code, this.devicesn, this.reply});

  Reply.fromJson(Map<String, dynamic> json) {
    cmd = json['cmd'];
    code = json['code'];
    devicesn = json['device_sn'];
    reply = json['reply'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cmd'] = cmd;
    data['code'] = code;
    data['device_sn'] = devicesn;
    data['reply'] = reply;
    return data;
  }
}
