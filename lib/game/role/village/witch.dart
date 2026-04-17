import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/commands/mark_revived.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesDeathReason, WerewolvesTeam;
import 'package:werewolf_narrator/game/util/hooks.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

part 'witch.mapper.dart';

@RegisterRole()
class WitchRole extends Role {
  WitchRole._({required RoleConfiguration config, required super.playerIndex})
    : healPotions = config[healPotionOptionId],
      killPotions = config[killPotionOptionId];
  static final RoleType type = RoleType.of<WitchRole>();
  @override
  RoleType get roleType => type;

  static const String healPotionOptionId = 'heal';
  static const String killPotionOptionId = 'kill';

  int healPotions;
  int killPotions;

  static void registerRole() {
    RoleManager.registerRole<WitchRole>(
      type,
      RegisterRoleInformation(
        constructor: WitchRole._,
        name: (context) => AppLocalizations.of(context).role_witch_name,
        description: (context) =>
            AppLocalizations.of(context).role_witch_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_witch_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: options,
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 15,
        ),
      ),
    );
  }

  static final IList<ConfigurationOption> options = IList([
    IntOption(
      id: healPotionOptionId,
      label: (context) =>
          AppLocalizations.of(context).role_witch_option_healPotionCount_label,
      description: (context) => AppLocalizations.of(
        context,
      ).role_witch_option_healPotionCount_description,
      min: 0,
      defaultValue: 1,
    ),
    IntOption(
      id: killPotionOptionId,
      label: (context) =>
          AppLocalizations.of(context).role_witch_option_killPotionCount_label,
      description: (context) => AppLocalizations.of(
        context,
      ).role_witch_option_killPotionCount_description,
      min: 0,
      defaultValue: 1,
    ),
  ]);

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterWitchNightActionCommand(playerIndex));
  }
}

@MappableClass(discriminatorValue: 'witch')
class WitchDeathReason with WitchDeathReasonMappable implements DeathReason {
  const WitchDeathReason(this.playerIndex);

  final int playerIndex;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_witch_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});
}

class WitchScreen extends StatefulWidget {
  final int killPotions;
  final int healPotions;
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const WitchScreen({
    required this.killPotions,
    required this.healPotions,
    required this.playerIndex,
    required this.onPhaseComplete,
    super.key,
  });

  @override
  State<WitchScreen> createState() => _WitchScreenState();
}

class _WitchScreenState extends State<WitchScreen> {
  final Set<int> _selectedKillPlayers = {};
  final Set<int> _selectedHealPlayers = {};

  late bool _killModeActive = widget.healPotions == 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: GameAppBar(title: Text(localizations.role_witch_name)),
      body: widget.healPotions > 0 || widget.killPotions > 0
          ? HasPotionsBody(
              playerIndex: widget.playerIndex,
              healPotions: widget.healPotions,
              killPotions: widget.killPotions,
              killModeActive: _killModeActive,
              enableKillMode: () {
                setState(() {
                  _killModeActive = true;
                });
              },
              disableKillMode: () {
                setState(() {
                  _killModeActive = false;
                });
              },
              playerEnabled: playerEnabled,
              selectedHealPlayers: _selectedHealPlayers.lock,
              selectedKillPlayers: _selectedKillPlayers.lock,
              onTapHeal: onTapHeal,
              onTapKill: onTapKill,
            )
          : Center(
              child: Text(
                localizations.role_witch_nightAction_instruction_noPotionsLeft,
                style: const TextStyle(fontSize: 18),
              ),
            ),
      bottomNavigationBar: BottomContinueButton(
        onPressed: () {
          final gameState = Provider.of<GameState>(context, listen: false);
          gameState.apply(
            WitchUsePotionsCommand(
              playerIndex: widget.playerIndex,
              healPlayers: _selectedHealPlayers.lock,
              killPlayers: _selectedKillPlayers.lock,
            ),
          );
          widget.onPhaseComplete();
        },
      ),
    );
  }

  bool playerEnabled(GameState gameState, int index) {
    final killedByWerewolves =
        gameState.currentCycleDeaths.containsKey(index) &&
        (gameState.currentCycleDeaths[index]?.any(
              (reason) => reason is WerewolvesDeathReason,
            ) ??
            false);
    return gameState.players[index].isAlive &&
        (_killModeActive
            ? (index != widget.playerIndex &&
                  gameState.players[index].isAlive &&
                  !killedByWerewolves)
            : killedByWerewolves);
  }

  VoidCallback? onTapKill(GameState gameState, int index) =>
      handleOnTap(gameState, index, _selectedKillPlayers, widget.killPotions);

  VoidCallback? onTapHeal(GameState gameState, int index) =>
      handleOnTap(gameState, index, _selectedHealPlayers, widget.healPotions);
  VoidCallback? handleOnTap(
    GameState gameState,
    int index,
    Set<int> selectedSet,
    int maxSelectable,
  ) {
    if (!playerEnabled(gameState, index)) return null;

    if (maxSelectable == 1) {
      if (selectedSet.contains(index)) {
        return () {
          setState(() {
            selectedSet.remove(index);
          });
        };
      } else {
        return () {
          setState(() {
            selectedSet.clear();
            selectedSet.add(index);
          });
        };
      }
    }

    if (maxSelectable <= selectedSet.length && !selectedSet.contains(index)) {
      return null;
    }

    return () {
      setState(() {
        selectedSet.toggle(index);
      });
    };
  }
}

