import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id; //
  final String email; //
  final String? name; //
  final String? phoneNumber; //
  final String? address; //
  final String? profileImage; //
  final bool isVerified; //
  final bool isProfileComplete;
  final bool isBlocked; //
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? idType;
  final String? idImageUrl;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.address,
    this.profileImage,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.isBlocked = false,
    required this.createdAt,
    this.verifiedAt,
    this.idType,
    this.idImageUrl,
  });

  // Convert User object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isProfileComplete': isProfileComplete,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'idType': idType,
      'idImageUrl': idImageUrl,
    };
  }

  // Create User object from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle Timestamp conversion
    DateTime? createdAtDate;
    DateTime? verifiedAtDate;

    try {
      createdAtDate = data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    try {
      verifiedAtDate = data['verifiedAt'] is Timestamp
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null;
    } catch (e) {
      verifiedAtDate = null;
    }

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      profileImage: data['profileImage'],
      isVerified: data['isVerified'] ?? false,
      isProfileComplete: data['isProfileComplete'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      createdAt: createdAtDate,
      verifiedAt: verifiedAtDate,
      idType: data['idType'],
      idImageUrl: data['idImageUrl'],
    );
  }
}

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection =
      _firestore.collection('users');

  // Get user by ID
  static Stream<User?> getUserById(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? User.fromFirestore(doc) : null);
  }

  // Get all users
  static Stream<List<User>> getAllUsers() {
    return _usersCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Get unverified users
  static Stream<List<User>> getUnverifiedUsers() {
    return _usersCollection
        .where('isVerified', isEqualTo: false)
        .where('isProfileComplete', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Update user verification status
  static Future<void> updateUserVerification(
      String userId, bool isVerified) async {
    await _usersCollection.doc(userId).update({
      'isVerified': isVerified,
      'verifiedAt': isVerified ? Timestamp.now() : null,
    });
  }

  // Block/Unblock user
  static Future<void> updateUserBlockStatus(
      String userId, bool isBlocked) async {
    await _usersCollection.doc(userId).update({
      'isBlocked': isBlocked,
    });
  }
}
