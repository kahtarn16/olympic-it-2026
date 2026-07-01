class CategoryRequest {
  final String name;

  CategoryRequest({required this.name});

  Map<String, dynamic> toJson() {
    return {
      "name": name,
    };
  }
}