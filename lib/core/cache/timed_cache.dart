class TimedCache<T> {
  TimedCache({required this.ttl});

  final Duration ttl;
  T? _value;
  DateTime? _storedAt;

  T? get value {
    final storedAt = _storedAt;
    if (_value == null || storedAt == null) return null;
    if (DateTime.now().difference(storedAt) > ttl) {
      clear();
      return null;
    }
    return _value;
  }

  void set(T value) {
    _value = value;
    _storedAt = DateTime.now();
  }

  void clear() {
    _value = null;
    _storedAt = null;
  }
}
