import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mjpeg_stream/mjpeg_stream.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  static const String renderBaseUrl = 'https://guardian-collar.onrender.com';

  bool loading = true;
  String? streamUrl;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCameraUrl();
  }

  Future<void> fetchCameraUrl() async {
    try {
      final res = await http.get(
        Uri.parse('$renderBaseUrl/api/device/status'),
      );

      if (res.statusCode != 200) {
        throw Exception('Server returned ${res.statusCode}');
      }

      final data = jsonDecode(res.body);
      final url = data['cameraUrl'];

      if (url == null || url.toString().isEmpty) {
        throw Exception('Camera URL not available yet');
      }

      setState(() {
        streamUrl = url.toString();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget buildStreamBox() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2933),
            ),
          ),
        ),
      );
    }

    return MJPEGStreamScreen(
      streamUrl: streamUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      showLiveIcon: true,
      showLogs: false,
      showWatermark: false,
      borderRadius: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Live Camera',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF374957),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7FF5F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.videocam_rounded, color: Color(0xFF1F2933)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mithu Live View',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: buildStreamBox(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2933),
                    side: const BorderSide(color: Color(0xFFD7FF5F), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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