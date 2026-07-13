import { API_BASE } from "./config.js";
import { storageToken } from "./storage_token.js";

const EXCLUDED_FROM_REFRESH = new Set([
    "auth/login",
    "auth/resend-otp",
    "auth/forgot-password",
    "auth/reset-password",
    "auth/refresh",
]);

class ApiClient {
    _authService = null;

    init(authService) {
        this._authService = authService;
    }

    _buildUrl(endpoint) {
        const path = endpoint.startsWith("/") ? endpoint.slice(1) : endpoint;
        return new URL(path, API_BASE).toString();
    }

    _headers(endpoint) {
        const token = storageToken.getAccessToken();
        const skipAuth = EXCLUDED_FROM_REFRESH.has(endpoint);
        return {
            "Content-Type": "application/json",
            ...(token && !skipAuth ? { Authorization: `Bearer ${token}` } : {}),
        };
    }

    _shouldRefresh(endpoint) {
        return !EXCLUDED_FROM_REFRESH.has(endpoint);
    }

    async _requestRaw(endpoint, method, body) {
        return fetch(this._buildUrl(endpoint), {
            method,
            headers: this._headers(endpoint),
            body: body !== undefined ? JSON.stringify(body) : undefined,
        });
    }

    async _requestWithRetry(endpoint, method, body) {
        let response = await this._requestRaw(endpoint, method, body);

        if (response.status === 401 && this._shouldRefresh(endpoint) && this._authService) {
            await this._authService.refreshTokens();
            response = await this._requestRaw(endpoint, method, body);
        }

        return response;
    }

    get(endpoint) {
        return this._requestWithRetry(endpoint, "GET");
    }

    post(endpoint, body) {
        return this._requestWithRetry(endpoint, "POST", body ?? {});
    }

    put(endpoint, body) {
        return this._requestWithRetry(endpoint, "PUT", body ?? {});
    }

    delete(endpoint) {
        return this._requestWithRetry(endpoint, "DELETE");
    }

    deleteWithBody(endpoint, body) {
        return this._requestWithRetry(endpoint, "DELETE", body ?? {});
    }

    postRaw(endpoint, body) {
        return this._requestRaw(endpoint, "POST", body ?? {});
    }

    async uploadMultipart(endpoint, field, file) {
        const token = storageToken.getAccessToken();
        const form = new FormData();
        form.append(field, file, file.name);

        return fetch(this._buildUrl(endpoint), {
            method: "POST",
            headers: token ? { Authorization: `Bearer ${token}` } : {},
            body: form,
        });
    }
}

export const apiClient = new ApiClient();

export async function safeDecode(response) {
    const text = (await response.text()).trim();

    if (!response.ok) {
        throw new Error(`Lỗi API: ${response.status} - ${text}`);
    }

    if (!text) {
        return {
            code: 200,
            message: "Success",
            data: null,
        };
    }

    return JSON.parse(text);
}