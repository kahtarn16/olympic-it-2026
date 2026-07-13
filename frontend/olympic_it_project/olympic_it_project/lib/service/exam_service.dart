import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_exception.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/core/page_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_restore_response.dart';
import 'package:olympic_it_project/dto/profile/submit_answer_response.dart';

class ExamService {
  final _api = ApiClient.instance;

  Future<ExamRestoreResponse> restoreExamState(int examId) async {
  final response = await _api.get('exam-session/$examId/restore');
  final jsonMap = safeDecode(response);

  if (response.statusCode != 200) {
    final code = jsonMap['code'] ?? response.statusCode;
    final message = jsonMap['message'] ?? 'Có lỗi xảy ra';
    throw ApiException(code as int, message as String);
  }

  return ExamRestoreResponse.fromJson(jsonMap);
}

  Future<SubmitAnswerResponse> submitAnswer(
  int examId,
  Map<String, dynamic> payload,
) async {
  final response = await _api.post('exam-session/$examId/submit', payload);
  final jsonMap = safeDecode(response);

  if (response.statusCode != 200) {
    final code = jsonMap['code'] ?? response.statusCode;
    final message = jsonMap['message'] ?? 'Có lỗi xảy ra';
    throw ApiException(code as int, message as String);
  }

  return SubmitAnswerResponse.fromJson(jsonMap);
}

  Future<void> recordViolation(int examId, String violationType) async {
    final response = await _api.post('exam/anti-cheat', {
      'examId': examId,
      'type': violationType,
    });
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception(
        'Server trả về body rỗng với status ${response.statusCode}',
      );
    }

    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(jsonMap, (d) => d);
    if (apiResponse.code != 200) throw Exception(apiResponse.message);
  }

  Future<void> removeParticipant(int examId, int userId) async {
    final response = await _api.delete(
      'admin/exam/participant?examId=$examId&userId=$userId',
    );
    _checkResponse(response);
  }

  Future<PageResponse<ExamResponse>> getAllPaged({
    required int page,
    required int size,
    String? keyword,
  }) async {
    final response = await _api.get(
      'admin/exam?page=$page&size=$size&keyword=${keyword ?? ""}',
    );

    final json = safeDecode(response);

    final api = ApiResponse<PageResponse<ExamResponse>>.fromJson(
      json,
      (data) => PageResponse<ExamResponse>.fromJson(
        data,
        (e) => ExamResponse.fromJson(e),
      ),
    );

    return api.data!;
  }
}