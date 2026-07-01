import 'dart:convert';

import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/create_student_request.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/update_student_request.dart';

class StudentService {
  final _api = ApiClient.instance;

  Future<List<StudentResponse>> getAll() async {
    final response = await _api.get("admin/student");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<List<StudentResponse>>.fromJson(
      jsonMap,
      (data) => (data as List)
          .map((e) => StudentResponse.fromJson(e))
          .toList(),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<void> create(CreateStudentRequest request) async {
    final response = await _api.post(
      "admin/student",
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

  Future<void> update(int id, UpdateStudentRequest request) async {
    final response = await _api.put(
      "admin/student/$id",
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
    final response = await _api.delete("admin/student/$id");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> unlock(int id) async {
    final response = await _api.put("admin/student/$id/unlock", {});

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