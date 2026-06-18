import 'package:olympic_it_project/core/storage/token_storage.dart';
import 'package:olympic_it_project/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_request.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_response.dart';

class AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepository(this.authRemoteDataSource, this.tokenStorage);
  
  Future<LoginResponse> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);

      final response = await authRemoteDataSource.login(request);

      await tokenStorage.saveToken(response.token);

      return response;
    } catch (e) {
      throw Exception("Repository Error: ${e.toString()}");
    }
  }
}