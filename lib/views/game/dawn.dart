import 'package:flutter/material.dart';
import 'package:werewolf_narrator/views/game/deaths_screen.dart';

class DawnScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DawnScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) => DeathsScreen(
    onPhaseComplete: onPhaseComplete,
    title: const Text('The village wakes as dawn breaks...'),
    beamColor: Colors.orange.shade300,
  );
}
