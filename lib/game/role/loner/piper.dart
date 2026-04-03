import 'package:dart_mappable/dart_mappable.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart'
    show BottomContinueButton;
import 'package:werewolf_narrator/widgets/game/app_bar.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart'
    show PlayerList;

part 'piper.mapper.dart';

@RegisterRole()
class PiperRole extends Role {
  PiperRole._({required RoleConfiguration config, required super.playerIndex})
    : charmAmountPerNight = config[charmAmountPerNightOptionId];
  static final RoleType type = RoleType.of<PiperRole>();
  @override
  RoleType get roleType => type;
  static const String charmAmountPerNightOptionId = 'charmAmountPerNight';

  final int charmAmountPerNight;

  Set<int> charmedPlayers = {};

  static void registerRole() {
    RoleManager.registerRole<PiperRole>(
      type,
      RegisterRoleInformation(
        constructor: PiperRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_piper_description,
        initialTeam: null,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_piper_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          IntOption(
            id: charmAmountPerNightOptionId,
            label: (context) => AppLocalizations.of(
              context,
            ).role_piper_option_charmAmountPerNight_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_piper_option_charmAmountPerNight_description,
            min: 1,
            defaultValue: 2,
          ),
        ]),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.loner,
          priority: 2,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(
      CompositeGameCommand(
        [
          RegisterWinConditionCommand(PiperWinCondition(playerIndex)),
          RegisterPiperNightActionCommand(
            charmAmountPerNight: charmAmountPerNight,
            charmedPlayers: charmedPlayers,
            playerIndex: playerIndex,
          ),
        ].lock,
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_piper_name;
}

@MappableClass(discriminatorValue: 'piper')
class PiperWinCondition with PiperWinConditionMappable implements WinCondition {
  const PiperWinCondition(this.playerIndex);

  final int playerIndex;

  @override
  bool hasWon(GameState gameState) {
    final piperRole = gameState.players[playerIndex].role as PiperRole;
    final charmedPlayers = piperRole.charmedPlayers;

    return gameState.alivePlayerIndices
        .difference(charmedPlayers)
        .singleElementEquals(playerIndex);
  }

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_piper_winHeadline;

  @override
  ISet<int> winningPlayers(GameState gameState) => ISet({playerIndex});
}

class PiperScreen extends StatefulWidget {
  const PiperScreen({
    super.key,
    required this.playerIndex,
    required this.charmedPlayers,
    required this.charmAmountPerNight,
    required this.onComplete,
  });

  final int playerIndex;
  final Set<int> charmedPlayers;
  final int charmAmountPerNight;
  final VoidCallback onComplete;

  @override
  State<PiperScreen> createState() => _PiperScreenState();
}

class _PiperScreenState extends State<PiperScreen> {
  bool hasCharmedPlayers = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final deadIndices = gameState.knownDeadPlayerIndices;
    final charmedOrDead = ISet(
      widget.charmedPlayers,
    ).union(deadIndices).union(ISet({widget.playerIndex}));

    return !hasCharmedPlayers
        ? ActionScreen(
            key: UniqueKey(),
            actionIdentifier: (PiperRole, false),
            appBarTitle: Text(PiperRole._name(context)),
            instruction: Text(
              localizations.role_piper_nightAction_instruction(
                count: widget.charmAmountPerNight,
              ),
            ),
            selectionCount: widget.charmAmountPerNight,
            allowSelectLess: true,
            currentActorIndices: ISet({widget.playerIndex}),
            disabledPlayerIndices: charmedOrDead,
            playerSpecificDisplayData: IMap.fromKeys(
              keys: widget.charmedPlayers.difference(deadIndices.unlockView),
              valueMapper: (index) => PlayerDisplayData(
                trailing: (context) =>
                    const Icon(Icons.auto_awesome, color: Colors.purple),
              ),
            ),
            onConfirm: (selectedPlayers, gameState) {
              gameState.apply(
                PiperCharmPlayersCommand(
                  playerIndex: widget.playerIndex,
                  charmedPlayers: selectedPlayers,
                ),
              );
              setState(() {
                hasCharmedPlayers = true;
              });
            },
          )
        : Scaffold(
            appBar: GameAppBar(title: Text(PiperRole._name(context))),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    localizations
                        .role_piper_nightAction_wakeCharmed_instruction,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  child: PlayerList(
                    phaseIdentifier: (PiperRole, true),
                    hiddenPlayers:
                        List.generate(gameState.playerCount, (i) => i)
                            .where(
                              (index) => !widget.charmedPlayers.contains(index),
                            )
                            .toISet(),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomContinueButton(
              onPressed: widget.onComplete,
            ),
          );
  }
}

@MappableClass(discriminatorValue: 'registerPiperNightAction')
class RegisterPiperNightActionCommand
    with RegisterPiperNightActionCommandMappable
    implements GameCommand {
  const RegisterPiperNightActionCommand({
    required this.playerIndex,
    required this.charmedPlayers,
    required this.charmAmountPerNight,
  });

  final int playerIndex;
  final Set<int> charmedPlayers;
  final int charmAmountPerNight;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      PiperRole,
      (gameState, onComplete) =>
          (context) => PiperScreen(
            playerIndex: playerIndex,
            onComplete: onComplete,
            charmedPlayers: charmedPlayers,
            charmAmountPerNight: charmAmountPerNight,
          ),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(PiperRole);
  }
}

@MappableClass(discriminatorValue: 'piperCharmPlayers')
class PiperCharmPlayersCommand
    with PiperCharmPlayersCommandMappable
    implements GameCommand {
  const PiperCharmPlayersCommand({
    required this.playerIndex,
    required this.charmedPlayers,
  });

  final int playerIndex;
  final ISet<int> charmedPlayers;

  @override
  void apply(GameData gameData) {
    final role = gameData.players[playerIndex].role as PiperRole;
    role.charmedPlayers.addAll(charmedPlayers);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final role = gameData.players[playerIndex].role as PiperRole;
    role.charmedPlayers.removeAll(charmedPlayers);
  }
}
