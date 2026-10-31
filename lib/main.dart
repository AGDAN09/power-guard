import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_theme.dart';
import 'power_page.dart';
// budi george poke wokwok
final ValueNotifier<ScanResult?> connectedDevice =
    ValueNotifier<ScanResult?>(null);

String scanName(ScanResult r) {
  return r.advertisementData.advName.isNotEmpty
      ? r.advertisementData.advName
      : r.device.platformName;
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POWER GUARD APP',
      theme: buildDarkTheme(),
      home: const PowerPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  BluetoothAdapterState _adapter = BluetoothAdapterState.unknown;
  bool _onlyNamed = false;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((s) {
      if (mounted) setState(() => _adapter = s);
    });
  }

  bool get _btOn => _adapter == BluetoothAdapterState.on;

  Future<bool> _requestPermissions() async {
    final result = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final ok = result.values.every((s) => s.isGranted);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Izin Bluetooth dan Lokasi diperlukan untuk scan.'),
          action: SnackBarAction(
              label: 'Pengaturan', onPressed: openAppSettings),
        ),
      );
    }
    return ok;
  }

  Future<void> _turnOn() async {
    try {
      if (await _requestPermissions()) {
        await FlutterBluePlus.turnOn();
      }
    } catch (_) {}
  }

  Future<void> _toggleScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
      return;
    }
    if (!await _requestPermissions()) return;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  Future<void> _connect(ScanResult r) async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    final n = scanName(r);
    final name = n.isEmpty ? r.device.remoteId.str : n;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await r.device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 30),
      );
      if (!mounted) return;
      Navigator.pop(context);
      connectedDevice.value = r;
      final sub = r.device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected &&
            connectedDevice.value?.device.remoteId == r.device.remoteId) {
          connectedDevice.value = null;
        }
      });
      r.device.cancelWhenDisconnected(sub, delayed: true, next: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terhubung ke $name')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal terhubung ke $name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Bluetooth',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _OnOffPill(on: _btOn),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_btOn) _BtOffBanner(onTap: _turnOn),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  const Expanded(child: Text('Hanya yang bernama')),
                  NeonSwitch(
                    value: _onlyNamed,
                    onChanged: (v) => setState(() => _onlyNamed = v),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snap) {
                var list = List<ScanResult>.from(snap.data ?? []);
                if (_onlyNamed) {
                  list = list.where((r) => scanName(r).isNotEmpty).toList();
                }
                list.sort((a, b) => b.rssi.compareTo(a.rssi));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${list.length} perangkat ditemukan',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          StreamBuilder<bool>(
                            stream: FlutterBluePlus.isScanning,
                            initialData: false,
                            builder: (context, s) => (s.data ?? false)
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.cyan,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada perangkat.\nTekan Scan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              itemCount: list.length,
                              itemBuilder: (_, i) => _DeviceTile(
                                r: list[i],
                                onTap: () => _connect(list[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (context, snap) {
          final scanning = snap.data ?? false;
          return FloatingActionButton.extended(
            onPressed: _btOn ? _toggleScan : null,
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.black,
            icon: Icon(scanning ? Icons.stop : Icons.search),
            label: Text(
              scanning ? 'Stop' : 'Scan',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        },
      ),
    );
  }
}

class _OnOffPill extends StatelessWidget {
  final bool on;
  const _OnOffPill({required this.on});

  @override
  Widget build(BuildContext context) {
    final c = on ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        //borderRadius: //BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? Icons.check : Icons.close, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            on ? 'ON' : 'OFF',
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BtOffBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _BtOffBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        //borderRadius: //BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panel,
            //borderRadius: //BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.8)),
          ),
          child: const Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.white70),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth HP mati',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ketuk untuk mengaktifkan dan memindai perangkat',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final ScanResult r;
  final VoidCallback onTap;
  const _DeviceTile({required this.r, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = scanName(r);
    final upper = name.toUpperCase();
    final isEsp = upper.startsWith('ESP') || upper.contains('POWERGUARD');
    final c = jarakColor(r.rssi);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panel,
        //borderRadius: //BorderRadius.circular(16),
        child: InkWell(
          //borderRadius: //BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //borderRadius: //BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(isEsp ? Icons.memory : Icons.bluetooth,
                    color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '(tanpa nama)' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.device.remoteId.str,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.rssi} dBm',
                      style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      jarakLabel(r.rssi),
                      style: TextStyle(color: c, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}//AMBATUKAAAAAAAAAMMMMMMMMMMMMMMMMMM!!!!!!!!!!!