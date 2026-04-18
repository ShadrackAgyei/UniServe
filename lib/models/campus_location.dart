import 'package:latlong2/latlong.dart';

class CampusLocation {
  final String name;
  final String category;
  final LatLng position;
  final String description;

  const CampusLocation({
    required this.name,
    required this.category,
    required this.position,
    required this.description,
  });
}
