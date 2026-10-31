import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'power_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POWER GUARD APP',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
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

  Future<void> _toggleScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
      return;
    }
    if (!await _requestPermissions()) return;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> _connect(ScanResult r) async {
    await FlutterBluePlus.stopScan();
    final n = _name(r);
    final name = n.isEmpty ? r.device.remoteId.str : n;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await r.device.connect(
  license: License.free,
  timeout: const Duration(seconds: 10),
);
      if (!mounted) return;
      Navigator.pop(context); // tutup loading
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

  String _name(ScanResult r) {
    return r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : r.device.platformName;
  }

  String _jarak(int rssi) {
    if (rssi >= -55) return 'Sangat dekat';
    if (rssi >= -70) return 'Dekat';
    if (rssi >= -85) return 'Sedang';
    return 'Jauh';
  }

  Color _warna(int rssi) {
    if (rssi >= -55) return Colors.green;
    if (rssi >= -70) return Colors.lightGreen;
    if (rssi >= -85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bluetooth'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                _btOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                size: 18,
                color: _btOn ? Colors.blue : Colors.grey,
              ),
              label: Text(_btOn ? 'ON' : 'OFF'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_btOn)
            MaterialBanner(
              content: const Text('Bluetooth HP mati.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (await _requestPermissions()) {
                      await FlutterBluePlus.turnOn();
                    }
                  },
                  child: const Text('Aktifkan Bluetooth'),
                ),
              ],
            ),
          SwitchListTile(
            title: const Text('Hanya yang bernama'),
            value: _onlyNamed,
            onChanged: (v) => setState(() => _onlyNamed = v),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snap) {
                var list = List<ScanResult>.from(snap.data ?? []);
                if (_onlyNamed) {
                  list = list.where((r) => _name(r).isNotEmpty).toList();
                }
                list.sort((a, b) => b.rssi.compareTo(a.rssi));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${list.length} perangkat ditemukan'),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(
                              child: Text('Belum ada perangkat.\nTekan Scan.',
                                  textAlign: TextAlign.center),
                            )
                          : ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final r = list[i];
                                final name = _name(r);
                                final isEsp =
                                    name.toUpperCase().startsWith('ESP');
                                return ListTile(
                                  leading: Icon(
                                    isEsp ? Icons.memory : Icons.bluetooth,
                                    color: isEsp ? Colors.indigo : null,
                                  ),
                                  title: Text(
                                    name.isEmpty ? '(tanpa nama)' : name,
                                    style: TextStyle(
                                      fontWeight: isEsp
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(r.device.remoteId.str),
                                  onTap: () => _connect(r),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${r.rssi} dBm',
                                          style: TextStyle(
                                              color: _warna(r.rssi),
                                              fontWeight: FontWeight.bold)),
                                      Text(_jarak(r.rssi),
                                          style:
                                              const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              },
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
            icon: Icon(scanning ? Icons.stop : Icons.search),
            label: Text(scanning ? 'Stop' : 'Scan'),
          );
        },
      ),
    );
  }
}