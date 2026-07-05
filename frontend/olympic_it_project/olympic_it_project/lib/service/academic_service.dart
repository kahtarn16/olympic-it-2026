import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/create_academic_year_request.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/update_academic_year_request.dart';

class AcademicYearService {
  final _api = ApiClient.instance;

  Future<List<AcademicYearResponse>> getAll() async {
    final response = await _api.get("admin/academic-year");

    final apiResponse = decodeApiResponse<List<AcademicYearResponse>>(
      response,
      (data) => (data as List)
          .map((e) => AcademicYearResponse.fromJson(e))
          .toList(),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<void> create(CreateAcademicYearRequest request) async {
    final response = await _api.post(
      "admin/academic-year/create",
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

  Future<void> update(int id, UpdateAcademicYearRequest request) async {
    final response = await _api.put(
      "admin/academic-year/$id",
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
    final response = await _api.delete("admin/academic-year/$id");

    final apiResponse = decodeApiResponse<String>(
      response,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }
}
