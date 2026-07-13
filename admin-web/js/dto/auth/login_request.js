export class LoginRequest {
  constructor(username, password) {
    this.username = username;
    this.password = password;
  }

  toJson() {
    return { username: this.username, password: this.password };
  }
}