import { examService } from "./service/exam_service.js";
import { questionService } from "./service/question_service.js";
import { studentService } from "./service/student_service.js";
import { examSessionService } from "./service/exam_session_service.js";

// DOM Elements cho Form Đề thi
const examName = document.getElementById("examName");
const shuffleOption = document.getElementById("shuffleOption");
const btnSubmit = document.getElementById("btnSubmit");
const btnCancel = document.getElementById("btnCancel");
const formTitle = document.getElementById("formTitle");

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

const examParticipantList = document.getElementById("examParticipantList");
const participantSelect = document.getElementById("participantSelect");
const btnAddParticipant = document.getElementById("btnAddParticipant");

// --- STATE QUẢN LÝ ỨNG DỤNG ---
let editId = null;
let currentPage = 0;
const pageSize = 10;
let totalPages = 1;
let currentKeyword = "";

let managingExamId = null; // ID của đề thi đang mở khu vực Quản lý
let currentExamQuestions = []; // Danh sách câu hỏi hiện có trong đề đang quản lý (để kiểm tra STT)

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
        <button class="btn btn-success"
            onclick="createRoom(${exam.id})">
            🟢 Tạo phòng
        </button>
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

window.restartExam = async function (examId) {

    if (!confirm("Bạn có chắc muốn thi lại?")) {
        return;
    }

    try {

        await examSessionService.reset(examId);

        localStorage.setItem("currentExamId", examId);

        window.location.href = "exam_room.html";

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

    window.location.href = "exam_result.html";

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
                <td>${e.shuffleOption ? "Có" : "Không"}</td>
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

// --- GỬI FORM (CREATE / UPDATE) ĐỀ THI ---
btnSubmit.addEventListener("click", async () => {
    if (!examName.value.trim()) {
        alert("Vui lòng nhập tên đề thi!");
        return;
    }

    try {
        if (editId) {
            // UpdateExamRequest: { name, shuffleOption }
            const request = {
                name: examName.value.trim(),
                shuffleOption: shuffleOption.checked,
            };
            await examService.update(editId, request);
            alert("Cập nhật đề thi thành công!");
        } else {
            const createdById = getCurrentAdminId();
            if (!createdById) return;

            // CreateExamRequest: { name, shuffleOption, createdById }
            const request = {
                name: examName.value.trim(),
                shuffleOption: shuffleOption.checked,
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
        shuffleOption.checked = !!e.shuffleOption;

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
    shuffleOption.checked = false;
}
btnCancel.addEventListener("click", clearForm);

// ==========================================================
// KHU VỰC QUẢN LÝ CÂU HỎI + THÍ SINH CỦA 1 ĐỀ THI
// ==========================================================

window.manageExam = async function (id) {
    managingExamId = id;
    managePanel.classList.remove("d-none");
    await loadQuestionOptionsForSelect(); // đổ dropdown danh sách toàn bộ câu hỏi để chọn thêm vào đề
    await loadUserOptionsForSelect();     // đổ dropdown danh sách người dùng để chọn thí sinh thêm vào đề
    await refreshManagePanel();
    managePanel.scrollIntoView({ behavior: "smooth" });
};

btnCloseManage.addEventListener("click", closeManagePanel);

function closeManagePanel() {
    managingExamId = null;
    managePanel.classList.add("d-none");
    examQuestionList.innerHTML = "";
    examParticipantList.innerHTML = "";
}

async function refreshManagePanel() {
    if (!managingExamId) return;

    const detail = await examService.getDetail(managingExamId);

    manageExamName.innerText = detail.name;
    manageExamStatus.outerHTML = statusBadge(detail.status).replace("<span", `<span id="manageExamStatus"`);
    renderExamActions(detail);

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
                    ${p.fullName} <span class="text-muted small">(${p.className || "N/A"})</span>
                    — <span class="badge ${isBanned ? "bg-danger" : "bg-secondary"}">${p.status}</span>
                </span>
                <div class="d-flex gap-1">
                    ${isBanned
                ? `<button class="btn btn-outline-success btn-sm" onclick="unbanParticipant(${p.userId})">Gỡ cấm</button>`
                : ""}
                    <button class="btn btn-outline-danger btn-sm" onclick="removeParticipantFromExam(${p.userId})">Xóa</button>
                </div>
            </li>
        `;
    });
}

// Đổ danh sách toàn bộ câu hỏi (từ questionService) vào dropdown chọn để thêm vào đề
async function loadQuestionOptionsForSelect() {
    try {
        const data = await questionService.getAll(0, 100, null); // lấy tối đa 100 câu hỏi đầu tiên
        const items = data.items || [];
        questionSelect.innerHTML = items
            .map(q => `<option value="${q.id}">#${q.id} - ${(q.content || "").slice(0, 40)}</option>`)
            .join("");
    } catch (err) {
        questionSelect.innerHTML = `<option value="">Không tải được danh sách câu hỏi</option>`;
    }
}

// Đổ danh sách sinh viên (từ studentService) vào dropdown chọn thí sinh để thêm vào đề
async function loadUserOptionsForSelect() {
    try {
        const data = await studentService.getAll(); // không truyền classId -> lấy toàn bộ sinh viên
        const items = (data || []).filter(u => u.status !== "LOCKED"); // bỏ sinh viên đang bị khóa
        participantSelect.innerHTML = items
            .map(u => `<option value="${u.id}">${u.fullName} - ${u.className || "N/A"} (${u.username})</option>`)
            .join("");
    } catch (err) {
        participantSelect.innerHTML = `<option value="">Không tải được danh sách sinh viên</option>`;
    }
}

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

    if (!userId) {
        alert("Vui lòng chọn thí sinh cần thêm!");
        return;
    }

    try {
        // AddParticipantRequest: { examId, userId }
        await examService.addParticipant({
            examId: managingExamId,
            userId: userId,
        });
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

// --- KHỞI TẠO ---
async function init() {
    await loadExams();
}
init();