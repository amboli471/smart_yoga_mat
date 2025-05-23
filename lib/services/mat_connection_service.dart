import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class MatConnectionService extends ChangeNotifier {
  bool _isScanning = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  String? _lastConnectedDeviceId;
  Timer? _scanTimer;

  // Simulated device info
  String _matFirmwareVersion = "1.2.3";
  String _matName = "";
  int _matBatteryLevel = 85;

  // Getters
  bool get isScanning => _isScanning;
  ConnectionStatus get status => _status;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get matFirmwareVersion => _matFirmwareVersion;
  String get matName => _matName;
  int get matBatteryLevel => _matBatteryLevel;
  bool get isConnected => _status == ConnectionStatus.connected;

  MatConnectionService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastConnectedDeviceId = prefs.getString('lastConnectedMatId');
    _matName = prefs.getString('lastConnectedMatName') ?? "";

    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    _scanResults = [];
    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      _scanTimer = Timer(Duration(seconds: 10), () {
        stopScan();
      });
    } catch (e) {
      print('Error starting scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    _scanTimer?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> simulateConnection(String deviceName) async {
    _status = ConnectionStatus.connecting;
    _matName = deviceName;
    notifyListeners();

    await Future.delayed(Duration(seconds: 2));

    _status = ConnectionStatus.connected;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastConnectedMatId', deviceName);
    await prefs.setString('lastConnectedMatName', deviceName);

    notifyListeners();
    return true;
  }

  Future<void> disconnect() async {
    if (_status != ConnectionStatus.connected) return;

    await Future.delayed(Duration(milliseconds: 500));

    _status = ConnectionStatus.disconnected;
    _connectedDevice = null;
    _matName = "";

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastConnectedMatId');
    await prefs.remove('lastConnectedMatName');

    notifyListeners();
  }

  Future<bool> sendCommand(String command) async {
    if (_status != ConnectionStatus.connected) {
      return false;
    }

    await Future.delayed(Duration(milliseconds: 300));
    print('Sending command to yoga mat: $command');
    return true;
  }

  void updateBatteryLevel(int level) {
    _matBatteryLevel = level;
    notifyListeners();
  }
}