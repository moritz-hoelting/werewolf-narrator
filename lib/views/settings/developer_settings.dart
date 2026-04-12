import 'dart:async' show unawaited;

import 'package:drift_db_viewer/drift_db_viewer.dart' show DriftDbViewer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:werewolf_narrator/database/database.dart'
    show AppDatabase, AppDatabaseHolder;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/pubspec_info.g.dart';
import 'package:werewolf_narrator/util/consts.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/localization.dart';
import 'package:werewolf_narrator/util/settings.dart';

// At this point of time there is no incentive to add localization to developer
// settings, as they are not intended to be used by regular users.
class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Developer Settings')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<DeveloperSettings>(
        builder: (context, developerSettings, child) => ListView(
          children: [
            CheckboxListTile(
              title: const Text('Enabled'),
              subtitle: const Text(
                'Uncheck to disable (and hide) developer settings',
              ),
              value: developerSettings.enabled,
              onChanged: (value) {
                if (value != null) {
                  developerSettings.enabled = value;
                }
              },
            ),

            const ListTile(
              title: Text('Git Hash: $gitHash'),
              subtitle: Text('Build Date: $buildDate'),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new),
                tooltip: 'View commit in repository',
                onPressed:
                    PubspecInfo.repositoryUrl != null && gitHash != 'unknown'
                    ? _openGitCommit
                    : null,
              ),
            ),

            CheckboxListTile(
              title: const Text('Autofill default player names'),
              subtitle: const Text(
                'Players are named sequentially instead of being left blank',
              ),
              value: developerSettings.fillPlayerNames,
              onChanged: (value) {
                if (value != null) {
                  developerSettings.fillPlayerNames = value;
                }
              },
            ),

            CheckboxListTile(
              title: const Text('Autofill villager roles'),
              subtitle: const Text(
                'Remaining unassigned roles in the role distribution are filled with villager roles',
              ),
              value: developerSettings.fillVillagerRoles,
              onChanged: (value) {
                if (value != null) {
                  developerSettings.fillVillagerRoles = value;
                }
              },
            ),

            ListTile(
              title: const Text('View Database'),
              subtitle: FutureBuilder(
                future: AppDatabaseHolder.databaseLocation(),
                builder: (context, databaseLocation) => Text(
                  'Database file location: ${databaseLocation.data ?? "..."}',
                ),
              ),
              onTap: () {
                final db = Provider.of<AppDatabase>(context, listen: false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DriftDbViewer(db)),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Delete database',
                onPressed: () async {
                  final answer = await showDialog<bool>(
                    useRootNavigator: false,
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      icon: const Icon(Icons.delete),
                      title: const Text('Delete Database'),
                      content: const Text(
                        'Do you really want to delete the entire database? This cannot be undone!',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            MaterialLocalizations.of(context).cancelButtonLabel,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            MaterialLocalizations.of(context).okButtonLabel,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (answer == true && context.mounted) {
                    unawaited(
                      Provider.of<AppDatabaseHolder>(
                        context,
                        listen: false,
                      ).recreateDatabase(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openGitCommit() {
  final url =
      "${PubspecInfo.repositoryUrl!}${PubspecInfo.repositoryUrl!.endsWith('/') ? '' : '/'}tree/$gitHash";
  launchUrl(Uri.parse(url));
}

class SettingsDisplay extends StatelessWidget {
  const SettingsDisplay({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(localizations.screen_settings_themeMode),
          leading: const Icon(Icons.color_lens),
          trailing: DropdownButton<ThemeMode>(
            padding: const EdgeInsets.all(4),
            value: settings.themeMode,
            items: ThemeMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(switch (mode) {
                          ThemeMode.light => Icons.light_mode,
                          ThemeMode.dark => Icons.dark_mode,
                          ThemeMode.system => Icons.settings,
                        }),
                        const SizedBox(width: 8),
                        Text(switch (mode) {
                          ThemeMode.light =>
                            localizations.screen_settings_themeMode_light,
                          ThemeMode.dark =>
                            localizations.screen_settings_themeMode_dark,
                          ThemeMode.system =>
                            localizations.screen_settings_themeMode_system,
                        }),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (newMode) {
              if (newMode != null) {
                settings.themeMode = newMode;
              }
            },
          ),
        ),
        CheckboxListTile(
          title: Text(localizations.screen_settings_dynamicGameTheme),
          secondary: const Icon(Icons.brightness_auto),
          subtitle: Text(
            localizations.screen_settings_dynamicGameTheme_description,
          ),
          value: settings.dynamicGameTheme,
          onChanged: (value) {
            if (value != null) {
              settings.dynamicGameTheme = value;
            }
          },
        ),
        ListTile(
          title: Text(localizations.screen_settings_language),
          leading: const Icon(Icons.language),
          trailing: DropdownButton<Locale?>(
            padding: const EdgeInsets.all(4),
            value: settings.locale,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(localizations.screen_settings_language_default),
              ),
              ...AppLocalizations.supportedLocales.map(
                (locale) => DropdownMenuItem<Locale?>(
                  value: locale,
                  child: Text(locale.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              settings.locale = value;
            },
          ),
        ),
      ],
    );
  }
}
