
import 'package:flutter/foundation.dart';

typedef JsonParser2<T> = T Function(dynamic data);

@immutable
class QueryPage<T> {
  const QueryPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  factory QueryPage.fromJson(Map<String, dynamic> json, JsonParser2<T> jsonParser) {
    return QueryPage(
      items: (json['items'] as List<dynamic>)
          .map((item) => jsonParser.call(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }

  final List<T> items;
  final int page;
  final bool hasMore;

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => (item as dynamic).toJson()).toList(),
      'page': page,
      'hasMore': hasMore,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueryPage &&
          other.items == items &&
          other.page == page &&
          other.hasMore == hasMore);

  @override
  int get hashCode => Object.hash(items, page, hasMore);

  @override
  String toString() => 'PostPage(posts: ${items.length}, page: $page, hasMore: $hasMore)';
}