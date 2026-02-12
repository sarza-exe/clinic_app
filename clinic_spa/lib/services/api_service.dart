// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://localhost:3000';
    } else {
      return 'http://localhost:10.0.2.2';
    }
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Map<String, String> _authHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  
  // AUTH

  Future<Map<String, dynamic>> loginWithGoogle( String idToken, String type) async {
    final uri = Uri.parse('$_baseUrl/api/auth/google');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'type': type}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      final role  = body['role'];
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final id = decoded['id'] as String;
      await _storage.write(key: 'jwt', value: token);
      await _storage.write(key: 'role', value: role);
      await _storage.write(key: 'id', value: id);
      return decoded;
    }
    else {
      throw Exception('${response.statusCode} Google login failed: ${response.body}');
    }
  }

  Future<void> login(String email, String password, String type ) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'type': type}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      final role  = body['role'];
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final id = decoded['id'] as String;
      await _storage.write(key: 'jwt', value: token);
      await _storage.write(key: 'role', value: role);
      await _storage.write(key: 'id', value: id);
    } else {
      throw Exception('${response.statusCode} Login failed: ${response.body}');
    }
  }

  Future<void> registerPatient(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register/patient');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception('Registration failed: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> registerDoctor(Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/auth/register/doctor');
    final response = await http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception('${response.statusCode} Doctor registration failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }


  // DOCTORS

  Future<List<dynamic>> fetchDoctors({int page = 1, int limit = 20}) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors?page=$page&limit=$limit');
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] as List<dynamic>;
    } else {
      throw Exception('${response.statusCode} Failed to load doctors: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchDoctorById(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors/$id');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        '${response.statusCode} Failed to load doctor: ${response.body}'
      );
    }
  }

  Future<List<dynamic>> fetchDoctorsBySpecialty(String specialty) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors/specialty/$specialty');
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch doctors by specialty: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> updateDoctor(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors/$id');
    final response = await http.put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update doctor: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> changeDoctorPassword(String id, String newPassword) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors/$id/password');
    final response = await http.patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({'password': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change doctor password: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> deleteDoctor(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/doctors/$id');
    final response = await http.delete(uri, headers: _authHeaders(token));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete doctor: ${response.body} ${response.statusCode}');
    }
  }


  // PATIENTS

  Future<List<dynamic>> fetchPatients({int page = 1, int limit = 20}) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients?page=$page&limit=$limit');
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] as List<dynamic>;
    } else {
      throw Exception('${response.statusCode} Failed to load patients: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchPatientById(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/$id');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      // Instead of body['data'], parse the JSON object directly:
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        '${response.statusCode} Failed to load patient: ${response.body}'
      );
    }
  }

  Future<List<dynamic>> fetchPatientsByDoctor(String doctorId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/doctor/$doctorId');
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('${response.statusCode} Failed to fetch patients by doctor: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchAppointmentsByPatient(String patientId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/$patientId/appointments');
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load patient appointments: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> updatePatient(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/$id');
    final response = await http.put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update patient: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> changePatientPassword(String id, String newPassword) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/$id/password');
    final response = await http.patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({'password': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change patient password: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> deletePatient(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/patients/$id');
    final response = await http.delete(uri, headers: _authHeaders(token));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete patient: ${response.body} ${response.statusCode}');
    }
  }



  // APPOINTMENTS

  Future<List<dynamic>> fetchAppointments({
    int page = 1,
    int limit = 20,
    String? doctorName,
    String? patientName,
    DateTime? date,
    String? sort, // 'asc' or 'desc'
  }) async {
    final token = await _getToken();
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (doctorName != null) 'doctor': doctorName,
      if (patientName != null) 'patient': patientName,
      if (date != null) 'date': date.toIso8601String(),
      if (sort != null) 'sort': sort,
    };
    final uri = Uri.parse('$_baseUrl/api/appointments').replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded;
    } else {
      throw Exception('${response.statusCode} Failed to load appointments: ${response.body}');
    }
  }

  Future<void> createAppointment(Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/appointments');
    final response = await http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create appointment: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/appointments/$id');
    final response = await http.put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment: ${response.body} ${response.statusCode}');
    }
  }

  Future<void> deleteAppointment(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/appointments/$id');
    final response = await http.delete(uri, headers: _authHeaders(token));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete appointment: ${response.body} ${response.statusCode}');
    }
  }
}
