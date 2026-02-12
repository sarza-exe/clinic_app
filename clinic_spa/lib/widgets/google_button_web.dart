// lib/google_button_web.dart

import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// On web, initialize the web plugin and then render GSI’s button.
/// We ignore [onTap] because the web button handles its own click internally.
Widget buildGoogleSignInButton(VoidCallback onTap) {
  // Cast the platform instance to the web plugin:
  final GoogleSignInPlugin plugin =
      GoogleSignInPlatform.instance as GoogleSignInPlugin;

  // Initialize before we call renderButton():
  plugin.init();

  return plugin.renderButton(
    configuration: GSIButtonConfiguration(
      theme: GSIButtonTheme.filledBlue,
      text: GSIButtonText.signinWith,
      shape: GSIButtonShape.pill,
    ),
  );
}
