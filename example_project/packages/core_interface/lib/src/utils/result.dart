/// 结果类型，用于包装操作结果
/// 
/// 提供类型安全的错误处理机制
sealed class Result<T> {
  const Result();
  
  /// 成功结果
  const factory Result.success(T data) = Success<T>;
  
  /// 失败结果
  const factory Result.failure(String error, {String? code, dynamic details}) = Failure<T>;
  
  /// 是否成功
  bool get isSuccess => this is Success<T>;
  
  /// 是否失败
  bool get isFailure => this is Failure<T>;
  
  /// 获取数据（成功时）
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  /// 获取错误信息（失败时）
  String? get error => isFailure ? (this as Failure<T>).error : null;
  
  /// 获取错误代码（失败时）
  String? get errorCode => isFailure ? (this as Failure<T>).code : null;
  
  /// 获取错误详情（失败时）
  dynamic get errorDetails => isFailure ? (this as Failure<T>).details : null;
  
  /// 映射结果
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(mapper(data)),
      Failure<T>(error: final error, code: final code, details: final details) => 
        Result.failure(error, code: code, details: details),
    };
  }
  
  /// 异步映射结果
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    return switch (this) {
      Success<T>(data: final data) => Result.success(await mapper(data)),
      Failure<T>(error: final error, code: final code, details: final details) => 
        Result.failure(error, code: code, details: details),
    };
  }
  
  /// 折叠结果
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(String error) onFailure,
  ) {
    return switch (this) {
      Success<T>(data: final data) => onSuccess(data),
      Failure<T>(error: final error) => onFailure(error),
    };
  }
}

/// 成功结果
final class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);
  
  @override
  String toString() => 'Success(data: $data)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
}

/// 失败结果
final class Failure<T> extends Result<T> {
  final String error;
  final String? code;
  final dynamic details;
  
  const Failure(this.error, {this.code, this.details});
  
  @override
  String toString() => 'Failure(error: $error, code: $code, details: $details)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          code == other.code &&
          details == other.details;
  
  @override
  int get hashCode => Object.hash(error, code, details);
}
