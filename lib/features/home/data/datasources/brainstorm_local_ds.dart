/// Local data source — Hive CRUD for brainstorm sessions.
library;

import 'package:hive/hive.dart';

import '../models/brainstorm_model.dart';

class BrainstormLocalDataSource {
  final Box<BrainstormModel> _box;

  const BrainstormLocalDataSource(this._box);

  /// Load all saved brainstorms, sorted by most recent first.
  Future<List<BrainstormModel>> getAll() async {
    final all = _box.values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Save or update a brainstorm.
  Future<void> save(BrainstormModel model) async {
    await _box.put(model.id, model);
  }

  /// Delete a brainstorm by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Check if a brainstorm exists.
  bool exists(String id) => _box.containsKey(id);
}
