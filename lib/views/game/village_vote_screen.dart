import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/village.dart';

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
    final localizations = AppLocalizations.of(context)!;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.screen_villageVote_title),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              final player = gameState.players[index];

              return ListTile(
                title: Text(player.name),
                trailing: index == gameState.sheriff
                    ? const Icon(Icons.local_police_outlined)
                    : null,
                onTap: player.isAlive
                    ? () {
                        setState(() {
                          _selectedPlayer = _selectedPlayer == index
                              ? null
                              : index;
                        });
                      }
                    : null,
                selected: _selectedPlayer == index,
                enabled: player.isAlive,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(localizations.button_continueLabel),
              onPressed: () async {
                if (_selectedPlayer == null) {
                  final continueWithoutVote = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(localizations.dialog_noVote_title),
                      content: Text(localizations.dialog_noVote_message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(localizations.button_noLabel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(localizations.button_yesLabel),
                        ),
                      ],
                    ),
                  );

                  if (continueWithoutVote == true) {
                    widget.onPhaseComplete();
                  }
                } else {
                  gameState.markPlayerDead(
                    _selectedPlayer!,
                    (gameState.teams[VillageTeam.type] as VillageTeam),
                  );
                  widget.onPhaseComplete();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
