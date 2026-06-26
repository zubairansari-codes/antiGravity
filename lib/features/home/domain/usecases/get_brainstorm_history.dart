/// Use case: Load all saved brainstorms from local cache.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/brainstorm.dart';
import '../repositories/brainstorm_repository.dart';

class GetBrainstormHistoryUseCase {

  const GetBrainstormHistoryUseCase(this._repo);
  final BrainstormRepository _repo;

  Future<Either<Failure, List<Brainstorm>>> call() {
    return _repo.getBrainstormHistory();
  }
}
