import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/classes";

class ClassesService {
    async getAll(academicYearId) {
        const query = academicYearId ? `?academicYearId=${academicYearId}` : "";
        const res = await apiClient.get(`${BASE}${query}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async create(className, academicYearId) {
        const res = await apiClient.post(BASE, { className, academicYearId });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async update(id, className, academicYearId) {
        const res = await apiClient.put(`${BASE}/${id}`, { className, academicYearId });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async delete(id) {
        const res = await apiClient.delete(`${BASE}/${id}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const classesService = new ClassesService();