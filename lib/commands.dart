import 'package:dio/dio.dart';
import 'package:reset/auth_cmd.dart';
import 'package:reset/reply.dart';

String resetCfgCmd(bool backup) {
  var cmd = '';
  if (backup) {
    cmd =
        'mv /data_fs/config/face.ini /data_fs/config/face.ini.${DateTime.now().toIso8601String()}';
  } else {
    cmd = 'rm /data_fs/config/face.ini';
  }
  return cmd;
}

const rebootCmd = 'reboot';

const resetDingDingCmd = 'rm -rf /data_fs/sdk_*';

const resetMultipleSendCmd = 'rm -f /data_fs/config/worksite_manager.json';

//删除广告文件
const clearADFilesCmd = 'rm -f /data_fs/screensaver/*';

Future<bool> resetPassword(String ip) async {
  final dio = Dio();
  try {
    final resp = await dio.post('http://$ip:8000', data: const AuthCmd());
    final reply = Reply.fromJson(resp.data);
    return reply.code == 0;
  } catch (e) {
    return false;
  }
}
