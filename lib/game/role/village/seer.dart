import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

class SeerRole extends Role {
  SeerRole._();
  static final RoleType type = RoleType<SeerRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = SeerRole._();

  static void registerRole() {
    RoleManager.registerRole<SeerRole>(
      RegisterRoleInformation(SeerRole._, instance),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      SeerRole.type,
      (gameState, onComplete) =>
          (context) =>
              SeerScreen(playerIndex: playerIndex, onPhaseComplete: onComplete),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      after: [CupidRole.type],
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_seer_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_seer_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context);
    return localizations.role_seer_checkInstruction(count: count);
  }
}

class SeerScreen extends StatefulWidget {
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const SeerScreen({
    super.key,
    required this.playerIndex,
    required this.onPhaseComplete,
  });

  @override
  State<SeerScreen> createState() => _SeerScreenState();
}

class _SeerScreenState extends State<SeerScreen> {
  int? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_seer_name),
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  localizations.role_seer_nightAction_instruction,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Expanded(
                child: PlayerList(
                  phaseIdentifier: SeerScreen,
                  selectedPlayers: {_selectedPlayer}.nonNulls.toSet(),
                  disabledPlayers: gameState.knownDeadPlayerIndices.union({
                    widget.playerIndex,
                  }),
                  currentActorIndices: {widget.playerIndex},
                  playerSpecificDisplayData: _selectedPlayer != null
                      ? {
                          _selectedPlayer!: PlayerDisplayData(
                            subtitle: (context) => Text(
                              gameState.players[_selectedPlayer!].role?.name(
                                    context,
                                  ) ??
                                  localizations.role_unknown_name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        }
                      : {},
                  onPlayerTap: (index) => () {
                    setState(() {
                      _selectedPlayer = index;
                    });
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomContinueButton(
            onPressed: _selectedPlayer != null ? widget.onPhaseComplete : null,
          ),
        );
      },
    );
  }
}
