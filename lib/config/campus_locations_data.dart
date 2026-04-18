import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';

// Ashesi University campus coordinates
final LatLng campusCenter = LatLng(5.7599, -0.2197);

final List<CampusLocation> campusLocations = [
  CampusLocation(
    name: 'Main Library',
    category: 'Academic',
    position: LatLng(5.7602, -0.2195),
    description: 'The main campus library with study rooms and computer labs',
  ),
  CampusLocation(
    name: 'Lecture Hall A',
    category: 'Academic',
    position: LatLng(5.7596, -0.2200),
    description: 'Large lecture hall for introductory courses',
  ),
  CampusLocation(
    name: 'Lecture Hall B',
    category: 'Academic',
    position: LatLng(5.7594, -0.2193),
    description: 'Medium-sized lecture hall for upper-level courses',
  ),
  CampusLocation(
    name: 'Engineering Lab',
    category: 'Academic',
    position: LatLng(5.7598, -0.2188),
    description: 'Computer science and engineering laboratory',
  ),
  CampusLocation(
    name: 'Cafeteria',
    category: 'Dining',
    position: LatLng(5.7605, -0.2192),
    description: 'Main campus dining hall',
  ),
  CampusLocation(
    name: 'Student Residence - Block A',
    category: 'Housing',
    position: LatLng(5.7610, -0.2185),
    description: 'First-year student dormitory',
  ),
  CampusLocation(
    name: 'Student Residence - Block B',
    category: 'Housing',
    position: LatLng(5.7612, -0.2190),
    description: 'Upper-year student dormitory',
  ),
  CampusLocation(
    name: 'Sports Complex',
    category: 'Recreation',
    position: LatLng(5.7590, -0.2205),
    description: 'Gymnasium, basketball courts, and football field',
  ),
  CampusLocation(
    name: 'Admin Building',
    category: 'Administration',
    position: LatLng(5.7600, -0.2202),
    description: 'Administrative offices and student services',
  ),
  CampusLocation(
    name: 'Health Center',
    category: 'Health',
    position: LatLng(5.7607, -0.2198),
    description: 'Campus clinic and medical services',
  ),
];
