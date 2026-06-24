/// Data source interface for local Hive storage.
///
/// Allows mocking in tests and decouples the repository
/// from concrete Hive implementations.
library;

import '../models/brainstorm_model.dart';

abstract class IBrainstormLocalDataSource {
  /// Load all saved brainstorms, sorted by most recent first.
  Future<List<BrainstormModel>> getAll();

  /// Save or update a brainstorm.
  Future<void> save(BrainstormModel model);

  /// Delete a brainstorm by ID.
  Future<void> delete(String id);

  /// Check if a brainstorm exists.
  bool exists(String id);
}
