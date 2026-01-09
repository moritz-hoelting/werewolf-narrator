import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/role.dart';

class GameState extends ChangeNotifier {
  final List<String> _players;

  final Map<Role, int> _roles;

  GameState({required List<String> players, required Map<Role, int> roles})
    : _players = players,
      _roles = roles;

  List<String> get players => _players;
  Map<Role, int> get roles => _roles;

  bool get isNight => false;
}
