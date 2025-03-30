import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  final String token;

  const SupportPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
          textAlign: TextAlign.start,
        ),
        backgroundColor: const Color.fromARGB(
            255, 134, 23, 116), // Set the background color of the AppBar
        centerTitle: false, // Center the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            const ExpansionTile(
              title: Text('FAQs'),
              children: [
                ListTile(
                  title: Text('Q: What is this app about?'),
                  subtitle: Text(
                      'A: This app is a platform to manage your accounts and transactions.'),
                ),
                ListTile(
                  title: Text('Q: How do I reset my password?'),
                  subtitle: Text(
                      'A: You can reset your password by going to the login page and clicking on "Forgot Password".'),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Terms and Conditions'),
              children: [
                ListTile(
                  title: Text('Terms and Conditions'),
                  subtitle: Text(
                    'These are the terms and conditions for using this app. By using this app, you agree to comply with these terms and conditions.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Privacy Policy'),
              children: [
                ListTile(
                  title: Text('Privacy Policy'),
                  subtitle: Text(
                    'This is the privacy policy for this app. We are committed to protecting your privacy and ensuring that your personal information is handled in a safe and responsible manner.',
                  ),
                ),
              ],
            ),
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Message',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Implement support request submission logic here
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color.fromARGB(255, 185, 3, 155)),
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                      padding: WidgetStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12)),
                      textStyle: WidgetStateProperty.all<TextStyle>(
                          const TextStyle(fontSize: 16)),
                    ),
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
