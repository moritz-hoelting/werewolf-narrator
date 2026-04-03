import 'package:flutter/material.dart';
import 'package:werewolf_narrator/widgets/game/redo_button.dart';
import 'package:werewolf_narrator/widgets/game/undo_button.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GameAppBar({
    required this.title,
    super.key,
    this.leading,
    this.backgroundColor,
    this.automaticallyImplyLeading = false,
  });

  final Widget title;

  final Widget? leading;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    backgroundColor: backgroundColor,
    actions: [const UndoButton(), const RedoButton()],
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
