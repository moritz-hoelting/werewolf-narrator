import 'package:flutter/material.dart';
import 'package:graphs/graphs.dart';
import 'package:werewolf_narrator/state/game.dart';

typedef NightActionBuilder =
    WidgetBuilder? Function(GameState gameState, VoidCallback onComplete);

class NightActionManager {
  final List<NightActionRegistration> _registrations = [];

  List<NightActionEntry> _phases = [];

  bool _ordered = false;

  void registerAction(
    Object identifier,
    NightActionBuilder builder, {
    bool Function(GameState gameState)? conditioned,
    List<Object> after = const [],
    bool beforeAll = false,
  }) {
    assert(
      !_ordered,
      'Cannot register new actions after actions have been ordered.',
    );
    _registrations.add(
      NightActionRegistration(
        identifier,
        builder,
        conditioned:
            conditioned ?? (gameState) => builder(gameState, () {}) != null,
        after: after,
        beforeAll: beforeAll,
      ),
    );
  }

  void orderActions() {
    assert(!_ordered, 'Actions have already been ordered.');
    _ordered = true;

    final beforeAllActions = _registrations
        .where((reg) => reg.beforeAll)
        .toList();

    final order = topologicalSort(
      _registrations.where((reg) => !reg.beforeAll),
      (from) =>
          _registrations.where((to) => to.after.contains(from.identifier)),
      equals: (a, b) => a.identifier == b.identifier,
    );

    _phases = [...beforeAllActions, ...order]
        .map(
          (reg) => NightActionEntry(
            builder: reg.builder,
            conditioned: reg.conditioned,
          ),
        )
        .toList();
  }

  void ensureOrdered() {
    if (!_ordered) {
      orderActions();
    }
  }

  List<NightActionEntry> get nightActions {
    assert(_ordered, 'Actions must be ordered before accessing them.');
    return _phases;
  }
}

class NightActionRegistration {
  final Object identifier;

  final NightActionBuilder builder;
  final bool Function(GameState gameState) conditioned;

  final List<Object> after;
  final bool beforeAll;

  NightActionRegistration(
    this.identifier,
    this.builder, {
    required this.conditioned,
    required this.after,
    required this.beforeAll,
  });

  @override
  String toString() {
    return 'NightActionRegistration(identifier: $identifier, after: $after, beforeAll: $beforeAll)';
  }
}

class NightActionEntry {
  final NightActionBuilder builder;
  final bool Function(GameState gameState) conditioned;

  const NightActionEntry({required this.builder, required this.conditioned});
}
