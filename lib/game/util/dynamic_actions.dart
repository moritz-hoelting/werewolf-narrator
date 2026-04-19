import 'dart:developer';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:graphs/graphs.dart';
import 'package:werewolf_narrator/game/game_state.dart';

typedef DynamicActionBuilder =
    WidgetBuilder? Function(GameState gameState, VoidCallback onComplete);

class DynamicActionManager {
  final List<DynamicActionRegistration> _registrations = [];

  List<DynamicActionEntry> _actions = [];

  bool _ordered = true;

  /// Registers an action with the given configuration and constraints.
  void registerAction(
    DynamicActionIdentifier identifier,
    DynamicActionBuilder builder, {
    required Set<int> players,
    bool Function(GameState gameState)? conditioned,
    ISet<DynamicActionIdentifier> before = const ISet.empty(),
    ISet<DynamicActionIdentifier> after = const ISet.empty(),
    bool beforeAll = false,
    bool afterAll = false,
  }) {
    _ordered = false;
    _registrations.add(
      DynamicActionRegistration(
        DynamicActionEntry(
          identifier: identifier,
          builder: builder,
          conditioned:
              conditioned ?? (gameState) => builder(gameState, () {}) != null,
          players: players,
        ),
        before: before,
        after: after,
        beforeAll: beforeAll,
        afterAll: afterAll,
      ),
    );
  }

  /// Unregisters the action with the given identifier.
  void unregisterAction(DynamicActionIdentifier identifier) {
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
        (from) => {
          ..._registrations.where((to) => to.after.contains(from.identifier)),
          ..._registrations.where((to) => from.before.contains(to.identifier)),
        },
        equals: (a, b) => a.identifier == b.identifier,
      );
    } on CycleException catch (e) {
      log('Cycle detected in dynamic action ordering: $e');
      order = unorderedRegistrations.toList();
    }

    _actions = [
      ...beforeAllActions,
      ...order,
      ...afterAllActions,
    ].map((reg) => reg.entry).toList();
  }

  /// The ordered list of night actions.
  IList<DynamicActionEntry> get orderedActions {
    if (!_ordered) {
      orderActions();
    }
    return _actions.lock;
  }
}

class DynamicActionRegistration {
  /// The entry for this registration.
  final DynamicActionEntry entry;

  /// The list of identifiers that this action must come before.
  final ISet<DynamicActionIdentifier> before;

  /// The list of identifiers that this action must come after.
  final ISet<DynamicActionIdentifier> after;

  /// Whether this action should come before all others.
  final bool beforeAll;

  /// Whether this action should come after all others.
  final bool afterAll;

  DynamicActionIdentifier get identifier => entry.identifier;

  const DynamicActionRegistration(
    this.entry, {
    required this.before,
    required this.after,
    required this.beforeAll,
    required this.afterAll,
  });

  @override
  String toString() =>
      'DynamicActionRegistration(entry: $entry, before: $before, after: $after, beforeAll: $beforeAll, afterAll: $afterAll)';
}

class DynamicActionEntry {
  /// The unique identifier for this dynamic action.
  final DynamicActionIdentifier identifier;

  /// The builder function for this dynamic action screen.
  final DynamicActionBuilder builder;

  /// The condition under which this dynamic action is shown.
  final bool Function(GameState gameState) conditioned;

  /// The player indices that this action belongs to.
  final Set<int> players;

  const DynamicActionEntry({
    required this.identifier,
    required this.builder,
    required this.conditioned,
    required this.players,
  });

  @override
  String toString() =>
      'DynamicActionEntry(identifier: $identifier, players: $players)';
}

abstract interface class DynamicActionIdentifier {}
