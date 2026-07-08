import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/core/page_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_participant_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/anti_cheat_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/create_exam_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_details_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_restore_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/remove_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/update_exam_request.dart';
import 'package:olympic_it_project/dto/profile/submit_answer_response.dart';

class ExamService {
  final _api = ApiClient.instance;

  Future<ExamDetailsResponse> getDetail(int id) async {
    final response = await _api.get('admin/exam/$id');

    final jsonMap = safeDecode(response) as Map<String, dynamic>;

    final apiResponse = ApiResponse<ExamDetailsResponse>.fromJson(
      jsonMap,
      (data) => ExamDetailsResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data!;
  }

  Future<void> create(CreateExamRequest request) async {
    final response = await _api.post('admin/exam', request.toJson());
    _checkResponse(response);
  }

  Future<void> update(int id, UpdateExamRequest request) async {
    final response = await _api.put('admin/exam/$id', request.toJson());
    _checkResponse(response);
  }

  Future<void> delete(int id) async {
    final response = await _api.delete('admin/exam/$id');
    _checkResponse(response);
  }

  Future<void> addQuestion(AddExamQuestionRequest request) async {
    final response = await _api.post('admin/exam/question', request.toJson());
    _checkResponse(response);
  }

  Future<void> removeQuestion(RemoveExamQuestionRequest request) async {
    final response = await _api.deleteWithBody(
      'admin/exam/question',
      request.toJson(),
    );
    _checkResponse(response);
  }

  Future<void> addParticipant(AddParticipantRequest request) async {
    final response = await _api.post(
      'admin/exam/participant',
      request.toJson(),
    );
    _checkResponse(response);
  }

  Future<List<ExamParticipantResponse>> getExamParticipants(int examId) async {
    final response = await _api.get('admin/exam/$examId/participants');
    final jsonMap = safeDecode(response) as Map<String, dynamic>;
    final apiResponse = ApiResponse<List<ExamParticipantResponse>>.fromJson(
      jsonMap,
      (data) => (data as List)
          .map(
            (e) => ExamParticipantResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<List<ExamQuestionResponse>> getExamQuestions(int examId) async {
    final response = await _api.get('admin/exam/$examId/questions');
    final jsonMap = safeDecode(response) as Map<String, dynamic>;
    final apiResponse = ApiResponse<List<ExamQuestionResponse>>.fromJson(
      jsonMap,
      (data) => (data as List)
          .map((e) => ExamQuestionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<void> createRoom(int examId) async {
    final response = await _api.post('exam-session/$examId/room', {});
    _checkResponse(response);
  }

  Future<void> startExam(int examId) async {
    final response = await _api.post('exam-session/$examId/start', {});
    _checkResponse(response);
  }

  Future<ExamRestoreResponse> restoreExamState(int examId) async {
    final response = await _api.get('exam-session/$examId/restore');

    final jsonMap = safeDecode(response);

    return ExamRestoreResponse.fromJson(jsonMap);
  }

  Future<void> resetExam(int examId) async {
    final response = await _api.post('exam-session/$examId/reset', {});

    _checkResponse(response);
  }

  Future<void> nextQuestion(int examId) async {
    final response = await _api.post('exam-session/$examId/next', {});

    _checkResponse(response);
  }

  Future<SubmitAnswerResponse> submitAnswer(
    int examId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.post('exam-session/$examId/submit', payload);
    final jsonMap = safeDecode(
      response,
    ); 
    return SubmitAnswerResponse.fromJson(jsonMap);
  }

  Future<List<AntiCheatResponse>> getAntiCheatLogs(int examId) async {
    final response = await _api.get('exam/anti-cheat/$examId');
    final jsonMap = safeDecode(response) as Map<String, dynamic>;

    final apiResponse = ApiResponse<List<AntiCheatResponse>>.fromJson(
      jsonMap,
      (data) => (data as List)
          .map((e) => AntiCheatResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data ?? [];
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