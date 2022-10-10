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

const resetMultipleSend = 'rm -f /data_fs/config/worksite_manager.json';
