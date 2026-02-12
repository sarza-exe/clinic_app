// lib/screens/create_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/drawer.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({Key? key}) : super(key: key);

  @override
  _CreateAppointmentScreenState createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _doctors = [];
  List<String> _specialties = [];
  String? _selectedSpecialty;
  dynamic _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime; // store time slot as "HH:mm"
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final _storage = const FlutterSecureStorage();
  String _id = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
    _loadIdFromStorage();
    _fetchDoctors();
  }

  Future<void> _loadRoleFromStorage() async {
    final storedRole = await _storage.read(key: 'role');
    setState(() {
      _role = storedRole ?? 'unknown';
    });
  }

  Future<void> _loadIdFromStorage() async {
    // Attempt to read the value stored under the key "role"
    final storedId = await _storage.read(key: 'id');
    setState(() {
      _id = storedId ?? 'unknown';
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
        // Extract distinct specialties
        _specialties = doctors
            .map((d) => d['specialty'] as String)
            .toSet()
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: 503')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate time slots from 10:00 to 18:00 every 30 minutes
  final List<String> _timeSlots = List.generate(
    ((18 - 10) * 2) + 1, // (hours range * 2) + 1 for inclusive 18:00
    (index) {
      final totalMinutes = 10 * 60 + (index * 30);
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    },
  );

  // Filter doctors by selected specialty (or show all)
  List<dynamic> get _filteredDoctors {
    if (_selectedSpecialty == null || _selectedSpecialty == 'All') {
      return _doctors;
    }
    return _doctors
        .where((d) => d['specialty'] == _selectedSpecialty)
        .toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // reset time whenever date changes
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Combine selectedDate and selectedTime into a single DateTime
    final timeParts = _selectedTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    final body = {
      'doctor': _selectedDoctor['_id'],
      'patient': _id,
      'date': combinedDateTime.toIso8601String(),
      'reason': _reasonController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.createAppointment(body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment created successfully')),
      );
      Navigator.of(context).pop(); // Go back after creation
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create appointment: $e')),
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
        title: const Text('Create Appointment'),
      ),
      drawer: MainDrawer(currentRoute: '/create_appointment', role: _role),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Specialty filter dropdown
                      DropdownButton<String>(
                        hint: const Text('Filter by Specialty'),
                        value: _selectedSpecialty,
                        items: ['All', ..._specialties].map((String specialty) {
                          return DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSpecialty = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // 2. ListView of filtered doctors
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (ctx, index) {
                            final doctor = _filteredDoctors[index];
                            final isSelected = _selectedDoctor != null &&
                                _selectedDoctor['_id'] == doctor['_id'];
                            return ListTile(
                              title: Text(doctor['name']),
                              subtitle: Text(doctor['specialty']),
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedDoctor = doctor;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      // 3. Show selected doctor
                      if (_selectedDoctor != null)
                        Text(
                          'Selected Doctor: ${_selectedDoctor['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                      const SizedBox(height: 10),
                      // 4. Date picker
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _pickDate,
                            child: const Text('Choose Date'),
                          ),
                          const SizedBox(width: 10),
                          if (_selectedDate != null)
                            Text(DateFormat.yMMMd().format(_selectedDate!)),
                        ],
                      ),

                      const SizedBox(height: 10),
                      // 5. Time slot dropdown (visible once a date is chosen)
                      if (_selectedDate != null)
                        DropdownButton<String>(
                          hint: const Text('Choose Time'),
                          value: _selectedTime,
                          items: _timeSlots.map((String slot) {
                            return DropdownMenuItem<String>(
                              value: slot,
                              child: Text(slot),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTime = newValue;
                            });
                          },
                        ),

                      const SizedBox(height: 10),
                      // 6. Reason input
                      TextField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Appointment',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),
                      // 7. Submit button
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitAppointment,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Create Appointment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}