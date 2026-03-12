import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

class ActionScreen extends StatefulWidget {
  final Widget appBarTitle;
  final Widget? instruction;
  final Object? actionIdentifier;

  final ISet<int> currentActorIndices;
  final ISet<int> disabledPlayerIndices;

  final int selectionCount;
  final bool allowSelectLess;

  final void Function(ISet<int> playerIds, GameState gameState) onConfirm;

  const ActionScreen({
    super.key,
    required this.appBarTitle,
    this.instruction,
    this.actionIdentifier,
    this.currentActorIndices = const ISet.empty(),
    this.disabledPlayerIndices = const ISet.empty(),
    required this.selectionCount,
    this.allowSelectLess = false,
    required this.onConfirm,
  });

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  final Set<int> _selectedPlayers = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) => Scaffold(
        appBar: AppBar(
          title: widget.appBarTitle,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            if (widget.instruction != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.instruction!,
              ),
            Expanded(
              child: PlayerList(
                phaseIdentifier: widget.actionIdentifier,
                onPlayerTap: (index) => getOnTapPlayer(index, gameState),
                selectedPlayers: _selectedPlayers.lock,
                disabledPlayers: widget.disabledPlayerIndices.union(
                  gameState.knownDeadPlayerIndices,
                ),
                currentActorIndices: widget.currentActorIndices,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomContinueButton(
          onPressed: getOnContinue(gameState),
        ),
      ),
    );
  }

  VoidCallback? getOnTapPlayer(int index, GameState gameState) {
    if (!gameState.playerAliveUntilDawn(index)) {
      return null;
    }

    if (widget.disabledPlayerIndices.contains(index)) {
      return null;
    }

    if (widget.selectionCount == 1) {
      return () {
        setState(() {
          _selectedPlayers.clear();
          _selectedPlayers.add(index);
        });
      };
    }

    return (_selectedPlayers.contains(index) ||
            (!_selectedPlayers.contains(index) &&
                _selectedPlayers.length < widget.selectionCount))
        ? () {
            setState(() {
              _selectedPlayers.toggle(index);
            });
          }
        : null;
  }

  VoidCallback? getOnContinue(GameState gameState) =>
      (_selectedPlayers.length == widget.selectionCount ||
          (widget.allowSelectLess &&
              _selectedPlayers.length < widget.selectionCount))
      ? () {
          if (_selectedPlayers.length < widget.selectionCount) {
            final answer = showDialog<bool>(
              useRootNavigator: false,
              context: context,
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                return AlertDialog(
                  title: Text(localizations.dialog_fewerSelectionsTitle),
                  content: Text(
                    localizations.dialog_fewerSelectionsMessage(
                      selectedCount: _selectedPlayers.length,
                      maxCount: widget.selectionCount,
                    ),
                  ),
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
                );
              },
            );
            answer.then((continueWithLess) {
              if (continueWithLess == true) {
                widget.onConfirm(_selectedPlayers.lock, gameState);
              }
            });
          } else {
            widget.onConfirm(_selectedPlayers.lock, gameState);
          }
        }
      : null;
}
