import 'package:deepcopy/deepcopy.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';

class RoleOptionsDialog extends StatefulWidget {
  const RoleOptionsDialog({
    super.key,
    required this.role,
    required this.configuration,
    required this.setConfiguration,
  });

  final RoleType role;
  final RoleConfiguration configuration;
  final void Function(RoleConfiguration configuration) setConfiguration;

  @override
  State<RoleOptionsDialog> createState() => _RoleOptionsDialogState();
}

class _RoleOptionsDialogState extends State<RoleOptionsDialog> {
  late final RoleConfiguration data = Map<String, dynamic>.from(
    widget.configuration.deepcopy(),
  );

  @override
  Widget build(BuildContext context) {
    final roleInformation = widget.role.information;
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 8),
          Text(roleInformation.name(context)),
        ],
      ),
      content: SizedBox(
        height: size.height * 0.6,
        width: size.width * 0.8,
        child: ListView(
          shrinkWrap: true,
          children: roleInformation.options.map((option) {
            return switch (option) {
              IntOption() => IntOptionWidget(option: option, data: data),
              BoolOption() => BoolOptionWidget(option: option, data: data),
            };
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () {
            widget.setConfiguration(data);
            Navigator.of(context).pop();
          },
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}

class IntOptionWidget extends StatefulWidget {
  const IntOptionWidget({super.key, required this.option, required this.data});

  final IntOption option;
  final RoleConfiguration data;

  @override
  State<IntOptionWidget> createState() => _IntOptionWidgetState();
}

class _IntOptionWidgetState extends State<IntOptionWidget> {
  late int currentValue =
      widget.data[widget.option.id] ?? widget.option.defaultValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.option.label(context)),
      subtitle: Text(widget.option.description(context)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed:
                widget.option.min == null || currentValue > widget.option.min!
                ? () {
                    final int newValue = currentValue - 1;
                    widget.data[widget.option.id] = newValue;
                    setState(() => currentValue = newValue);
                  }
                : null,
          ),
          Text('$currentValue'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                widget.option.max == null || currentValue < widget.option.max!
                ? () {
                    final int newValue = currentValue + 1;
                    widget.data[widget.option.id] = newValue;
                    setState(() => currentValue = newValue);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class BoolOptionWidget extends StatefulWidget {
  const BoolOptionWidget({super.key, required this.option, required this.data});

  final BoolOption option;
  final RoleConfiguration data;

  @override
  State<BoolOptionWidget> createState() => _BoolOptionWidgetState();
}

class _BoolOptionWidgetState extends State<BoolOptionWidget> {
  late bool checked =
      widget.data[widget.option.id] ?? widget.option.defaultValue;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.option.label(context)),
      subtitle: Text(widget.option.description(context)),
      value: checked,
      onChanged: (value) {
        if (value != null) {
          widget.data[widget.option.id] = value;
          setState(() => checked = value);
        }
      },
    );
  }
}
