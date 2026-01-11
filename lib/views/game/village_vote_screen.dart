import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/death_reason.dart';
import 'package:werewolf_narrator/state/game.dart';

class VillageVoteScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const VillageVoteScreen({super.key, required this.onPhaseComplete});

  @override
  State<VillageVoteScreen> createState() => _VillageVoteScreenState();
}

class _VillageVoteScreenState extends State<VillageVoteScreen> {
  int? _selectedPlayer;
  bool _voteConfirmed = false;

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
                subtitle: _voteConfirmed && _selectedPlayer == index
                    ? Text(
                        'Role: ${gameState.players[index].role?.name(context) ?? "Unknown"}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : null,
                onTap: !_voteConfirmed && gameState.players[index].isAlive
                    ? () {
                        setState(() {
                          _selectedPlayer = index;
                        });
                      }
                    : null,
                selected: _selectedPlayer == index,
                enabled:
                    (!_voteConfirmed && gameState.players[index].isAlive) ||
                    _selectedPlayer == index,
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: _voteConfirmed
                  ? () {
                      gameState.markPlayerDead(
                        _selectedPlayer!,
                        DeathReason.vote,
                      );
                      widget.onPhaseComplete();
                    }
                  : (_selectedPlayer != null
                        ? () {
                            setState(() {
                              _voteConfirmed = true;
                            });
                          }
                        : null),
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
