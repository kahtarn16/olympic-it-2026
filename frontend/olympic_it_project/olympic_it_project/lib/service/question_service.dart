import 'dart:convert';

import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_option_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_detail_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_page_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/update_question_option_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/update_question_request.dart';

class QuestionService {
  final _api = ApiClient.instance;

  Future<QuestionPageResponse> getAll({
    int page = 0,
    int size = 10,
    int? categoryId,
  }) async {
    String url = "admin/question?page=$page&size=$size";
    if (categoryId != null) url += "&categoryId=$categoryId";

    final response = await _api.get(url);
    final jsonMap = safeDecode(response) as Map<String, dynamic>;

    final apiResponse = ApiResponse<QuestionPageResponse>.fromJson(
      jsonMap,
      (data) => QuestionPageResponse.fromJson(data),
    );

    return apiResponse.data!;
  }

  Future<QuestionDetailResponse> getDetail(int id) async {
    final response = await _api.get("admin/question/$id");
    final jsonMap = safeDecode(response) as Map<String, dynamic>;

    final apiResponse = ApiResponse<QuestionDetailResponse>.fromJson(
      jsonMap,
      (data) => QuestionDetailResponse.fromJson(data),
    );

    return apiResponse.data!;
  }

  Future<void> create(CreateQuestionRequest request) async {
    final response =
        await _api.post("admin/question", request.toJson());

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> update(int id, UpdateQuestionRequest request) async {
    final response =
        await _api.put("admin/question/$id", request.toJson());

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> delete(int id) async {
    final response = await _api.delete("admin/question/$id");

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> createOption(int questionId, CreateQuestionOptionRequest request) async {
    final response =
        await _api.post("admin/question/$questionId/option", request.toJson());

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> updateOption(int id, UpdateQuestionOptionRequest request) async {
    final response =
        await _api.put("admin/question/option/$id", request.toJson());

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> deleteOption(int id) async {
    final response =
        await _api.delete("admin/question/option/$id");

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception('Server trả về body rỗng với status ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);

    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }
}