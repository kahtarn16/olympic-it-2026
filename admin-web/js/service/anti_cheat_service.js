import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "exam/anti-cheat";

class AntiCheatService {
    async getViolations(examId) {
        const res = await apiClient.get(`${BASE}/${examId}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const antiCheatService = new AntiCheatService();