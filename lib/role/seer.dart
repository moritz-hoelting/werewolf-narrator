import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class SeerRole extends Role {
  const SeerRole._();
  static final RoleType type = RoleType<SeerRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = SeerRole._();

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
    return AppLocalizations.of(context)!.role_seer_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_seer_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.role_seer_checkInstruction(count);
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
        final localizations = AppLocalizations.of(context)!;

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
                  localizations.screen_roleAction_instruction_seer,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: gameState.playerCount,
                  itemBuilder: (context, index) {
                    return PlayerListTile(
                      playerName: gameState.players[index].name,
                      roleName: gameState.players[index].role?.name(context),
                      enabled:
                          gameState.playerAliveUntilDawn(index) &&
                          index != widget.playerIndex,
                      selected: _selectedPlayer == index,
                      onTap: () {
                        setState(() {
                          _selectedPlayer = index;
                        });
                      },
                    );
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

class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    super.key,
    required this.playerName,
    this.roleName,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final String playerName;
  final String? roleName;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(playerName),
      subtitle: selected
          ? Text(
              roleName ?? localizations.role_unknown_name,
              style: Theme.of(context).textTheme.bodyLarge,
            )
          : null,
      onTap: onTap,
      selected: selected,
      enabled: enabled,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
    );
  }
}
