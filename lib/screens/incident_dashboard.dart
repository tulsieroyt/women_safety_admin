import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import 'admin_management_screen.dart';
import 'admin_profile_screen.dart';
import 'incident_details_screen.dart';

class IncidentDashboard extends StatefulWidget {
  const IncidentDashboard({super.key});

  @override
  State<IncidentDashboard> createState() => _IncidentDashboardState();
}

class _IncidentDashboardState extends State<IncidentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              tooltip: 'Admin Menu',
              onSelected: (value) async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
                if (!doc.exists) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are not registered as an admin.')),
                  );
                  return;
                }

                final isSuperAdmin = doc['isSuperAdmin'] ?? false;

                if (value == 'profile') {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isSuperAdmin
                          ? const AdminManagementScreen()
                          : const AdminProfileScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('My Profile')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(child: Text('Pending')),
            Tab(child: Text('In Progress')),
            Tab(child: Text('Resolved')),
          ],
        ),
      ),


      body: TabBarView(
        controller: _tabController,
        children: const [
          IncidentList(status: 'all'),
          IncidentList(status: 'pending'),
          IncidentList(status: 'in_progress'),
          IncidentList(status: 'resolved'),
        ],
      ),
    );
  }
}

class IncidentList extends StatefulWidget {
  final String status;

  const IncidentList({super.key, required this.status});

  @override
  State<IncidentList> createState() => _IncidentListState();
}

class _IncidentListState extends State<IncidentList> {
  bool isInitialLoad = true;
  List<Incident>? cachedIncidents;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: IncidentService.getIncidentsByStatus(widget.status),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isInitialLoad = true;
                      cachedIncidents = null;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Handle loading state
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Update cached incidents when new data arrives
        if (snapshot.hasData) {
          cachedIncidents = snapshot.data;
          isInitialLoad = false;
        }

        // Show loading indicator during initial load
        if (isInitialLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        final incidents = cachedIncidents ?? [];

        if (incidents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No incidents found',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              isInitialLoad = true;
              cachedIncidents = null;
            });
          },
          child: ListView.builder(
            itemCount: incidents.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return IncidentCard(incident: incidents[index]);
            },
          ),
        );
      },
    );
  }
}

class IncidentCard extends StatelessWidget {
  final Incident incident;

  const IncidentCard({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                IncidentDetailsScreen(incidentId: incident.id),
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Flexible(
              child: Text(
                'INC${incident.id.substring(0, 8)}...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(incident.description),
            const SizedBox(height: 8),
            Text(
              'Reported: ${_formatDateTime(incident.timestamp)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Status: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: incident.status.toUpperCase(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showIncidentActions(context, incident),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(incident.severity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(incident.severity)),
      ),
      child: Text(
        incident.severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String severity) {
    switch (severity) {
      case 'emergency':
        return Colors.red.shade400;
      case 'normal':
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _showIncidentActions(BuildContext context, Incident incident) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Update Status'),
            onTap: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('View Location'),
            onTap: () async {
              try {
                // Format coordinates to 6 decimal places for better precision
                final lat = incident.latitude.toStringAsFixed(6);
                final lng = incident.longitude.toStringAsFixed(6);

                // Try Google Maps URL first
                final googleMapsUrl = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                );

                // Fallback to Apple Maps URL
                final appleMapsUrl = Uri.parse(
                  'https://maps.apple.com/?q=$lat,$lng',
                );

                // Try launching Google Maps first
                if (await canLaunchUrl(googleMapsUrl)) {
                  await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                }
                // If Google Maps fails, try Apple Maps
                else if (await canLaunchUrl(appleMapsUrl)) {
                  await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
                }
                // If both fail, show error
                else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open maps application'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening maps: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Incident Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              onTap: () async {
                try {
                  await IncidentService.updateIncidentStatus(
                      incident.id, 'pending');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Pending')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('In Progress'),
              onTap: () async {
                try {
                  await IncidentService.updateIncidentStatus(
                      incident.id, 'in_progress');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Status updated to In Progress')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Resolved'),
              onTap: () async {
                try {
                  await IncidentService.updateIncidentStatus(
                      incident.id, 'resolved');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Resolved')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
