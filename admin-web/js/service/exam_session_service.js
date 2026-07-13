import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "exam-session";

class ExamSessionService {

    async createRoom(examId) {
        const res = await apiClient.post(`${BASE}/${examId}/room`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async startExam(examId) {
        const res = await apiClient.post(`${BASE}/${examId}/start`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async nextQuestion(examId) {
        const res = await apiClient.post(`${BASE}/${examId}/next`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async getSession(examId) {
        const res = await apiClient.get(`${BASE}/${examId}`);
        return safeDecode(res); // <-- SỬA: bỏ unwrap
    }

    async restore(examId) {
        const res = await apiClient.get(`${BASE}/${examId}/restore`);
        return safeDecode(res);
    }

    async leaderboard(examId) {
        const res = await apiClient.get(`${BASE}/${examId}/leaderboard`);
        return safeDecode(res);
    }

    async reset(examId) {
        const res = await apiClient.post(`${BASE}/${examId}/reset`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async submit(examId, request) {
        const res = await apiClient.post(`${BASE}/${examId}/submit`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }
    async adminRestore(examId) {
        const res = await apiClient.get(`${BASE}/${examId}/admin-restore`);
        return safeDecode(res);
    }

    async unbanParticipant(examId, userId) {
        const res = await apiClient.post(`${BASE}/${examId}/participants/${userId}/unban`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const examSessionService = new ExamSessionService();