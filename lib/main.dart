import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'package:provider/provider.dart';
import 'global_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GlobalState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
    );
  }
}
