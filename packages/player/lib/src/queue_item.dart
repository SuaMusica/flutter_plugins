import 'package:equatable/equatable.dart';

class QueueItem<T> extends Equatable {
  final position;
  final T item;
  QueueItem(this.position, this.item) : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          item == other.item;

  @override
  int get hashCode => [position, item].hashCode;

  @override
  String toString() => "$position -> $item";
}