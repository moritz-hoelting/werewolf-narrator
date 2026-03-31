import 'package:fpdart/fpdart.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/misc/winners/lovers.dart' show Lovers;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

@RegisterRole()
class CupidRole extends Role {
  CupidRole._({required RoleConfiguration config, required super.playerIndex});

  static final RoleType<CupidRole> type = RoleType<CupidRole>();
  @override
  RoleType<CupidRole> get objectType => type;

  Lovers? lovers;

  static void registerRole() {
    RoleManager.registerRole<CupidRole>(
      type,
      RegisterRoleInformation(
        constructor: CupidRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_cupid_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_cupid_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 50,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_cupid_name;

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);
    gameState.apply(RegisterCupidNightActionCommand(playerIndex));
  }
}

class CupidScreen extends StatelessWidget {
  const CupidScreen({
    super.key,
    required this.onComplete,
    required this.cupidIndex,
    required this.cupidRole,
  });

  final int cupidIndex;
  final CupidRole cupidRole;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (cupidRole.lovers == null) {
      return ActionScreen(
        appBarTitle: Text(CupidRole._name(context)),
        instruction: Text(
          AppLocalizations.of(context).role_cupid_nightAction_instruction,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionIdentifier: CupidRole.type,
        currentActorIndices: ISet({cupidIndex}),
        selectionCount: 2,
        onConfirm: onAssignLovers,
      );
    } else {
      return WakeLoversScreen(
        onPhaseComplete: onComplete,
        lovers: cupidRole.lovers!.lovers,
      );
    }
  }

  void onAssignLovers(ISet<int> selectedIndices, GameState gameState) {
    assert(
      selectedIndices.length == 2,
      'Cupid must select exactly two players as lovers.',
    );
    gameState.finishBatch(
      CupidAssignLoversCommand(cupidIndex: cupidIndex, lovers: selectedIndices),
    );
  }
}

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;
  final ISet<int> lovers;

  const WakeLoversScreen({
    super.key,
    required this.onPhaseComplete,
    required this.lovers,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);
        return Scaffold(
          appBar: GameAppBar(
            title: Text(localizations.screen_wakeLovers_title),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 160),
                  Text(
                    localizations.screen_wakeLovers_instructions,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  ...lovers
                      .sorted((a, b) => a.compareTo(b))
                      .map(
                        (playerIndex) =>
                            Text(gameState.players[playerIndex].name),
                      ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: onPhaseComplete,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}

class RegisterCupidNightActionCommand implements GameCommand {
  final int playerIndex;

  const RegisterCupidNightActionCommand(this.playerIndex);

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      CupidRole.type,
      (gameState, onComplete) {
        return nightActionScreen(gameState, onComplete);
      },
      conditioned: (gameState) =>
          gameState.winConditions.whereType<Lovers>().toList().isEmpty &&
          gameState.playerAliveUntilDawn(playerIndex),
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(CupidRole.type);
  }

  WidgetBuilder nightActionScreen(
    GameState gameState,
    VoidCallback onComplete,
  ) {
    return (context) => CupidScreen(
      onComplete: onComplete,
      cupidIndex: playerIndex,
      cupidRole: gameState.players[playerIndex].role as CupidRole,
    );
  }
}

class CupidAssignLoversCommand implements GameCommand {
  CupidAssignLoversCommand({required this.cupidIndex, required this.lovers});

  final int cupidIndex;
  final ISet<int> lovers;

  Option<Lovers?> _previousLovers = Option.none();

  @override
  void apply(GameData gameData) {
    final lovers_ = Lovers(lovers);
    final cupidRole = gameData.players[cupidIndex].role as CupidRole;
    _previousLovers = Option.of(cupidRole.lovers);
    cupidRole.lovers = lovers_;
    gameData.state.apply(RegisterWinConditionCommand(lovers_));
    lovers_.initialize(gameData.state);
  }

  @override
  bool get canBeUndone => _previousLovers.isSome();

  @override
  void undo(GameData gameData) {
    final cupidRole = gameData.players[cupidIndex].role as CupidRole;
    cupidRole.lovers = _previousLovers.getOrElse(() => null);
    _previousLovers = Option.none();
  }
}
