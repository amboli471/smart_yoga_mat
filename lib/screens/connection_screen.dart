import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import '../services/mat_connection_service.dart';
import '../theme/app_theme.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final List<Map<String, dynamic>> _nearbyMats = [
    {
      'name': 'YogaFlex Pro',
      'address': '00:11:22:33:44:55',
      'signal': 4,
      'battery': 85,
    },
    {
      'name': 'YogaFlex Lite',
      'address': '11:22:33:44:55:66',
      'signal': 3,
      'battery': 72,
    },
    {
      'name': 'YogaFlex Pro Max',
      'address': '22:33:44:55:66:77',
      'signal': 2,
      'battery': 94,
    },
  ];

  bool _isScanning = false;

  void _startScan() {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning for 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matService = Provider.of<MatConnectionService>(context);
    final isConnected = matService.status == ConnectionStatus.connected;
    final isConnecting = matService.status == ConnectionStatus.connecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Mat'),
      ),
      body: Column(
        children: [
          // Animation and status area
          _buildStatusArea(matService),

          // List of nearby mats
          Expanded(
            child: _isScanning || isConnecting
                ? _buildScanningIndicator()
                : _buildNearbyMatsList(matService),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning || isConnecting
                      ? null
                      : _startScan,
                  icon: Icon(Icons.refresh),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Mats'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (isConnected) ...[
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => matService.disconnect(),
                    icon: Icon(Icons.bluetooth_disabled),
                    label: Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusArea(MatConnectionService matService) {
    final isConnected = matService.status == ConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Animation
          isConnected
              ? Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success,
          )
              : Icon(
            Icons.bluetooth_searching,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          // Status text
          Text(
            isConnected
                ? 'Connected to ${matService.matName}'
                : 'Select a mat to connect',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          if (isConnected) ...[
            SizedBox(height: 8),
            Text(
              'Battery: ${matService.matBatteryLevel}% • Firmware: ${matService.matFirmwareVersion}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Scanning for nearby mats...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyMatsList(MatConnectionService matService) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _nearbyMats.length,
      itemBuilder: (context, index) {
        final mat = _nearbyMats[index];

        return FadeInUp(
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 100),
          child: Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.self_improvement,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              title: Text(
                mat['name'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Battery: ${mat['battery']}%'),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        mat['signal'],
                            (i) => Icon(
                          Icons.signal_cellular_alt_1_bar,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      ...List.generate(
                        4 - (mat['signal'] as num).toInt(),
                            (i) => Icon(
                          Icons.signal_cellular_alt_1_bar,
                          size: 14,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('Signal', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  matService.simulateConnection(mat['name']);
                  Navigator.pop(context);
                },
                child: Text('Connect'),
              ),
            ),
          ),
        );
      },
    );
  }
}