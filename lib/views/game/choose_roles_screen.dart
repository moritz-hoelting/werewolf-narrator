import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/developer_settings.dart'
    show DeveloperSettings;
import 'package:werewolf_narrator/widgets/game/game_configuration.dart'
    show RoleOptionsDialog;

class ChooseRolesScreen extends StatefulWidget {
  final IMap<RoleType, ({Map<String, dynamic> config, int count})>?
  initialRoles;
  final int playerCount;
  final ValueChanged<IMap<RoleType, ({int count, RoleConfiguration config})>>
  onSubmit;
  final ValueChanged<IMap<RoleType, ({int count, RoleConfiguration config})>>
  onBack;

  const ChooseRolesScreen({
    required this.initialRoles,
    required this.playerCount,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  @override
  State<ChooseRolesScreen> createState() => _ChooseRolesScreenState();
}

class _ChooseRolesScreenState extends State<ChooseRolesScreen> {
  late final ValueNotifier<Map<RoleType, ({int index, int count})>> _roles;

  late final Map<RoleType, RoleConfiguration> _roleConfigurations;

  final IList<({ChooseRolesCategory category, IList<RoleType> roles})>
  categorizedRoles = RoleManager.categorizedRoles;

  @override
  void initState() {
    super.initState();

    _roles = ValueNotifier(
      widget.initialRoles != null && widget.initialRoles!.isNotEmpty
          ? Map.fromEntries(
              widget.initialRoles!.mapTo(
                (key, value) => MapEntry(key, (
                  count: value.count,
                  index: value.count == 0
                      ? -1
                      : key.information.validRoleCounts.indexed
                            .firstWhere((v) => v.$2 == value.count)
                            .$1,
                )),
              ),
            )
          : {},
    );

    _roleConfigurations =
        widget.initialRoles != null && widget.initialRoles!.isNotEmpty
        ? Map.fromEntries(
            widget.initialRoles!.mapTo(
              (key, value) => MapEntry(key, {...value.config}),
            ),
          )
        : {};
  }

  int _totalSelected(Map<RoleType, ({int index, int count})> roles) =>
      roles.values.fold(0, (sum, e) => sum + e.count);

  void _setCount(RoleType role, int index, int count) {
    final current = Map<RoleType, ({int index, int count})>.from(_roles.value);

    if (count == 0) {
      current.remove(role);
    } else {
      current[role] = (index: index, count: count);
    }

    _roles.value = current;
  }

  RoleConfiguration _roleConfiguration(RoleType role) =>
      _roleConfigurations[role] ?? {};

  IMap<RoleType, ({Map<String, dynamic> config, int count})> _getFinalRoles(
    Map<RoleType, ({int index, int count})> roles,
  ) {
    final modified =
        Map<RoleType, ({int count, RoleConfiguration config})>.from(
          roles.map(
            (role, value) => MapEntry(role, (
              count: value.count,
              config: _roleConfiguration(role),
            )),
          ),
        );

    for (final role in roles.keys) {
      role.information.roleCountAdjuster?.call(modified, widget.playerCount);
    }

    return modified.lock;
  }

  void _submit(Map<RoleType, ({int index, int count})> roles) {
    final missingRoles = widget.playerCount - _totalSelected(roles);
    if (missingRoles > 0) {
      final villagerCount = roles[VillagerRole.type]?.count ?? 0;
      final newVillagerCount = villagerCount + missingRoles;
      roles[VillagerRole.type] = (
        index: newVillagerCount - 1,
        count: newVillagerCount,
      );
    }

    widget.onSubmit(_getFinalRoles(roles));
  }

  int findMaxCountIndexOfRole(RoleType role, int upperLimit) {
    final validRoleCounts = role.information.validRoleCounts;
    final indexList = validRoleCounts.take(upperLimit + 1).toList();
    final lb = lowerBound(indexList, upperLimit);
    if (indexList.length >= lb + 1 && indexList[lb] == upperLimit) return lb;
    if (lb == 0) return -1;
    return lb - 1;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        widget.onBack(_getFinalRoles(_roles.value));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.screen_gameSetup_chooseRoles_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.onBack(_getFinalRoles(_roles.value)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16).copyWith(top: 0),
          child: ValueListenableBuilder<Map<RoleType, ({int index, int count})>>(
            valueListenable: _roles,
            builder: (context, roles, _) {
              final totalSelected = _totalSelected(roles);
              final missingRoles = widget.playerCount - totalSelected;

              final selectedTeams = roles.entries
                  .where((e) => e.value.count > 0)
                  .map((e) => e.key.information.initialTeam)
                  .toSet();

              final devSettings = Provider.of<DeveloperSettings>(
                context,
                listen: false,
              );

              final canSubmit = devSettings.fillVillagerRolesEnabled
                  ? selectedTeams.difference({VillageTeam.type}).isNotEmpty
                  : totalSelected == widget.playerCount &&
                        selectedTeams.length >= 2;

              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        for (final (:category, roles: categoryRoles)
                            in categorizedRoles) ...[
                          /// Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                category.name(context),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                            ),
                          ),

                          /// Grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final role = categoryRoles[index];
                                final selected = roles[role];

                                final count = selected?.count ?? 0;
                                final idx = selected?.index ?? -1;

                                final maxCountIndex = findMaxCountIndexOfRole(
                                  role,
                                  missingRoles + count,
                                );

                                return RoleSelectorCard(
                                  role: role,
                                  count: count,
                                  countIndex: idx,
                                  maxCountIndex: maxCountIndex,
                                  configuration: _roleConfiguration(role),
                                  setCount: (i, c) => _setCount(role, i, c),
                                  setConfiguration: (config) {
                                    _roleConfigurations[role] = config;
                                  },
                                );
                              }, childCount: categoryRoles.length),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 1,
                                  ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      label: Text(localizations.screen_chooseRoles_startButton),
                      icon: const Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                      ),
                      onPressed: canSubmit ? () => _submit(roles) : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class RoleSelectorCard extends StatelessWidget {
  final RoleType role;
  final int count;
  final int countIndex;
  final int maxCountIndex;
  final RoleConfiguration configuration;
  final void Function(int index, int count) setCount;
  final void Function(RoleConfiguration configuration) setConfiguration;

  const RoleSelectorCard({
    required this.role,
    required this.count,
    required this.countIndex,
    required this.maxCountIndex,
    required this.setCount,
    required this.configuration,
    required this.setConfiguration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleInformation = role.information;

    final maxCount = maxCountIndex == -1
        ? 0
        : roleInformation.validRoleCounts.elementAt(maxCountIndex);
    final validCounts = roleInformation.validRoleCounts.take(maxCountIndex + 1);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            roleInformation.name(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          _Counter(
            value: count,
            valueIndex: countIndex,
            validCounts: validCounts,
            maxValue: maxCount,
            setValue: setCount,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => RoleInfoDialog(role: role),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: roleInformation.options.isNotEmpty
                    ? () => showDialog(
                        context: context,
                        builder: (_) => RoleOptionsDialog(
                          role: role,
                          configuration: configuration,
                          setConfiguration: setConfiguration,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int valueIndex;
  final int maxValue;
  final Iterable<int> validCounts;
  final void Function(int index, int value) setValue;

  const _Counter({
    required this.value,
    required this.valueIndex,
    required this.validCounts,
    required this.maxValue,
    required this.setValue,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.remove),
        onPressed: value > 0
            ? () => setValue(
                valueIndex - 1,
                valueIndex == 0 ? 0 : validCounts.elementAt(valueIndex - 1),
              )
            : null,
        onLongPress: value > 0 ? () => setValue(-1, 0) : null,
      ),

      Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),

      IconButton(
        icon: const Icon(Icons.add),
        onPressed: value < maxValue
            ? () => setValue(
                valueIndex + 1,
                validCounts.elementAt(valueIndex + 1),
              )
            : null,
        onLongPress: value < maxValue
            ? () => setValue(validCounts.length - 1, maxValue)
            : null,
      ),
    ],
  );
}

class RoleInfoDialog extends StatelessWidget {
  const RoleInfoDialog({required this.role, super.key});

  final RoleType role;

  @override
  Widget build(BuildContext context) {
    final roleInformation = role.information;

    return AlertDialog(
      title: Text(roleInformation.name(context)),
      content: Text(roleInformation.description(context)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
