import 'package:collection/collection.dart'
    show groupBy, ListExtensions, IterableExtension;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/model/role.dart'
    show ChooseRolesCategory, RoleType, RoleManager;
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class RolesOverviewScreen extends StatelessWidget {
  const RolesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final IList<MapEntry<ChooseRolesCategory, List<RoleType>>>
    categorizedRoles =
        groupBy(
              RoleManager.registeredRoles,
              (role) => role.information.chooseRolesInformation.category,
            )
            .mapValue(
              (list) => list
                ..sortByCompare(
                  (role) => role.information.chooseRolesInformation.priority,
                  (a, b) => b.compareTo(a),
                ),
            )
            .entries
            .sortedByCompare(
              (entry) => entry.key.priority,
              (a, b) => b.compareTo(a),
            )
            .toIList();

    return Scaffold(
      appBar: AppBar(title: Text(localizations.screen_rolesOverview_title)),
      body: Container(
        padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        child: ListView.separated(
          itemCount: categorizedRoles.length,
          itemBuilder: (context, index) {
            final roles = categorizedRoles[index].value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    categorizedRoles[index].key.name(context),
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, index) => RoleCard(role: roles[index]),
                ),
              ],
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 32),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  const RoleCard({super.key, required this.role});

  final RoleType role;

  @override
  Widget build(BuildContext context) {
    final roleInformation = role.information;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              roleInformation.name(context),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => RoleInfoDialog(role: role),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleInfoDialog extends StatelessWidget {
  const RoleInfoDialog({super.key, required this.role});

  final RoleType role;

  @override
  Widget build(BuildContext context) {
    final roleInformation = role.information;

    return AlertDialog(
      title: Text(roleInformation.name(context)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(roleInformation.description(context)),
          if (roleInformation.options.isNotEmpty)
            RoleInfoSettings(options: roleInformation.options),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class RoleInfoSettings extends StatelessWidget {
  const RoleInfoSettings({super.key, required this.options});

  final IList<RoleOption> options;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          localizations.screen_rolesOverview_optionsHeading,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ...options.map(
          (option) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option.label(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                option.description(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
