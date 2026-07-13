import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";
import { storageToken } from "../core/storage_token.js";
import { LoginResponse } from "../dto/auth/login_response.js";
import { LoginRequest } from "../dto/auth/login_request.js";

const ADMIN_ROLE = "ADMIN";


class AuthService {
    async login(loginRequest) {
        const res = await apiClient.postRaw("auth/login", loginRequest.toJson());
        const json = await safeDecode(res);
        const data = unwrap(json, LoginResponse.fromJson);

        if ((data.roleName ?? "").toUpperCase() !== ADMIN_ROLE) {
            throw new Error("Thí sinh không được phép đăng nhập vào trang quản lý admin!");
        }

        storageToken.saveTokens(data.accessToken, data.refreshToken);
        storageToken.saveUserInfo(data.userId, data.roleName);

        return data;
    }

    async refreshTokens() {
        const oldRefreshToken = storageToken.getRefreshToken();
        if (!oldRefreshToken) {
            storageToken.deleteAll();
            throw new Error("Không có refresh token");
        }

        const res = await apiClient.postRaw("auth/refresh", {
            refreshToken: oldRefreshToken,
        });

        if (!res.ok) {
            storageToken.deleteAll();
            throw new Error("Refresh token thất bại");
        }

        const json = await safeDecode(res);
        const data = unwrap(json, LoginResponse.fromJson);
        storageToken.saveTokens(data.accessToken, data.refreshToken);
    }

    async logout() {
        try {
            await apiClient.post("auth/logout", {});
        } finally {
            storageToken.deleteAll();
        }
    }
}

export const authService = new AuthService();