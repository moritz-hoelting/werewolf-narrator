import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/state/game.dart';

class VillageVoteScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const VillageVoteScreen({super.key, required this.onPhaseComplete});

  @override
  State<VillageVoteScreen> createState() => _VillageVoteScreenState();
}

class _VillageVoteScreenState extends State<VillageVoteScreen> {
  int? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Select player to vote out'),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(gameState.players[index].name),
                subtitle: index == gameState.sheriff
                    ? const Text('Sheriff')
                    : null,
                onTap: gameState.players[index].isAlive
                    ? () {
                        setState(() {
                          if (_selectedPlayer == index) {
                            _selectedPlayer = null;
                          } else {
                            _selectedPlayer = index;
                          }
                        });
                      }
                    : null,
                selected: _selectedPlayer == index,
                enabled: gameState.players[index].isAlive,
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: () {
                if (_selectedPlayer == null) {
                  final answer = showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('No player selected'),
                      content: const Text(
                        'Do you really want to continue without voting anybody out?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                  answer.then((continueWithoutVote) {
                    if (continueWithoutVote == true) {
                      widget.onPhaseComplete();
                    }
                  });
                } else {
                  gameState.markPlayerDead(_selectedPlayer!, DeathReason.vote);
                  widget.onPhaseComplete();
                }
              },
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
