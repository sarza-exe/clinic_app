import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/create_appointment_screen.dart';
import 'screens/profile_screen.dart';

// flutter run --web-port=5000

void main() => runApp(const ClinicApp());

class ClinicApp extends StatelessWidget {
  const ClinicApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic SPA',
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/doctors': (ctx) => const DoctorsScreen(),
        '/patients': (ctx) => const PatientsScreen(),
        '/appointments': (ctx) => const AppointmentsScreen(),
        '/create_appointment': (ctx) => const CreateAppointmentScreen(),
        '/profile': (ctx) => const ProfileScreen(),
      },
    );
  }
}