// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
  }

  Future<void> _loadRoleFromStorage() async {
    // Attempt to read the value stored under the key "role"
    final storedRole = await _storage.read(key: 'role');
    setState(() {
      _role = storedRole ?? 'unknown';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $_role'),
      ),
      drawer: MainDrawer(currentRoute: '/home', role: _role),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Clinic App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('My Profile'),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
            if(_role != 'patient')
              const SizedBox(height: 24),
            if(_role != 'patient')
              ElevatedButton.icon(
                icon: const Icon(Icons.medical_services),
                label: const Text('View Doctors'),
                onPressed: () => Navigator.pushNamed(context, '/doctors'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            if(_role != 'patient')
              const SizedBox(height: 16),
            if(_role != 'patient')
              ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text('View Patients'),
                onPressed: () => Navigator.pushNamed(context, '/patients'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.event_note),
              label: const Text('View Appointments'),
              onPressed: () => Navigator.pushNamed(context, '/appointments'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
            if(_role == 'patient')
            const SizedBox(height: 16),
            if(_role == 'patient')
            ElevatedButton.icon(
              icon: const Icon(Icons.event_note),
              label: const Text('Create Appointment'),
              onPressed: () => Navigator.pushNamed(context, '/create_appointment'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }
}