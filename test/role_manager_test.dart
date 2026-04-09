import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/game/game_registry.g.dart' show GameRegistry;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/util/iterable.dart' show InfiniteIterable;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GameRegistry.ensureInitialized();
  });

  test(
    'Ensure valid role counts are sorted in ascending order and do not contain 0',
    () {
      for (final roleType in RoleManager.registeredRoles) {
        final validCountsRaw = roleType.information.validRoleCounts;
        final validCounts = validCountsRaw is InfiniteIterable
            ? validCountsRaw.take(100)
            : validCountsRaw;

        expect(
          validCounts,
          isNotEmpty,
          reason: 'Role $roleType has no valid role counts',
        );
        expect(
          validCounts,
          isSortedUsing<int>((a, b) => a.compareTo(b)),
          reason: 'Role $roleType has unsorted valid role counts',
        );
        expect(
          validCounts,
          isNot(contains(0)),
          reason:
              'Role $roleType has 0 as a valid role count, which is not allowed',
        );
      }
    },
  );
}
