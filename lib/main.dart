import 'package:flutter/material.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/views/game.dart';

void main() {
  runApp(const WerewolfNarratorApp());
}

class WerewolfNarratorApp extends StatelessWidget {
  const WerewolfNarratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Werewolf Narrator',
      theme: Themes.lightTheme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('Werewolf Narrator'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startNewGame(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            fixedSize: const Size(250, 250),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('New Game'),
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GameView()));
  }
}
