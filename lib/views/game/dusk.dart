import 'package:flutter/material.dart';
import 'package:werewolf_narrator/util/gradient.dart';

class DuskScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DuskScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 2,
            colors: [Colors.purple.shade700, Colors.transparent],
            stops: const [0.0, 0.7],
            transform: ScaleGradient(scaleX: 1.25, scaleY: 0.75),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'The village sleeps as night falls...',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
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