class HasPotionsBody extends StatelessWidget {
  const HasPotionsBody({
    required this.playerIndex,
    required this.killModeActive,
    required this.healPotions,
    required this.killPotions,
    required this.enableKillMode,
    required this.disableKillMode,
    required this.playerEnabled,
    required this.selectedHealPlayers,
    required this.selectedKillPlayers,
    required this.onTapHeal,
    required this.onTapKill,
    super.key,
  });

  final int playerIndex;
  final bool killModeActive;
  final int healPotions;
  final int killPotions;
  final VoidCallback enableKillMode;
  final VoidCallback disableKillMode;
  final bool Function(GameState, int) playerEnabled;
  final ISet<int> selectedHealPlayers;
  final ISet<int> selectedKillPlayers;
  final VoidCallback? Function(GameState, int) onTapHeal;
  final VoidCallback? Function(GameState, int) onTapKill;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final modeButtonStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
    final selectedModeButtonStyle = TextButton.styleFrom(
      disabledForegroundColor: Theme.of(context).colorScheme.primary,
    );

    return Column(
      children: [
        TextButton.icon(
          style: !killModeActive ? selectedModeButtonStyle : modeButtonStyle,
          onPressed: killModeActive && healPotions > 0 ? disableKillMode : null,
          label: Text(
            localizations.role_witch_nightAction_instruction_heal +
                (healPotions > 1 ? ' ($healPotions)' : ''),
          ),
          icon: const Icon(Icons.healing),
        ),
        TextButton.icon(
          style: killModeActive ? selectedModeButtonStyle : modeButtonStyle,
          onPressed: !killModeActive && killPotions > 0 ? enableKillMode : null,
          label: Text(
            localizations.role_witch_nightAction_instruction_kill +
                (killPotions > 1 ? ' ($killPotions)' : ''),
          ),
          icon: const Icon(Icons.science),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            localizations.role_witch_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Consumer<GameState>(
          builder: (context, gameState, child) => Expanded(
            child: PlayerList(
              phaseIdentifier: WitchScreen,
              onPlayerTap: (index) => killModeActive
                  ? onTapKill(gameState, index)
                  : onTapHeal(gameState, index),
              selectedPlayers: killModeActive
                  ? selectedKillPlayers
                  : selectedHealPlayers,
              disabledPlayers: List.generate(
                gameState.playerCount,
                (i) => i,
              ).where((index) => !playerEnabled(gameState, index)).toISet(),
              currentActorIndices: ISet({playerIndex}),
              playerSpecificDisplayData: {
                for (final index in selectedHealPlayers)
                  index: PlayerDisplayData(
                    trailing: (context) => const Icon(Icons.healing),
                    selectedTileColor: Colors.green.withAlpha(50),
                    tileColor: Colors.green.withAlpha(30),
                  ),
                for (final index in selectedKillPlayers)
                  index: PlayerDisplayData(
                    trailing: (context) => const Icon(Icons.science),
                    selectedTileColor: Colors.red.withAlpha(50),
                    tileColor: Colors.red.withAlpha(30),
                  ),
              }.lock,
            ),
          ),
        ),
      ],
    );
  }
}

@MappableClass(discriminatorValue: 'registerWitchNightAction')
class RegisterWitchNightActionCommand
    with RegisterWitchNightActionCommandMappable
    implements GameCommand {
  const RegisterWitchNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      WitchRole.type,
      (gameState, onComplete) {
        final witch = gameState.players[playerIndex].role as WitchRole;

        return (context) => WitchScreen(
          healPotions: witch.healPotions,
          killPotions: witch.killPotions,
          playerIndex: playerIndex,
          onPhaseComplete: onComplete,
        );
      },
      conditioned: (gameState) => gameState.players[playerIndex].isAlive,
      after: IList([WerewolvesTeam.type, CupidRole.type]),
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(WitchRole.type);
  }
}

@MappableClass(discriminatorValue: 'witchUsePotions')
class WitchUsePotionsCommand
    with WitchUsePotionsCommandMappable
    implements GameCommand {
  WitchUsePotionsCommand({
    required this.playerIndex,
    required this.healPlayers,
    required this.killPlayers,
  });

  final int playerIndex;
  final ISet<int> healPlayers;
  final ISet<int> killPlayers;

  @override
  void apply(GameData gameData) {
    final witchRole = gameData.players[playerIndex].role as WitchRole;

    if (healPlayers.isNotEmpty || killPlayers.isNotEmpty) {
      gameData.state.apply(
        CompositeGameCommand(
          <GameCommand>[
            if (healPlayers.isNotEmpty) MarkRevivedCommand(healPlayers),
            if (killPlayers.isNotEmpty)
              MarkDeadCommand(
                players: killPlayers,
                deathReason: WitchDeathReason(playerIndex),
              ),
          ].lock,
        ),
      );
    }

    witchRole.healPotions -= healPlayers.length;
    witchRole.killPotions -= killPlayers.length;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final witchRole = gameData.players[playerIndex].role as WitchRole;

    witchRole.healPotions += healPlayers.length;
    witchRole.killPotions += killPlayers.length;
  }
}
