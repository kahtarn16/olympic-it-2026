class PageResponse<T> {
  final List<T> data;
  final int totalPages;
  final int totalElements;
  final int page;
  final int size;

  PageResponse({
    required this.data,
    required this.totalPages,
    required this.totalElements,
    required this.page,
    required this.size,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PageResponse(
      data: (json['data'] as List)
          .map((e) => fromJsonT(e))
          .toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
    );
  }
}