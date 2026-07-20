import { examService } from "./service/exam_service.js";
import { examSessionService } from "./service/exam_session_service.js";

const examId = localStorage.getItem("currentExamId");

const examNameEl = document.getElementById("examName");
const leaderboardTableEl = document.getElementById("leaderboardTable");

function escapeHtml(text) {
    if (text === null || text === undefined) return "";
    return String(text)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

if (!examId) {
    alert("Thiếu examId, vui lòng quay lại danh sách đề thi.");
    throw new Error("Thiếu examId");
}

async function init() {
    // Tên đề thi
    try {
        const exam = await examService.getDetail(examId);
        examNameEl.innerText = `Kết quả: ${exam.name}`;
    } catch (err) {
        console.warn("Không tải được tên đề thi:", err.message);
    }

    // Bảng xếp hạng
    try {
        const leaderboard = await examSessionService.leaderboard(examId);

        if (!leaderboard || leaderboard.length === 0) {
            leaderboardTableEl.innerHTML = `<tr><td colspan="3" class="text-muted">Chưa có dữ liệu kết quả.</td></tr>`;
            return;
        }

        leaderboardTableEl.innerHTML = leaderboard
            .map(l => `
                <tr>
                    <td>${l.rank}</td>
                    <td>${escapeHtml(l.name)}</td>
                    <td>${l.score}</td>
                </tr>
            `).join("");
    } catch (err) {
        leaderboardTableEl.innerHTML = `<tr><td colspan="3" class="text-danger">Lỗi tải kết quả: ${escapeHtml(err.message)}</td></tr>`;
    }
}

init();