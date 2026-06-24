/// Failure hierarchy for AntiGravity.
///
/// All repository methods return `Either<Failure, T>` so callers
/// MUST handle both cases.  Never throw raw exceptions across layers.
library;

/// Base failure class — every domain error extends this.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// The AI service (OpenAI) returned an error or timed out.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'AI service unavailable. Please try again.',
  ]);
}

/// Device has no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network.',
  ]);
}

/// Speech recognition or TTS failed.
class SpeechFailure extends Failure {
  const SpeechFailure([
    super.message = 'Could not process voice input. Try again.',
  ]);
}

/// Hive local storage read/write failed.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Failed to save your brainstorm.',
  ]);
}

/// User input validation failed.
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Invalid input provided.',
  ]);
}
