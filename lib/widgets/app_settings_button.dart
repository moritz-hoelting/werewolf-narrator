import 'package:flutter/material.dart';
import 'package:werewolf_narrator/views/settings.dart';

class AppSettingsButton extends StatelessWidget {
  const AppSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
      },
      icon: const Icon(Icons.settings),
    );
  }
}
