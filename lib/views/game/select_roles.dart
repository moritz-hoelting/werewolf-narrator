import 'package:flutter/material.dart';

class SelectRolesView extends StatefulWidget {
  final int playerCount;
  final VoidCallback onSubmit;

  const SelectRolesView({super.key, required this.playerCount, required this.onSubmit});

  @override
  State<SelectRolesView> createState() => _SelectRolesViewState();
}

class _SelectRolesViewState extends State<SelectRolesView> {
  @override
  Widget build(BuildContext context) {
    return Text('Select roles for ${widget.playerCount} players');
  }
}