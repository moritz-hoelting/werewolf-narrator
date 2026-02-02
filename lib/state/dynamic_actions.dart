import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:graphs/graphs.dart';
import 'package:werewolf_narrator/state/game.dart';

typedef DynamicActionBuilder =
    WidgetBuilder? Function(GameState gameState, VoidCallback onComplete);

class DynamicActionManager {
  final List<DynamicActionRegistration> _registrations = [];

  List<DynamicActionEntry> _actions = [];

  bool _ordered = true;

  /// Registers an action with the given configuration and constraints.
  void registerAction(
    Object identifier,
    DynamicActionBuilder builder, {
    bool Function(GameState gameState)? conditioned,
    List<Object> before = const [],
    List<Object> after = const [],
    bool beforeAll = false,
    bool afterAll = false,
  }) {
    _ordered = false;
    _registrations.add(
      DynamicActionRegistration(
        identifier,
        builder,
        conditioned:
            conditioned ?? (gameState) => builder(gameState, () {}) != null,
        before: before,
        after: after,
        beforeAll: beforeAll,
        afterAll: afterAll,
      ),
    );
  }

  /// Unregisters the action with the given identifier.
  void unregisterAction(Object identifier) {
    _ordered = false;
    _registrations.removeWhere((reg) => reg.identifier == identifier);
  }

  /// Orders the registered actions based on their constraints.
  void orderActions() {
    if (_ordered) return;
    _ordered = true;

    final beforeAllActions = _registrations
        .where((reg) => reg.beforeAll)
        .toList();
    final afterAllActions = _registrations
        .where((reg) => reg.afterAll)
        .toList();

    final unorderedRegistrations = _registrations.where(
      (reg) => !reg.beforeAll && !reg.afterAll,
    );

    late final List<DynamicActionRegistration> order;

    try {
      order = topologicalSort(
        unorderedRegistrations,
        (from) => [
          ..._registrations.where((to) => to.after.contains(from.identifier)),
          ..._registrations.where((to) => from.before.contains(to.identifier)),
        ],
        equals: (a, b) => a.identifier == b.identifier,
      );
    } on CycleException catch (e) {
      log('Cycle detected in dynamic action ordering: $e');
      order = unorderedRegistrations.toList();
    }

    _actions = [...beforeAllActions, ...order, ...afterAllActions]
        .map(
          (reg) => DynamicActionEntry(
            identifier: reg.identifier,
            builder: reg.builder,
            conditioned: reg.conditioned,
          ),
        )
        .toList();
  }

  /// The ordered list of night actions.
  List<DynamicActionEntry> get orderedActions {
    if (!_ordered) {
      orderActions();
    }
    return _actions;
  }
}

class DynamicActionRegistration {
  /// The unique identifier for this dynamic action.
  final Object identifier;

  /// The builder function for this action screen.
  final DynamicActionBuilder builder;

  /// The condition under which this action is shown.
  final bool Function(GameState gameState) conditioned;

  /// The list of identifiers that this action must come before.
  final List<Object> before;

  /// The list of identifiers that this action must come after.
  final List<Object> after;

  /// Whether this action should come before all others.
  final bool beforeAll;

  /// Whether this action should come after all others.
  final bool afterAll;

  DynamicActionRegistration(
    this.identifier,
    this.builder, {
    required this.conditioned,
    required this.before,
    required this.after,
    required this.beforeAll,
    required this.afterAll,
  });

  @override
  String toString() {
    return 'DynamicActionRegistration(identifier: $identifier, before: $before, after: $after, beforeAll: $beforeAll, afterAll: $afterAll)';
  }
}

class DynamicActionEntry {
  /// The unique identifier for this dynamic action.
  final Object identifier;

  /// The builder function for this dynamic action screen.
  final DynamicActionBuilder builder;

  /// The condition under which this dynamic action is shown.
  final bool Function(GameState gameState) conditioned;

  const DynamicActionEntry({
    required this.identifier,
    required this.builder,
    required this.conditioned,
  });
}
