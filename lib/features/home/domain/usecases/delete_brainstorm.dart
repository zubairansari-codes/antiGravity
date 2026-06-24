/// Use case: Delete a saved brainstorm by ID.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/brainstorm_repository.dart';

class DeleteBrainstormUseCase {
  final BrainstormRepository _repo;

  const DeleteBrainstormUseCase(this._repo);

  Future<Either<Failure, Unit>> call(String id) {
    return _repo.deleteBrainstorm(id);
  }
}
