class Entry<K, V> {
  final K key;
  final V value;
  Entry(this.key, this.value);

  @override
  toString() => "${this.key}=${this.value}";
}