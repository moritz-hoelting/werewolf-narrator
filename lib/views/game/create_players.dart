import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart' show AppDatabase;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/settings.dart' show AppSettings;

class CreatePlayersScreen extends StatefulWidget {
  final void Function(IList<String>) onSubmit;
  final IList<String>? initialPlayers;

  const CreatePlayersScreen({
    required this.onSubmit,
    super.key,
    this.initialPlayers,
  });

  @override
  State<CreatePlayersScreen> createState() => _CreatePlayersScreenState();
}

class _CreatePlayersScreenState extends State<CreatePlayersScreen> {
  late List<({String name, Key key})> playerNames;
  Set<int> invalidIndices = {};

  static int get minPlayers => AppSettings.instance.minPlayers;

  @override
  void initState() {
    super.initState();

    playerNames =
        widget.initialPlayers == null || widget.initialPlayers!.isEmpty
        ? List.generate(
            minPlayers,
            (index) => (name: '', key: UniqueKey()),
            growable: true,
          )
        : widget.initialPlayers!
              .map((name) => (name: name, key: UniqueKey()))
              .toList();
  }

  void updatePlayerName(int index, String name) {
    setState(() {
      playerNames[index] = (name: name, key: playerNames[index].key);
    });
  }

  void deletePlayer(int index) {
    setState(() {
      playerNames.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.screen_gameSetup_createPlayers_title),
      ),
      body: Padding(
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
                          playerNames.add((name: '', key: UniqueKey()));
                        });
                      },
                      label: Text(localizations.screen_createPlayers_addPlayer),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                itemCount: playerNames.length,
                itemBuilder: (context, index) => Padding(
                  key: playerNames[index].key,
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
                          initialText: playerNames[index].name,
                          isInvalid: invalidIndices.contains(index),
                          onNameChanged: (name) =>
                              updatePlayerName(index, name),
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
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                onPressed: validateNames() ? submit : null,
                label: Text(
                  localizations.screen_createPlayers_chooseRolesButtonLabel,
                ),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool validateNames() {
    final trimmedNames = playerNames
        .map((player) => player.name.trim())
        .toList();
    final invalid = <int>{};

    for (var i = 0; i < trimmedNames.length; i++) {
      if (trimmedNames[i].isEmpty) invalid.add(i);
    }

    final seen = <String>{};
    for (var i = 0; i < trimmedNames.length; i++) {
      final name = trimmedNames[i];
      if (name.isNotEmpty && seen.contains(name)) {
        invalid.add(i);
      } else {
        seen.add(name);
      }
    }

    setState(() {
      invalidIndices = invalid;
    });

    return trimmedNames.where((name) => name.isNotEmpty).toSet().length >=
        minPlayers;
  }

  void reorderPlayer(int oldIndex, int newIndex) {
    setState(() {
      final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = playerNames.removeAt(oldIndex);
      playerNames.insert(adjustedNewIndex, item);
    });
  }

  void submit() {
    final names = playerNames.map((player) => player.name.trim()).toIList();
    final database = Provider.of<AppDatabase>(context, listen: false);
    database.playerNamesDao.addNameSuggestions(names);
    widget.onSubmit(names);
  }
}

class PlayerNameInput extends StatefulWidget {
  final String initialText;
  final int idx;
  final void Function(String) onNameChanged;
  final VoidCallback? onDelete;
  final bool isInvalid;

  const PlayerNameInput({
    required this.idx,
    required this.initialText,
    required this.onNameChanged,
    super.key,
    this.isInvalid = false,
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
      setState(() {
        _touched = _touched || _focusNode.hasFocus;
      });
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
    final localizations = AppLocalizations.of(context);

    return Autocomplete<String>(
      focusNode: _focusNode,
      textEditingController: _controller,
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final appDatabase = Provider.of<AppDatabase>(context, listen: false);
        return appDatabase.playerNamesDao
            .getAllNameSuggestionsStartingWith(textEditingValue.text)
            .get()
            .then(
              (names) => names.where((name) => name != textEditingValue.text),
            );
      },
      onSelected: (option) {
        _controller.text = option;
        widget.onNameChanged(option);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) =>
              TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: localizations
                      .screen_createPlayers_playerNumberInputLabel(
                        number: widget.idx + 1,
                      ),
                  errorText:
                      (_touched && !_focusNode.hasFocus && widget.isInvalid)
                      ? localizations
                            .screen_createPlayers_error_invalidOrDuplicateName
                      : null,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onDelete,
                    disabledColor: Theme.of(context).disabledColor,
                  ),
                ),
                onChanged: widget.onNameChanged,
              ),
      optionsViewBuilder: (context, onSelected, options) => Material(
        elevation: 4,
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options.elementAt(index);
            return ListTile(
              title: Text(option),
              onTap: () => onSelected(option),
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      localizations
                          .screen_createPlayers_deleteNameFromCacheTitle,
                    ),
                    content: Text(
                      localizations
                          .screen_createPlayers_deleteNameFromCacheContent(
                            name: option,
                          ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.button_noLabel),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<AppDatabase>(
                            context,
                            listen: false,
                          ).playerNamesDao.disableNameSuggestion(option);
                          Navigator.of(context).pop();
                        },
                        child: Text(localizations.button_yesLabel),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
