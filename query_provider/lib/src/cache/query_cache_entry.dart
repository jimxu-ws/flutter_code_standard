import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../options/query_options.dart';

dynamic _toJsonCompatible<T>(T obj) {
  if (obj == null || obj is num || obj is String || obj is bool) {
    return obj;
  } else if (obj is List) {
    return obj.map(_toJsonCompatible).toList();
  } else if (obj is Map) {
    return obj.map((key, value) => MapEntry(key, _toJsonCompatible(value)));
  } else { //custom type
    try{
      return (obj as dynamic).toJson();
    }catch(e){
      throw ArgumentError('Unsupported type: ${obj.runtimeType}');
    }
  }
}

// ignore: unused_element
Object? _fromJsonCompatible(dynamic json) {
  if (json == null || json is num || json is String || json is bool) {
    return json;
  } else if (json is List) {
    return json.map(_fromJsonCompatible).toList();
  } else if (json is Map<String, dynamic>) {
    final result = <String, dynamic>{};
    json.forEach((key, value) {
      result[key] = _fromJsonCompatible(value);
    });
    return result;
  }
  return json;
}

Type _typeOf<X>() => X;
final Map<Type, dynamic Function(dynamic json)> _parserTable = {};
void registerParser<T>(T Function(dynamic json) parser){
  _parserTable[_typeOf<T>()] = parser;
}

/// Cache entry for storing query data and metadata
@immutable
class QueryCacheEntry<T> {
  const QueryCacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.cacheTime,
    required this.staleTime,
    this.error,
    this.stackTrace,
  });
  factory QueryCacheEntry.fromJson(Map<String, dynamic> json, {JsonParser<T>? jsonParser}) {
    if(jsonParser == null){
      throw ArgumentError('jsonParser is required');
    }
    return QueryCacheEntry(
      data: jsonParser.call(json['data']),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      cacheTime: Duration(milliseconds: json['cacheTime'] as int),
      staleTime: Duration(milliseconds: json['staleTime'] as int),
    );
  }

  factory QueryCacheEntry.rawFromJson(Map<String, dynamic> json) {
    return QueryCacheEntry(
      data: json['data'] as T,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      cacheTime: Duration(milliseconds: json['cacheTime'] as int),
      staleTime: Duration(milliseconds: json['staleTime'] as int),
    );
  }

  final T? data;
  final DateTime fetchedAt;
  /// Time after which data is considered stale and will be refetched
  final Duration staleTime;
  /// Time after which unused data is removed from cache
  final Duration cacheTime;
  final Object? error;
  final StackTrace? stackTrace;

  /// Returns true if the cached data is stale
  bool get isStale {
    final now = DateTime.now();
    return now.difference(fetchedAt) > staleTime;
  }

  /// Returns true if the cache entry should be evicted
  bool get shouldEvict {
    final now = DateTime.now();
    return now.difference(fetchedAt) > cacheTime;
  }

  /// Returns true if this entry has valid data
  bool get hasData => data != null && error == null;

  /// Returns true if this entry has an error
  bool get hasError => error != null;

  /// Create a copy of the entry
  QueryCacheEntry<T> copyWith({
    T? data,
    DateTime? fetchedAt,
    Duration? cacheTime,
    Duration? staleTime,
    Object? error,
    StackTrace? stackTrace,
  }) => QueryCacheEntry<T>(
      data: data ?? this.data,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      cacheTime: cacheTime ?? this.cacheTime,
      staleTime: staleTime ?? this.staleTime,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );

  /// Create a stale copy of the entry
    QueryCacheEntry<T> copyAsStale() => QueryCacheEntry<T>(
      data: data,
      fetchedAt: fetchedAt.subtract(staleTime + const Duration(minutes: 1)),
      cacheTime: cacheTime,
      staleTime: staleTime,
      error: error,
      stackTrace: stackTrace,
    );

  Map<String, dynamic> toJson() => {
        'data': _toJsonCompatible(data),
        'fetchedAt': fetchedAt.toIso8601String(),
        'cacheTime': cacheTime.inMilliseconds,
        'staleTime': staleTime.inMilliseconds,
        // 'error': error,
        // 'stackTrace': stackTrace,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueryCacheEntry<T> &&
          other.data == data &&
          other.fetchedAt == fetchedAt &&
          other.error == error);

  @override
  int get hashCode => Object.hash(data, fetchedAt, error);

  @override
  String toString() => 'QueryCacheEntry<$T>('
      'data: $data, '
      'fetchedAt: $fetchedAt, '
      'hasError: $hasError, '
      'isStale: $isStale)';
}
