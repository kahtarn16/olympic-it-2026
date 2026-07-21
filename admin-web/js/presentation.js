import { stompConnect } from "./core/stomp_connect.js";
import { examService } from "./service/exam_service.js";
import { examSessionService } from "./service/exam_session_service.js";
import { HOST } from "./core/config.js";

// --- LẤY THÔNG TIN CẦN THIẾT ---
// Màn trình chiếu chạy trên máy admin (dùng chung token + currentExamId đã lưu
// khi admin bấm "Tạo phòng" / "Tham gia phòng" ở admin.html).
const token = localStorage.getItem("access_token");
const examId = localStorage.getItem("currentExamId");

// --- DOM ELEMENTS ---
const examNameEl = document.getElementById("examName");
const roomStateEl = document.getElementById("roomState");
const contentAreaEl = document.getElementById("contentArea");
const rightPanelTitleEl = document.getElementById("rightPanelTitle");
const rightPanelAreaEl = document.getElementById("rightPanelArea");
const joinedCountEl = document.getElementById("joinedCount");

if (!token || !examId) {
    alert("Thiếu token hoặc examId, vui lòng mở màn trình chiếu từ danh sách đề thi.");
    throw new Error("Thiếu token/examId");
}

// --- ESCAPE HTML ---
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
    WAITING: { text: "Chờ tạo phòng", cls: "bg-secondary" },
    ROOM_READY: { text: "Đã tạo phòng", cls: "bg-info text-dark" },
    PREVIEW: { text: "Xem trước câu hỏi", cls: "bg-warning text-dark" },
    SHOW_QUESTION: { text: "Đang làm bài", cls: "bg-primary" },
    SHOW_ANSWER: { text: "Hiện đáp án", cls: "bg-success" },
    FINISHED: { text: "Đã kết thúc", cls: "bg-dark" },
};

const QUESTION_TYPE_LABELS = {
    MCQ_TEXT: { text: "Trắc nghiệm", cls: "bg-primary", hasMedia: false },
    MCQ_MEDIA: { text: "Trắc nghiệm", cls: "bg-primary", hasMedia: true },
    ESSAY_TEXT: { text: "Tự luận", cls: "bg-purple", hasMedia: false },
    ESSAY_MEDIA: { text: "Tự luận", cls: "bg-purple", hasMedia: true },
};

function getTypeInfo(type) {
    return QUESTION_TYPE_LABELS[type] || { text: type, cls: "bg-secondary", hasMedia: false };
}

const LEVEL_LABELS = { EASY: "Dễ", MEDIUM: "Trung bình", HARD: "Khó" };

function getLevelLabel(level) {
    return LEVEL_LABELS[level] || level;
}

