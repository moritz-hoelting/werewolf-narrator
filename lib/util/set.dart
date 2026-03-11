extension SetExtensions<T> on Set<T> {
  void toggle(T value) {
    if (!remove(value)) {
      add(value);
    }
  }
}

extension PairToSet<T> on (T, T) {
  Set<T> toSet() => {$1, $2};
}

extension TripleToSet<T> on (T, T, T) {
  Set<T> toSet() => {$1, $2, $3};
}
