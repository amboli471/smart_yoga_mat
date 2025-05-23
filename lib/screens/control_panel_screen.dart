import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import '../services/mat_connection_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({Key? key}) : super(key: key);

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  bool _isWarmUpActive = false;
  bool _isRelaxationActive = false;
  int _activeSeconds = 0;
  int _totalSeconds = 300; // 5 minutes default
  
  @override
  void initState() {
    super.initState();
  }
  
  void _startWarmUp() {
    final matService = Provider.of<MatConnectionService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    setState(() {
      _isWarmUpActive = true;
      _isRelaxationActive = false;
      _activeSeconds = 0;
      _totalSeconds = 300; // 5 minutes
    });
    
    matService.sendCommand('start_warmup');
    analyticsService.recordFeatureUsage('Warm-Up Mode');
    
    _startTimer();
  }
  
  void _startRelaxation() {
    final matService = Provider.of<MatConnectionService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    setState(() {
      _isWarmUpActive = false;
      _isRelaxationActive = true;
      _activeSeconds = 0;
      _totalSeconds = 600; // 10 minutes
    });
    
    matService.sendCommand('start_relaxation');
    analyticsService.recordFeatureUsage('Relaxation Mode');
    
    _startTimer();
  }
  
  void _stopSession() {
    final matService = Provider.of<MatConnectionService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    String sessionType = _isWarmUpActive ? 'Warm-Up' : 'Relaxation';
    int durationMinutes = _activeSeconds ~/ 60;
    
    if (durationMinutes > 0) {
      analyticsService.recordSession(sessionType, durationMinutes);
    }
    
    setState(() {
      _isWarmUpActive = false;
      _isRelaxationActive = false;
    });
    
    matService.sendCommand('stop_session');
  }
  
  void _startTimer() {
    // In a real app, we would start a timer here
    // For the prototype, we'll just simulate progress
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && (_isWarmUpActive || _isRelaxationActive)) {
        setState(() {
          _activeSeconds += 5;
          if (_activeSeconds >= _totalSeconds) {
            _stopSession();
          }
        });
        
        if (_isWarmUpActive || _isRelaxationActive) {
          _startTimer();
        }
      }
    });
  }
  
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final matService = Provider.of<MatConnectionService>(context);
    final isConnected = matService.status == ConnectionStatus.connected;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mat Controls'),
      ),
      body: !isConnected
          ? _buildNotConnectedView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Your Mat',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a session by selecting one of the modes below',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  // Active session indicator
                  if (_isWarmUpActive || _isRelaxationActive)
                    _buildActiveSessionCard(),
                  
                  // Control buttons
                  FadeInUp(
                    duration: Duration(milliseconds: 500),
                    child: _buildControlCard(
                      title: 'Warm-Up Mode',
                      description: 'Increase temperature and pressure sensitivity for a gentle warm-up session',
                      icon: Icons.whatshot,
                      color: AppColors.primary,
                      isActive: _isWarmUpActive,
                      onTap: _isRelaxationActive ? null : _isWarmUpActive ? _stopSession : _startWarmUp,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  FadeInUp(
                    duration: Duration(milliseconds: 500),
                    delay: Duration(milliseconds: 100),
                    child: _buildControlCard(
                      title: 'Relaxation Mode',
                      description: 'Gentle vibrations and subtle heating for deep relaxation',
                      icon: Icons.spa,
                      color: AppColors.secondary,
                      isActive: _isRelaxationActive,
                      onTap: _isWarmUpActive ? null : _isRelaxationActive ? _stopSession : _startRelaxation,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Mat status
                  FadeInUp(
                    duration: Duration(milliseconds: 500),
                    delay: Duration(milliseconds: 200),
                    child: _buildMatStatusCard(matService),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildNotConnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets3.lottiefiles.com/packages/lf20_yjrdpceb.json',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Not Connected',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please connect to your yoga mat first to access controls',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.bluetooth),
              label: Text('Go to Connection Screen'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActiveSessionCard() {
    double progress = _activeSeconds / _totalSeconds;
    String timeLeft = _formatTime(_totalSeconds - _activeSeconds);
    String mode = _isWarmUpActive ? 'Warm-Up' : 'Relaxation';
    
    return FadeIn(
      child: Card(
        color: _isWarmUpActive ? AppColors.primaryLight : AppColors.secondaryLight,
        margin: EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isWarmUpActive ? Icons.whatshot : Icons.spa,
                    color: _isWarmUpActive ? AppColors.primaryDark : AppColors.secondaryDark,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$mode Mode Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isWarmUpActive ? AppColors.primaryDark : AppColors.secondaryDark,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _isWarmUpActive ? AppColors.primaryDark : AppColors.secondaryDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    timeLeft,
                    style: TextStyle(
                      color: _isWarmUpActive ? AppColors.primaryDark : AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(
                  _isWarmUpActive ? AppColors.primaryDark : AppColors.secondaryDark,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _stopSession,
                icon: Icon(Icons.stop),
                label: Text('Stop Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(isActive ? Icons.stop : Icons.play_arrow),
                label: Text(isActive ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.redAccent : color,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatStatusCard(MatConnectionService matService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mat Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            _buildStatusRow(
              icon: Icons.battery_charging_full,
              title: 'Battery',
              value: '${matService.matBatteryLevel}%',
              color: _getBatteryColor(matService.matBatteryLevel),
            ),
            Divider(height: 24),
            _buildStatusRow(
              icon: Icons.memory,
              title: 'Firmware',
              value: matService.matFirmwareVersion,
              color: AppColors.primary,
            ),
            Divider(height: 24),
            _buildStatusRow(
              icon: Icons.bluetooth_connected,
              title: 'Connection',
              value: 'Connected',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Color _getBatteryColor(int level) {
    if (level > 50) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.error;
  }
}