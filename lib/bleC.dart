import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
class BleController extends GetxController {
  Future scanDevices() async{
    if (await Permission.bluetoothScan.request().isGranted && await Permission.bluetoothConnect.request().isGranted){
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    }
  }
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}