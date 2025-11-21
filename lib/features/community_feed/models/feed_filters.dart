import 'package:collection/collection.dart';

enum FeedSort {
  newest,
  top,
  hot,
  rising,
}

enum FeedTimeRange {
  day,
  week,
  month,
  year,
  all,
}

class FeedFilter {
  const FeedFilter({
    this.sort = FeedSort.newest,
    this.timeRange = FeedTimeRange.week,
    this.sports = const <String>[],
    this.includeNsfw = true,
    this.includeSpoilers = true,
    this.authorId,
    this.searchQuery,
  });

  final FeedSort sort;
  final FeedTimeRange timeRange;
  final List<String> sports;
  final bool includeNsfw;
  final bool includeSpoilers;
  final String? authorId;
  final String? searchQuery;

  static const defaultFilter = FeedFilter();

  FeedFilter copyWith({
    FeedSort? sort,
    FeedTimeRange? timeRange,
    List<String>? sports,
    bool? includeNsfw,
    bool? includeSpoilers,
    String? authorId,
    String? searchQuery,
  }) {
    return FeedFilter(
      sort: sort ?? this.sort,
      timeRange: timeRange ?? this.timeRange,
      sports: sports ?? List<String>.from(this.sports),
      includeNsfw: includeNsfw ?? this.includeNsfw,
      includeSpoilers: includeSpoilers ?? this.includeSpoilers,
      authorId: authorId ?? this.authorId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasSearch => searchQuery != null && searchQuery!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'sort': sort.name,
      'timeRange': timeRange.name,
      'sports': sports,
      'includeNsfw': includeNsfw,
      'includeSpoilers': includeSpoilers,
      'authorId': authorId,
      'searchQuery': searchQuery,
    };
  }

  factory FeedFilter.fromJson(Map<String, dynamic> json) {
    FeedSort parseSort(String? value) {
      return FeedSort.values.firstWhere(
        (element) => element.name == value,
        orElse: () => FeedSort.newest,
      );
    }

    FeedTimeRange parseRange(String? value) {
      return FeedTimeRange.values.firstWhere(
        (element) => element.name == value,
        orElse: () => FeedTimeRange.week,
      );
    }

    return FeedFilter(
      sort: parseSort(json['sort'] as String?),
      timeRange: parseRange(json['timeRange'] as String?),
      sports: (json['sports'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      includeNsfw: json['includeNsfw'] as bool? ?? true,
      includeSpoilers: json['includeSpoilers'] as bool? ?? true,
      authorId: json['authorId'] as String?,
      searchQuery: json['searchQuery'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedFilter &&
        other.sort == sort &&
        other.timeRange == timeRange &&
        const ListEquality<String>().equals(other.sports, sports) &&
        other.includeNsfw == includeNsfw &&
        other.includeSpoilers == includeSpoilers &&
        other.authorId == authorId &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(
        sort,
        timeRange,
        Object.hashAll(sports),
        includeNsfw,
        includeSpoilers,
        authorId,
        searchQuery,
      );

}

