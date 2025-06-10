import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import 'user_details_screen.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({super.key});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'User Verification',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Verification Requests'),
              Tab(text: 'Verified Users'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildUserList(false), _buildUserList(true)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(bool showVerified) {
    return StreamBuilder<List<User>>(
      stream: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data!;
        final filteredUsers = allUsers.where((user) {
          if (user.isVerified != showVerified) return false;
          if (_searchQuery.isEmpty) return true;

          final searchLower = _searchQuery.toLowerCase();
          return (user.name?.toLowerCase().contains(searchLower) ?? false) ||
              user.email.toLowerCase().contains(searchLower);
        }).toList();

        return filteredUsers.isEmpty
            ? Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? (showVerified
                          ? 'No verified users yet'
                          : 'No pending verification requests')
                      : 'No users found matching "$_searchQuery"',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsScreen(
                              userData: {
                                'uid': user.id,
                                'name': user.name,
                                'email': user.email,
                                'phone': user.phoneNumber,
                                'profileImage': user.profileImage,
                                'isVerified': user.isVerified,
                                'isBlocked': user.isBlocked,
                                'address': user.address,
                                'createdAt': user.createdAt,
                                'verifiedAt': user.verifiedAt,
                                'idType': user.idType,
                                'idImageUrl': user.idImageUrl,
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: user.profileImage != null
                                      ? NetworkImage(user.profileImage!)
                                      : null,
                                  child: user.profileImage == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.name ?? 'Unnamed User',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (user.isVerified)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: user.isBlocked
                                                    ? Colors.red[100]
                                                    : Colors.green[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user.isBlocked
                                                    ? 'Blocked'
                                                    : 'Active',
                                                style: TextStyle(
                                                  color: user.isBlocked
                                                      ? Colors.red[900]
                                                      : Colors.green[900],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (user.phoneNumber != null)
                              _buildInfoRow(Icons.phone, user.phoneNumber!),
                            if (user.address != null)
                              _buildInfoRow(Icons.location_on, user.address!),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Registered on ${user.createdAt.toString().split(' ')[0]}',
                            ),
                            if (!showVerified) ...[
                              const SizedBox(height: 16),
                              if (user.idImageUrl != null) ...[
                                const Text(
                                  'ID Document:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    user.idImageUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (user.idType != null)
                                  Text(
                                    'ID Type: ${user.idType}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _verifyUser(context, user),
                                    child: const Text('Verify User'),
                                  ),
                                ],
                              ),
                            ],
                            if (showVerified) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        _showUserHistory(context, user),
                                    child: const Text('View History'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _toggleBlockUser(context, user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: user.isBlocked
                                          ? Colors.blue
                                          : Colors.red,
                                    ),
                                    child: Text(
                                      user.isBlocked
                                          ? 'Unblock User'
                                          : 'Block User',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _verifyUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify User'),
        content: Text(
            'Are you sure you want to verify ${user.name ?? "this user"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await UserService.updateUserVerification(user.id, true);
                if (context.mounted) {
                  Get.snackbar(
                    'Success',
                    '${user.name ?? "User"} has been verified',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to verify user: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showUserHistory(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Registration Date: ${user.createdAt.toString().split(' ')[0]}'),
            const SizedBox(height: 8),
            Text(
                'Verification Status: ${user.isVerified ? 'Verified' : 'Pending'}'),
            if (user.verifiedAt != null) ...[
              const SizedBox(height: 8),
              Text('Verified On: ${user.verifiedAt.toString().split(' ')[0]}'),
            ],
            const SizedBox(height: 8),
            Text('Account Status: ${user.isBlocked ? 'Blocked' : 'Active'}'),
            const SizedBox(height: 8),
            Text(
                'Profile Status: ${user.isProfileComplete ? 'Complete' : 'Incomplete'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleBlockUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          user.isBlocked
              ? 'Are you sure you want to unblock ${user.name ?? "this user"}?'
              : 'Are you sure you want to block ${user.name ?? "this user"}? This will prevent them from using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await UserService.updateUserBlockStatus(
                    user.id, !user.isBlocked);
                if (context.mounted) {
                  Get.snackbar(
                    'Success',
                    '${user.name ?? "User"} has been ${user.isBlocked ? 'unblocked' : 'blocked'}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: user.isBlocked ? Colors.green : Colors.red,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to ${user.isBlocked ? "unblock" : "block"} user: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBlocked ? Colors.blue : Colors.red,
            ),
            child: Text(user.isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
