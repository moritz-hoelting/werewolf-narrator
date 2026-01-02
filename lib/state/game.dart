import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/role.dart';

class GameState extends ChangeNotifier {

  
  final List<Role> _roles = [];
  List<Role> get roles => _roles;

  void addRole(Role role) {
    _roles.add(role);
    notifyListeners();
  }

  void removeRole(int index) {
    _roles.removeAt(index);
    notifyListeners();
  }
}