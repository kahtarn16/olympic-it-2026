import 'dart:convert';

import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_request.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';

class CategoryService {
  final _api = ApiClient.instance;

  Future<List<CategoryResponse>> getAll() async {
    final response = await _api.get("admin/category");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(
      jsonMap,
      (data) => (data as List)
          .map((e) => CategoryResponse.fromJson(e))
          .toList(),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<void> create(CategoryRequest request) async {
    final response = await _api.post(
      "admin/category",
      request.toJson(),
    );

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> update(int id, CategoryRequest request) async {
    final response = await _api.put(
      "admin/category/$id",
      request.toJson(),
    );

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> delete(int id) async {
    final response = await _api.delete("admin/category/$id");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }
}