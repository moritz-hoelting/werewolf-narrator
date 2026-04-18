import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/mark_revived.dart';
import 'package:werewolf_narrator/game/commands/override_team.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/player.dart' show PlayerView;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesDeathReason, WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

part 'ancient_werewolf.mapper.dart';

// TODO: remove from pending deaths instead of reviving
@RegisterRole()
class AncientWerewolfRole extends Role {
  AncientWerewolfRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<AncientWerewolfRole>();
  @override
  RoleType get roleType => type;

  int? convertedPlayerIndex;
  int? convertedDayCount;

  static void registerRole() {
    RoleManager.registerRole<AncientWerewolfRole>(
      type,
      RegisterRoleInformation(
        constructor: AncientWerewolfRole._,
        name: (context) =>
            AppLocalizations.of(context).role_ancientWerewolf_name,
        description: (context) =>
            AppLocalizations.of(context).role_ancientWerewolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_ancientWerewolf_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.werewolves,
          priority: 10,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterAncientWerewolfNightActionCommand(playerIndex));
  }
}

class AncientWerewolfScreen extends StatelessWidget {
  const AncientWerewolfScreen({
    required this.playerIndex,
    required this.onPhaseComplete,
    super.key,
  });

  final int playerIndex;
  final VoidCallback onPhaseComplete;

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) {
      final localizations = AppLocalizations.of(context);

      final ancientWerewolfRole =
          gameState.players[playerIndex].role as AncientWerewolfRole;

      if (ancientWerewolfRole.convertedPlayerIndex != null) {
        if (ancientWerewolfRole.convertedDayCount == gameState.dayCounter) {
          return Scaffold(
            appBar: GameAppBar(
              title: Text(localizations.role_ancientWerewolf_name),
            ),
            body: Center(
              child: Text(
                localizations.role_ancientWerewolf_nightAction_informPlayer(
                  player: gameState
                      .players[ancientWerewolfRole.convertedPlayerIndex!]
                      .name,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            bottomNavigationBar: BottomContinueButton(
              onPressed: onPhaseComplete,
            ),
          );
        } else {
          return Scaffold(
            appBar: GameAppBar(
              title: Text(localizations.role_ancientWerewolf_name),
            ),
            body: Center(
              child: Text(
                localizations.role_ancientWerewolf_nightAction_hasUsedAbility,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            bottomNavigationBar: BottomContinueButton(
              onPressed: onPhaseComplete,
            ),
          );
        }
      }

      final int? lastAttackedPlayer = findLastAttackedPlayer(gameState)?.index;

      if (lastAttackedPlayer == null) {
        return Scaffold(
          appBar: GameAppBar(
            title: Text(localizations.role_ancientWerewolf_name),
          ),
          body: Center(
            child: Text(
              localizations.role_ancientWerewolf_nightAction_noAttackThisNight,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          bottomNavigationBar: BottomContinueButton(onPressed: onPhaseComplete),
        );
      }

      return BinarySelectionScreen(
        key: UniqueKey(),
        appBarTitle: Text(localizations.role_ancientWerewolf_name),
        instruction: Text(
          localizations.role_ancientWerewolf_nightAction_instruction(
            playerName: findLastAttackedPlayer(gameState)?.player.name ?? '?',
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        firstOption: Text(localizations.button_yesLabel),
        secondOption: Text(localizations.button_noLabel),
        onComplete: (selectedFirst) {
          submit(gameState, selectedFirst!);
        },
      );
    },
  );

  void submit(GameState gameState, bool selectedFirst) {
    if (selectedFirst) {
      final lastAttackedPlayer = findLastAttackedPlayer(gameState);
      if (lastAttackedPlayer != null) {
        useAbilityOn(
          gameState,
          lastAttackedPlayer.index,
          lastAttackedPlayer.player,
        );
      }
    } else {
      onPhaseComplete();
    }
  }

  ({int index, PlayerView player})? findLastAttackedPlayer(
    GameState gameState,
  ) {
    final lastAttackedPlayerIndex = gameState.currentCycleDeaths.entries
        .where(
          (entry) =>
              entry.value.any((reason) => reason is WerewolvesDeathReason),
        )
        .map((entry) => entry.key)
        .lastOrNull;
    if (lastAttackedPlayerIndex == null) {
      return null;
    }
    final player = gameState.players[lastAttackedPlayerIndex];
    return (index: lastAttackedPlayerIndex, player: player);
  }

  void useAbilityOn(GameState gameState, int playerIndex, PlayerView player) {
    gameState.finishBatch(
      CompositeGameCommand(
        [
          MarkRevivedCommand.single(playerIndex),
          OverrideTeamCommand(playerIndex, WerewolvesTeam.type),
          AncientWerewolfSaveConvertPlayerIndexCommand(
            playerIndex: this.playerIndex,
            convertedPlayerIndex: playerIndex,
            convertedDayCount: gameState.dayCounter,
          ),
        ].lock,
      ),
    );
  }
}

@MappableClass(discriminatorValue: 'registerAncientWerewolfNightAction')
class RegisterAncientWerewolfNightActionCommand
    with RegisterAncientWerewolfNightActionCommandMappable
    implements GameCommand {
  const RegisterAncientWerewolfNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      AncientWerewolfRole.type,
      (gameState, onComplete) =>
          (context) => AncientWerewolfScreen(
            playerIndex: playerIndex,
            onPhaseComplete: onComplete,
          ),
      conditioned: (gameState) => gameState.players[playerIndex].isAlive,
      after: ISet({WerewolvesTeam.type}),
      before: ISet({WitchRole.type}),
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(AncientWerewolfRole.type);
  }
}

@MappableClass(discriminatorValue: 'ancientWerewolfSaveConvertPlayerIndex')
class AncientWerewolfSaveConvertPlayerIndexCommand
    with AncientWerewolfSaveConvertPlayerIndexCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int convertedPlayerIndex;
  final int convertedDayCount;

  AncientWerewolfSaveConvertPlayerIndexCommand({
    required this.playerIndex,
    required this.convertedPlayerIndex,
    required this.convertedDayCount,
  });

  Option<({int? convertedPlayerIndex, int? convertedDayCount})> _previousData =
      const Option.none();

  @override
  void apply(GameData gameData) {
    final role = gameData.players[playerIndex].role as AncientWerewolfRole;
    _previousData = Option.of((
      convertedPlayerIndex: role.convertedPlayerIndex,
      convertedDayCount: role.convertedDayCount,
    ));
    role.convertedPlayerIndex = convertedPlayerIndex;
    role.convertedDayCount = convertedDayCount;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final role = gameData.players[playerIndex].role as AncientWerewolfRole;
    final previousData = _previousData.getOrElse(
      () => (convertedPlayerIndex: null, convertedDayCount: null),
    );
    role.convertedPlayerIndex = previousData.convertedPlayerIndex;
    role.convertedDayCount = previousData.convertedDayCount;
    _previousData = const Option.none();
  }
}
