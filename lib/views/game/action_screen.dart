import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class ActionScreen extends StatefulWidget {
  final Widget appBarTitle;
  final Widget? instruction;

  final Set<int> disabledPlayerIndices;

  final int selectionCount;
  final bool allowSelectLess;

  final void Function(Set<int> playerIds, GameState gameState) onConfirm;

  const ActionScreen({
    super.key,
    required this.appBarTitle,
    this.instruction,
    this.disabledPlayerIndices = const {},
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
      builder: (context, gameState, _) {
        return Scaffold(
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
                child: ListView.builder(
                  itemCount: gameState.playerCount,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(gameState.players[index].name),
                      onTap: getOnTapPlayer(index, gameState),
                      selected: _selectedPlayers.contains(index),
                      enabled:
                          gameState.players[index].isAlive &&
                          !widget.disabledPlayerIndices.contains(index),
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomContinueButton(
            onPressed: getOnContinue(gameState),
          ),
        );
      },
    );
  }

  VoidCallback? getOnTapPlayer(int index, GameState gameState) {
    if (!gameState.players[index].isAlive) {
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
              context: context,
              builder: (context) {
                final localizations = AppLocalizations.of(context)!;
                return AlertDialog(
                  title: Text(localizations.dialog_fewerSelectionsTitle),
                  content: Text(
                    localizations.dialog_fewerSelectionsMessage(
                      _selectedPlayers.length,
                      widget.selectionCount,
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
                widget.onConfirm(_selectedPlayers, gameState);
              }
            });
          } else {
            widget.onConfirm(_selectedPlayers, gameState);
          }
        }
      : null;
}
