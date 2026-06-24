/// Local data source — Hive CRUD for brainstorm sessions.
library;

import 'package:hive/hive.dart';

import '../models/brainstorm_model.dart';

import 'brainstorm_local_ds_interface.dart';

class BrainstormLocalDataSource implements IBrainstormLocalDataSource {
  final Box<BrainstormModel> _box;

  const BrainstormLocalDataSource(this._box);

  /// Load all saved brainstorms, sorted by most recent first.
  @override
  Future<List<BrainstormModel>> getAll() async {
    final all = _box.values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Save or update a brainstorm.
  @override
  Future<void> save(BrainstormModel model) async {
    await _box.put(model.id, model);
  }

  /// Delete a brainstorm by ID.
  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Check if a brainstorm exists.
  @override
  bool exists(String id) => _box.containsKey(id);
}
