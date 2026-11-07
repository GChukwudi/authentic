import 'dart:async';

import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/domain/repositories/repositories.dart';

/// Checks made on this phone, newest first. Kept for the session only.
class InMemoryHistoryRepository implements HistoryRepository {
  final List<ScanOutcome> _items = [];
  final _controller = StreamController<List<ScanOutcome>>.broadcast();

  @override
  List<ScanOutcome> get current => List.unmodifiable(_items);

  @override
  Stream<List<ScanOutcome>> watch() => _controller.stream;

  @override
  void add(ScanOutcome outcome) {
    _items.insert(0, outcome);
    _controller.add(current);
  }
}
