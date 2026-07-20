import { examService } from "./service/exam_service.js";
import { questionService } from "./service/question_service.js";
import { studentService } from "./service/student_service.js";
import { examSessionService } from "./service/exam_session_service.js";
import { categoryService } from "./service/category_service.js";
// ⚠️ Sửa lại đúng tên file service quản lý lớp bạn đang có nếu khác đường dẫn này
import { classesService } from "./service/classes_service.js";

// DOM Elements cho Form Đề thi
const examName = document.getElementById("examName");
const btnSubmit = document.getElementById("btnSubmit");
const btnCancel = document.getElementById("btnCancel");
const formTitle = document.getElementById("formTitle");
const btnOpenPresentation = document.getElementById("btnOpenPresentation");

// DOM Elements cho Tìm kiếm
const keywordInput = document.getElementById("keywordInput");
const btnSearch = document.getElementById("btnSearch");

// DOM Elements cho Bảng danh sách
const table = document.getElementById("examTable");
const paginationInfo = document.getElementById("paginationInfo");
const btnPrev = document.getElementById("btnPrev");
const btnNext = document.getElementById("btnNext");
const currentPageNum = document.getElementById("currentPageNum");

// DOM Elements cho Khu vực Quản lý câu hỏi + thí sinh
const managePanel = document.getElementById("managePanel");
const manageExamName = document.getElementById("manageExamName");
const manageExamStatus = document.getElementById("manageExamStatus");
const btnCloseManage = document.getElementById("btnCloseManage");
const examActionArea = document.getElementById("examActionArea");

const examQuestionList = document.getElementById("examQuestionList");
const questionSelect = document.getElementById("questionSelect");
const btnAddQuestion = document.getElementById("btnAddQuestion");
// Bộ lọc câu hỏi
const questionCategoryFilter = document.getElementById("questionCategoryFilter");
const questionLevelFilter = document.getElementById("questionLevelFilter");

const examParticipantList = document.getElementById("examParticipantList");
const participantSelect = document.getElementById("participantSelect");
const btnAddParticipant = document.getElementById("btnAddParticipant");
// Bộ lọc thí sinh
const participantClassFilter = document.getElementById("participantClassFilter");

// Nhãn ngắn cho độ khó hiển thị trong dropdown câu hỏi
const LEVEL_LABEL_SHORT = { EASY: "Dễ", MEDIUM: "TB", HARD: "Khó" };

// --- STATE QUẢN LÝ ỨNG DỤNG ---
let editId = null;
let currentPage = 0;
const pageSize = 10;
let totalPages = 1;
let currentKeyword = "";

let managingExamId = null; // ID của đề thi đang mở khu vực Quản lý
let currentExamQuestions = []; // Danh sách câu hỏi hiện có trong đề đang quản lý (để kiểm tra STT)
let scheduleCountdownInterval = null;

// Nhãn trạng thái tiếng Việt cho ExamStatus (WAITING / RUNNING / FINISHED)
const STATUS_LABELS = {
    WAITING: { text: "Chờ diễn ra", cls: "bg-secondary" },
    RUNNING: { text: "Đang diễn ra", cls: "bg-warning text-dark" },
    FINISHED: { text: "Đã kết thúc", cls: "bg-success" },
    ROOM_READY: { text: "Đã tạo phòng", cls: "bg-info text-dark" },
};

function statusBadge(status) {
    const info = STATUS_LABELS[status] || { text: status || "N/A", cls: "bg-secondary" };
    return `<span class="badge ${info.cls}">${info.text}</span>`;
}

