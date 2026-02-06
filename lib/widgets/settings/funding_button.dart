import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class FundingButton extends StatelessWidget {
  const FundingButton({super.key, required this.fundingUrls});

  final List<Uri> fundingUrls;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return TextButton.icon(
      onPressed: () {
        if (fundingUrls.length == 1) {
          launchUrl(fundingUrls.first);
        } else {
          showDialog(
            context: context,
            builder: (context) {
              final localizations = AppLocalizations.of(context);

              return AlertDialog(
                icon: const Icon(Icons.favorite, color: Colors.red, size: 48),
                title: Text(localizations.screen_settings_supportAuthor),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: fundingUrls
                        .map(
                          (url) => TextButton(
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () {
                              launchUrl(url);
                              Navigator.of(context).pop();
                            },
                            child: Text(url.toString()),
                          ),
                        )
                        .toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
      icon: const Icon(Icons.favorite, color: Colors.red),
      label: Text(localizations.screen_settings_supportAuthor),
    );
  }
}
