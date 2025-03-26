import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../home.dart';

class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({super.key});

  @override
  _BiometricAuthPageState createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      if (didAuthenticate) {
            Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(token: '')),
    );
  
      }
    } catch (e) {
      print('Error during biometric authentication: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Authentication'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _authenticate,
          child: const Text('Authenticate with Biometrics'),
        ),
      ),
    );
  }
}
