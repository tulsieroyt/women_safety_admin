import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_service.dart';

class EmergencyServiceData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _servicesCollection =
      _firestore.collection('emergency_services');

  // Get all emergency services of a specific type
  static Stream<List<EmergencyService>> getServicesByType(ServiceType type) {
    return _servicesCollection
        .where('type', isEqualTo: type.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyService.fromFirestore(doc))
            .toList());
  }

  // Add a new emergency service
  static Future<DocumentReference> addEmergencyService(
      EmergencyService service) {
    return _servicesCollection.add(service.toFirestore());
  }

  // Update an existing emergency service
  static Future<void> updateEmergencyService(EmergencyService service) {
    return _servicesCollection.doc(service.id).update(service.toFirestore());
  }

  // Delete an emergency service
  static Future<void> deleteEmergencyService(String serviceId) {
    return _servicesCollection.doc(serviceId).delete();
  }

  // Get a single emergency service by ID
  static Future<EmergencyService?> getServiceById(String serviceId) async {
    final doc = await _servicesCollection.doc(serviceId).get();
    if (!doc.exists) return null;
    return EmergencyService.fromFirestore(doc);
  }
}
