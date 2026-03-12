import 'package:fast_immutable_collections/fast_immutable_collections.dart';

extension ISetExtension<T> on ISet<T> {
  bool singleElementEquals(T element) => length == 1 && contains(element);
}

extension PairToSet<T> on (T, T) {
  Set<T> toSet() => {$1, $2};
  ISet<T> toISet() => ISet({$1, $2});
}

extension TripleToSet<T> on (T, T, T) {
  Set<T> toSet() => {$1, $2, $3};
  ISet<T> toISet() => ISet({$1, $2, $3});
}
