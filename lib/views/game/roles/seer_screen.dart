import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class SeerScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const SeerScreen({super.key, required this.onPhaseComplete});

  @override
  State<SeerScreen> createState() => _SeerScreenState();
}

class _SeerScreenState extends State<SeerScreen> {
  int? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Select action for ${Role.seer.name(context)}'),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(gameState.players[index].name),
                subtitle: _selectedPlayer == index
                    ? Text(
                        'Role: ${gameState.players[index].role?.name(context) ?? "Unknown"}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedPlayer = index;
                  });
                },
                selected: _selectedPlayer == index,
                enabled:
                    gameState.players[index].isAlive &&
                    gameState.players[index].role != Role.seer,
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: _selectedPlayer != null
                  ? widget.onPhaseComplete
                  : null,
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
