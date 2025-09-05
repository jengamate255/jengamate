import 'package:flutter/material.dart';

void main() {
  runApp(const DevApp());
}

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JengaMate Dev Safe Mode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const DevHomePage(),
    );
  }
}

class DevHomePage extends StatelessWidget {
  const DevHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Safe Mode')),
      body: const Center(
        child: Text(
          'Dev server is running.\nThis is a minimal entry to bypass compile errors.\nUse this to validate environment and hot reload.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
