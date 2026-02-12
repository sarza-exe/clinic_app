// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../widgets/drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  late Future<void> _futureProfile;

  // Role + ID from storage
  String _role = '';
  String _userId = '';

  // Controllers for all editable fields:
  final TextEditingController _nameController      = TextEditingController();
  final TextEditingController _emailController     = TextEditingController();
  final TextEditingController _phoneController     = TextEditingController(); // patients only

  // Read-only fields (use controllers to set text, but mark as readOnly & disabled)
  final TextEditingController _birthDateController = TextEditingController(); // patients only
  final TextEditingController _specialtyController = TextEditingController(); // doctors only
  final TextEditingController _roleFieldController = TextEditingController(); // doctors only

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  /// Reads "role" and "id" from secure storage, then fetches profile.
  Future<void> _loadProfile() async {

  // 1) Read from secure storage
  final storedRole = await _storage.read(key: 'role');
  final storedId   = await _storage.read(key: 'id');
  _role   = storedRole ?? 'patient';
  _userId = storedId   ?? '';

    if (_role == 'patient') {
      // Wrap the fetch in try/catch so network errors show a Snackbar
      Map<String, dynamic> profile;
      try {
        profile = await _apiService.fetchPatientById(_userId);
      } catch (err) {
        // If the call itself fails (e.g. server is off), show a SnackBar and return early
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch profile (network error)')),
        );
        return;
      }

      // If the backend returned an empty JSON object “{}” (unlikely, but just in case):
      if (profile.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile data is empty (503)')),
        );
        return;
      }

      // Populate controllers now that we have a non-empty map:
      _nameController.text  = profile['name']  as String? ?? '';
      _emailController.text = profile['email'] as String? ?? '';
      _phoneController.text = profile['phone'] as String? ?? '';
      if (profile['birthDate'] != null) {
        final dt = DateTime.parse(profile['birthDate']).toLocal();
        _birthDateController.text = DateFormat('dd-MM-yyyy').format(dt);
      } else {
        _birthDateController.text = '';
      }
    } else {
      // Doctor branch: same pattern
      Map<String, dynamic> profile;
      try {
        profile = await _apiService.fetchDoctorById(_userId);
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch profile (network error)')),
        );
        return;
      }
      if (profile.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile data is empty (503)')),
        );
        return;
      }
      _nameController.text      = profile['name']      as String? ?? '';
      _emailController.text     = profile['email']     as String? ?? '';
      _specialtyController.text = profile['specialty'] as String? ?? '';
      _roleFieldController.text = profile['role']      as String? ?? '';
    }
}

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_role == 'patient') {
        final body = <String, dynamic>{
          'name':  _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        };
        await _apiService.updatePatient(_userId, body);
      } else {
        final body = <String, dynamic>{
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
        };
        await _apiService.updateDoctor(_userId, body);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: \$e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _futureProfile,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Still loading role/id & profile from API
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Now we can build the actual form, since all controllers have text set
        return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        drawer: MainDrawer(currentRoute: '/profile', role: _role),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // allow overscroll when content is small
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                // make the box at least as tall as the viewport
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  // center both vertically & horizontally
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    // cap width at 1000px
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          // disable its own scrolling; we scroll the parent
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            if (_role == 'patient') ...[
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _birthDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Birth Date',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              TextFormField(
                                controller: _specialtyController,
                                decoration: const InputDecoration(
                                  labelText: 'Specialty',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _roleFieldController,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                            ],

                            _isSaving
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _saveProfile,
                                  child: const Text('Save Changes'),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _specialtyController.dispose();
    _roleFieldController.dispose();
    super.dispose();
  }
}
