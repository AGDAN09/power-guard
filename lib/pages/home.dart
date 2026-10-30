import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../bleC.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class hometest extends StatelessWidget {
  const hometest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nyoba Bluetooth"),
        backgroundColor: const Color.fromARGB(255, 55, 192, 255),
      ),
      backgroundColor: const Color.fromARGB(255, 137, 218, 255),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (BleController controller) {
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    final results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return const Center(child: Text("Belum ada perangkat"));
                    }
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final data = results[index];
                        final name = data.device.platformName;
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(name.isEmpty ? "(tanpa nama)" : name),
                            subtitle: Text(data.device.remoteId.str),
                            trailing: Text(data.rssi.toString()),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Bluetooth",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => controller.scanDevices(),
                child: const Icon(Icons.bluetooth, size: 50, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}