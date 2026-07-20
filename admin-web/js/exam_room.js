import { stompConnect } from "./core/stomp_connect.js";
import { examService } from "./service/exam_service.js";
import { examSessionService } from "./service/exam_session_service.js";
import { antiCheatService } from "./service/anti_cheat_service.js";
import { HOST } from "./core/config.js";

// --- LẤY THÔNG TIN CẦN THIẾT ---
const token = localStorage.getItem("access_token");
const examId = localStorage.getItem("currentExamId");

// --- DOM ELEMENTS ---
const examNameEl = document.getElementById("examName");
const roomStateEl = document.getElementById("roomState");
const joinedCountEl = document.getElementById("joinedCount");
const participantListEl = document.getElementById("participantList");
const contentAreaEl = document.getElementById("contentArea");
const btnStart = document.getElementById("btnStart");
const btnNext = document.getElementById("btnNext");
const antiCheatListEl = document.getElementById("antiCheatList");
const bannedCountEl = document.getElementById("bannedCount");
const submittedListEl = document.getElementById("submittedList");
const submittedCountEl = document.getElementById("submittedCount");

if (!token || !examId) {
    alert("Thiếu token hoặc examId, vui lòng quay lại danh sách đề thi.");
    throw new Error("Thiếu token/examId");
}

