import 'package:flutter/material.dart';
import 'package:werewolf_narrator/views/game.dart';

void main() {
  runApp(const WerewolfNarratorApp());
}

class WerewolfNarratorApp extends StatelessWidget {
  const WerewolfNarratorApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Werewolf Narrator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Werewolf Narrator'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
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
