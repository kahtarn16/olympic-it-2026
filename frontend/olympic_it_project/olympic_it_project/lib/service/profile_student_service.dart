import 'dart:convert';
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_exception.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_session_response.dart';
import 'package:olympic_it_project/dto/profile/exam_session_dto.dart';
import 'package:olympic_it_project/dto/profile/join_room_response.dart';
import 'package:olympic_it_project/dto/profile/student_exam_response.dart';
import 'package:olympic_it_project/dto/profile/student_exam_result_response.dart';

class ProfileStudentService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.get("profile/me");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      jsonMap,
      (data) => Map<String, dynamic>.from(data),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<List<Map<String, dynamic>>> getMyExams() async {
    final response = await _api.get("profile/my-exams");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      jsonMap,
      (data) => List<dynamic>.from(data),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception(apiResponse.message);
  }

  Future<StudentExamDetailResponse> getExamDetail(int examId) async {
    final response = await _api.get("student/exam/$examId");

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<StudentExamDetailResponse>.fromJson(
      jsonMap,
      (data) => StudentExamDetailResponse.fromJson(data),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(apiResponse.message);
  }

  Future<JoinRoomResponse> joinRoom(int examId) async {
  final response = await _api.post('student/exam/$examId/join', {});
  final jsonMap = safeDecode(response);

  final apiResponse = ApiResponse<JoinRoomResponse>.fromJson(
    jsonMap,
    (data) => JoinRoomResponse.fromJson(data as Map<String, dynamic>),
  );

  if (apiResponse.code != 200 || apiResponse.data == null) {
    throw ApiException(apiResponse.code, apiResponse.message);
  }

  return apiResponse.data!;
}

  Future<ExamSessionDto> getExamSession(int examId) async {
    final response = await _api.get('student/exam/$examId/session');

    final jsonMap = safeDecode(response);

    final apiResponse = ApiResponse<ExamSessionDto>.fromJson(
      jsonMap,
      (data) => ExamSessionDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data!;
  }

  Future<StudentExamResultResponse> getExamResult(int examId) async {
    final response = await _api.get('student/exam/$examId/result');

    final jsonMap = safeDecode(response);

    final apiResponse = ApiResponse<StudentExamResultResponse>.fromJson(
      jsonMap,
      (data) =>
          StudentExamResultResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data!;
  }
}
