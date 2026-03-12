import 'package:flutter/material.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart'
    show BottomContinueButton;

class BinarySelectionScreen extends StatefulWidget {
  final Widget appBarTitle;
  final Widget? instruction;
  final Widget firstOption;
  final Widget secondOption;
  final void Function(bool? selectedFirst) onComplete;

  final bool allowSelectNone;

  const BinarySelectionScreen({
    super.key,
    required this.appBarTitle,
    required this.firstOption,
    required this.secondOption,
    required this.onComplete,
    this.instruction,
    this.allowSelectNone = false,
  });

  @override
  State<BinarySelectionScreen> createState() => _BinarySelectionScreenState();
}

class _BinarySelectionScreenState extends State<BinarySelectionScreen> {
  bool? _selectedFirst;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.appBarTitle,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.instruction != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.instruction,
                ),
                const SizedBox(height: 20),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_selectedFirst == true) {
                      _selectedFirst = null;
                    } else {
                      _selectedFirst = true;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 150),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  backgroundColor: _selectedFirst == true
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5)
                      : null,
                  elevation: 4,
                ),
                child: widget.firstOption,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_selectedFirst == false) {
                      _selectedFirst = null;
                    } else {
                      _selectedFirst = false;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 150),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  backgroundColor: _selectedFirst == false
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5)
                      : null,
                  elevation: 4,
                ),
                child: widget.secondOption,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomContinueButton(
        onPressed: _selectedFirst == null && !widget.allowSelectNone
            ? null
            : () {
                widget.onComplete(_selectedFirst);
              },
      ),
    );
  }
}
