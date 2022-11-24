/* 
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/
class Auth {
  bool? enable;
  String? username;
  String? password;

  Auth({this.enable, this.username, this.password});

  Auth.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    username = json['username'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    data['username'] = username;
    data['password'] = password;
    return data;
  }
}

class AuthCmd {
  String? cmd;
  Auth? auth;

  AuthCmd({this.cmd, this.auth});

  AuthCmd.fromJson(Map<String, dynamic> json) {
    cmd = json['cmd'];
    auth = json['auth'] != null ? Auth?.fromJson(json['auth']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cmd'] = cmd;
    data['auth'] = auth!.toJson();
    return data;
  }
}
