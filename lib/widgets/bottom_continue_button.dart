import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class BottomContinueButton extends StatelessWidget {
  const BottomContinueButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
        onPressed: onPressed,
        label: Text(localizations.button_continueLabel),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
