import 'package:flutter/material.dart';

class NumberPickerDialog extends StatefulWidget {
  const NumberPickerDialog({
    required this.title,
    required this.initialValue,
    this.minValue,
    this.maxValue,
    super.key,
  });

  final Widget title;
  final int initialValue;

  final int? minValue;
  final int? maxValue;

  @override
  State<NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<NumberPickerDialog> {
  late int _currentValue = widget.initialValue;

  late final _controller = TextEditingController(
    text: widget.initialValue.toString(),
  );
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _increase() {
    setState(() => _currentValue++);
    _controller.text = _currentValue.toString();
  }

  void _decrease() {
    setState(() => _currentValue--);
    _controller.text = _currentValue.toString();
  }

  void _onTextFinished() {
    final intValue = int.tryParse(_controller.text);
    if (intValue != null &&
        (widget.minValue == null || intValue >= widget.minValue!) &&
        (widget.maxValue == null || intValue <= widget.maxValue!)) {
      setState(() => _currentValue = intValue);
    } else {
      _controller.text = _currentValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed:
                widget.minValue != null && _currentValue <= widget.minValue!
                ? null
                : _decrease,
          ),
          // Text(
          //   _currentValue.toString(),
          //   style: Theme.of(context).textTheme.headlineMedium,
          // ),
          IntrinsicWidth(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              selectAllOnFocus: true,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: false,
                signed: widget.minValue == null || widget.minValue! < 0,
              ),
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(border: InputBorder.none),
              onEditingComplete: _onTextFinished,
              onTapOutside: (_) {
                _focusNode.unfocus();
                _onTextFinished();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                widget.maxValue != null && _currentValue >= widget.maxValue!
                ? null
                : _increase,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _currentValue),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
