import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart'
    show BottomContinueButton;
import 'package:werewolf_narrator/widgets/game/player_list.dart'
    show PlayerList;

class PiperRole extends Role implements WinCondition {
  PiperRole._();
  static final RoleType type = RoleType<PiperRole>();
  @override
  RoleType get objectType => type;

  static const int charmAmountPerNight = 2;

  int? playerIndex;
  Set<int> charmedPlayers = {};

  static void registerRole() {
    RoleManager.registerRole<PiperRole>(
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
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;
    gameState.winConditions.add(this);

    gameState.nightActionManager.registerAction(
      PiperRole,
      (gameState, onComplete) =>
          (context) => PiperScreen(
            playerIndex: playerIndex,
            onComplete: onComplete,
            charmedPlayers: charmedPlayers,
          ),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      players: {playerIndex},
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_piper_name;

  @override
  bool hasWon(GameState gameState) =>
      playerIndex != null &&
      gameState.alivePlayerIndices
          .difference(charmedPlayers)
          .singleElementEquals(playerIndex!);

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_piper_winHeadline;

  @override
  List<(int, Player)> winningPlayers(GameState gameState) {
    return [(playerIndex!, gameState.players[playerIndex!])];
  }
}

class PiperScreen extends StatefulWidget {
  const PiperScreen({
    super.key,
    required this.playerIndex,
    required this.charmedPlayers,
    required this.onComplete,
  });

  final int playerIndex;
  final Set<int> charmedPlayers;
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
                count: PiperRole.charmAmountPerNight,
              ),
            ),
            selectionCount: PiperRole.charmAmountPerNight,
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
              widget.charmedPlayers.addAll(selectedPlayers);
              setState(() {
                hasCharmedPlayers = true;
              });
            },
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(PiperRole._name(context)),
              automaticallyImplyLeading: false,
            ),
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
