import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';

class ActionScreen extends StatefulWidget {
  final Widget appBarTitle;
  final Widget? instruction;

  final List<int> disabledPlayerIndices;

  final int selectionCount;
  final bool allowSelectLess;

  final void Function(List<int> playerIds, GameState gameState) onConfirm;

  const ActionScreen({
    super.key,
    required this.appBarTitle,
    this.instruction,
    this.disabledPlayerIndices = const [],
    required this.selectionCount,
    this.allowSelectLess = false,
    required this.onConfirm,
  });

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  late final List<bool> _selectedPlayers;

  int get selectedCount =>
      _selectedPlayers.where((isSelected) => isSelected).length;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = List.filled(
      Provider.of<GameState>(context, listen: false).playerCount,
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context)!;

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
                      selected: _selectedPlayers[index],
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
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed:
                  (selectedCount == widget.selectionCount ||
                      (widget.allowSelectLess &&
                          selectedCount < widget.selectionCount))
                  ? () {
                      final selectedPlayers = _selectedPlayers
                          .asMap()
                          .entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      if (selectedCount < widget.selectionCount) {
                        final answer = showDialog<bool>(
                          context: context,
                          builder: (context) {
                            final localizations = AppLocalizations.of(context)!;
                            return AlertDialog(
                              title: Text(
                                localizations.dialog_fewerSelectionsTitle,
                              ),
                              content: Text(
                                localizations.dialog_fewerSelectionsMessage(
                                  selectedCount,
                                  widget.selectionCount,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(localizations.button_noLabel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(localizations.button_yesLabel),
                                ),
                              ],
                            );
                          },
                        );
                        answer.then((continueWithLess) {
                          if (continueWithLess == true) {
                            widget.onConfirm(selectedPlayers, gameState);
                          }
                        });
                      } else {
                        widget.onConfirm(selectedPlayers, gameState);
                      }
                    }
                  : null,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
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
          for (int i = 0; i < _selectedPlayers.length; i++) {
            _selectedPlayers[i] = false;
          }
          _selectedPlayers[index] = true;
        });
      };
    }

    return (_selectedPlayers[index] ||
            (!_selectedPlayers[index] && selectedCount < widget.selectionCount))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }
}
