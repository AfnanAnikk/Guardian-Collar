import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiService {
  static const String baseUrl = 'https://guardian-collar.onrender.com';

  static Future<Map<String, dynamic>> getStatus() async {
      final res = await http.get(Uri.parse('$baseUrl/api/device/status'));
      return jsonDecode(res.body);
    }

    static Future<Map<String, dynamic>> setSafeZone({
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/safe-zone'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendCommand({
    required String type,
    int? intensity,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/device/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'intensity': intensity,
      }),
    );

    return jsonDecode(res.body);
  }
}