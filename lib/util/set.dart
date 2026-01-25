extension SetExtensions<T> on Set<T> {
  void toggle(T value) {
    if (!remove(value)) {
      add(value);
    }
  }
}
