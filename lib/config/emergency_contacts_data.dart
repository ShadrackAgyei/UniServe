import '../models/emergency_contact.dart';

final List<EmergencyContact> campusEmergencyContacts = [
  EmergencyContact(
    name: 'Campus Security',
    phone: '+233302610330',
    department: 'Security',
    icon: 'security',
    sortOrder: 1,
  ),
  EmergencyContact(
    name: 'Medical Center',
    phone: '+233302610331',
    department: 'Health Services',
    icon: 'medical',
    sortOrder: 2,
  ),
  EmergencyContact(
    name: 'Fire Emergency',
    phone: '193',
    department: 'Fire Service',
    icon: 'fire',
    sortOrder: 3,
  ),
  EmergencyContact(
    name: 'Maintenance Office',
    phone: '+233302610332',
    department: 'Facilities',
    icon: 'maintenance',
    sortOrder: 4,
  ),
  EmergencyContact(
    name: 'Student Affairs',
    phone: '+233302610333',
    department: 'Administration',
    icon: 'admin',
    sortOrder: 5,
  ),
  EmergencyContact(
    name: 'IT Help Desk',
    phone: '+233302610334',
    department: 'IT Support',
    icon: 'it',
    sortOrder: 6,
  ),
  EmergencyContact(
    name: 'Counseling Center',
    phone: '+233302610335',
    department: 'Wellness',
    icon: 'counseling',
    sortOrder: 7,
  ),
  EmergencyContact(
    name: 'National Emergency',
    phone: '112',
    department: 'Emergency',
    icon: 'emergency',
    sortOrder: 8,
  ),
];
