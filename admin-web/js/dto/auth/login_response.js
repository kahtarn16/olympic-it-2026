export class LoginResponse {
  constructor({ accessToken, refreshToken, userId, roleName }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.roleName = roleName;
  }

  static fromJson(json) {
    return new LoginResponse({
      accessToken: json.accessToken,
      refreshToken: json.refreshToken,
      userId: json.userId,
      roleName: json.roleName,
    });
  }
}