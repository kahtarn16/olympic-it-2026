import 'package:http/http.dart' as http;
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/core/page_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_participant_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/create_exam_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/remove_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/update_exam_request.dart';

class ExamService {
  final _api = ApiClient.instance;

  Future<ExamResponse> getDetail(int id) async {
    final response = await _api.get('admin/exam/$id');
    final apiResponse = decodeApiResponse<ExamResponse>(
      response,
      (data) => ExamResponse.fromJson(data as Map<String, dynamic>),
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
    final apiResponse = decodeApiResponse<List<ExamParticipantResponse>>(
      response,
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
    final apiResponse = decodeApiResponse<List<ExamQuestionResponse>>(
      response,
      (data) => (data as List)
          .map((e) => ExamQuestionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<void> startExam(int examId) async {
    final response = await _api.put('admin/exam/$examId/start', {});
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw Exception(safeErrorMessage(response));
    }

    final apiResponse = decodeApiResponse<dynamic>(response, (d) => d);
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

    final apiResponse = decodeApiResponse<PageResponse<ExamResponse>>(
      response,
      (data) => PageResponse<ExamResponse>.fromJson(
        data,
        (e) => ExamResponse.fromJson(e),
      ),
    );

    return apiResponse.data!;
  }
}
