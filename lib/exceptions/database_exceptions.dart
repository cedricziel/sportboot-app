/// Base class for all database-related exceptions
abstract class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const DatabaseException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      '$runtimeType: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

/// Exception thrown when database initialization fails
class DatabaseInitializationException extends DatabaseException {
  const DatabaseInitializationException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when a database query fails
class QueryException extends DatabaseException {
  final String? query;

  const QueryException({
    required super.message,
    this.query,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      super.toString() + (query != null ? '\nQuery: $query' : '');
}

/// Exception thrown when a database transaction fails
class TransactionException extends DatabaseException {
  const TransactionException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when data migration fails
class MigrationException extends DatabaseException {
  final String? stage;
  final int? version;

  const MigrationException({
    required super.message,
    this.stage,
    this.version,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      super.toString() +
      (stage != null ? '\nStage: $stage' : '') +
      (version != null ? '\nVersion: $version' : '');
}

/// Exception thrown when data validation fails
class DataValidationException extends DatabaseException {
  final String? field;
  final dynamic invalidValue;

  const DataValidationException({
    required super.message,
    this.field,
    this.invalidValue,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      super.toString() +
      (field != null ? '\nField: $field' : '') +
      (invalidValue != null ? '\nInvalid value: $invalidValue' : '');
}

/// Exception thrown when a record is not found
class RecordNotFoundException extends DatabaseException {
  final String? table;
  final dynamic id;

  const RecordNotFoundException({
    required super.message,
    this.table,
    this.id,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      super.toString() +
      (table != null ? '\nTable: $table' : '') +
      (id != null ? '\nID: $id' : '');
}

/// Exception thrown when a duplicate record is encountered
class DuplicateRecordException extends DatabaseException {
  final String? table;
  final dynamic id;

  const DuplicateRecordException({
    required super.message,
    this.table,
    this.id,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      super.toString() +
      (table != null ? '\nTable: $table' : '') +
      (id != null ? '\nID: $id' : '');
}
