// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class Device {
  final String mac;
  final String ip;
  final String platform;
  final String system;
  final String mask;
  const Device({
    required this.mac,
    required this.ip,
    required this.platform,
    required this.system,
    required this.mask,
  });

  Device copyWith({
    String? mac,
    String? ip,
    String? platform,
    String? system,
    String? mask,
  }) {
    return Device(
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      platform: platform ?? this.platform,
      system: system ?? this.system,
      mask: mask ?? this.mask,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mac': mac,
      'ip': ip,
      'platform': platform,
      'system': system,
      'mask': mask,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      mac: map['mac'] as String,
      ip: map['ip'] as String,
      platform: map['platform'] as String,
      system: map['system'] as String,
      mask: map['mask'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Device.fromJson(String source) =>
      Device.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Device(mac: $mac, ip: $ip, platform: $platform, system: $system, mask: $mask)';
  }

  @override
  bool operator ==(covariant Device other) {
    if (identical(this, other)) return true;

    return other.mac == mac;
  }

  @override
  int get hashCode {
    return mac.hashCode;
  }
}

int _countNonZeroBytes(Uint8List bytesArray, int start) {
  var cnt = 0;
  var i = start;
  while (bytesArray[i] != 0) {
    cnt++;
    i++;
  }
  return cnt + start;
}

const _multicastAddress = "224.0.1.1";
const _multicastPort = 6100;

Future<List<Device>> discoverDevices() async {
  // Get the interface IP address.

  final result = <Device>[];

  InternetAddress multicastAddress = InternetAddress(_multicastAddress);
  final socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, _multicastPort);
  socket.broadcastEnabled = true;
  socket.joinMulticast(multicastAddress);

  socket.send(
    [0xbb, 0x0b, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xbb, 0x0b, 0x00, 0x00],
    multicastAddress,
    _multicastPort,
  );

  final subscription = socket.listen((RawSocketEvent e) {
    Datagram? d = socket.receive();
    if (d == null) return;
    int type = ByteData.view(d.data.buffer).getInt32(0, Endian.little);

    // If the packet type is 3004, parse the packet and extract the device information.
    if (type == 3004 && d.data.length > 120) {
      final buffer = d.data;
      // Get the SN.
      const utf8 = Utf8Decoder();
      var start = 8;
      var end = _countNonZeroBytes(buffer, start);
      var mac = utf8.convert(buffer, 8, end).trim();

      // Get the IP address.
      start = 28;
      end = _countNonZeroBytes(buffer, start);
      var ip = utf8.convert(buffer, start, end).trim();

      start = 48;
      end = _countNonZeroBytes(buffer, start);
      // Get the mask.
      var mask = utf8.convert(buffer, start, end).trim();

      start = 84;
      end = _countNonZeroBytes(buffer, start);
      // Get the platform.
      var platform = utf8.convert(buffer, start, end).trim();

      start = 116;
      end = _countNonZeroBytes(buffer, start);
      // Get the system.
      var system = utf8.convert(buffer, start, end).trim();

      if (system != 'Depi') {
        final device = Device(
          mac: mac,
          ip: ip,
          platform: platform,
          system: system,
          mask: mask,
        );
        if (!result.contains(device)) {
          result.add(device);
        }
      }
    }
  });

  await Future.delayed(const Duration(seconds: 5));
  subscription.cancel();
  socket.close();
  return result;
}

Future<bool> setIpbyMac({
  required String mac,
  required String ip,
  required String mask,
  required String gateway,
}) async {
  final macBytes = ascii.encoder.convert('$mac '); //must append a space
  final ipBytes = ascii.encoder.convert(ip);
  final maskBytes = ascii.encoder.convert(mask);
  final gatewayBytes = ascii.encoder.convert(gateway);

  final bytes = Uint8List(4 * 2 + 20 * 4);
  final byteData = bytes.buffer.asByteData();
  byteData.setInt32(0, 3005, Endian.little); //header
  byteData.setInt32(4, 80, Endian.little); //length of following bytes
  bytes.setRange(8, 8 + macBytes.length, macBytes); //20 bytes
  bytes.setRange(28, 28 + ipBytes.length, ipBytes); //20 bytes
  bytes.setRange(48, 48 + maskBytes.length, maskBytes); //20 bytes
  bytes.setRange(68, 68 + gatewayBytes.length, gatewayBytes); //20 bytes

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final multiCast = InternetAddress(_multicastAddress);
  final result = socket.send(bytes, multiCast, _multicastPort) != 0;
  socket.close();
  return result;
}
