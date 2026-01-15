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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Werewolf Narrator'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => newGame(context),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.primary,
            ),
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: const Text('New Game'),
        ),
      ),
    );
  }

  void newGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return GameView();
        },
      ),
    );
  }
}
