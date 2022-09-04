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

String rebootCmd() {
  return 'reboot';
}
