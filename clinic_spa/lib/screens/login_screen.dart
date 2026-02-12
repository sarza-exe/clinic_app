import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/google_button.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // radio button state for user type
  String _selectedType = 'patient';

  static const String WEB_CLIENT_ID =
      '67750453943-d784cdhm13nbo13qimepoegbqeakfgdg.apps.googleusercontent.com';

  // 1) Initialize GoogleSignIn
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? WEB_CLIENT_ID : null,
    serverClientId: kIsWeb ? null : WEB_CLIENT_ID,
    scopes: ['email'],
  );

  // 2) Android/iOS sign-in handler
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        return;
      }

      final googleAuth = await account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID token from Google.');
      }

      final result = await _apiService.loginWithGoogle(idToken, _selectedType);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: {
          'role': result['role'],
          'id':   result['id'],
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      print("TRYING LOGIN\n");
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedType,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Web‐only: listen for the sign-in result
    if (kIsWeb) {
      _googleSignIn.onCurrentUserChanged.listen((account) async {
        if (account != null) {
          setState(() => _isLoading = true);
          try {
            final googleAuth = await account.authentication;
            final String? idToken = googleAuth.idToken;
            if (idToken == null) {
              throw Exception('No ID token from Google on web.');
            }
            final result =
                await _apiService.loginWithGoogle(idToken, _selectedType);
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed(
              '/home',
              arguments: {
                'role': result['role'],
                'id':   result['id'],
              },
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sign-in error: $e')),
            );
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "CLINIC LOGIN",
                    style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 30),
                    ),
                  const SizedBox(height: 24),
                  // Radio buttons for user type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: 'patient',
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      const Text('Patient'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'doctor',
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      const Text('Doctor'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 225),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        // (no need for maximumSize here)
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log In'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Create an account'),
                  ),
                  const SizedBox(height: 12),

                  // Google Sign-In button (mobile or web)
                  _isLoading
                      ? const CircularProgressIndicator()
                      : buildGoogleSignInButton(_handleGoogleSignIn),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
