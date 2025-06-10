import 'package:flutter/material.dart';
import '../models/emergency_service.dart';

class EmergencyServiceSelectionScreen extends StatelessWidget {
  final ServiceType serviceType;
  final Stream<List<EmergencyService>> servicesStream;
  final String title;

  const EmergencyServiceSelectionScreen({
    super.key,
    required this.serviceType,
    required this.servicesStream,
    required this.title,
  });

  IconData get serviceIcon {
    switch (serviceType) {
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.fire:
        return Icons.local_fire_department;
      case ServiceType.ambulance:
        return Icons.medical_services;
      case ServiceType.womenOrg:
        return Icons.people;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<EmergencyService>>(
        stream: servicesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(serviceIcon, color: Colors.blue),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              service.address,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${service.contactNumber}...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context, service);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
