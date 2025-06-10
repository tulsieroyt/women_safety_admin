import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:women_safety_admin/screens/manage_emergency_services_screen.dart';
import 'package:women_safety_admin/screens/messages_list_screen.dart';
import 'package:women_safety_admin/screens/user_verification_screen.dart';
import 'incident_dashboard.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;

  final screens = [
    const IncidentDashboard(),
    const UserVerificationScreen(),
    const ManageEmergencyServicesScreen(),
    const MessagesListScreen()
  ];

  void changePage(int index) {
    currentIndex.value = index;
  }
}

class MainBottomNavScreen extends StatelessWidget {
  MainBottomNavScreen({super.key});

  final MainController controller = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: controller.screens,
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changePage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined),
              selectedIcon: Icon(Icons.emergency),
              label: 'Emergency',
            ),
            NavigationDestination(
              icon: Icon(Icons.message),
              selectedIcon: Icon(Icons.message),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }
}
