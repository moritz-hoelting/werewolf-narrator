import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/misc/phases/sheriff.dart'
    show sheriffEnabledOption;
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/widgets/game/game_configuration.dart'
    show BoolOptionWidget, IntOptionWidget;

class ConfigureGameScreen extends StatefulWidget {
  final GameConfiguration? initialConfiguration;
  final ValueChanged<GameConfiguration> onSubmit;
  final ValueChanged<GameConfiguration> onBack;

  static final List<ConfigurationOption> configurationOptions = [
    sheriffEnabledOption,
  ];

  const ConfigureGameScreen({
    required this.initialConfiguration,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  @override
  State<ConfigureGameScreen> createState() => _ConfigureGameScreenState();
}

class _ConfigureGameScreenState extends State<ConfigureGameScreen> {
  late final Map<String, dynamic> _gameConfiguration;

  @override
  void initState() {
    super.initState();

    _gameConfiguration = widget.initialConfiguration?.unlockLazy ?? {};
  }

  void _submit() =>
      widget.onSubmit(fillDefaultGameConfiguration(_gameConfiguration));

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        widget.onBack(_gameConfiguration.lock);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.screen_configureGame_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.onBack(_gameConfiguration.lock),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16).copyWith(top: 0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: ConfigureGameScreen.configurationOptions
                      .map(
                        (option) => switch (option) {
                          IntOption() => IntOptionWidget(
                            option: option,
                            data: _gameConfiguration,
                          ),
                          BoolOption() => BoolOptionWidget(
                            option: option,
                            data: _gameConfiguration,
                          ),
                        },
                      )
                      .toList(),
                ),
              ),

              const Divider(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  label: Text(
                    localizations.screen_configureGame_chooseRolesButtonLabel,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
