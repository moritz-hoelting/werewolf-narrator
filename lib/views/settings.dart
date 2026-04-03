import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart' show AppDatabase;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/localization.dart';
import 'package:werewolf_narrator/util/settings.dart';
import 'package:werewolf_narrator/views/settings/developer_settings.dart';
import 'package:werewolf_narrator/widgets/settings/info_display.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.screen_settings_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Consumer<AppSettings>(
              builder: (context, settings, child) =>
                  SettingsDisplay(settings: settings),
            ),
            if (Provider.of<DeveloperSettings>(context).enabled)
              ListTile(
                title: const Text("Developer Settings"),
                leading: const Icon(Icons.developer_board),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeveloperSettingsScreen(),
                  ),
                ),
              ),

            Divider(height: 32),
            const AppInfoDisplay(),
          ],
        ),
      ),
    );
  }
}

class SettingsDisplay extends StatelessWidget {
  const SettingsDisplay({super.key, required this.settings});

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
        ListTile(
          title: Text(localizations.screen_settings_manageNameCache),
          leading: const Icon(Icons.storage),
          trailing: IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: localizations.screen_settings_clearNameCache,
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                final materialLocalizations = MaterialLocalizations.of(context);
                return AlertDialog(
                  title: Text(localizations.screen_settings_clearNameCache),
                  content: Text(
                    localizations.screen_settings_clearNameCache_description,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(materialLocalizations.cancelButtonLabel),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<AppDatabase>(
                          context,
                          listen: false,
                        ).nameCacheDao.emptyCache();
                        Navigator.pop(context);
                      },
                      child: Text(materialLocalizations.okButtonLabel),
                    ),
                  ],
                );
              },
            ),
          ),
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(localizations.screen_settings_manageNameCache),
              content: StreamBuilder(
                stream: Provider.of<AppDatabase>(
                  context,
                  listen: false,
                ).nameCacheDao.watchAllNames(),
                builder: (context, cachedNames) {
                  if (cachedNames.hasError) {
                    return Text('Error: ${cachedNames.error}');
                  }
                  if (!cachedNames.hasData) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 100),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final names = cachedNames.data!.sorted();
                  if (names.isEmpty) {
                    return const Icon(
                      Icons.no_accounts,
                      size: 64,
                      color: Colors.grey,
                    );
                  }
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width * 0.6).clamp(
                      0,
                      400,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: names.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(names[index]),
                        leading: IconButton(
                          onPressed: () => Provider.of<AppDatabase>(
                            context,
                            listen: false,
                          ).nameCacheDao.deleteNameFromCache(names[index]),
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