function renderExamActions(exam) {

    let html = "";

    switch (exam.status) {

        case "WAITING":
            html = `
        <button class="btn btn-success" onclick="createRoom(${exam.id})">
            🟢 Tạo phòng ngay
        </button>

        ${exam.scheduledStartAt ? `
            <div class="alert alert-info mt-2 py-2 px-3 mb-0 d-flex justify-content-between align-items-center">
                <div>
                    <div class="small">Tự động bắt đầu lúc: <b>${new Date(exam.scheduledStartAt).toLocaleString("vi-VN")}</b></div>
                    <div class="fw-bold text-primary" id="countdownDisplay">Đang tính...</div>
                </div>
                <button class="btn btn-outline-danger btn-sm" onclick="cancelSchedule(${exam.id})">
                    Hủy hẹn giờ
                </button>
            </div>
        ` : `
            <div class="input-group input-group-sm mt-2" style="max-width: 320px;">
                <input type="datetime-local" id="scheduleInput_${exam.id}" class="form-control">
                <button class="btn btn-outline-primary" onclick="scheduleAutoStart(${exam.id})">
                    ⏰ Hẹn giờ tự động
                </button>
            </div>
        `}
    `;
            break;

        case "ROOM_READY":
            html = `
        <button class="btn btn-primary"
            onclick="connectRoom(${exam.id})">
            🔵 Tham gia phòng
        </button>
    `;
            break;

        case "RUNNING":
            html = `
        <button class="btn btn-warning"
            onclick="connectRoom(${exam.id})">
            🔄 Tham gia lại
        </button>
    `;
            break;

        case "FINISHED":
            html = `
        <button class="btn btn-info text-white"
            onclick="viewResult(${exam.id})">
            📊 Kết quả
        </button>

        <button class="btn btn-danger"
            onclick="restartExam(${exam.id})">
            🔄 Thi lại
        </button>
    `;
            break;
        default:
            html = "";
    }

    examActionArea.innerHTML = html;
}

function startScheduleCountdown(targetTimeStr) {
    clearInterval(scheduleCountdownInterval);

    const targetTime = new Date(targetTimeStr).getTime();
    const el = document.getElementById("countdownDisplay");
    if (!el) return;

    function tick() {
        const el = document.getElementById("countdownDisplay");
        if (!el) {
            clearInterval(scheduleCountdownInterval);
            return;
        }

        const now = Date.now();
        const diff = targetTime - now;

        if (diff <= 0) {
            el.innerText = "Đang tự động tạo phòng...";
            clearInterval(scheduleCountdownInterval);
            return;
        }

        const totalSeconds = Math.floor(diff / 1000);
        const h = Math.floor(totalSeconds / 3600);
        const m = Math.floor((totalSeconds % 3600) / 60);
        const s = totalSeconds % 60;

        const parts = [];
        if (h > 0) parts.push(`${h}h`);
        parts.push(`${String(m).padStart(2, "0")}m`);
        parts.push(`${String(s).padStart(2, "0")}s`);

        el.innerText = `Còn lại: ${parts.join(" ")}`;
    }

    tick();
    scheduleCountdownInterval = setInterval(tick, 1000);
}

