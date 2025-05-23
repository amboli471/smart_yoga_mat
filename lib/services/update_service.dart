import 'package:flutter/material.dart';
import 'dart:math';

class UpdateInfo {
  final String version;
  final String releaseDate;
  final List<String> changes;
  final int sizeInKb;
  final bool isCritical;

  const UpdateInfo({
    required this.version,
    required this.releaseDate,
    required this.changes,
    required this.sizeInKb,
    required this.isCritical,
  });
}

enum UpdateStatus {
  upToDate,
  updateAvailable,
  updating,
  updated,
  error,
}

class UpdateService extends ChangeNotifier {
  UpdateStatus _status = UpdateStatus.upToDate;
  String _currentVersion = "1.2.3";
  UpdateInfo? _availableUpdate;
  double _updateProgress = 0.0;
  String? _error;
  DateTime? _lastChecked;

  UpdateStatus get status => _status;
  String get currentVersion => _currentVersion;
  UpdateInfo? get availableUpdate => _availableUpdate;
  double get updateProgress => _updateProgress;
  String? get error => _error;
  DateTime? get lastChecked => _lastChecked;

  UpdateService() {
    checkForUpdates();
  }

  Future<void> checkForUpdates() async {
    _status = UpdateStatus.upToDate;
    _availableUpdate = null;
    _error = null;
    _lastChecked = DateTime.now(); // Add this line
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    if (Random().nextBool()) {
      _availableUpdate = const UpdateInfo(
        version: "1.3.0",
        releaseDate: "2025-06-15",
        changes: [
          "Improved pose detection accuracy",
          "Added support for custom sound tracks",
          "Fixed battery reporting issues",
          "Enhanced pressure sensitivity for better feedback"
        ],
        sizeInKb: 2458,
        isCritical: false,
      );
      _status = UpdateStatus.updateAvailable;
    } else {
      _status = UpdateStatus.upToDate;
    }

    notifyListeners();
  }

  Future<bool> installUpdate() async {
    if (_status != UpdateStatus.updateAvailable || _availableUpdate == null) {
      return false;
    }

    _status = UpdateStatus.updating;
    _updateProgress = 0.0;
    notifyListeners();

    try {
      // Simulate download and installation
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        _updateProgress = i / 10;
        notifyListeners();
      }

      await Future.delayed(const Duration(seconds: 1));

      // Update completed
      _currentVersion = _availableUpdate!.version;
      _status = UpdateStatus.updated;
      _availableUpdate = null;

      notifyListeners();
      return true;
    } catch (e) {
      print('Error installing update: $e');
      _status = UpdateStatus.error;
      _error = 'Failed to install update: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}