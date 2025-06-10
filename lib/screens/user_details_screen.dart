import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'message_details_screen.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  late final FirebaseFirestore _firestore;

  UserDetailsScreen({
    super.key,
    required this.userData,
  }) {
    _firestore = FirebaseFirestore.instance;
  }

  void _startChat(BuildContext context) {
    // Ensure we have a valid user ID
    if (userData['uid'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot start chat - Invalid user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final conversation = Conversation(
      userId: userData['uid'],
      userName: userData['name'] ?? 'Unknown User',
      userImage: userData['profileImage'] ?? 'https://via.placeholder.com/150',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unread: false,
      messages: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailsScreen(conversation: conversation),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyUser(BuildContext context) async {
    try {
      await _firestore.collection('users').doc(userData['uid']).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userData['name']} has been verified'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBlockUser(BuildContext context) async {
    try {
      await _firestore.collection('users').doc(userData['uid']).update({
        'isBlocked': !userData['isBlocked'],
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${userData['name']} has been ${userData['isBlocked'] ? 'unblocked' : 'blocked'}',
            ),
            backgroundColor: userData['isBlocked'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.deepPurple,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Hero(
                        tag: 'user-${userData['uid']}',
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              userData['profileImage']?.isNotEmpty == true
                                  ? NetworkImage(userData['profileImage']!)
                                  : null,
                          child: userData['profileImage']?.isNotEmpty != true
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    userData['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: userData['isVerified']
                          ? (userData['isBlocked'] ? Colors.red : Colors.green)
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          userData['isVerified']
                              ? (userData['isBlocked']
                                  ? Icons.block
                                  : Icons.verified_user)
                              : Icons.pending,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userData['isVerified']
                              ? (userData['isBlocked'] ? 'Blocked' : 'Verified')
                              : 'Pending Verification',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Email',
                    userData['email'] ?? 'N/A',
                    Icons.email_outlined,
                  ),
                  _buildInfoRow(
                    'Phone',
                    userData['phone'] ?? 'N/A',
                    Icons.phone_outlined,
                  ),
                  _buildInfoRow(
                    'Address',
                    userData['address'] ?? 'N/A',
                    Icons.location_on_outlined,
                  ),
                  _buildInfoRow(
                    'Registration Date',
                    userData['createdAt']?.toString().split(' ')[0] ?? 'N/A',
                    Icons.calendar_today_outlined,
                  ),
                  if (userData['verifiedAt'] != null)
                    _buildInfoRow(
                      'Verification Date',
                      userData['verifiedAt'].toString().split(' ')[0],
                      Icons.verified_outlined,
                    ),
                  if (userData['idType'] != null)
                    _buildInfoRow(
                      'ID Type',
                      userData['idType'],
                      Icons.badge_outlined,
                    ),
                  if (userData['idImageUrl']?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'ID Document',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          userData['idImageUrl']!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[300],
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (!userData['isVerified'])
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyUser(context),
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Verify User'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _startChat(context),
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Message User'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (userData['isVerified'])
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleBlockUser(context),
                        icon: Icon(
                          userData['isBlocked']
                              ? Icons.lock_open_outlined
                              : Icons.block_outlined,
                        ),
                        label: Text(userData['isBlocked']
                            ? 'Unblock User'
                            : 'Block User'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
