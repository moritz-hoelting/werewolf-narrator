import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

class FoxRole extends Role {
  FoxRole._(RoleConfiguration config)
    : loosePowersOnWrongGuess = config[losePowersOnWrongGuessOptionId];
  static final RoleType<FoxRole> type = RoleType<FoxRole>();
  @override
  RoleType<FoxRole> get objectType => type;

  static const String losePowersOnWrongGuessOptionId = 'losePowersOnWrongGuess';

  final bool loosePowersOnWrongGuess;

  bool hasLostPowers = false;

  static void registerRole() {
    RoleManager.registerRole<FoxRole>(
      type,
      RegisterRoleInformation(
        constructor: FoxRole._,
        name: (context) => AppLocalizations.of(context).role_fox_name,
        description: (context) =>
            AppLocalizations.of(context).role_fox_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_fox_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          BoolOption(
            id: losePowersOnWrongGuessOptionId,
            defaultValue: true,
            label: (context) => AppLocalizations.of(
              context,
            ).role_fox_option_losePowersOnWrongGuess_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_fox_option_losePowersOnWrongGuess_description,
          ),
        ]),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 30,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      FoxRole.type,
      (gameState, onComplete) =>
          (context) => FoxScreen(
            foxRole: this,
            playerIndex: playerIndex,
            onPhaseComplete: onComplete,
          ),
      conditioned: (gameState) =>
          !hasLostPowers && gameState.playerAliveUntilDawn(playerIndex),
      after: IList([CupidRole.type]),
      players: {playerIndex},
    );
  }
}

class FoxScreen extends StatefulWidget {
  final FoxRole foxRole;
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const FoxScreen({
    super.key,
    required this.foxRole,
    required this.playerIndex,
    required this.onPhaseComplete,
  });

  @override
  State<FoxScreen> createState() => _FoxScreenState();
}

class _FoxScreenState extends State<FoxScreen> {
  bool? _foundWerewolf;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_fox_name),
            automaticallyImplyLeading: false,
            leading: _foundWerewolf != null
                ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => setState(() {
                      _foundWerewolf = null;
                    }),
                  )
                : null,
          ),
          body: _foundWerewolf != null
              ? _ShowResult(
                  foundWerewolf: _foundWerewolf!,
                  gameState: gameState,
                )
              : _SelectPlayer(
                  playerIndex: widget.playerIndex,
                  gameState: gameState,
                  onPlayerSelected: (index) {
                    final foundWerewolf = _checkForWerewolves(gameState, index);
                    setState(() {
                      _foundWerewolf = foundWerewolf;
                    });
                  },
                ),
          bottomNavigationBar: BottomContinueButton(
            onPressed: _foundWerewolf != null
                ? () {
                    if (widget.foxRole.loosePowersOnWrongGuess &&
                        !_foundWerewolf!) {
                      widget.foxRole.hasLostPowers = true;
                    }
                    widget.onPhaseComplete();
                  }
                : () => promptSkipAbility(context, widget.onPhaseComplete),
          ),
        );
      },
    );
  }

  void promptSkipAbility(BuildContext context, VoidCallback onComplete) {
    final localizations = AppLocalizations.of(context);
    final skip = showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.role_fox_nightAction_skip),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.button_noLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.button_yesLabel),
          ),
        ],
      ),
    );

    skip.then((continueWithLess) {
      if (continueWithLess == true) {
        onComplete();
      }
    });
  }
}

class _SelectPlayer extends StatelessWidget {
  const _SelectPlayer({
    required this.playerIndex,
    required this.gameState,
    required this.onPlayerSelected,
  });

  final int playerIndex;
  final GameState gameState;
  final void Function(int selectedPlayer) onPlayerSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            localizations.role_fox_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: PlayerList(
            phaseIdentifier: FoxScreen,
            selectedPlayers: const ISet.empty(),
            disabledPlayers: gameState.knownDeadPlayerIndices,
            currentActorIndices: ISet({playerIndex}),
            onPlayerTap: (index) =>
                () => onPlayerSelected(index),
          ),
        ),
      ],
    );
  }
}

class _ShowResult extends StatelessWidget {
  const _ShowResult({required this.foundWerewolf, required this.gameState});

  final bool foundWerewolf;
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        foundWerewolf
            ? AppLocalizations.of(context).role_fox_nightAction_result_werewolf
            : AppLocalizations.of(
                context,
              ).role_fox_nightAction_result_noWerewolf,
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

bool _checkForWerewolves(GameState gameState, int playerIndex) {
  final (leftNeighborIndex, rightNeighborIndex) = gameState.getAliveNeighbors(
    playerIndex,
  );

  final indicesToCheck = {playerIndex, leftNeighborIndex, rightNeighborIndex};

  return indicesToCheck.any(
    (index) =>
        gameState.players[index].role?.team(gameState) == WerewolvesTeam.type,
  );
}
