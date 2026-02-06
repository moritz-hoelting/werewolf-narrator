import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/localization.dart';
import 'package:werewolf_narrator/util/settings.dart';
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
      ],
    );
  }
}
