// lib/screens/appointments_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/drawer.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  // Controllers for pagination and filtering
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _pageController = TextEditingController(text: '1');
  final TextEditingController _limitController = TextEditingController(text: '20');
  DateTime? _selectedDate;
  String? _sortValue; // 'asc' or 'desc'

  late Future<List<dynamic>> _futureAppointments;
  String _role = '';
  String? _loadError; // for FutureBuilder UI: 403/404/500 messages

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
    _fetchFilteredAppointments();
  }

  Future<void> _loadRoleFromStorage() async {
    final storedRole = await _storage.read(key: 'role');
    setState(() {
      _role = storedRole ?? 'unknown';
    });
  }

   void _fetchFilteredAppointments() {
    setState(() {
      _loadError = null;
      final page = int.tryParse(_pageController.text) ?? 1;
      final limit = int.tryParse(_limitController.text) ?? 20;
      final doctorName = _doctorController.text.isNotEmpty
          ? _doctorController.text.trim()
          : null;
      final patientName = _patientController.text.isNotEmpty
          ? _patientController.text.trim()
          : null;

      _futureAppointments = _apiService
          .fetchAppointments(
            page: page,
            limit: limit,
            doctorName: doctorName,
            patientName: patientName,
            date: _selectedDate,
            sort: _sortValue,
          )
          .catchError((e) {
        // Inspect the exception message for common status codes:
        final msg = e.toString();
        print(msg);
        if (msg.contains('403')) {
          _loadError = 'You do not have permission to view these appointments.';
        } else if (msg.contains('404')) {
          _loadError = 'Error 404. No appointments found.';
        } else if (msg.contains('500')) {
          _loadError = 'Server error occurred. Please try again later.';
        } else {
          _loadError = 'Network error';
        }
        // Return an empty list so FutureBuilder completes
        return <dynamic>[];
      });
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _editAppointment(Map<String, dynamic> appt) async {
    final _statusController = TextEditingController(text: appt['status']);
    final _reasonController = TextEditingController(text: appt['reason']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.updateAppointment(appt['_id'], {
                  'status': _statusController.text.trim(),
                  'reason': _reasonController.text.trim(),
                });
                Navigator.of(ctx).pop();
                _fetchFilteredAppointments();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
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
      await _apiService.deleteAppointment(id);
      _fetchFilteredAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _patientController.dispose();
    _pageController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      drawer: MainDrawer(currentRoute: '/appointments', role: _role),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filter & Pagination Row
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _patientController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: _selectedDate == null
                              ? 'Select Date'
                              : '${_selectedDate!.day.toString().padLeft(2, '0')}-'
                                '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                                '${_selectedDate!.year}',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Page',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    value: _sortValue,
                    decoration: const InputDecoration(
                      labelText: 'Sort by Date',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                      DropdownMenuItem(value: 'desc', child: Text('Descending')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortValue = value;
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _fetchFilteredAppointments,
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Appointment List
            Expanded(
              child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: FutureBuilder<List<dynamic>>(
                    future: _futureAppointments,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_loadError != null) {
                        return Center(child: Text(_loadError!));
                      }
                      else if (snapshot.hasError) {
                        print("losefsefsef");
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final appointments = snapshot.data ?? [];
                      if (appointments.isEmpty) {
                        return const Center(child: Text('No appointments found.'));
                      }
                      return ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (ctx, index) {
                          final appt = appointments[index];
                          final dt = DateTime.parse(appt['date']).toLocal();
                          final formattedDate = '${dt.day.toString().padLeft(2, '0')}-'
                          '${dt.month.toString().padLeft(2, '0')}-'
                          '${dt.year}';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text('Dr: ${appt['doctor']['name']}'),
                              subtitle: Text(
                                'Pt: ${appt['patient']['name']}\n'
                                'Date: $formattedDate\n'
                                'Status: ${appt['status']}\n'
                                'Reason: ${appt['reason']}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_role != 'patient')
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editAppointment(appt),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAppointment(appt['_id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