function setRoomState(state) {
    const info = STATE_LABELS[state] || { text: state, cls: "bg-secondary" };
    roomStateEl.className = `badge pm-state-pill fs-6 ${info.cls}`;
    roomStateEl.innerText = info.text;
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

function resolveImageUrl(url) {
    if (!url) return null;
    if (/^https?:\/\//i.test(url)) return url;
    return HOST + (url.startsWith("/") ? url : "/" + url);
}

// Cập nhật mặt đồng hồ đếm ngược (dùng chung cho preview & câu hỏi)
function paintClock(el, seconds, urgentThreshold = 5) {
    if (!el) return;
    el.innerText = seconds;
    el.classList.toggle("pm-clock-urgent", seconds > 0 && seconds <= urgentThreshold);
}

let currentOptions = [];

// ==========================================================
// STATE CHO SƠ ĐỒ CHỖ NGỒI
// ==========================================================
// Danh sách toàn bộ thí sinh trong đề (userId, fullName, className, seatNumber, status)
let allParticipants = [];
// userId đang bị BANNED -> đánh dấu X bất kể đang ở giai đoạn nào
let bannedUserIds = new Set();
// userId đã nộp bài cho câu hiện tại -> reset mỗi khi sang câu mới (PREVIEW mới)
let submittedUserIds = new Set();
// Giai đoạn hiển thị sơ đồ ghế hiện tại: "idle" (trước khi nộp) | "answer" (đã có đáp án)
let seatStage = "idle";
// Kết quả đúng/sai theo ghế của câu vừa hiện đáp án (từ payload SHOW_ANSWER)
let lastSeatResults = null;

// Lấy lại toàn bộ danh sách thí sinh + trạng thái BANNED mới nhất từ server
async function refreshParticipants() {
    try {
        const participants = await examService.getExamParticipants(examId);
        allParticipants = participants || [];
        bannedUserIds = new Set(
            allParticipants.filter(p => p.status === "BANNED").map(p => p.userId)
        );
    } catch (err) {
        console.warn("Không tải được danh sách thí sinh:", err.message);
    }
}

// ==========================================================
// BÊN TRÁI: NỘI DUNG CHÍNH
// ==========================================================

function renderWaiting() {
    contentAreaEl.innerHTML = `
        <div class="text-center py-5">
            <div class="spinner-border mb-3" style="color: var(--pm-teal);" role="status"></div>
            <p class="text-muted fs-5 mb-0">Đang chờ quản trị viên tạo phòng thi...</p>
        </div>
    `;
}

function renderRoomReady() {
    contentAreaEl.innerHTML = `
        <div class="text-center py-5">
            <p class="text-muted fs-5 mb-0">Phòng đã sẵn sàng, chờ quản trị viên bắt đầu...</p>
        </div>
    `;
}

function renderPreview(data) {
    const typeInfo = getTypeInfo(data.type);

    contentAreaEl.innerHTML = `
        <div class="text-center py-3">
            <p class="pm-question-index mb-3">Câu ${data.index + 1}/${data.totalQuestions}</p>

            <div class="pm-meta-row">
                <span class="badge ${typeInfo.cls}">${escapeHtml(typeInfo.text)}</span>
                ${data.category ? `<span class="badge" style="background-color:#0d9488;">${escapeHtml(data.category)}</span>` : ""}
                <span class="badge bg-secondary">${escapeHtml(getLevelLabel(data.level))}</span>
                <span class="badge bg-dark">${data.score} điểm</span>
                ${typeInfo.hasMedia ? `<span class="badge bg-info text-dark">🖼️ Có hình minh họa</span>` : ""}
            </div>

            <div class="pm-clock-wrap">
                <span class="pm-clock-label">Sẵn sàng trong</span>
                <div class="pm-clock" id="previewTimer">${data.duration}</div>
                <span class="pm-clock-label">giây</span>
            </div>
        </div>
    `;
    startCountdown(data.duration, (s) => {
        paintClock(document.getElementById("previewTimer"), s);
    });

    // Sang câu mới -> reset danh sách đã nộp, chuyển sơ đồ ghế về trạng thái "chưa nộp" (đen)
    submittedUserIds = new Set();
    lastSeatResults = null;
    seatStage = "idle";
    renderSeatGrid();
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
                        <div class="pm-option">
                            <span class="badge bg-secondary me-2">${o.label ?? letters[i]}</span>
                            ${escapeHtml(o.contentText)}
                            ${o.imageUrl ? `<br><img src="${resolveImageUrl(o.imageUrl)}" class="img-fluid mt-1 rounded" style="max-height:120px">` : ""}
                        </div>
                    </div>
                `).join("")}
            </div>
        `;
    }

    contentAreaEl.innerHTML = `
        <div class="d-flex justify-content-between align-items-center mb-2">
            <h5 class="mb-0">Câu ${payload.currentQuestionIndex + 1}/${payload.totalQuestions}</h5>
            <span class="pm-timer-chip">⏱ <span id="questionTimer">${payload.duration}</span>s</span>
        </div>
        ${q.category ? `<span class="badge mb-2" style="background-color:#0d9488;">${escapeHtml(q.category)}</span>` : ""}
        <p class="pm-question-text">${escapeHtml(q.content)}</p>
        ${q.imageUrl ? `<img src="${resolveImageUrl(q.imageUrl)}" class="img-fluid mb-2 rounded" style="max-height:250px">` : ""}
        ${q.videoUrl ? `<video src="${resolveImageUrl(q.videoUrl)}" class="img-fluid mb-2 rounded" style="max-height:250px" controls></video>` : ""}
        ${optionsHtml}
    `;

    startCountdown(payload.duration, (s) => {
        const el = document.getElementById("questionTimer");
        if (el) el.innerText = s;
    });

    seatStage = "idle";
    renderSeatGrid();
}

function renderAnswer(data) {
    const correctOption = currentOptions.find(o => o.id === data.correctOptionId);

    contentAreaEl.innerHTML = `
        <div class="text-center py-3">
            <p class="pm-question-index mb-3">Đáp án câu ${data.index + 1}</p>
            <div class="pm-answer-banner">
                ${correctOption
            ? `<span>✅ <b>${escapeHtml(correctOption.label)}. ${escapeHtml(correctOption.contentText)}</b></span>`
            : `<span>✅ Đáp án mẫu: <b>${escapeHtml(data.sampleAnswer) || "(không có)"}</b></span>`}
            </div>
        </div>
    `;

    lastSeatResults = data.seatResults || [];
    seatStage = "answer";
    renderSeatGrid();
}

function renderFinish(data) {
    contentAreaEl.innerHTML = `
        <div class="text-center py-4">
            <h5 class="mb-2">🎉 Kỳ thi đã kết thúc</h5>
            <p class="text-muted mb-0">Tổng số câu hỏi: ${data.totalQuestions}</p>
            <p class="text-muted small mt-3">Bảng xếp hạng đầy đủ ở bên phải</p>
        </div>
    `;

    rightPanelTitleEl.innerText = "Bảng xếp hạng";
    joinedCountEl.classList.add("d-none");
    rightPanelAreaEl.innerHTML = `
        ${(data.leaderboard || []).map(l => `
            <div class="pm-leaderboard-item ${l.rank <= 3 ? "pm-top3" : ""}">
                <span class="pm-rank">${l.rank <= 3 ? "🏆" : l.rank}</span>
                <span class="pm-name">${escapeHtml(l.name)}</span>
                <span class="pm-joined-pill">${l.score} điểm</span>
            </div>
        `).join("") || `<p class="text-muted small">Chưa có dữ liệu</p>`}
    `;
}

// ==========================================================
// BÊN PHẢI: SƠ ĐỒ CHỖ NGỒI (dùng xuyên suốt WAITING -> FINISHED, trừ lúc FINISHED đổi qua bảng xếp hạng)
// ==========================================================

function seatClassFor(userId, seatEntry) {
    // Bị cấm thi -> luôn đánh dấu X, bất kể đang ở giai đoạn nào
    if (bannedUserIds.has(userId)) return "seat-banned";

    if (seatStage === "answer") {
        if (!seatEntry || !seatEntry.answered) return "seat-pending";
        return seatEntry.isCorrect ? "seat-correct" : "seat-wrong";
    }

    // seatStage === "idle": đen (chưa nộp) / trắng (đã nộp)
    return submittedUserIds.has(userId) ? "seat-submitted" : "seat-idle";
}

function renderSeatGrid() {
    rightPanelTitleEl.innerText = seatStage === "answer" ? "Sơ đồ chỗ ngồi - Kết quả" : "Sơ đồ chỗ ngồi";
    joinedCountEl.classList.add("d-none");

    const seated = allParticipants.filter(p => p.seatNumber !== null && p.seatNumber !== undefined);

    if (seated.length === 0) {
        rightPanelAreaEl.innerHTML = `<p class="text-muted small">Chưa có thí sinh nào được gán số ghế.</p>`;
        return;
    }

    const seatResultByUserId = new Map((lastSeatResults || []).map(s => [s.userId, s]));
    const sorted = [...seated].sort((a, b) => a.seatNumber - b.seatNumber);

    rightPanelAreaEl.innerHTML = `
        <div class="d-flex flex-wrap gap-2">
            ${sorted.map(p => {
        const cls = seatClassFor(p.userId, seatResultByUserId.get(p.userId));
        const content = cls === "seat-banned" ? "✕" : p.seatNumber;
        return `
                    <div class="seat-box ${cls}" title="${escapeHtml(p.fullName)}">
                        ${content}
                    </div>
                `;
    }).join("")}
        </div>
        <div class="pm-legend">
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-idle"></span> Chưa nộp bài</span>
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-submitted"></span> Đã nộp bài</span>
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-correct"></span> Đúng</span>
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-wrong"></span> Sai</span>
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-pending"></span> Không trả lời</span>
            <span class="pm-legend-item"><span class="pm-legend-swatch seat-banned"></span> Bị cấm thi</span>
        </div>
    `;
}

function renderRoomUpdate(data) {
    // ROOM_UPDATE bắn ra cả lúc unban -> nhân tiện đồng bộ lại toàn bộ danh sách + trạng thái BANNED
    refreshParticipants().then(renderSeatGrid);

    joinedCountEl.classList.remove("d-none");
    joinedCountEl.innerText = `${data.joinedCount}/${data.totalParticipants}`;
}

// ==========================================================
// XỬ LÝ MESSAGE TỪ WEBSOCKET
// ==========================================================

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
        case "RESET":
            setRoomState("WAITING");
            renderWaiting();
            submittedUserIds = new Set();
            lastSeatResults = null;
            seatStage = "idle";
            refreshParticipants().then(renderSeatGrid);
            break;
        case "ANSWER_SUBMITTED":
            // Đánh dấu ghế của thí sinh vừa nộp bài -> chuyển từ đen sang trắng ngay lập tức
            submittedUserIds.add(message.userId);
            if (seatStage === "idle") renderSeatGrid();
            break;
        default:
            console.warn("Không rõ loại message:", message);
    }
}

