class QueueItem<T> {
  int position;
  int originalPosition;
  final T item;
  QueueItem(this.originalPosition, this.position, this.item) : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem &&
          runtimeType == other.runtimeType &&
          originalPosition == other.originalPosition &&
          position == other.position &&
          item == other.item;

  @override
  int get hashCode => [originalPosition, position, item].hashCode;

  QueueItem<T> copyWith({
    int originalPosition,
    int position,
    T item,
  }) {
    return QueueItem<T>(
      originalPosition ?? this.originalPosition,
      position ?? this.position,
      item ?? this.item,
    );
  }

  @override
  String toString() =>
      "original: $originalPosition - position: $position -> $item";
}
