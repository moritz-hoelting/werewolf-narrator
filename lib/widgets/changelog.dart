import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/changelog.dart';

class Changelog extends StatelessWidget {
  const Changelog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).screen_settings_changelog),
      ),
      body: const _ChangelogBody(),
    );
  }
}

class _ChangelogBody extends StatelessWidget {
  const _ChangelogBody();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadChangelog(),
      builder: (context, asyncChangelog) {
        final localizations = AppLocalizations.of(context);

        if (asyncChangelog.hasError) {
          return Center(
            child: Text(
              localizations.screen_settings_changelog_loadingError(
                error: asyncChangelog.error.toString(),
              ),
            ),
          );
        } else if (!asyncChangelog.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final markdownData = asyncChangelog.data!;
          return Markdown(
            data: markdownData,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
          );
        }
      },
    );
  }
}

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.screen_settings_changelog),
      content: const SizedBox(width: double.maxFinite, child: _ChangelogBody()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
