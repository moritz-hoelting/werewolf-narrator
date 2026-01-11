import 'package:flutter/material.dart';

class DuskScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DuskScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, Colors.purple.shade700],
            stops: const [0.65, 1.0],
          ),
        ),
        child: Center(
          child: Text(
            'The village sleeps as night falls...',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
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
