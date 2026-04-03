import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/deaths_screen.dart';

class DawnScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DawnScreen({required this.onPhaseComplete, super.key});

  @override
  Widget build(BuildContext context) => DeathsScreen(
    key: UniqueKey(),
    onPhaseComplete: onPhaseComplete,
    title: Text(AppLocalizations.of(context).screen_dawn_message),
    beamColor: Colors.orange.shade300,
  );
}
