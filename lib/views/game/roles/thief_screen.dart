import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

class ThiefScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const ThiefScreen({super.key, required this.onPhaseComplete});

  @override
  State<ThiefScreen> createState() => _ThiefScreenState();
}

class _ThiefScreenState extends State<ThiefScreen> {
  _Selected _selected = _Selected.none;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final localizations = AppLocalizations.of(context)!;

        final missingRoles = gameState.unassignedRoles;

        assert(
          missingRoles.length == 2 * gameState.roles[Role.thief]!,
          'Number of missing roles must match twice the number of Thief roles assigned',
        );

        final (roleA, roleB) = (missingRoles[0], missingRoles[1]);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_thief_name),
            automaticallyImplyLeading: false,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  localizations.screen_roleAction_instruction_thief,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_selected == _Selected.roleA) {
                          _selected = _Selected.none;
                        } else {
                          _selected = _Selected.roleA;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 150),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      backgroundColor: _selected == _Selected.roleA
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5)
                          : null,
                      elevation: 4,
                    ),
                    child: Text(roleA.name(context)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_selected == _Selected.roleB) {
                          _selected = _Selected.none;
                        } else {
                          _selected = _Selected.roleB;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 150),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      backgroundColor: _selected == _Selected.roleB
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5)
                          : null,
                      elevation: 4,
                    ),
                    child: Text(roleB.name(context)),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed:
                  _selected == _Selected.none &&
                      roleA.team == Team.werewolves &&
                      roleB.team == Team.werewolves
                  ? null
                  : () {
                      submit(gameState, roleA, roleB);
                    },
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  void submit(GameState gameState, Role roleA, Role roleB) {
    if (_selected != _Selected.none) {
      final selectedRole = _selected == _Selected.roleA ? roleA : roleB;
      gameState.players
              .where((player) => player.role == Role.thief)
              .firstOrNull
              ?.role =
          selectedRole;
    }
    widget.onPhaseComplete();
  }
}

enum _Selected { none, roleA, roleB }
