/// Use case: Delete a saved brainstorm by ID.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/brainstorm_repository.dart';

class DeleteBrainstormUseCase {

  const DeleteBrainstormUseCase(this._repo);
  final BrainstormRepository _repo;

  Future<Either<Failure, Unit>> call(String id) {
    return _repo.deleteBrainstorm(id);
  }
}
