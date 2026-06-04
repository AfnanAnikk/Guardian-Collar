import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'live_stream_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double vibrationIntensity = 40;
  bool manualVibrationOn = false;
  bool isLoadingStatus = true;
  bool isSendingCommand = false;

  String activity = 'Loading...';
  String location = 'Loading...';
  String safeZone = 'Loading...';
  String meowResult = 'Loading...';
  String lastUpdated = 'Not updated yet';

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final result = await ApiService.getStatus();
      final data = result['data'];

      if (!mounted) return;

      setState(() {
        activity = data['activity']?.toString() ?? 'Waiting for ESP32';
        location = data['gpsText']?.toString() ?? data['gps_text']?.toString() ?? 'Waiting for GPS fix';
        safeZone = data['safeZoneStatus']?.toString() ?? data['safe_zone_status']?.toString() ?? 'Not set';
        meowResult = data['meowText']?.toString() ?? data['meow_text']?.toString() ?? 'No translation yet';
        lastUpdated = data['updatedAt']?.toString() ?? data['updated_at']?.toString() ?? 'Not updated yet';
        isLoadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingStatus = false;
      });
      _showMessage('Could not load collar status');
    }
  }

  Future<void> _sendCommand(String type, {int? intensity}) async {
    setState(() => isSendingCommand = true);

    try {
      final result = await ApiService.sendCommand(
        type: type,
        intensity: intensity,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        _showMessage('Command failed');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send command');
    } finally {
      if (mounted) setState(() => isSendingCommand = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFD7FF5F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF1F2933)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, color: Color(0xFF374957), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isSendingCommand ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFFD7FF5F).withOpacity(0.75),
        highlightColor: const Color(0xFFD7FF5F).withOpacity(0.35),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFD7FF5F) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1F2933)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2933),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guardian Collar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
                          SizedBox(height: 4),
                          Text('Mithu status dashboard', style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadStatus,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text('Last updated: $lastUpdated', style: const TextStyle(fontSize: 12, color: Colors.grey)),

                const SizedBox(height: 20),

                _statusCard(title: 'Current Activity', value: activity, icon: Icons.directions_walk_rounded),
                const SizedBox(height: 12),
                _statusCard(title: 'Last Location', value: location, icon: Icons.location_on_rounded),
                const SizedBox(height: 12),
                _statusCard(title: 'Safe Zone', value: safeZone, icon: Icons.shield_rounded),

                const SizedBox(height: 24),

                const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
                const SizedBox(height: 12),

                _actionButton(text: 'Find Mithu', icon: Icons.my_location_rounded, onTap: () => _sendCommand('find_location')),
                const SizedBox(height: 10),
                _actionButton(text: "What's Mithu Doing?", icon: Icons.monitor_heart_rounded, onTap: () => _sendCommand('get_activity')),
                const SizedBox(height: 10),
                _actionButton(text: 'Set Safe Zone', icon: Icons.map_rounded, onTap: () => _sendCommand('set_safe_zone')),
                const SizedBox(height: 10),
                _actionButton(text: 'Meow to Human', icon: Icons.graphic_eq_rounded, onTap: () => _sendCommand('meow_to_human')),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meow Translation', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(meowResult, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveStreamPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('Open Live Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F2933),
                      side: const BorderSide(color: Color(0xFFD7FF5F), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Collar Control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        text: 'Food Time',
                        icon: Icons.restaurant_rounded,
                        onTap: () => _sendCommand('food_time'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        text: 'Calm Down',
                        icon: Icons.self_improvement_rounded,
                        onTap: () => _sendCommand('calm_down'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manual Intensity: ${vibrationIntensity.round()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF374957))),
                      Slider(
                        value: vibrationIntensity,
                        min: 0,
                        max: 100,
                        activeColor: const Color(0xFF9BC400),
                        inactiveColor: Colors.grey.shade300,
                        onChanged: (value) {
                          setState(() => vibrationIntensity = value);
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => manualVibrationOn = !manualVibrationOn);
                            _sendCommand(
                              manualVibrationOn ? 'manual_vibration_on' : 'manual_vibration_off',
                              intensity: vibrationIntensity.round(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: manualVibrationOn ? const Color(0xFF1F2933) : const Color(0xFFD7FF5F),
                          foregroundColor: manualVibrationOn ? Colors.white : const Color(0xFF1F2933),
                          overlayColor: Colors.black.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                          child: Text(
                            manualVibrationOn ? 'Turn Vibration Off' : 'Turn Vibration On',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}