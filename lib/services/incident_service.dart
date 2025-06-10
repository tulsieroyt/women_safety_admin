import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../models/emergency_service.dart';

class IncidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _incidentsCollection =
      _firestore.collection('incidents');

  // Get all incidents
  static Stream<List<Incident>> getAllIncidents() {
    return _incidentsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList());
  }

  // Get incidents by status
  static Stream<List<Incident>> getIncidentsByStatus(String status) {
    if (status == 'all') return getAllIncidents();

    return _incidentsCollection
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList());
  }

  // Get a single incident
  static Stream<Incident?> getIncident(String incidentId) {
    return _incidentsCollection
        .doc(incidentId)
        .snapshots()
        .map((doc) => doc.exists ? Incident.fromFirestore(doc) : null);
  }

  // Update incident status
  static Future<void> updateIncidentStatus(String incidentId, String status) {
    return _incidentsCollection.doc(incidentId).update({'status': status});
  }

  // Get user details for an incident
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;
    return {'uid': userDoc.id, ...userDoc.data()!};
  }

  // Get assigned emergency service details
  static Future<EmergencyService?> getAssignedEmergencyService(
    String serviceId,
  ) async {
    if (serviceId.isEmpty) return null;
    final doc =
        await _firestore.collection('emergency_services').doc(serviceId).get();
    if (!doc.exists) return null;
    return EmergencyService.fromFirestore(doc);
  }
}
