import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/role.dart';

class Player {
  final String name;
  Role? role;
  DeathInformation? _deathInformation;
  bool usedDeathAction = false;
  bool deathAnnounced = false;

  Player({required this.name, this.role, DeathInformation? deathInformation})
    : _deathInformation = deathInformation;

  DeathInformation? get deathInformation => _deathInformation;
  bool get isAlive => _deathInformation == null;
  bool get waitForDeathAction {
    if (isAlive || usedDeathAction || role == null) {
      return false;
    }
    return role!.hasDeathScreen;
  }

  void markDead(DeathInformation deathInfo) {
    _deathInformation = deathInfo;
  }

  void revive() {
    _deathInformation = null;
  }

  @override
  String toString() {
    return 'Player(name: $name, role: $role, isAlive: $isAlive)';
  }
}
