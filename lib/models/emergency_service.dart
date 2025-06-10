import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceType {
  police,
  fire,
  ambulance,
  womenOrg,
}

class EmergencyService {
  final String id;
  final String name;
  final String address;
  final String contactNumber;
  final ServiceType type;
  final GeoPoint? location;

  EmergencyService({
    required this.id,
    required this.name,
    required this.address,
    required this.contactNumber,
    required this.type,
    this.location,
  });

  // Convert Firestore document to EmergencyService object
  factory EmergencyService.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyService(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      type: ServiceType.values.firstWhere(
        (e) => e.toString() == 'ServiceType.${data['type']}',
        orElse: () => ServiceType.police,
      ),
      location: data['location'] as GeoPoint?,
    );
  }

  // Convert EmergencyService object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'type': type.toString().split('.').last,
      if (location != null) 'location': location,
    };
  }
}
