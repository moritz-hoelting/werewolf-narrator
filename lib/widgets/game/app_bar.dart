import 'package:flutter/material.dart';
import 'package:werewolf_narrator/widgets/game/redo_button.dart';
import 'package:werewolf_narrator/widgets/game/undo_button.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GameAppBar({
    super.key,
    required this.title,
    this.leading,
    this.backgroundColor,
  });

  final Widget title;

  final Widget? leading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      automaticallyImplyLeading: false,
      leading: leading,
      backgroundColor: backgroundColor,
      actions: [UndoButton(), RedoButton()],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
