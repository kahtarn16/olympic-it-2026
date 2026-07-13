import { apiClient, safeDecode } from "../core/api_client.js";
import { unwrap } from "../core/api_response.js";

const BASE = "admin/student";

class StudentService {

    async getAll(classId = null) {
        let query = "";

        if (classId) {
            query = `?classId=${classId}`;
        }

        const res = await apiClient.get(`${BASE}${query}`);
        const json = await safeDecode(res);

        return unwrap(json);
    }

    async create({ username, password, email, fullName, classId }) {
        const res = await apiClient.post(BASE, {
            username,
            password,
            email,
            fullName,
            classId
        });

        const json = await safeDecode(res);

        return unwrap(json);
    }

    async update(id, { username, email, fullName, classId }) {
        const res = await apiClient.put(`${BASE}/${id}`, {
            username,
            email,
            fullName,
            classId
        });

        const json = await safeDecode(res);

        return unwrap(json);
    }

    async lock(id) {
        const res = await apiClient.delete(`${BASE}/${id}`);
        const json = await safeDecode(res);

        return unwrap(json);
    }

    async unlock(id) {
        const res = await apiClient.put(`${BASE}/${id}/unlock`);
        const json = await safeDecode(res);

        return unwrap(json);
    }
}

export const studentService = new StudentService();