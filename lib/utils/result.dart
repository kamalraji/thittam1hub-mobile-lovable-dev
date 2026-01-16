/// A sealed class representing either a successful result or a failure.
/// Used for propagating errors from services to the UI layer.
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation with data.
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Represents a failed operation with an error message.
class Failure<T> extends Result<T> {
  final String message;
  final dynamic error;
  const Failure(this.message, [this.error]);
}
