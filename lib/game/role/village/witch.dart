import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/util/hooks.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesDeathReason;
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

class WitchRole extends Role implements DeathReason {
  WitchRole._();
  static final RoleType type = RoleType<WitchRole>();
  @override
  RoleType get objectType => type;

  int? playerIndex;

  int healPotions = 1;
  int killPotions = 1;

  static void registerRole() {
    RoleManager.registerRole<WitchRole>(
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
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 15,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;

    gameState.nightActionManager.registerAction(
      WitchRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      after: IList([WerewolvesTeam.type, CupidRole.type]),
      players: {playerIndex},
    );
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_witch_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex!});

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) => WitchScreen(
        witchRole: this,
        playerIndex: playerIndex,
        onPhaseComplete: onComplete,
        useUpPotions: ({heal = 0, kill = 0}) {
          healPotions -= heal;
          killPotions -= kill;
          if (heal > 0 || kill > 0) {
            Provider.of<GameState>(context, listen: false).notifyUpdate();
          }
        },
      );
}

class WitchScreen extends StatefulWidget {
  final WitchRole witchRole;
  final int playerIndex;
  final VoidCallback onPhaseComplete;
  final void Function({int heal, int kill}) useUpPotions;

  const WitchScreen({
    super.key,
    required this.witchRole,
    required this.playerIndex,
    required this.onPhaseComplete,
    required this.useUpPotions,
  });

  @override
  State<WitchScreen> createState() => _WitchScreenState();
}

class _WitchScreenState extends State<WitchScreen> {
  final Set<int> _selectedKillPlayers = {};
  final Set<int> _selectedHealPlayers = {};

  late bool _killModeActive = widget.witchRole.healPotions == 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.role_witch_name),
        automaticallyImplyLeading: false,
      ),
      body: widget.witchRole.healPotions > 0 || widget.witchRole.killPotions > 0
          ? HasPotionsBody(
              playerIndex: widget.playerIndex,
              healPotions: widget.witchRole.healPotions,
              killPotions: widget.witchRole.killPotions,
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
                style: TextStyle(fontSize: 18),
              ),
            ),
      bottomNavigationBar: BottomContinueButton(
        onPressed: () {
          final GameState gameState = Provider.of<GameState>(
            context,
            listen: false,
          );
          if (_selectedHealPlayers.isNotEmpty) {
            for (final healIndex in _selectedHealPlayers) {
              gameState.markPlayerRevived(healIndex);
            }
          }
          if (_selectedKillPlayers.isNotEmpty) {
            for (final killIndex in _selectedKillPlayers) {
              gameState.markPlayerDead(killIndex, widget.witchRole);
            }
          }
          widget.useUpPotions(
            heal: _selectedHealPlayers.length,
            kill: _selectedKillPlayers.length,
          );
          widget.onPhaseComplete();
        },
      ),
    );
  }

  bool playerEnabled(GameState gameState, int index) {
    final killedByWerewolves =
        gameState.currentCycleDeaths.containsKey(index) &&
        gameState.currentCycleDeaths[index] is WerewolvesDeathReason;
    return gameState.playerAliveOrKilledThisCycle(index) &&
        (_killModeActive
            ? (index != widget.playerIndex &&
                  gameState.playerAliveOrKilledThisCycle(index) &&
                  !killedByWerewolves)
            : (killedByWerewolves));
  }

  VoidCallback? onTapKill(GameState gameState, int index) => handleOnTap(
    gameState,
    index,
    _selectedKillPlayers,
    widget.witchRole.killPotions,
  );

  VoidCallback? onTapHeal(GameState gameState, int index) => handleOnTap(
    gameState,
    index,
    _selectedHealPlayers,
    widget.witchRole.healPotions,
  );
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
    super.key,
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
