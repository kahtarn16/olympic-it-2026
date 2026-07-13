// examService.js
import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/exam";

class ExamService {
    async getAll(page = 0, size = 10, keyword) {
        const params = new URLSearchParams({ page, size });
        if (keyword) params.append("keyword", keyword);

        const res = await apiClient.get(`${BASE}?${params.toString()}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async getDetail(examId) {
        const res = await apiClient.get(`${BASE}/${examId}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async create(request) {
        const res = await apiClient.post(BASE, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async update(examId, request) {
        const res = await apiClient.put(`${BASE}/${examId}`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async delete(examId) {
        const res = await apiClient.delete(`${BASE}/${examId}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async getExamQuestions(examId) {
        const res = await apiClient.get(`${BASE}/${examId}/questions`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async getExamParticipants(examId) {
        const res = await apiClient.get(`${BASE}/${examId}/participants`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async addQuestion(request) {
        const res = await apiClient.post(`${BASE}/question`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    // DELETE có body -> dùng deleteWithBody
    async removeQuestion(request) {
        const res = await apiClient.deleteWithBody(`${BASE}/question`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async addParticipant(request) {
        const res = await apiClient.post(`${BASE}/participant`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    // DELETE dùng query param -> nối vào URL, không cần body
    async removeParticipant(examId, userId) {
        const params = new URLSearchParams({ examId, userId });
        const res = await apiClient.delete(`${BASE}/participant?${params.toString()}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async validateJoin(request) {
        const res = await apiClient.post(`${BASE}/validate-join`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async resetExam(examId) {
        const res = await apiClient.post(`exam-session/${examId}/reset`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const examService = new ExamService();