import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'live_stream_page.dart';
import 'safe_zone_map_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_vibration_page.dart';

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
  List<Map<String, dynamic>> customPatterns = [];

  double? safeZoneLat;
  double? safeZoneLng;
  int? safeZoneRadius;

  double? collarLat;
  double? collarLng;

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
    _loadCustomPatterns();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStatus();
    });
  }

  Future<void> _loadCustomPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('custom_vibrations') ?? [];
    setState(() {
      customPatterns = stored.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
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
        final rawLocation = data['gpsText']?.toString() ?? data['gps_text']?.toString();

        _parseCollarLocation(rawLocation);

        if (collarLat != null && collarLng != null) {
          location = 'Location available';
        } else {
          location = 'Waiting for GPS fix';
        }
        safeZone = data['safeZoneStatus']?.toString() ?? data['safe_zone_status']?.toString() ?? 'Not set';
        meowResult = data['meowText']?.toString() ?? data['meow_text']?.toString() ?? 'No translation yet';
        lastUpdated = data['updatedAt']?.toString() ?? data['updated_at']?.toString() ?? 'Not updated yet';
        isLoadingStatus = false;
        safeZoneLat = data['safeZoneLatitude'];
        safeZoneLng = data['safeZoneLongitude'];
        safeZoneRadius = data['safeZoneRadius'];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingStatus = false;
      });
      _showMessage('Could not load collar status');
    }
  }

  Future<void> _sendCommand(String type, {int? intensity, List<int>? pattern}) async {
    setState(() => isSendingCommand = true);

    try {
      final result = await ApiService.sendCommand(
        type: type,
        intensity: intensity,
        pattern: pattern,
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

  void _parseCollarLocation(String? rawLocation) {
    if (rawLocation == null || !rawLocation.contains(',')) return;

    final parts = rawLocation.split(',');
    if (parts.length != 2) return;

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) return;

    collarLat = lat;
    collarLng = lng;
  }

  Future<void> _openCollarMap() async {
    if (collarLat == null || collarLng == null) {
      _showMessage('No collar location available yet');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$collarLat,$collarLng',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Could not open map');
    }
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
                  ],
                ),

                const SizedBox(height: 10),
                Text('Last updated: $lastUpdated', style: const TextStyle(fontSize: 12, color: Colors.grey)),

                const SizedBox(height: 20),

                _statusCard(title: 'Current Activity', value: activity, icon: Icons.directions_walk_rounded),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openCollarMap,
                  child: Container(
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
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFF1F2933)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Location',
                                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location,
                                style: const TextStyle(fontSize: 18, color: Color(0xFF374957), fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                collarLat == null || collarLng == null
                                    ? 'Waiting for collar GPS signal'
                                    : 'Tap to view collar on map',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: safeZone.toLowerCase().contains('outside')
                        ? const Color(0xFFFFE8E8)
                        : safeZone.toLowerCase().contains('not set')
                            ? const Color(0xFFF7F8FA)
                            : const Color(0xFFF1FFD0),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: safeZone.toLowerCase().contains('outside')
                              ? Colors.red.shade100
                              : const Color(0xFFD7FF5F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          safeZone.toLowerCase().contains('outside')
                              ? Icons.warning_rounded
                              : Icons.shield_rounded,
                          color: const Color(0xFF1F2933),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Safe Zone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              safeZone,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF374957),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap Edit Safe Zone to move or resize the boundary.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
                const SizedBox(height: 12),

                _actionButton(text: 'Find Mithu', icon: Icons.my_location_rounded, onTap: () => _sendCommand('find_location')),
                const SizedBox(height: 10),
                _actionButton(text: "What's Mithu Doing?", icon: Icons.monitor_heart_rounded, onTap: () => _sendCommand('get_activity')),
                const SizedBox(height: 10),
                _actionButton(
                  text: safeZone.toLowerCase().contains('not set') ? 'Set Safe Zone' : 'Edit Safe Zone',
                  icon: Icons.map_rounded,
                  filled: false,
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SafeZoneMapPage(),
                      ),
                    );

                    if (updated == true) {
                      _loadStatus();
                    }
                  },
                ),
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
                    onPressed: () async {
                      await _sendCommand('start_camera');

                      if (!mounted) return;

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

                Column(
                  children: [
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
                    const SizedBox(height: 10),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: _actionButton(
                          text: 'Come Back',
                          icon: Icons.keyboard_return_rounded,
                          onTap: () => _sendCommand('come_back'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (customPatterns.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 10),
                      ...customPatterns.map((patternObj) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _actionButton(
                            text: patternObj['name'],
                            icon: Icons.waves_rounded,
                            onTap: () {
                              List<dynamic> dynamicPattern = patternObj['pattern'];
                              List<int> patternList = dynamicPattern.cast<int>();
                              _sendCommand('custom_vibration', pattern: patternList);
                            },
                          ),
                        );
                      }),
                    ],
                    _actionButton(
                      text: 'Create Custom Vibration',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () async {
                        final added = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomVibrationPage()),
                        );
                        if (added == true) {
                          _loadCustomPatterns();
                        }
                      },
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