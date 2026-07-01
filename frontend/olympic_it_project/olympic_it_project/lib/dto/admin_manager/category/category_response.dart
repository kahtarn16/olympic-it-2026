class CategoryResponse {
  final int id;
  final String name;

  CategoryResponse({
    required this.id,
    required this.name,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: json["id"],
      name: json["name"],
    );
  }
}