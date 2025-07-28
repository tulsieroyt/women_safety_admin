import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  Future<Map<String, dynamic>?> getLoggedInUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    if (!doc.exists) return null;

    return {
      'name': doc['name'] ?? 'Unknown',
      'email': doc['email'] ?? 'N/A',
      'isSuperAdmin': doc['isSuperAdmin'] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getLoggedInUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.verified_user, color: Colors.teal),
                    title: Text(user['name']),
                    subtitle: Text(user['email']),
                    trailing: Chip(
                      label: Text(user['isSuperAdmin'] ? "Super Admin" : "Admin"),
                      backgroundColor: user['isSuperAdmin'] ? Colors.deepPurple : Colors.grey[400],
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("✅ Approved Admins",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(child: _buildAdminList(true)),
                const Divider(thickness: 1.5, height: 40),
                const Text("🕐 Approval Requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(child: _buildAdminList(false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminList(bool isApproved) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .where('isApproved', isEqualTo: isApproved)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(isApproved ? "No approved admins found" : "No pending requests"),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(data['name'] ?? 'N/A'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email: ${data['email']}"),
                    Text("Created: ${data['createdAt']?.toDate().toString().substring(0, 16) ?? 'N/A'}"),
                  ],
                ),
                trailing: isApproved
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        data['isSuperAdmin'] == true ? 'Super Admin' : 'Admin',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                      data['isSuperAdmin'] == true ? Colors.deepPurple : Colors.teal,
                    ),
                    if (data['isSuperAdmin'] != true)
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Delete Admin',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Admin?"),
                              content: const Text(
                                  "Are you sure you want to delete this admin from Firestore?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('admins')
                                .doc(doc.id)
                                .delete();

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Admin deleted successfully.")),
                            );
                          }
                        },
                      ),
                  ],
                )
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('admins')
                        .doc(doc.id)
                        .update({'isApproved': true});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
