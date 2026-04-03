import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

part 'voting.mapper.dart';

class VillageVoteScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const VillageVoteScreen({super.key, required this.onComplete});

  @override
  State<VillageVoteScreen> createState() => _VillageVoteScreenState();

  static void registerAction(GameState gameState) {
    gameState.apply(RegisterVillageVoteScreenCommand());
  }
}

class _VillageVoteScreenState extends State<VillageVoteScreen> {
  int? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer<GameState>(
      builder: (context, gameState, _) => Scaffold(
        appBar: GameAppBar(title: Text(localizations.screen_villageVote_title)),
        body: PlayerList(
          phaseIdentifier: VillageVoteScreen,
          disabledPlayers: gameState.knownDeadPlayerIndices,
          selectedPlayers: {_selectedPlayer}.nonNulls.toISet(),
          onPlayerTap: (index) => () {
            setState(() {
              _selectedPlayer = _selectedPlayer == index ? null : index;
            });
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
                  useRootNavigator: false,
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
                  widget.onComplete();
                }
              } else {
                gameState.apply(
                  MarkDeadCommand.single(
                    player: _selectedPlayer!,
                    deathReason: VillageVoteDeathReason(
                      gameState.knownAlivePlayerIndices,
                    ),
                  ),
                );
                widget.onComplete();
              }
            },
          ),
        ),
      ),
    );
  }
}

@MappableClass(discriminatorValue: 'villageVote')
class VillageVoteDeathReason
    with VillageVoteDeathReasonMappable
    implements DeathReason {
  const VillageVoteDeathReason(this.responsiblePlayers);

  final ISet<int> responsiblePlayers;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).team_village_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => responsiblePlayers;
}

@MappableClass(discriminatorValue: 'registerVillageVoteScreen')
class RegisterVillageVoteScreenCommand
    with RegisterVillageVoteScreenCommandMappable
    implements GameCommand {
  @override
  void apply(GameData gameData) {
    gameData.dayActionManager.registerAction(
      VillageVoteScreen,
      (gameState, onComplete) =>
          (context) => VillageVoteScreen(onComplete: onComplete),
      conditioned: (gameState) => gameState.alivePlayerCount > 1,
      players: const {},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.dayActionManager.unregisterAction(VillageVoteScreen);
  }
}
