extension IterableExt<T> on Iterable<T> {
  InfiniteIterable<T> generateInfinite(T Function(int) generator) {
    return InfiniteIterable(generator);
  }
}

class InfiniteIterable<T> extends Iterable<T> {
  const InfiniteIterable(this.generator);

  final T Function(int) generator;

  @override
  Iterator<T> get iterator => _InfiniteIterator(generator);
}

class _InfiniteIterator<T> implements Iterator<T> {
  _InfiniteIterator(this.generator);

  final T Function(int) generator;
  int index = 0;

  @override
  late T current;

  @override
  bool moveNext() {
    current = generator(index);
    index++;
    return true;
  }
}

int Function(int index) _startingAtGenerator(int start) =>
    (int index) => index + start;

InfiniteIterable<int> infiniteIterableStartingAt(int start) {
  return InfiniteIterable(_startingAtGenerator(start));
}
