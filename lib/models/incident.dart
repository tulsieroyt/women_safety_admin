import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final String userId;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status; // 'pending', 'in_progress', 'resolved'
  final String severity;
  final String? assignedTo;
  final List<String> mediaUrls;
  final String? policeStationId;
  final String? fireStationId;
  final String? ambulanceServiceId;
  final String? womenOrgId;

  Incident({
    required this.id,
    required this.userId,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    required this.severity,
    this.assignedTo,
    required this.mediaUrls,
    this.policeStationId,
    this.fireStationId,
    this.ambulanceServiceId,
    this.womenOrgId,
  });

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      severity: data['severity'] ?? 'normal',
      assignedTo: data['assignedTo'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      policeStationId: data['policeStationId'],
      fireStationId: data['fireStationId'],
      ambulanceServiceId: data['ambulanceServiceId'],
      womenOrgId: data['womenOrgId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'severity': severity,
      'assignedTo': assignedTo,
      'mediaUrls': mediaUrls,
      'policeStationId': policeStationId,
      'fireStationId': fireStationId,
      'ambulanceServiceId': ambulanceServiceId,
      'womenOrgId': womenOrgId,
    };
  }
}