// --- KẾT NỐI WEBSOCKET ---
stompConnect.connect(token, () => {
    console.log("WS Ready (presentation)");
    stompConnect.subscribe(`/topic/exam/${examId}`, handleMessage);
});

// --- KHỞI TẠO ---
async function init() {
    try {
        const exam = await examService.getDetail(examId);
        examNameEl.innerText = exam.name;
    } catch (err) {
        console.warn("Không tải được tên đề thi:", err.message);
    }

    await refreshParticipants();

    try {
        const restore = await examSessionService.adminRestore(examId);
        setRoomState(restore.state);

        if (restore.currentQuestion) {
            currentOptions = restore.currentQuestion.options || [];
        }

        switch (restore.state) {
            case "WAITING":
                renderWaiting();
                seatStage = "idle";
                renderSeatGrid();
                break;

            case "ROOM_READY":
                renderRoomReady();
                seatStage = "idle";
                renderSeatGrid();
                break;

            case "PREVIEW":
                contentAreaEl.innerHTML = `
                    <p class="text-muted text-center py-4">
                        Đang xem trước câu ${restore.currentQuestionIndex + 1}/${restore.totalQuestions}...
                    </p>
                `;
                seatStage = "idle";
                renderSeatGrid();
                break;

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
                if (restore.currentQuestion) {
                    renderQuestion({
                        currentQuestionIndex: restore.currentQuestionIndex,
                        totalQuestions: restore.totalQuestions,
                        questionData: restore.currentQuestion,
                        duration: 0,
                    });
                    contentAreaEl.insertAdjacentHTML("beforeend", `
                        <div class="alert alert-info mt-3 mb-0">
                            ℹ️ Đang ở bước hiện đáp án.
                        </div>
                    `);
                }
                seatStage = "idle";
                renderSeatGrid();
                break;

            case "FINISHED": {
                const leaderboard = await examSessionService.leaderboard(examId);
                renderFinish({ totalQuestions: restore.totalQuestions, leaderboard });
                break;
            }

            default:
                renderWaiting();
                seatStage = "idle";
                renderSeatGrid();
        }
    } catch (err) {
        console.warn("Không khôi phục được trạng thái:", err.message);
        contentAreaEl.innerHTML = `<p class="text-danger">Không tải được trạng thái phòng thi. Vui lòng tải lại trang.</p>`;
    }
}

init();