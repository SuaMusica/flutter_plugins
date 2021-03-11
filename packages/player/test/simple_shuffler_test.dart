import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smplayer/src/queue_item.dart';
import 'package:smplayer/src/simple_shuffle.dart';

void main() {
  group('Simple Shuffle Test Suit', () {
    test('Shuffling a list should return a shuffled list', () {
      final subject = SimpleShuffler();
      var items = _createTestData(5);
      var result = subject.shuffle(List.from(items));
      expect(false, listEquals(items, result));
    });

    test('Unshuffling a list should return the same original list', () {
      final subject = SimpleShuffler();
      var items = _createTestData(100);
      var result = subject.shuffle(items);
      result = subject.unshuffle(result);
      expect(result, equals(items));
    });
  });
}

_createTestData(int size) {
  var items = <QueueItem>[];
  for (var i = 0; i < size; ++i) {
    items.add(QueueItem(i, 0, "ITEM-$i"));
  }

  return items;
}