window.scheduleAutoStart = async function (examId) {
    const input = document.getElementById(`scheduleInput_${examId}`);
    if (!input || !input.value) {
        alert("Vui lòng chọn thời gian!");
        return;
    }

    try {
        await examSessionService.scheduleAutoStart(examId, input.value);
        alert("Đã hẹn giờ tự động tạo phòng và bắt đầu thi!");
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

window.cancelSchedule = async function (examId) {
    if (!confirm("Hủy lịch tự động của đề thi này?")) return;

    try {
        await examSessionService.cancelSchedule(examId);
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

window.restartExam = async function (examId) {

    if (!confirm("Bạn có chắc muốn thi lại?")) {
        return;
    }

    try {

        await examSessionService.reset(examId);

        alert("Đã reset đề thi, có thể tạo phòng lại.");

        // Nếu đang mở đúng panel quản lý của đề này thì refresh tại chỗ
        if (managingExamId === examId) {
            await refreshManagePanel();
        }

        // Cập nhật lại bảng danh sách đề thi (status đã đổi về WAITING)
        await loadExams();

    } catch (err) {
        alert(err.message);
    }
};

window.createRoom = async function (examId) {

    try {

        await examSessionService.createRoom(examId);

        localStorage.setItem("currentExamId", examId);

        window.location.href = "exam_room.html";

    } catch (err) {
        alert(err.message);
    }
};

window.connectRoom = async function (examId) {

    localStorage.setItem("currentExamId", examId);

    window.location.href = "exam_room.html";

};

window.viewResult = function (examId) {
    localStorage.setItem("currentExamId", examId);
    window.location.href = "resuilt.html";
};

// --- LẤY ID ADMIN ĐANG ĐĂNG NHẬP ---
// TODO: Thay bằng cách lấy userId thật của bạn (vd: decode JWT, hoặc đọc từ localStorage sau khi login).
function getCurrentAdminId() {
    const id = localStorage.getItem("user_id");
    if (!id) {
        alert("Không xác định được tài khoản admin hiện tại...");
        return null;
    }
    return parseInt(id);
}

// --- TẢI VÀ RENDER DANH SÁCH ĐỀ THI ---
async function loadExams() {
    const result = await examService.getAll(currentPage, pageSize, currentKeyword || undefined);

    // Giả định PageResponse trả về { data: [...], totalElements, totalPages, page, size }
    const items = result.data || [];

    table.innerHTML = "";
    items.forEach(e => {
        table.innerHTML += `
            <tr>
                <td>${e.id}</td>
                <td class="text-start">${e.name}</td>
                <td>${statusBadge(e.status)}</td>
                <td>${e.createdBy || "N/A"}</td>
                <td>${e.createdAt ? new Date(e.createdAt).toLocaleString("vi-VN") : ""}</td>
                <td>
                    <button class="btn btn-info btn-sm text-white me-1" onclick="manageExam(${e.id})">Quản lý</button>
                    <button class="btn btn-warning btn-sm me-1" onclick="editExam(${e.id})">Sửa</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteExam(${e.id})">Xóa</button>
                </td>
            </tr>
        `;
    });

    totalPages = result.totalPages || 1;
    currentPageNum.innerText = currentPage + 1;
    paginationInfo.innerText = `Tổng số đề thi: ${result.totalElements ?? items.length} (Trang ${currentPage + 1}/${totalPages})`;

    btnPrev.classList.toggle("disabled", currentPage === 0);
    btnNext.classList.toggle("disabled", currentPage >= totalPages - 1);
}

btnPrev.addEventListener("click", () => { if (currentPage > 0) { currentPage--; loadExams(); } });
btnNext.addEventListener("click", () => { if (currentPage < totalPages - 1) { currentPage++; loadExams(); } });

btnSearch.addEventListener("click", () => {
    currentKeyword = keywordInput.value.trim();
    currentPage = 0;
    loadExams();
});
keywordInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") btnSearch.click();
});

btnOpenPresentation.addEventListener("click", () => {
    if (!managingExamId) return;
    localStorage.setItem("currentExamId", managingExamId);

    window.open("presentation.html", "_blank");
});

// --- GỬI FORM (CREATE / UPDATE) ĐỀ THI ---
btnSubmit.addEventListener("click", async () => {
    if (!examName.value.trim()) {
        alert("Vui lòng nhập tên đề thi!");
        return;
    }

    try {
        if (editId) {
            // UpdateExamRequest: { name }
            const request = {
                name: examName.value.trim(),
            };
            await examService.update(editId, request);
            alert("Cập nhật đề thi thành công!");
        } else {
            const createdById = getCurrentAdminId();
            if (!createdById) return;

            // CreateExamRequest: { name, createdById }
            const request = {
                name: examName.value.trim(),
                createdById: createdById,
            };
            await examService.create(request);
            alert("Thêm đề thi thành công!");
        }
        clearForm();
        await loadExams();
    } catch (error) {
        alert(error.message);
    }
});

// --- SỬA ĐỀ THI ---
window.editExam = async function (id) {
    try {
        const e = await examService.getDetail(id);
        editId = id;
        formTitle.innerText = `Chỉnh sửa đề thi [ID: ${id}]`;
        btnCancel.classList.remove("d-none");
        btnSubmit.innerText = "Cập nhật";

        examName.value = e.name;

        window.scrollTo({ top: 0, behavior: "smooth" });
    } catch (err) {
        alert("Lỗi tải chi tiết: " + err.message);
    }
};

// --- XÓA ĐỀ THI ---
window.deleteExam = async function (id) {
    if (confirm("Hành động này sẽ xóa vĩnh viễn đề thi, gồm cả câu hỏi và thí sinh liên quan. Tiếp tục?")) {
        try {
            await examService.delete(id);
            alert("Xóa thành công!");
            if (managingExamId === id) closeManagePanel();
            await loadExams();
        } catch (err) {
            alert(err.message);
        }
    }
};

function clearForm() {
    editId = null;
    formTitle.innerText = "Thêm đề thi mới";
    btnCancel.classList.add("d-none");
    btnSubmit.innerText = "Thêm đề thi";

    examName.value = "";
}
btnCancel.addEventListener("click", clearForm);

// ==========================================================
// KHU VỰC QUẢN LÝ CÂU HỎI + THÍ SINH CỦA 1 ĐỀ THI
// ==========================================================

window.manageExam = async function (id) {
    managingExamId = id;
    managePanel.classList.remove("d-none");

    // Đổ dữ liệu cho 2 dropdown bộ lọc trước
    await loadCategoryFilterOptions();
    await loadClassFilterOptions();

    await loadQuestionOptionsForSelect(); // đổ dropdown danh sách câu hỏi (theo bộ lọc hiện tại) để chọn thêm vào đề
    await loadUserOptionsForSelect();     // đổ dropdown danh sách sinh viên (theo bộ lọc hiện tại) để chọn thí sinh thêm vào đề
    await refreshManagePanel();
    managePanel.scrollIntoView({ behavior: "smooth" });
};

btnCloseManage.addEventListener("click", closeManagePanel);

function closeManagePanel() {
    managingExamId = null;
    managePanel.classList.add("d-none");
    examQuestionList.innerHTML = "";
    examParticipantList.innerHTML = "";
    clearInterval(scheduleCountdownInterval);
}

async function refreshManagePanel() {
    if (!managingExamId) return;

    const detail = await examService.getDetail(managingExamId);

    manageExamName.innerText = detail.name;
    manageExamStatus.outerHTML = statusBadge(detail.status).replace("<span", `<span id="manageExamStatus"`);
    renderExamActions(detail);

    if (detail.scheduledStartAt) {
        startScheduleCountdown(detail.scheduledStartAt);
    }

    // Danh sách câu hỏi trong đề
    const questions = detail.questions || [];
    currentExamQuestions = questions; // lưu lại để kiểm tra STT khi thêm câu hỏi mới
    examQuestionList.innerHTML = "";
    if (questions.length === 0) {
        examQuestionList.innerHTML = `<li class="list-group-item text-muted small">Chưa có câu hỏi nào trong đề.</li>`;
    }
    questions.forEach(item => {
        // Giả định field: item.orderIndex và item.question (object chi tiết câu hỏi)
        const q = item.question || {};
        const preview = (q.content || "").slice(0, 60);
        examQuestionList.innerHTML += `
            <li class="list-group-item d-flex justify-content-between align-items-center">
                <span><span class="badge bg-primary me-2">#${item.orderIndex}</span>${preview}${(q.content || "").length > 60 ? "..." : ""}</span>
                <button class="btn btn-outline-danger btn-sm" onclick="removeQuestionFromExam(${q.id})">Xóa</button>
            </li>
        `;
    });

    // Danh sách thí sinh trong đề
    const participants = detail.participants || [];
    examParticipantList.innerHTML = "";
    if (participants.length === 0) {
        examParticipantList.innerHTML = `<li class="list-group-item text-muted small">Chưa có thí sinh nào.</li>`;
    }
    participants.forEach(p => {
        const isBanned = p.status === "BANNED";

        examParticipantList.innerHTML += `
        <li class="list-group-item d-flex justify-content-between align-items-center ${isBanned ? "list-group-item-danger" : ""}">
            <span>
                <span class="badge bg-dark me-1">Ghế ${p.seatNumber ?? "?"}</span>
                ${p.fullName} <span class="text-muted small">(${p.className || "N/A"})</span>
                — <span class="badge ${isBanned ? "bg-danger" : "bg-secondary"}">${p.status}</span>
            </span>
            <div class="d-flex gap-1">
                <button class="btn btn-outline-secondary btn-sm" onclick="editSeat(${p.userId}, ${p.seatNumber ?? "null"})">Đổi ghế</button>
                ${isBanned
                ? `<button class="btn btn-outline-success btn-sm" onclick="unbanParticipant(${p.userId})">Gỡ cấm</button>`
                : ""}
                <button class="btn btn-outline-danger btn-sm" onclick="removeParticipantFromExam(${p.userId})">Xóa</button>
            </div>
        </li>
    `;
    });
}

// ---------- BỘ LỌC CÂU HỎI (danh mục + độ khó) ----------

// Đổ danh sách danh mục vào dropdown lọc câu hỏi
async function loadCategoryFilterOptions() {
    try {
        const categories = await categoryService.getAll();
        questionCategoryFilter.innerHTML =
            `<option value="">-- Tất cả danh mục --</option>` +
            (categories || []).map(c => `<option value="${c.id}">${c.name}</option>`).join("");
    } catch (err) {
        console.warn("Không tải được danh mục:", err.message);
    }
}

// Đổ danh sách câu hỏi (lọc theo danh mục + độ khó đang chọn) vào dropdown chọn để thêm vào đề
async function loadQuestionOptionsForSelect() {
    try {
        const categoryId = questionCategoryFilter.value || undefined;
        const level = questionLevelFilter.value || "";

        // categoryId lọc được ở backend luôn (đúng như questionService.getAll hỗ trợ)
        const data = await questionService.getAll(0, 100, categoryId);
        let items = data.items || [];

        // Backend chưa có tham số lọc level -> lọc tạm thời ở phía client
        if (level) {
            items = items.filter(q => q.level === level);
        }

        if (items.length === 0) {
            questionSelect.innerHTML = `<option value="">Không có câu hỏi phù hợp</option>`;
            return;
        }

        questionSelect.innerHTML = items
            .map(q => {
                const levelTag = q.level ? ` [${LEVEL_LABEL_SHORT[q.level] || q.level}]` : "";
                return `<option value="${q.id}">#${q.id} - ${(q.content || "").slice(0, 40)}${levelTag}</option>`;
            })
            .join("");
    } catch (err) {
        questionSelect.innerHTML = `<option value="">Không tải được danh sách câu hỏi</option>`;
    }
}

// Khi đổi bộ lọc danh mục hoặc độ khó -> load lại dropdown câu hỏi
questionCategoryFilter.addEventListener("change", loadQuestionOptionsForSelect);
questionLevelFilter.addEventListener("change", loadQuestionOptionsForSelect);

// ---------- BỘ LỌC THÍ SINH (lớp) ----------

// Đổ danh sách lớp vào dropdown lọc thí sinh
async function loadClassFilterOptions() {
    try {
        const classes = await classesService.getAll(); // không truyền academicYearId -> lấy tất cả các lớp
        participantClassFilter.innerHTML =
            `<option value="">-- Tất cả lớp --</option>` +
            (classes || []).map(c => `<option value="${c.id}">${c.className}</option>`).join("");
    } catch (err) {
        console.warn("Không tải được danh sách lớp:", err.message);
    }
}

// Đổ danh sách sinh viên (lọc theo lớp đang chọn) vào dropdown chọn thí sinh để thêm vào đề
async function loadUserOptionsForSelect() {
    try {
        const classId = participantClassFilter.value || null;
        const data = await studentService.getAll(classId);
        const items = (data || []).filter(u => u.status !== "LOCKED"); // bỏ sinh viên đang bị khóa

        if (items.length === 0) {
            participantSelect.innerHTML = `<option value="">Không có sinh viên phù hợp</option>`;
            return;
        }

        participantSelect.innerHTML = items
            .map(u => `<option value="${u.id}">${u.fullName} - ${u.className || "N/A"} (${u.username})</option>`)
            .join("");
    } catch (err) {
        participantSelect.innerHTML = `<option value="">Không tải được danh sách sinh viên</option>`;
    }
}

// Khi đổi bộ lọc lớp -> load lại dropdown thí sinh
participantClassFilter.addEventListener("change", loadUserOptionsForSelect);

// Thêm câu hỏi vào đề
btnAddQuestion.addEventListener("click", async () => {
    if (!managingExamId) return;
    const questionId = parseInt(questionSelect.value);

    if (!questionId) {
        alert("Vui lòng chọn câu hỏi cần thêm!");
        return;
    }

    // Tự động gán STT = STT lớn nhất hiện tại trong đề + 1
    const orderIndex = currentExamQuestions.length
        ? Math.max(...currentExamQuestions.map(q => q.orderIndex)) + 1
        : 1;

    try {
        // AddQuestionToExamRequest: { examId, questionId, orderIndex }
        await examService.addQuestion({
            examId: managingExamId,
            questionId: questionId,
            orderIndex: orderIndex,
        });
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
});

// Xóa câu hỏi khỏi đề
window.removeQuestionFromExam = async function (questionId) {
    if (!managingExamId) return;
    if (!confirm("Xóa câu hỏi này khỏi đề thi?")) return;

    try {
        // RemoveQuestionRequest: { examId, questionId }
        await examService.removeQuestion({
            examId: managingExamId,
            questionId: questionId,
        });
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

// Thêm thí sinh vào đề
btnAddParticipant.addEventListener("click", async () => {
    if (!managingExamId) return;
    const userId = parseInt(participantSelect.value);
    const seatNumberRaw = document.getElementById("seatNumberInput").value;
    const seatNumber = seatNumberRaw ? parseInt(seatNumberRaw) : null;

    if (!userId) {
        alert("Vui lòng chọn thí sinh cần thêm!");
        return;
    }

    try {
        // AddParticipantRequest: { examId, userId, seatNumber }
        await examService.addParticipant({
            examId: managingExamId,
            userId: userId,
            seatNumber: seatNumber,
        });
        document.getElementById("seatNumberInput").value = "";
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
});

// Xóa thí sinh khỏi đề
window.removeParticipantFromExam = async function (userId) {
    if (!managingExamId) return;
    if (!confirm("Xóa thí sinh này khỏi đề thi?")) return;

    try {
        await examService.removeParticipant(managingExamId, userId);
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

window.unbanParticipant = async function (userId) {
    if (!managingExamId) return;
    if (!confirm("Gỡ cấm thí sinh này khỏi trạng thái BANNED để họ có thể tiếp tục làm bài?")) return;

    try {
        await examSessionService.unbanParticipant(managingExamId, userId);
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

window.editSeat = async function (userId, currentSeat) {
    const val = prompt("Nhập số ghế mới:", currentSeat ?? "");
    if (val === null || val.trim() === "") return;

    try {
        await examService.updateSeat(managingExamId, userId, parseInt(val));
        await refreshManagePanel();
    } catch (err) {
        alert(err.message);
    }
};

// --- KHỞI TẠO ---
async function init() {
    await loadExams();
}
init();