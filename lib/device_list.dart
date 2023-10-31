import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reset/device_discovery.dart';
import 'package:reset/extensions.dart';
import 'package:reset/main.dart';
import 'main.i18n.dart' as t;

final devicesListProvider = FutureProvider<List<Device>>((ref) async {
  "discover device".log();
  return discoverDevices();
});

class DeviceList extends HookConsumerWidget {
  const DeviceList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceList = ref.watch(devicesListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.deviceListTitle.i18n),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(devicesListProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: deviceList.when(
        skipLoadingOnRefresh: false,
        data: (devices) => ListView.separated(
          itemBuilder: ((context, index) {
            final d = devices[index];
            return ListTile(
              title: Text('${d.ip} - ${d.mac}'),
              subtitle: Text(d.platform),
              onTap: () async {
                await ref.read(ipAddressProvider.notifier).set(d.ip);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          }),
          separatorBuilder: (ctx, index) => const Divider(),
          itemCount: devices.length,
        ),
        error: (e, _) => Center(
          child: Text(e.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
