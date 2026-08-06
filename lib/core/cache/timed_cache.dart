class TimedCache<T> {
  TimedCache({required this.ttl});

  final Duration ttl;
  T? _value;
  DateTime? _storedAt;

  T? get value {
    final storedAt = _storedAt;
    if (_value == null || storedAt == null) return null;
    if (DateTime.now().difference(storedAt) > ttl) return null;
    return _value;
  }

  T? get staleValue => _value;

  bool get isExpired {
    final storedAt = _storedAt;
    if (_value == null || storedAt == null) return true;
    return DateTime.now().difference(storedAt) > ttl;
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
