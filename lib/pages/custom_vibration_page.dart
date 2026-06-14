import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CustomVibrationPage extends StatefulWidget {
  const CustomVibrationPage({super.key});

  @override
  State<CustomVibrationPage> createState() => _CustomVibrationPageState();
}

class _CustomVibrationPageState extends State<CustomVibrationPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isRecording = false;
  
  List<int> _pattern = [];
  int _lastEventTime = 0;
  bool _isPressed = false;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _pattern = [];
      _lastEventTime = DateTime.now().millisecondsSinceEpoch;
      _isPressed = false;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      if (_isPressed) {
        _handleTapUp(null); // finish the current press
      }
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isRecording || _isPressed) return;
    
    int now = DateTime.now().millisecondsSinceEpoch;
    int offDuration = now - _lastEventTime;
    
    if (_pattern.isNotEmpty) {
      _pattern.add(offDuration);
    }
    
    _isPressed = true;
    _lastEventTime = now;
  }

  void _handleTapUp(TapUpDetails? details) {
    if (!_isRecording || !_isPressed) return;

    int now = DateTime.now().millisecondsSinceEpoch;
    int onDuration = now - _lastEventTime;
    
    _pattern.add(onDuration);
    
    _isPressed = false;
    _lastEventTime = now;
  }
  
  Future<void> _savePattern() async {
    if (_pattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a pattern first')),
      );
      return;
    }
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> storedPatterns = prefs.getStringList('custom_vibrations') ?? [];
    
    Map<String, dynamic> newPattern = {
      'name': _nameController.text.trim(),
      'pattern': _pattern,
    };
    
    storedPatterns.add(jsonEncode(newPattern));
    await prefs.setStringList('custom_vibrations', storedPatterns);
    
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Custom Vibration', style: TextStyle(color: Color(0xFF374957), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374957)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pattern Name (e.g. SOS)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording 
                  ? 'Recording... Tap and hold the big button below!'
                  : 'Press Start Recording, then tap to create a pattern.',
                style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: () => _handleTapUp(null),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isPressed ? const Color(0xFF1F2933) : const Color(0xFFF7F8FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD7FF5F), width: 4),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.touch_app_rounded,
                        size: 80,
                        color: _isPressed ? const Color(0xFFD7FF5F) : const Color(0xFF1F2933),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isRecording)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.fiber_manual_record, color: Colors.red),
                        label: const Text('Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF374957),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text('Stop Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _isRecording ? null : _savePattern,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF5F),
                  foregroundColor: const Color(0xFF1F2933),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('Save Pattern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
