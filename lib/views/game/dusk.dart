import 'package:flutter/material.dart';

class DuskScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DuskScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    // The Village sleeps as night falls...
    return Scaffold(
      body: Center(
        child: Text(
          'The village sleeps as night falls...',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed: onPhaseComplete,
          label: const Text('Continue'),
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
