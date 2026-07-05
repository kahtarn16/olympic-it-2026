import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/create_class_request.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/update_class_request.dart';

class ClassService {
  final _api = ApiClient.instance;

  Future<List<ClassResponse>> getAll({int? academicYearId}) async {
    String url = "admin/classes";

    if (academicYearId != null) {
      url += "?academicYearId=$academicYearId";
    }

    final response = await _api.get(url);

    final apiResponse = decodeApiResponse<List<ClassResponse>>(
      response,
      (data) => (data as List)
          .map((e) => ClassResponse.fromJson(e))
          .toList(),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<void> create(CreateClassRequest request) async {
    final response = await _api.post(
      "admin/classes",
      request.toJson(),
    );

    final apiResponse = decodeApiResponse<String>(
      response,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> update(int id, UpdateClassRequest request) async {
    final response = await _api.put(
      "admin/classes/$id",
      request.toJson(),
    );

    final apiResponse = decodeApiResponse<String>(
      response,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> delete(int id) async {
    final response = await _api.delete("admin/classes/$id");

    final apiResponse = decodeApiResponse<String>(
      response,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }
}