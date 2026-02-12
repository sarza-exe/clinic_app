// lib/google_button_mobile.dart

import 'package:flutter/material.dart';

/// On mobile, we just show a tappable Google logo image.
/// The [onTap] callback will come from your LoginScreen.
Widget buildGoogleSignInButton(VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Image.asset(
      'assets/google_logo.png',
    ),
  );
}
