// lib/widgets/drawer.dart

import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  final String currentRoute;
  final String role; // e.g. 'admin', 'doctor', or 'patient'

  const MainDrawer({
    Key? key,
    required this.currentRoute,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _buildNavItem({
      required String title,
      required IconData icon,
      required String routeName,
      bool visible = true,
    }) {
      if (!visible) return const SizedBox.shrink();

      final bool isSelected = (currentRoute == routeName);
      return ListTile(
        leading: Icon(icon, color: isSelected ? Colors.deepPurple : null),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () {
          if (!isSelected) {
            Navigator.of(context).pushReplacementNamed(routeName);
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurpleAccent),
            child: const Center(
              child: Text(
                'Clinic Menu',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),

          // Home: visible to everyone
          _buildNavItem(
            title: 'Home',
            icon: Icons.home,
            routeName: '/home',
            visible: true,
          ),

          _buildNavItem(
            title: 'My Profile',
            icon: Icons.person,
            routeName: '/profile',
            visible: true,
          ),

          // Doctors: hide for patients, show for doctor & admin
          _buildNavItem(
            title: 'Doctors',
            icon: Icons.medical_services,
            routeName: '/doctors',
            visible: role != 'patient',
          ),

          // Patients: only admin & doctor can see patients
          _buildNavItem(
            title: 'Patients',
            icon: Icons.people,
            routeName: '/patients',
            visible: role == 'doctor' || role == 'admin',
          ),

          // Appointments: patients see theirs, doctors/admin see all
          _buildNavItem(
            title: 'Appointments',
            icon: Icons.event_note,
            routeName: '/appointments',
            visible: true,
          ),

          // Create Appointment: hide for doctors/admin, only patient
          _buildNavItem(
            title: 'Create Appointment',
            icon: Icons.add,
            routeName: '/create_appointment',
            visible: role == 'patient',
          ),

          const Spacer(),

          // Logout: visible to everyone
          _buildNavItem(
            title: 'Logout',
            icon: Icons.logout,
            routeName: '/login',
            visible: true,
          ),
        ],
      ),
    );
  }
}
