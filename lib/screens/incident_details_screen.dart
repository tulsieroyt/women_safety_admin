import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../services/emergency_service.dart';
import '../services/incident_service.dart';
import '../models/incident.dart';
import 'emergency_service_selection_screen.dart';
import 'user_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailsScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  EmergencyService? selectedPoliceStation;
  EmergencyService? selectedFireStation;
  EmergencyService? selectedAmbulanceService;
  EmergencyService? selectedWomenOrg;
  Map<String, dynamic>? userData;
  bool hasChanges = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // Get the incident first
      final incident = await IncidentService.getIncident(widget.incidentId).first;
      
      if (incident != null) {
        // Load user data and assigned services in parallel
        await Future.wait([
          _loadUserData(incident),
          _loadAssignedServices(incident),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData(Incident incident) async {
    try {
      final userDetails = await IncidentService.getUserDetails(incident.userId);
      if (mounted) {
        setState(() {
          userData = userDetails;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAssignedServices(Incident incident) async {
    try {
      if (incident.policeStationId != null) {
        final service = await IncidentService.getAssignedEmergencyService(
            incident.policeStationId!);
        if (mounted && service != null) {
          setState(() => selectedPoliceStation = service);
        }
      }
      if (incident.fireStationId != null) {
        final service = await IncidentService.getAssignedEmergencyService(
            incident.fireStationId!);
        if (mounted && service != null) {
          setState(() => selectedFireStation = service);
        }
      }
      if (incident.ambulanceServiceId != null) {
        final service = await IncidentService.getAssignedEmergencyService(
            incident.ambulanceServiceId!);
        if (mounted && service != null) {
          setState(() => selectedAmbulanceService = service);
        }
      }
      if (incident.womenOrgId != null) {
        final service = await IncidentService.getAssignedEmergencyService(
            incident.womenOrgId!);
        if (mounted && service != null) {
          setState(() => selectedWomenOrg = service);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getServiceTitle(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return 'Select Police Station';
      case ServiceType.fire:
        return 'Select Fire Station';
      case ServiceType.ambulance:
        return 'Select Ambulance Service';
      case ServiceType.womenOrg:
        return 'Select Women Organization';
    }
  }

  Stream<List<EmergencyService>> _getServicesList(ServiceType type) {
    return EmergencyServiceData.getServicesByType(type);
  }

  EmergencyService? _getSelectedService(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return selectedPoliceStation;
      case ServiceType.fire:
        return selectedFireStation;
      case ServiceType.ambulance:
        return selectedAmbulanceService;
      case ServiceType.womenOrg:
        return selectedWomenOrg;
    }
  }

  void _setSelectedService(ServiceType type, EmergencyService service) {
    setState(() {
      switch (type) {
        case ServiceType.police:
          selectedPoliceStation = service;
          break;
        case ServiceType.fire:
          selectedFireStation = service;
          break;
        case ServiceType.ambulance:
          selectedAmbulanceService = service;
          break;
        case ServiceType.womenOrg:
          selectedWomenOrg = service;
          break;
      }
      hasChanges = true;
    });
  }

  Future<void> _updateEmergencyServices(Incident incident) async {
    try {
      // Create a map of updates
      final Map<String, dynamic> updates = {
        'policeStationId': selectedPoliceStation?.id,
        'fireStationId': selectedFireStation?.id,
        'ambulanceServiceId': selectedAmbulanceService?.id,
        'womenOrgId': selectedWomenOrg?.id,
      };

      // If status is pending and any service is selected, change to in_progress
      if (incident.status == 'pending' &&
          updates.values.any((v) => v != null)) {
        updates['status'] = 'in_progress';
      }

      // Update in Firestore directly using the updates map
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incident.id)
          .update(updates);

      if (mounted) {
        setState(() => hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Emergency services updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (hasChanges) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text(
                      'You have unsaved changes. Do you want to discard them?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'INC${widget.incidentId.substring(0, 8)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<Incident?>(
            stream: IncidentService.getIncident(widget.incidentId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final incident = snapshot.data!;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Description:'),
                      const SizedBox(height: 8),
                      Text(
                        incident.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Location: ${incident.latitude}, ${incident.longitude}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                          TextButton(
                            onPressed: () async {
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
                            child: const Text(
                              'See on Maps',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: ${incident.status.toUpperCase()}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showUpdateStatusDialog(context, incident),
                            child: const Text(
                              'Update Status',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Reported By:'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (userData != null) {
                              // Convert Firestore timestamps to DateTime
                              final createdAt = userData!['createdAt'] is Timestamp
                                  ? (userData!['createdAt'] as Timestamp).toDate()
                                  : null;
                              final verifiedAt = userData!['verifiedAt']
                                      is Timestamp
                                  ? (userData!['verifiedAt'] as Timestamp).toDate()
                                  : null;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailsScreen(
                                    userData: {
                                      ...userData!,
                                      'createdAt': createdAt,
                                      'verifiedAt': verifiedAt,
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Hero(
                                tag: 'user-${userData?['uid'] ?? ''}',
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      userData?['profileImage']?.isNotEmpty == true
                                          ? NetworkImage(userData!['profileImage'])
                                          : null,
                                  child: userData?['profileImage']?.isNotEmpty !=
                                          true
                                      ? const Icon(Icons.person, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData?['name'] ?? 'Loading...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      userData?['email'] ?? 'Loading...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAssignmentSection(
                        'Assign Police:',
                        'Select Police Station',
                        onTap: () {},
                      ),
                      _buildAssignmentSection(
                        'Assign Fire Service:',
                        'Select Fire Station',
                        onTap: () {},
                      ),
                      _buildAssignmentSection(
                        'Assign Ambulance:',
                        'Select Ambulance Service',
                        onTap: () {},
                      ),
                      _buildAssignmentSection(
                        'Assign Women Organization:',
                        'Select Women Organization',
                        onTap: () {},
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: incident.status == 'resolved'
                              ? null
                              : () => _updateEmergencyServices(incident),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasChanges ? Colors.blue : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: Text(
                            incident.status == 'resolved'
                                ? 'Resolved'
                                : hasChanges
                                    ? 'Confirm Changes'
                                    : 'No Changes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              onTap: () async {
                try {
                  await IncidentService.updateIncidentStatus(
                      incident.id, 'pending');
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Pending')),
                  );
                } catch (e) {
                  if (!mounted) return;
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
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Status updated to In Progress')),
                  );
                } catch (e) {
                  if (!mounted) return;
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
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Resolved')),
                  );
                } catch (e) {
                  if (!mounted) return;
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAssignmentSection(
    String title,
    String defaultValue, {
    required VoidCallback onTap,
  }) {
    ServiceType? serviceType;
    if (title.contains('Police')) {
      serviceType = ServiceType.police;
    } else if (title.contains('Fire')) {
      serviceType = ServiceType.fire;
    } else if (title.contains('Ambulance')) {
      serviceType = ServiceType.ambulance;
    } else if (title.contains('Women')) {
      serviceType = ServiceType.womenOrg;
    }

    if (serviceType != null) {
      final selectedService = _getSelectedService(serviceType);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedService?.name ?? defaultValue,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedService != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.blue),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Calling ${selectedService.contactNumber}...',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        if (serviceType == null) return;
                        final type = serviceType; // Capture the non-null value

                        final selected = await Navigator.push<EmergencyService>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EmergencyServiceSelectionScreen(
                              serviceType: type,
                              servicesStream: _getServicesList(type),
                              title: _getServiceTitle(type),
                            ),
                          ),
                        );
                        if (selected != null) {
                          _setSelectedService(type, selected);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (selectedService != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedService.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      );
    }

    // Return default section for non-service sections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                defaultValue,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
