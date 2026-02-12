// lib/screens/patient_screen.dart

import 'package:clinic_spa/widgets/drawer.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _patients = [];
  bool _isLoading = false;
  String role = '';

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
    _fetchPatients();
  }

  Future<void> _loadRoleFromStorage() async {
    final storedRole = await _storage.read(key: 'role');
    setState(() {
      role = storedRole ?? 'unknown';
    });
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final patients = await _apiService.fetchPatients(page: 1, limit: 50);
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      final msg = e.toString();
      String send;
      print(msg);
      if (msg.contains('403')) {
        send = 'You do not have permission.';
      } else if (msg.contains('404')) {
        send = 'Error 404.';
      } else if (msg.contains('409')) {
        send = 'Email already in use.';
      } else if (msg.contains('500')) {
        send = 'Server error occurred. Please try again later.';
      } else {
        send = 'Network error';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(send)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient(String patientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.deletePatient(patientId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient deleted successfully')),
      );
      _fetchPatients(); // Refresh list after deletion
    } catch (e) {
      final msg = e.toString();
      String send;
      print(msg);
      if (msg.contains('403')) {
        send = 'You do not have permission.';
      } else if (msg.contains('404')) {
        send = 'Error 404.';
      } else if (msg.contains('500')) {
        send = 'Server error occurred. Please try again later.';
      } else {
        send = 'Network error';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(send)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      drawer: MainDrawer(currentRoute: '/patients', role: role),
      body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPatients,
              child: ListView.builder(
                itemCount: _patients.length,
                itemBuilder: (ctx, index) {
                  final p = _patients[index];
                  final String patientId = p['_id'] as String;
                  final String name = (p['name'] as String?) ?? 'Unnamed';
                  final String email = (p['email'] as String?) ?? 'No email';
                  final String phone = (p['phone'] as String?) ?? 'No phone';

                  // Format birthDate if present
                  String birthDateStr = '';
                  if (p['birthDate'] != null) {
                    try {
                      final dt = DateTime.parse(p['birthDate']).toLocal();
                      birthDateStr = '${dt.day.toString().padLeft(2, '0')}-'
                      '${dt.month.toString().padLeft(2, '0')}-'
                      '${dt.year}';
                    } catch (_) {
                      birthDateStr = p['birthDate'].toString();
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'Email: $email\n'
                        'Phone: $phone\n'
                        'Birth Date: $birthDateStr',
                      ),
                      isThreeLine: true,
                      trailing: role == 'admin'
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePatient(patientId),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
        ),
      ),
    );
  }
}
