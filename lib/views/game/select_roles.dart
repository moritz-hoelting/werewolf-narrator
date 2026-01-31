import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';

class SelectRolesView extends StatefulWidget {
  final int playerCount;
  final void Function(Map<RoleType, int>) onSubmit;

  const SelectRolesView({
    super.key,
    required this.playerCount,
    required this.onSubmit,
  });

  @override
  State<SelectRolesView> createState() => _SelectRolesViewState();
}

class _SelectRolesViewState extends State<SelectRolesView> {
  final Map<RoleType, int> _selectedRoles = {};

  int get totalSelected =>
      _selectedRoles.values.fold(0, (sum, count) => sum + count);
  bool canAdd(int amount) => (totalSelected + amount) <= widget.playerCount;

  void setCount(RoleType role, int count) {
    setState(() {
      if (count == 0) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles[role] = count;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final int missingRoles = widget.playerCount - totalSelected;
    final Set<RoleType> selectedRoleSet = _selectedRoles.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toSet();
    final Set<TeamType> selectedTeams = selectedRoleSet
        .map((role) => role.instance.initialTeam)
        .toSet();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children:
                  groupBy(
                        RoleManager.registeredRoles,
                        (role) => role.instance.initialTeam,
                      ).values.flattened
                      .map(
                        (role) => RoleSelectorCard(
                          role: role,
                          count: _selectedRoles[role] ?? 0,
                          maxCount: role.instance.isUnique
                              ? ((_selectedRoles[role] ?? 0) == 0
                                    ? min(1, missingRoles)
                                    : 0)
                              : missingRoles + (_selectedRoles[role] ?? 0),
                          onChanged: (count) => setCount(role, count),
                        ),
                      )
                      .toList(),
            ),
          ),

          const Divider(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed:
                  totalSelected == widget.playerCount &&
                      selectedTeams.length >= 2
                  ? _submit
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(localizations.screen_selectRoles_startButton),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submit() {
    final modifiedRoles = Map<RoleType, int>.from(_selectedRoles);

    for (final role in modifiedRoles.keys) {
      final adjuster = RoleManager.getRoleCountAdjuster(role);
      if (adjuster != null) {
        adjuster(modifiedRoles, widget.playerCount);
      }
    }

    widget.onSubmit(modifiedRoles);
  }
}

class RoleSelectorCard extends StatefulWidget {
  final RoleType role;
  final int count;
  final int maxCount;
  final ValueChanged<int> onChanged;

  const RoleSelectorCard({
    super.key,
    required this.role,
    required this.count,
    required this.maxCount,
    required this.onChanged,
  });

  @override
  State<RoleSelectorCard> createState() => _RoleSelectorCardState();
}

class _RoleSelectorCardState extends State<RoleSelectorCard> {
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.role.instance;
    final description = role.description(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.count > 0
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Role name and description
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _descriptionExpanded = !_descriptionExpanded;
                          });
                        },
                        icon: Icon(
                          _descriptionExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ),
                      Text(
                        role.name(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Counter
                _Counter(
                  value: widget.count,
                  maxValue: widget.maxCount,
                  setValue: widget.onChanged,
                ),
              ],
            ),
            if (_descriptionExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(description, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int maxValue;
  final void Function(int) setValue;

  const _Counter({
    required this.value,
    required this.maxValue,
    required this.setValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 0 ? () => setValue(value - 1) : null,
          onLongPress: value > 0
              ? () {
                  setValue(0);
                }
              : null,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < maxValue ? () => setValue(value + 1) : null,
          onLongPress: value < maxValue
              ? () {
                  setValue(maxValue);
                }
              : null,
        ),
      ],
    );
  }
}
