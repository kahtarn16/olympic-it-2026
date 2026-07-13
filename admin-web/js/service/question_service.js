// questionService.js
import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/question";

class QuestionService {
    async getAll(page = 0, size = 10, categoryId) {
        const params = new URLSearchParams({ page, size });
        if (categoryId !== undefined && categoryId !== null) {
            params.append("categoryId", categoryId);
        }
        const res = await apiClient.get(`${BASE}?${params.toString()}`);
        const json = await safeDecode(res);
        return unwrap(json); // QuestionPageResponse
    }

    async getDetail(id) {
        const res = await apiClient.get(`${BASE}/${id}`);
        const json = await safeDecode(res);
        return unwrap(json); // QuestionDetailResponse
    }

    async create(request) {
        const res = await apiClient.post(BASE, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async update(id, request) {
        const res = await apiClient.put(`${BASE}/${id}`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async delete(id) {
        const res = await apiClient.delete(`${BASE}/${id}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async createOption(questionId, request) {
        const res = await apiClient.post(`${BASE}/${questionId}/option`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async updateOption(id, request) {
        const res = await apiClient.put(`${BASE}/option/${id}`, request);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async deleteOption(id) {
        const res = await apiClient.delete(`${BASE}/option/${id}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const questionService = new QuestionService();