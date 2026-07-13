import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/academic-year";

class AcademicYearService {
    async getAll() {
        const res = await apiClient.get(BASE);
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async create(academicYearName) {
        const res = await apiClient.post(`${BASE}/create`, { academicYearName });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async update(id, academicYearName) {
        const res = await apiClient.put(`${BASE}/${id}`, { academicYearName });
        const json = await safeDecode(res);
        return unwrap(json);
    }

    async delete(id) {
        const res = await apiClient.delete(`${BASE}/${id}`);
        const json = await safeDecode(res);
        return unwrap(json);
    }
}

export const academicYearService = new AcademicYearService();