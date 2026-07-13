const KEYS = {
  access: "access_token",
  refresh: "refresh_token",
  userId: "user_id",
  role: "role",
};

class StorageToken {
  saveTokens(accessToken, refreshToken) {
    localStorage.setItem(KEYS.access, accessToken);
    localStorage.setItem(KEYS.refresh, refreshToken);
  }

  getAccessToken() {
    return localStorage.getItem(KEYS.access);
  }

  getRefreshToken() {
    return localStorage.getItem(KEYS.refresh);
  }

  saveUserInfo(userId, role) {
    localStorage.setItem(KEYS.userId, String(userId));
    localStorage.setItem(KEYS.role, role);
  }

  getUserId() {
    const v = localStorage.getItem(KEYS.userId);
    return v ? Number(v) : null;
  }

  getRole() {
    return localStorage.getItem(KEYS.role);
  }

  deleteAll() {
    Object.values(KEYS).forEach((k) => localStorage.removeItem(k));
  }
}

export const storageToken = new StorageToken();