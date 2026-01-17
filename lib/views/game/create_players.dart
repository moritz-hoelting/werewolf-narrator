import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

final int minPlayers = 8;

class CreatePlayersScreen extends StatefulWidget {
  final void Function(List<String>) onSubmit;
  final List<String>? initialPlayers;

  const CreatePlayersScreen({
    super.key,
    required this.onSubmit,
    this.initialPlayers,
  });

  @override
  State<CreatePlayersScreen> createState() => _CreatePlayersScreenState();
}

class _CreatePlayersScreenState extends State<CreatePlayersScreen> {
  late List<String> playerNames =
      widget.initialPlayers == null || widget.initialPlayers!.isEmpty
      ? List.filled(minPlayers, '', growable: true)
      : widget.initialPlayers!;
  late List<Key> playerKeys = List.generate(
    playerNames.length,
    (_) => UniqueKey(),
  );

  Set<int> invalidIndexes = {};

  @override
  Widget build(BuildContext context) {
    void updatePlayerName(int index, String name) {
      setState(() {
        playerNames[index] = name;
      });
    }

    void deletePlayer(int index) {
      setState(() {
        playerNames.removeAt(index);
      });
    }

    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              footer: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        playerNames.add('');
                        playerKeys.add(UniqueKey());
                      });
                    },
                    label: Text(localizations.screen_createPlayers_addPlayer),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),

              itemCount: playerNames.length,
              itemBuilder: (context, index) => Padding(
                key: playerKeys[index],

                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, right: 8.0),
                        child: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PlayerNameInput(
                        idx: index,
                        initialText: playerNames[index],
                        isInvalid: invalidIndexes.contains(index),
                        onNameChanged: (name) => updatePlayerName(index, name),
                        onDelete: playerNames.length > minPlayers
                            ? () => deletePlayer(index)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              onReorder: reorderPlayer,
            ),
          ),
          Divider(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: validateNames()
                  ? () {
                      final names = playerNames
                          .map((name) => name.trim())
                          .where((name) => name.isNotEmpty)
                          .toList();
                      widget.onSubmit(names);
                    }
                  : null,
              label: Text(
                localizations.screen_createPlayers_selectRolesButtonLabel,
              ),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool validateNames() {
    final trimmedNames = playerNames.map((name) => name.trim()).toList();

    final invalid = <int>{};

    for (var i = 0; i < trimmedNames.length; i++) {
      if (trimmedNames[i].isEmpty) invalid.add(i);
    }

    final seen = <String>{};
    for (var i = 0; i < trimmedNames.length; i++) {
      final name = trimmedNames[i];
      if (name.isNotEmpty) {
        if (seen.contains(name)) {
          invalid.add(i);
        } else {
          seen.add(name);
        }
      }
    }

    setState(() {
      invalidIndexes = invalid;
    });

    return (trimmedNames.where((n) => n.isNotEmpty).toSet().length >=
        minPlayers);
  }

  void reorderPlayer(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = playerNames.removeAt(oldIndex);
      final key = playerKeys.removeAt(oldIndex);
      playerNames.insert(newIndex, item);
      playerKeys.insert(newIndex, key);
    });
  }
}

class PlayerNameInput extends StatefulWidget {
  final String initialText;
  final int idx;
  final void Function(String) onNameChanged;
  final VoidCallback? onDelete;
  final bool isInvalid;

  const PlayerNameInput({
    super.key,
    required this.idx,
    required this.initialText,
    this.isInvalid = false,
    required this.onNameChanged,
    this.onDelete,
  });

  @override
  State<PlayerNameInput> createState() => _PlayerNameInputState();
}

class _PlayerNameInputState extends State<PlayerNameInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  late final FocusNode _focusNode = FocusNode();

  bool _touched = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_touched) {
        setState(() {
          _touched = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return TextField(
      autocorrect: false,
      maxLength: 25,
      decoration: InputDecoration(
        labelText: localizations.screen_createPlayers_playerNumberInputLabel(
          widget.idx + 1,
        ),
        errorText: (_touched && !_focusNode.hasFocus && widget.isInvalid)
            ? localizations.screen_createPlayers_error_invalidOrDuplicateName
            : null,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.delete),
          iconSize: 30,
          onPressed: widget.onDelete,
          disabledColor: Colors.grey.shade400,
        ),
      ),
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onNameChanged,
    );
  }
}
