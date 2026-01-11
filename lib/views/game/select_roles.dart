import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/role.dart';

class SelectRolesView extends StatefulWidget {
  final int playerCount;
  final Function(Map<Role, int>) onSubmit;

  const SelectRolesView({
    super.key,
    required this.playerCount,
    required this.onSubmit,
  });

  @override
  State<SelectRolesView> createState() => _SelectRolesViewState();
}

class _SelectRolesViewState extends State<SelectRolesView> {
  final Map<Role, int> selectedRoles = {};

  int get totalSelected =>
      selectedRoles.values.fold(0, (sum, count) => sum + count);
  bool canAdd(int amount) => (totalSelected + amount) <= widget.playerCount;

  void setCount(Role role, int count) {
    setState(() {
      if (count == 0) {
        selectedRoles.remove(role);
      } else {
        selectedRoles[role] = count;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int missingRoles = widget.playerCount - totalSelected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: Role.values
                  .map(
                    (role) => RoleSelectorCard(
                      role: role,
                      count: selectedRoles[role] ?? 0,
                      maxCount: role.isUnique
                          ? (role.isUnique && (selectedRoles[role] ?? 0) == 0
                                ? 1
                                : 0)
                          : missingRoles + (selectedRoles[role] ?? 0),
                      onChanged: (count) => setCount(role, count),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: totalSelected == widget.playerCount
                  ? () => widget.onSubmit(selectedRoles)
                  : null,
              label: const Text('Start Game!'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class RoleSelectorCard extends StatelessWidget {
  final Role role;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: count > 0 ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Role name
            Expanded(
              child: Text(
                role.name(context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Counter
            _Counter(value: count, maxValue: maxCount, setValue: onChanged),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int maxValue;
  final Function(int) setValue;

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
