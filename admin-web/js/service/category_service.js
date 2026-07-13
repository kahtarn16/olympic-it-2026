import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/category";

class CategoryService {
    async getAll() {
        const res = await apiClient.get(BASE);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async create(name) {
        const res = await apiClient.post(BASE, { name });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async update(id, name) {
        const res = await apiClient.put(`${BASE}/${id}`, { name });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async delete(id) {
        const res = await apiClient.delete(`${BASE}/${id}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const categoryService = new CategoryService();