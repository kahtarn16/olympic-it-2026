import 'package:http/http.dart' as http;
import 'package:olympic_it_project/core/api_client.dart';

class UploadService {
  Future<String> uploadImage(String filePath) async {
    final streamedResponse = await ApiClient.instance.uploadMultipart(
      "upload/image", 
      "file", 
      filePath,
    );
    return _processResponse(streamedResponse);
  }

  Future<String> uploadVideo(String filePath) async {
    final streamedResponse = await ApiClient.instance.uploadMultipart(
      "upload/video", 
      "file", 
      filePath,
    );
    return _processResponse(streamedResponse);
  }

  Future<String> _processResponse(http.StreamedResponse streamedResponse) async {
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonMap = safeDecode(response);
      if (jsonMap is Map<String, dynamic> && jsonMap['url'] != null) {
        return jsonMap['url'].toString();
      }
      throw Exception("Tải file lên thất bại: phản hồi không hợp lệ");
    } else {
      throw Exception("Tải file lên thất bại (${response.statusCode}): ${safeErrorMessage(response)}");
    }
  }
}