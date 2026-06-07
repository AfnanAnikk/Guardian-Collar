import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class SafeZoneMapPage extends StatefulWidget {
  const SafeZoneMapPage({super.key});

  @override
  State<SafeZoneMapPage> createState() => _SafeZoneMapPageState();
}

class _SafeZoneMapPageState extends State<SafeZoneMapPage> {
  final MapController _mapController = MapController();

  LatLng? _safeZoneCenter;
  double _radius = 300;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      final permissionOk = await _handleLocationPermission();

      if (!permissionOk) {
        setState(() {
          _safeZoneCenter = const LatLng(23.8103, 90.4125);
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _safeZoneCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _safeZoneCenter = const LatLng(23.8103, 90.4125);
        _isLoading = false;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _useCurrentLocation() async {
    final permissionOk = await _handleLocationPermission();

    if (!permissionOk) {
      _showMessage('Location permission is required');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final newCenter = LatLng(position.latitude, position.longitude);

    setState(() => _safeZoneCenter = newCenter);
    _mapController.move(newCenter, 16);
  }

  Future<void> _saveSafeZone() async {
    final center = _safeZoneCenter;
    if (center == null) return;

    setState(() => _isSaving = true);

    try {
      final result = await ApiService.setSafeZone(
        latitude: center.latitude,
        longitude: center.longitude,
        radius: _radius.round(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showMessage('Safe zone saved');
        Navigator.pop(context, true);
      } else {
        _showMessage('Could not save safe zone');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save safe zone');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final center = _safeZoneCenter;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Set Safe Zone',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
      ),
      body: _isLoading || center == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 16,
                    onTap: (_, point) {
                      setState(() => _safeZoneCenter = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.guardian_collar',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: center,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: const Color(0xFFD7FF5F).withOpacity(0.28),
                          borderColor: const Color(0xFF9BC400),
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 54,
                          height: 54,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7FF5F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Color(0xFF1F2933),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Safe Zone Radius',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF374957),
                                ),
                              ),
                            ),
                            Text(
                              '${_radius.round()} m',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF9BC400),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radius,
                          min: 50,
                          max: 2000,
                          divisions: 39,
                          activeColor: const Color(0xFF9BC400),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setState(() => _radius = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _useCurrentLocation,
                                icon: const Icon(Icons.my_location_rounded),
                                label: const Text('Use My Location'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1F2933),
                                  side: const BorderSide(
                                    color: Color(0xFFD7FF5F),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveSafeZone,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFFD7FF5F),
                                  foregroundColor: const Color(0xFF1F2933),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap map or drag the paw to move the safe zone.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}