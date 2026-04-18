import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/campus_locations_data.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Academic',
    'Dining',
    'Housing',
    'Recreation',
    'Administration',
    'Health',
  ];

  List<Marker> get _markers {
    final locations = _selectedCategory == null || _selectedCategory == 'All'
        ? campusLocations
        : campusLocations.where((l) => l.category == _selectedCategory).toList();

    final markers = locations.map((loc) {
      return Marker(
        point: loc.position,
        width: 40,
        height: 40,
        child: Semantics(
          button: true,
          label: loc.name,
          hint: 'Show location details',
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: () async {
                await HapticsService.tap(context);
                if (context.mounted) {
                  _showLocationInfo(loc.name, loc.description, loc.category);
                }
              },
              radius: 24,
              child: Icon(
                _categoryIcon(loc.category),
                color: _categoryColor(loc.category),
                size: 32,
              ),
            ),
          ),
        ),
      );
    }).toList();

    if (_userLocation != null) {
      markers.add(Marker(
        point: _userLocation!,
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Academic':
        return Icons.school;
      case 'Dining':
        return Icons.restaurant;
      case 'Housing':
        return Icons.home;
      case 'Recreation':
        return Icons.sports_soccer;
      case 'Administration':
        return Icons.business;
      case 'Health':
        return Icons.local_hospital;
      default:
        return Icons.location_on;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Academic':
        return const Color(0xFF1565C0); // blue
      case 'Dining':
        return const Color(0xFFE65100); // orange
      case 'Housing':
        return const Color(0xFF2E7D32); // green
      case 'Recreation':
        return const Color(0xFF6A1B9A); // purple
      case 'Administration':
        return const Color(0xFF283593); // indigo
      case 'Health':
        return const Color(0xFFC62828); // red
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _showLocationInfo(String name, String description, String category) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(category), color: cs.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: cs.onSurface)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(color: cs.secondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(description, style: TextStyle(color: cs.secondary, fontSize: 14)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services are disabled')),
            );
            AccessibilityService.announce(context, 'Location services are disabled');
          }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
            AccessibilityService.announce(context, 'Location permission denied');
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions permanently denied')),
          );
          AccessibilityService.announce(context, 'Location permissions permanently denied');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _mapController.move(_userLocation!, 17);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
        AccessibilityService.announce(context, 'Error getting location');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMPUS MAP', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: campusCenter,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uniserve',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected =
                      (_selectedCategory == null && cat == 'All') ||
                          _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        HapticsService.selection(context);
                        setState(() {
                          _selectedCategory = cat == 'All' ? null : cat;
                        });
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'center',
            tooltip: 'Center map',
            onPressed: () {
              HapticsService.tap(context);
              _mapController.move(campusCenter, 16);
            },
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'location',
            tooltip: 'Use current location',
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            child: _isLoadingLocation
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary))
                : const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
