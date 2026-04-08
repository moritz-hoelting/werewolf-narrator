import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class LeaveGameDialog extends StatelessWidget {
  const LeaveGameDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.exit_to_app),
      title: Text(localizations.alert_leaveGame_title),
      content: Text(localizations.alert_leaveGame_message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
