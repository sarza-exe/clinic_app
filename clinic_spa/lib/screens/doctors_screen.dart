// lib/screens/doctors_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/drawer.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({Key? key}) : super(key: key);

  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _doctors = [];
  bool _isLoading = false;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
    _fetchDoctors();
  }

  Future<void> _loadRoleFromStorage() async {
    final storedRole = await _storage.read(key: 'role');
    setState(() {
      _role = storedRole ?? 'unknown';
    });
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doctors = await _apiService.fetchDoctors();
      setState(() {
        _doctors = doctors;
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

  Future<void> _deleteDoctor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to delete this doctor?'),
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

    try {
      await _apiService.deleteDoctor(id);
      _fetchDoctors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showCreateDoctorDialog() async {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String name = '';
    String specialty = '';
    String email = '';
    String password = '';
    String selectedRole = 'doctor';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Doctor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onChanged: (value) => name = value,
                      ),

                      // Specialty
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Specialty'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a specialty';
                          }
                          return null;
                        },
                        onChanged: (value) => specialty = value,
                      ),

                      // Email
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onChanged: (value) => email = value,
                      ),

                      // Password
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onChanged: (value) => password = value,
                      ),

                      // Role dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['doctor', 'admin'].map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedRole = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop();

                final body = {
                  'name': name,
                  'specialty': specialty,
                  'email': email,
                  'password': password,
                  'role': selectedRole,
                };

                setState(() {
                  _isLoading = true;
                });
                try {
                  await _apiService.registerDoctor(body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor created successfully')),
                  );
                  _fetchDoctors();
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
                    send = 'Unexpected error';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(send)),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Doctors'),
    ),
    drawer: MainDrawer(currentRoute: '/doctors', role: _role),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDoctors,
              child: ListView.builder(
                itemCount: _doctors.length,
                itemBuilder: (ctx, index) {
                  final doc = _doctors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(doc['name']),
                      subtitle: Text(
                        'Specialty: ${doc['specialty']}\n'
                        'Email: ${doc['email']}\n'
                        'Role: ${doc['role']}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_role == 'admin')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDoctor(doc['_id']),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      ),
    ),
    floatingActionButton: _role == 'admin'
      ? FloatingActionButton(
          onPressed: _showCreateDoctorDialog,
          child: const Icon(Icons.add),
        )
      : null,
  );
}

}
