export function unwrap(json, fromJson) {
    if (!json) {
        throw new Error("Không có dữ liệu trả về từ server");
    }

    const { code, message, data } = json;
    if (code !== 200) {
        throw new Error(message ?? "Có lỗi xảy ra");
    }

    if (data === undefined || data === null) {
        return data;
    }

    return fromJson ? fromJson(data) : data;
}