// --- ESCAPE HTML: tránh nội dung người dùng nhập (vd "<table>") bị trình duyệt hiểu nhầm là thẻ HTML ---
function escapeHtml(text) {
    if (text === null || text === undefined) return "";
    return String(text)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

// --- NHÃN TRẠNG THÁI ---
const STATE_LABELS = {
    WAITING: { text: "Chờ diễn ra", cls: "bg-secondary" },
    ROOM_READY: { text: "Đã tạo phòng", cls: "bg-info text-dark" },
    PREVIEW: { text: "Xem trước câu hỏi", cls: "bg-warning text-dark" },
    SHOW_QUESTION: { text: "Đang làm bài", cls: "bg-primary" },
    SHOW_ANSWER: { text: "Hiện đáp án", cls: "bg-success" },
    FINISHED: { text: "Đã kết thúc", cls: "bg-dark" },
};

// --- NHÃN LOẠI CÂU HỎI ---
// MCQ_TEXT / MCQ_MEDIA -> Trắc nghiệm | ESSAY_TEXT / ESSAY_MEDIA -> Tự luận
// Hậu tố _MEDIA nghĩa là câu hỏi có kèm hình ảnh minh họa
const QUESTION_TYPE_LABELS = {
    MCQ_TEXT: { text: "Trắc nghiệm", cls: "bg-primary", hasMedia: false },
    MCQ_MEDIA: { text: "Trắc nghiệm", cls: "bg-primary", hasMedia: true },
    ESSAY_TEXT: { text: "Tự luận", cls: "bg-purple", hasMedia: false },
    ESSAY_MEDIA: { text: "Tự luận", cls: "bg-purple", hasMedia: true },
};

function getTypeInfo(type) {
    return QUESTION_TYPE_LABELS[type] || { text: type, cls: "bg-secondary", hasMedia: false };
}

const LEVEL_LABELS = {
    EASY: "Dễ",
    MEDIUM: "Trung bình",
    HARD: "Khó",
};

function getLevelLabel(level) {
    return LEVEL_LABELS[level] || level;
}

// --- NHÃN LOẠI VI PHẠM ANTI-CHEAT ---
const VIOLATION_TYPE_LABELS = {
    SCREENSHOT: { text: "Chụp màn hình", icon: "📸" },
    RECORD_START: { text: "Bắt đầu quay màn hình", icon: "🎥" },
    RECORD_STOP: { text: "Dừng quay màn hình", icon: "⏹️" },
    OUT_OF_FOCUS: { text: "Rời khỏi ứng dụng (thoáng qua)", icon: "👀" },
    LEAVE_APP: { text: "Rời khỏi ứng dụng", icon: "🚪" },
    BACK_APP: { text: "Quay lại ứng dụng", icon: "↩️" },
    PHONE_CALL: { text: "Nghe điện thoại", icon: "📞" },
};

function getViolationInfo(type) {
    return VIOLATION_TYPE_LABELS[type] || { text: type, icon: "⚠️" };
}

// Khớp với AntiCheatService.MAX_VIOLATIONS bên backend
const MAX_VIOLATIONS = 3;

// --- ĐIỀU KHIỂN 2 NÚT DỰA TRÊN STATE HIỆN TẠI ---
function updateButtonsForState(state) {
    // Chỉ bấm "Bắt đầu" được khi phòng đang ở trạng thái ROOM_READY
    btnStart.disabled = state !== "ROOM_READY";

    // Chỉ bấm "Câu tiếp theo" được khi đang hiện đáp án (đúng logic adminNextQuestion bên BE)
    btnNext.disabled = state !== "SHOW_ANSWER";
}

function setRoomState(state) {
    const info = STATE_LABELS[state] || { text: state, cls: "bg-secondary" };
    roomStateEl.className = `badge ${info.cls}`;
    roomStateEl.innerText = info.text;
    updateButtonsForState(state);
}

// --- COUNTDOWN TIMER DÙNG CHUNG ---
let countdownInterval = null;

function startCountdown(seconds, onTick, onEnd) {
    clearInterval(countdownInterval);
    let remain = seconds;
    onTick(remain);

    countdownInterval = setInterval(() => {
        remain -= 1;
        if (remain <= 0) {
            clearInterval(countdownInterval);
            onTick(0);
            onEnd?.();
            return;
        }
        onTick(remain);
    }, 1000);
}

// --- GHÉP ĐƯỜNG DẪN ẢNH TƯƠNG ĐỐI VỚI DOMAIN BACKEND ---
// Backend trả imageUrl dạng "/uploads/images/xxx.png" (relative), cần ghép với domain backend
function resolveImageUrl(url) {
    if (!url) return null;
    if (/^https?:\/\//i.test(url)) return url; // đã là URL đầy đủ, giữ nguyên
    return HOST + (url.startsWith("/") ? url : "/" + url);
}

// --- LƯU LẠI OPTIONS CÂU HIỆN TẠI (để hiện label lúc SHOW_ANSWER) ---
let currentOptions = [];

// --- RENDER CÁC LOẠI MÀN HÌNH TRONG contentArea ---

function renderRoomReady() {
    contentAreaEl.innerHTML = `<p class="text-muted">Phòng đã sẵn sàng, chờ admin bắt đầu...</p>`;
}

function renderPreview(data) {
    const typeInfo = getTypeInfo(data.type);

    contentAreaEl.innerHTML = `
        <div class="text-center py-4">
            <h5 class="text-muted mb-3">Câu ${data.index + 1}/${data.totalQuestions}</h5>

            <div class="d-flex justify-content-center gap-2 mb-3 flex-wrap">
                <span class="badge ${typeInfo.cls} fs-6">${escapeHtml(typeInfo.text)}</span>
                ${data.category ? `<span class="badge fs-6" style="background-color:#0d9488;">${escapeHtml(data.category)}</span>` : ""}
                <span class="badge bg-secondary fs-6">${escapeHtml(getLevelLabel(data.level))}</span>
                <span class="badge bg-dark fs-6">${data.score} điểm</span>
                ${typeInfo.hasMedia ? `<span class="badge bg-info text-dark fs-6">🖼️ Có hình minh họa</span>` : ""}
            </div>

            <p class="text-muted">Sẵn sàng trong</p>
            <div class="display-4 fw-bold text-warning" id="previewTimer">${data.duration}</div>
            <p class="text-muted">giây...</p>
        </div>
    `;
    startCountdown(data.duration, (s) => {
        const el = document.getElementById("previewTimer");
        if (el) el.innerText = s;
    });
}

function renderQuestion(payload) {
    const q = payload.questionData;
    currentOptions = q.options || [];

    let optionsHtml = "";
    if (currentOptions.length > 0) {
        const letters = ["A", "B", "C", "D", "E", "F"];
        optionsHtml = `
            <div class="row g-2 mt-2">
                ${currentOptions.map((o, i) => `
                    <div class="col-md-6">
                        <div class="border rounded p-2 h-100">
                            <span class="badge bg-secondary me-2">${o.label ?? letters[i]}</span>
                            ${escapeHtml(o.contentText)}
                            ${o.imageUrl ? `<br><img src="${resolveImageUrl(o.imageUrl)}" class="img-fluid mt-1" style="max-height:120px">` : ""}
                        </div>
                    </div>
                `).join("")}
            </div>
        `;
    }

    contentAreaEl.innerHTML = `
        <div class="d-flex justify-content-between align-items-center mb-2">
            <h5 class="mb-0">Câu ${payload.currentQuestionIndex + 1}/${payload.totalQuestions}</h5>
            <span class="badge bg-primary fs-6">⏱ <span id="questionTimer">${payload.duration}</span>s</span>
        </div>
        ${q.category ? `<span class="badge mb-2" style="background-color:#0d9488;">${escapeHtml(q.category)}</span>` : ""}
        <p class="fs-5">${escapeHtml(q.content)}</p>
        ${q.imageUrl ? `<img src="${resolveImageUrl(q.imageUrl)}" class="img-fluid mb-2 rounded" style="max-height:250px">` : ""}
        ${optionsHtml}
    `;

    startCountdown(payload.duration, (s) => {
        const el = document.getElementById("questionTimer");
        if (el) el.innerText = s;
    });
}

function renderFinish(data) {
    const rows = (data.leaderboard || [])
        .map(l => `
            <tr>
                <td>${l.rank}</td>
                <td>${escapeHtml(l.name)}</td>
                <td>${l.score}</td>
            </tr>
        `).join("");

    contentAreaEl.innerHTML = `
        <h5>Kỳ thi đã kết thúc</h5>
        <p>Tổng số câu hỏi: ${data.totalQuestions}</p>
        <table class="table table-striped mt-2">
            <thead><tr><th>Hạng</th><th>Thí sinh</th><th>Điểm</th></tr></thead>
            <tbody>${rows}</tbody>
        </table>
        <button class="btn btn-secondary mt-2" onclick="window.location.href='admin.html'">
            ⬅ Quay về màn hình chính
        </button>
    `;
}

function renderRoomUpdate(data) {
    joinedCountEl.innerText = `${data.joinedCount}/${data.totalParticipants}`;
    participantListEl.innerHTML = (data.participants || [])
        .map(p => `
            <li class="list-group-item">
                ${escapeHtml(p.fullName)} <span class="text-muted small">(${escapeHtml(p.className) || "N/A"})</span>
            </li>
        `).join("") || `<li class="list-group-item text-muted small">Chưa có thí sinh nào tham gia.</li>`;
}

// --- ANTI-CHEAT LOG ---
let antiCheatLogs = [];

// Tính lại violationCount/banned cho danh sách lịch sử (REST không trả kèm 2 field này).
// history: mảng trả từ API, sắp xếp mới nhất -> cũ nhất (theo backend: findByExamIdOrderByCreatedAtDesc)
function computeCountsForHistory(history) {
    const ascending = [...history].reverse(); // cũ nhất -> mới nhất
    const counters = {};
    const withCounts = ascending.map(log => {
        const uid = log.userId;
        counters[uid] = (counters[uid] || 0) + 1;
        return {
            ...log,
            violationCount: counters[uid],
            banned: counters[uid] >= MAX_VIOLATIONS,
        };
    });
    return withCounts.reverse(); // trả lại thứ tự mới nhất -> cũ nhất để hiển thị
}

function updateBannedCount() {
    const bannedUsers = new Set(
        antiCheatLogs.filter(l => l.banned).map(l => l.userId)
    );
    bannedCountEl.innerText = `${bannedUsers.size} bị cấm`;
}

function renderAntiCheatLog() {
    if (!antiCheatLogs || antiCheatLogs.length === 0) {
        antiCheatListEl.innerHTML = `<li class="list-group-item text-muted small">Chưa có vi phạm nào.</li>`;
        updateBannedCount();
        return;
    }

    antiCheatListEl.innerHTML = antiCheatLogs.map(log => {
        const info = getViolationInfo(log.type);
        const time = log.createdAt
            ? new Date(log.createdAt).toLocaleTimeString("vi-VN")
            : "";

        return `
            <li class="list-group-item d-flex justify-content-between align-items-center ${log.banned ? "list-group-item-danger" : ""}">
                <div>
                    <div>${info.icon} <b>${escapeHtml(log.fullName)}</b></div>
                    <div class="small text-muted">${escapeHtml(info.text)} • ${time}</div>
                </div>
                <div class="text-end">
                    <span class="badge ${log.banned ? "bg-danger" : "bg-secondary"}">
                        ${log.violationCount ?? "?"}/${MAX_VIOLATIONS}
                    </span>
                    ${log.banned ? `
                        <div class="badge bg-danger mt-1">Đã cấm thi</div>
                        <div class="mt-1">
                            <button class="btn btn-outline-success btn-sm" onclick="unbanFromRoom(${log.userId})">
                                ✅ Gỡ cấm
                            </button>
                        </div>
                    ` : ""}
                </div>
            </li>
        `;
    }).join("");

    updateBannedCount();
}

let submittedAnswers = new Map();

function resetSubmittedAnswers() {
    submittedAnswers = new Map();
    renderSubmittedList();
}

function getOptionLabel(optionId) {
    const opt = currentOptions.find(o => o.id === optionId);
    return opt ? `${opt.label ?? "?"}. ${opt.contentText}` : "(không rõ)";
}

function renderSubmittedList() {
    const items = [...submittedAnswers.values()]
        .sort((a, b) => new Date(a.answeredAt) - new Date(b.answeredAt));

    submittedCountEl.innerText = items.length;

    if (items.length === 0) {
        submittedListEl.innerHTML = `<li class="list-group-item text-muted small">Chưa có ai nộp bài.</li>`;
        return;
    }

    submittedListEl.innerHTML = items.map(a => {
        const answerDisplay = a.selectedOptionId != null
            ? escapeHtml(getOptionLabel(a.selectedOptionId))
            : (a.answerText ? escapeHtml(a.answerText) : "(bỏ trống)");

        return `
            <li class="list-group-item">
                <b>${escapeHtml(a.fullName)}</b>
                ${a.seatNumber != null ? `<span class="text-muted small">(chỗ ${a.seatNumber})</span>` : ""}
                <div class="small text-muted">${answerDisplay}</div>
            </li>
        `;
    }).join("");
}

function handleAdminSubmission(data) {
    submittedAnswers.set(data.userId, data);
    renderSubmittedList();
}

function handleAntiCheatMessage(log) {
    // log đã có sẵn violationCount + banned từ backend (AntiCheatResponse)
    antiCheatLogs = [log, ...antiCheatLogs];
    renderAntiCheatLog();
}

window.unbanFromRoom = async function (userId) {
    if (!confirm("Gỡ cấm thí sinh này để họ có thể tham gia lại phòng thi?")) return;

    try {
        await examSessionService.unbanParticipant(examId, userId);

        antiCheatLogs = antiCheatLogs.filter(log => log.userId !== userId);
        renderAntiCheatLog();

        alert("Đã gỡ cấm và xóa lịch sử vi phạm! Thí sinh cần tham gia lại phòng thi.");
    } catch (err) {
        alert(err.message);
    }
};

// --- XỬ LÝ MESSAGE TỪ WEBSOCKET (topic chính) ---
function handleMessage(message) {
    switch (message.type) {
        case "ROOM_READY":
            setRoomState("ROOM_READY");
            renderRoomReady();
            break;
        case "ROOM_UPDATE":
            renderRoomUpdate(message);
            break;
        case "PREVIEW":
            setRoomState("PREVIEW");
            renderPreview(message.data);
            break;
        case "SHOW_QUESTION":
            setRoomState("SHOW_QUESTION");
            resetSubmittedAnswers();
            renderQuestion(message);
            break;
        case "SHOW_ANSWER":
            setRoomState("SHOW_ANSWER");
            renderAnswer(message);
            break;
        case "FINISH":
            setRoomState("FINISHED");
            renderFinish(message);
            break;
        case "ANSWER_SUBMITTED":
            console.log(`${message.fullName} vừa nộp câu ${message.questionIndex + 1}`);
            break;
        case "RESET":
            setRoomState("WAITING");
            contentAreaEl.innerHTML = `<p class="text-muted">Đề thi đã được reset.</p>`;
            antiCheatLogs = [];
            renderAntiCheatLog();
            resetSubmittedAnswers();
            break;
        case "REGRADE":
            (message.seatResults || []).forEach(r => {
                const existing = submittedAnswers.get(r.userId);
                if (existing) {
                    existing.isCorrect = r.isCorrect;
                    submittedAnswers.set(r.userId, existing);
                }
            });
            renderSubmittedList();
            if (document.getElementById("regradeArea")) {
                renderRegradePanel(message.questionIndex);
            }
            break;
        default:
            console.warn("Không rõ loại message:", message);
    }
}

// --- REGRADE (chỉ áp dụng cho câu tự luận, lúc đang ở SHOW_ANSWER) ---
let regradePending = new Map(); // userId -> isCorrect (giá trị admin đang chỉnh, chưa lưu)

function renderAnswer(data) {
    const correctOption = currentOptions.find(o => o.id === data.correctOptionId);
    const isEssay = currentOptions.length === 0; // không có option => câu tự luận

    contentAreaEl.innerHTML = `
        <div class="text-center py-3">
            <h5 class="text-muted mb-3">Đáp án câu ${data.index + 1}</h5>
            <div class="alert alert-success d-inline-block px-4 py-3">
                ${correctOption
            ? `<span class="fs-5">✅ <b>${escapeHtml(correctOption.label)}. ${escapeHtml(correctOption.contentText)}</b></span>`
            : `<span class="fs-5">✅ Đáp án mẫu: <b>${escapeHtml(data.sampleAnswer) || "(không có)"}</b></span>`}
            </div>
        </div>
        ${isEssay ? `<div id="regradeArea" class="mt-3"></div>` : ""}
    `;

    if (isEssay) {
        regradePending = new Map();
        renderRegradePanel(data.index);
    }
}

function renderRegradePanel(questionIndex) {
    const area = document.getElementById("regradeArea");
    if (!area) return;

    const items = [...submittedAnswers.values()]
        .filter(a => a.questionIndex === questionIndex);

    if (items.length === 0) {
        area.innerHTML = `<p class="text-muted small">Chưa có ai nộp bài câu này.</p>`;
        return;
    }

    area.innerHTML = `
        <div class="text-start">
            <h6 class="text-muted">Chấm lại câu tự luận</h6>
            <ul class="list-group mb-2">
                ${items.map(a => {
        const current = regradePending.has(a.userId) ? regradePending.get(a.userId) : a.isCorrect;
        return `
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                            <div>
                                <b>${escapeHtml(a.fullName)}</b>
                                ${a.seatNumber != null ? `<span class="text-muted small">(chỗ ${a.seatNumber})</span>` : ""}
                                <div class="small text-muted">${escapeHtml(a.answerText) || "(bỏ trống)"}</div>
                            </div>
                            <div class="btn-group btn-group-sm" role="group">
                                <button type="button"
                                    class="btn ${current ? "btn-success" : "btn-outline-success"}"
                                    onclick="setRegradeValue(${a.userId}, true)">Đúng</button>
                                <button type="button"
                                    class="btn ${!current ? "btn-danger" : "btn-outline-danger"}"
                                    onclick="setRegradeValue(${a.userId}, false)">Sai</button>
                            </div>
                        </li>
                    `;
    }).join("")}
            </ul>
            <button class="btn btn-warning btn-sm" onclick="saveRegrade(${questionIndex})">
                💾 Lưu chấm lại
            </button>
        </div>
    `;
}

window.setRegradeValue = function (userId, isCorrect) {
    regradePending.set(userId, isCorrect);
    const answer = submittedAnswers.get(userId);
    if (answer) renderRegradePanel(answer.questionIndex);
};

window.saveRegrade = async function (questionIndex) {
    if (regradePending.size === 0) {
        alert("Bạn chưa thay đổi gì.");
        return;
    }

    const items = [...regradePending.entries()].map(([userId, isCorrect]) => ({
        userId,
        isCorrect,
    }));

    try {
        await examSessionService.regradeAnswers(examId, { questionIndex, items });
        regradePending = new Map();
        alert("Đã lưu chấm lại!");
    } catch (err) {
        alert(err.message);
    }
};

// --- KẾT NỐI WEBSOCKET ---
stompConnect.connect(token, () => {
    console.log("WS Ready");
    stompConnect.subscribe(`/topic/exam/${examId}`, handleMessage);
    // Anti-cheat dùng topic riêng, payload gửi thẳng AntiCheatResponse (không bọc {type, data})
    stompConnect.subscribe(`/topic/exam/${examId}/anti-cheat`, handleAntiCheatMessage);
    // Danh sách nộp bài dùng topic riêng cho admin, không lộ đáp án cho học sinh khác
    stompConnect.subscribe(`/topic/exam/${examId}/admin-submissions`, handleAdminSubmission);
});

// --- NÚT BẤM ADMIN ---
btnStart.addEventListener("click", async () => {
    try {
        btnStart.disabled = true;
        await examSessionService.startExam(examId);
    } catch (err) {
        alert(err.message);
        // Trạng thái thật có thể đã khác so với UI đang hiển thị (vd: đã RUNNING từ tab khác) ->
        // đồng bộ lại UI theo trạng thái thật từ server thay vì chỉ đơn giản mở lại nút.
        try {
            const session = await examSessionService.getSession(examId);
            setRoomState(session.state);
        } catch {
            btnStart.disabled = false;
        }
    }
});

btnNext.addEventListener("click", async () => {
    try {
        btnNext.disabled = true;
        await examSessionService.nextQuestion(examId);
    } catch (err) {
        alert(err.message);
        try {
            const session = await examSessionService.getSession(examId);
            setRoomState(session.state);
        } catch {
            btnNext.disabled = false;
        }
    }
});

// --- KHỞI TẠO ---
async function init() {
    // Lấy tên đề thi
    try {
        const exam = await examService.getDetail(examId);
        examNameEl.innerText = exam.name; // dùng innerText nên không cần escape
    } catch (err) {
        console.warn("Không tải được tên đề thi:", err.message);
    }

    // Tải lịch sử vi phạm anti-cheat
    try {
        const history = await antiCheatService.getViolations(examId);
        antiCheatLogs = computeCountsForHistory(history);
        renderAntiCheatLog();
    } catch (err) {
        console.warn("Không tải được log anti-cheat:", err.message);
        antiCheatListEl.innerHTML = `<li class="list-group-item text-muted small">Không tải được log.</li>`;
    }

    // Khôi phục trạng thái hiện tại (phòng khi reload trang giữa chừng)
    //
    // LƯU Ý QUAN TRỌNG: examSessionService.restore() gọi API dành cho HỌC SINH
    // (ExamSessionService.restoreExam() bên BE bắt buộc user hiện tại phải là
    // ExamParticipant của đề thi, nếu không sẽ ném PARTICIPANT_NOT_FOUND).
    // Admin không phải participant nên gọi restore() sẽ LUÔN LỖI.
    //
    // -> Dùng đúng API dành cho admin: adminRestore() (map tới
    // GET /exam-session/{examId}/admin-restore -> ExamSessionService.getAdminSessionDetail()),
    // logic giống hệt restoreExam() nhưng KHÔNG yêu cầu phải là participant.
    // Nhờ đó admin reload trang vẫn thấy lại đầy đủ nội dung câu hỏi/đáp án như học sinh.
    try {
        const restore = await examSessionService.adminRestore(examId);
        setRoomState(restore.state);

        if (restore.currentQuestion) {
            currentOptions = restore.currentQuestion.options || [];
        }

        switch (restore.state) {
            case "SHOW_QUESTION":
                if (restore.currentQuestion) {
                    renderQuestion({
                        currentQuestionIndex: restore.currentQuestionIndex,
                        totalQuestions: restore.totalQuestions,
                        questionData: restore.currentQuestion,
                        duration: restore.remainingSeconds,
                    });
                }
                break;

            case "SHOW_ANSWER":
                // Admin-restore không trả kèm đáp án đúng (correctOptionId/sampleAnswer),
                // nên chỉ hiện lại nội dung câu hỏi kèm ghi chú đang ở bước xem đáp án.
                if (restore.currentQuestion) {
                    renderQuestion({
                        currentQuestionIndex: restore.currentQuestionIndex,
                        totalQuestions: restore.totalQuestions,
                        questionData: restore.currentQuestion,
                        duration: 0,
                    });
                    contentAreaEl.insertAdjacentHTML("beforeend", `
                        <div class="alert alert-info mt-3 mb-0">
                            ℹ️ Đang ở bước hiện đáp án. Bấm "Câu tiếp theo" để tiếp tục.
                        </div>
                    `);
                }
                break;

            case "PREVIEW":
                // Admin-restore không trả kèm type/level/score/category của bước preview,
                // nên hiện tạm màn chờ chung, admin có thể bấm "Câu tiếp theo" khi timer thật đã chạy xong.
                contentAreaEl.innerHTML = `
                    <p class="text-muted text-center py-4">
                        Đang xem trước câu ${restore.currentQuestionIndex + 1}/${restore.totalQuestions}...
                    </p>
                `;
                break;

            case "FINISHED": {
                const leaderboard = await examSessionService.leaderboard(examId);
                renderFinish({ totalQuestions: restore.totalQuestions, leaderboard });
                break;
            }

            case "ROOM_READY":
                renderRoomReady();
                break;

            case "WAITING":
                contentAreaEl.innerHTML = `
                    <p class="text-muted">
                        Đề thi chưa được tạo phòng. Vui lòng quay lại danh sách đề thi và bấm "Tạo phòng".
                    </p>
                `;
                break;

            default:
                contentAreaEl.innerHTML = `<p class="text-muted">Trạng thái: ${escapeHtml(restore.state)}</p>`;
        }
    } catch (err) {
        console.warn("Không khôi phục được trạng thái:", err.message);
        contentAreaEl.innerHTML = `<p class="text-danger">Không tải được trạng thái phòng thi. Vui lòng tải lại trang.</p>`;
    }
}

init();