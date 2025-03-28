import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../home.dart';

class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({super.key});

  @override
  _BiometricAuthPageState createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        final token = await _secureStorage.read(key: 'token');
        final username = await _secureStorage.read(key: 'username');

        if (token != null && username != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                token: token,
                username: username,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No saved login found.')),
          );
        }
      }
    } catch (e) {
      print('Error during biometric authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
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
