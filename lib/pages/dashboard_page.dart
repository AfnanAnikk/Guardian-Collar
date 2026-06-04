import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double vibrationIntensity = 40;
  bool manualVibrationOn = false;

  String activity = 'Walking';
  String location = 'Waiting for GPS fix';
  String safeZone = 'Not set';
  String meowResult = 'No translation yet';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2933)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fakeUpdateActivity() {
    setState(() {
      activity = 'Walking';
    });
  }

  void _fakeFindMithu() {
    setState(() {
      location = '23.8103, 90.4125';
    });
  }

  void _fakeMeowTranslate() {
    setState(() {
      meowResult = 'Hungry - feed me';
    });
  }

  void _fakeSafeZone() {
    setState(() {
      safeZone = 'Inside safe zone';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        Text('Mithu is online', style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFFD7FF5F), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.pets_rounded, color: Color(0xFF1F2933)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _statusCard(title: 'Current Activity', value: activity, icon: Icons.directions_walk_rounded),
              const SizedBox(height: 12),
              _statusCard(title: 'Last Location', value: location, icon: Icons.location_on_rounded),
              const SizedBox(height: 12),
              _statusCard(title: 'Safe Zone', value: safeZone, icon: Icons.shield_rounded),

              const SizedBox(height: 24),

              const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
              const SizedBox(height: 12),

              _actionButton(text: 'Find Mithu', icon: Icons.my_location_rounded, onTap: _fakeFindMithu, filled: true),
              const SizedBox(height: 10),
              _actionButton(text: "What's Mithu Doing?", icon: Icons.monitor_heart_rounded, onTap: _fakeUpdateActivity),
              const SizedBox(height: 10),
              _actionButton(text: 'Set Safe Zone', icon: Icons.map_rounded, onTap: _fakeSafeZone),
              const SizedBox(height: 10),
              _actionButton(text: 'Meow to Human', icon: Icons.graphic_eq_rounded, onTap: _fakeMeowTranslate),

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

              const SizedBox(height: 24),

              const Text('Collar Control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF374957))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      text: 'Food Time',
                      icon: Icons.restaurant_rounded,
                      onTap: () {},
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      text: 'Calm Down',
                      icon: Icons.self_improvement_rounded,
                      onTap: () {},
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
                        setState(() {
                          vibrationIntensity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            manualVibrationOn = !manualVibrationOn;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: manualVibrationOn ? const Color(0xFF1F2933) : const Color(0xFFD7FF5F),
                          foregroundColor: manualVibrationOn ? Colors.white : const Color(0xFF1F2933),
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

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {},
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
            ],
          ),
        ),
      ),
    );
  }
}