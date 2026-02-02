import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/pubspec_info.g.dart';
import 'package:werewolf_narrator/views/settings/funding_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.screen_settings_title)),
      body: FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final packageInfo = snapshot.data!;
            final localizations = AppLocalizations.of(context);
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appTitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    localizations.screen_settings_version(
                      version: packageInfo.version,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  if (PubspecInfo.authorName != null)
                    Text(
                      localizations.screen_settings_madeBy(
                        author: PubspecInfo.authorName!,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                  const SizedBox(height: 24),

                  if (PubspecInfo.repositoryUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse(PubspecInfo.repositoryUrl!));
                      },
                      icon: const Icon(Icons.code),
                      label: Text(localizations.screen_settings_viewRepository),
                    ),

                  if (PubspecInfo.fundingUrls != null &&
                      PubspecInfo.fundingUrls!.isNotEmpty)
                    FundingButton(
                      fundingUrls: PubspecInfo.fundingUrls!
                          .map(Uri.parse)
                          .toList(),
                    ),

                  if (PubspecInfo.issueTrackerUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse(PubspecInfo.issueTrackerUrl!));
                      },
                      icon: const Icon(Icons.bug_report),
                      label: Text(localizations.screen_settings_reportIssue),
                    ),

                  if (PubspecInfo.authorEmail != null)
                    TextButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse('mailto:${PubspecInfo.authorEmail}'),
                        );
                      },
                      icon: const Icon(Icons.email),
                      label: Text(localizations.screen_settings_contactAuthor),
                    ),

                  TextButton.icon(
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationIcon: SvgPicture.asset(
                          'assets/icon/icon.svg',
                          width: 64,
                          height: 64,
                        ),
                        applicationName: localizations.appTitle,
                        applicationVersion: packageInfo.version,
                        children: [
                          const SizedBox(height: 8),
                          if (PubspecInfo.authorName != null)
                            Text(
                              localizations.screen_settings_madeBy(
                                author: PubspecInfo.authorName!,
                              ),
                            ),
                        ],
                      );
                    },
                    label: Text(localizations.screen_settings_about),
                    icon: const Icon(Icons.info),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
