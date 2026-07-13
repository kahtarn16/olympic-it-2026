import { questionService } from "./service/question_service.js";
import { categoryService } from "./service/category_service.js";
import { apiClient, safeDecode } from "./core/api_client.js"
import { HOST } from "./core/config.js"; // Lấy link localhost:8080 để hiển thị ảnh trực tiếp

// DOM Elements cho Câu hỏi
const content = document.getElementById("content");
const categoryId = document.getElementById("categoryId");
const questionType = document.getElementById("questionType");
const level = document.getElementById("level");
const score = document.getElementById("score");
const timeLimit = document.getElementById("timeLimit");

// DOM Elements cho Media Câu hỏi chính
const mediaSection = document.getElementById("mediaSection");
const mediaInputsWrapper = document.getElementById("mediaInputsWrapper");
const mediaPreviewWrapper = document.getElementById("mediaPreviewWrapper");
const imageFile = document.getElementById("imageFile");
const videoFile = document.getElementById("videoFile");
const btnClearMedia = document.getElementById("btnClearMedia");
const mediaPreview = document.getElementById("mediaPreview");

// DOM Elements cho Loại câu hỏi
const essaySection = document.getElementById("essaySection");
const essayAnswer = document.getElementById("essayAnswer");

const mcqSection = document.getElementById("mcqSection");
const mcqOptionsWrapper = document.getElementById("mcqOptionsWrapper");
const optTypeText = document.getElementById("optTypeText");
const optTypeImage = document.getElementById("optTypeImage");

const btnSubmit = document.getElementById("btnSubmit");
const btnCancel = document.getElementById("btnCancel");
const formTitle = document.getElementById("formTitle");

const filterCategory = document.getElementById("filterCategory");
const table = document.getElementById("questionTable");

const paginationInfo = document.getElementById("paginationInfo");
const btnPrev = document.getElementById("btnPrev");
const btnNext = document.getElementById("btnNext");
const currentPageNum = document.getElementById("currentPageNum");

// State quản lý ứng dụng
let editId = null;
let currentPage = 0;
const pageSize = 10;
let totalPages = 1;

let uploadedMediaUrl = ""; // Chứa URL tương đối (/uploads/...) của câu hỏi chính
let optionMediaUrls = ["", "", "", ""]; // Chứa URL ảnh cho 4 options MCQ

// --- CẬP NHẬT TRẠNG THÁI HIỂN THỊ MEDIA CÂU HỎI ---
function updateMediaDOMState() {
    if (uploadedMediaUrl) {
        // Có ảnh/video -> Ẩn input chọn file, Hiện vùng preview kèm nút xóa
        if (mediaInputsWrapper) mediaInputsWrapper.classList.add("d-none");
        if (mediaPreviewWrapper) mediaPreviewWrapper.classList.remove("d-none");

        const fullUrl = `${HOST}${uploadedMediaUrl}`;
        // Nhận diện là video hay ảnh dựa vào đường dẫn URL từ Server trả về
        if (uploadedMediaUrl.toLowerCase().includes("/videos/")) {
            mediaPreview.innerHTML = `<video src="${fullUrl}" controls class="img-thumbnail shadow-sm" style="max-height: 220px; display: block;"></video>`;
        } else {
            mediaPreview.innerHTML = `<img src="${fullUrl}" class="img-thumbnail shadow-sm" style="max-height: 220px; display: block;" alt="Media Preview">`;
        }
    } else {
        // Không có media -> Hiện lại nút chọn file, Ẩn vùng preview đi
        if (mediaInputsWrapper) mediaInputsWrapper.classList.remove("d-none");
        if (mediaPreviewWrapper) mediaPreviewWrapper.classList.add("d-none");
        mediaPreview.innerHTML = "";
        imageFile.value = "";
        videoFile.value = "";
    }
}

// --- KHỞI TẠO ĐÁP ÁN TRẮC NGHIỆM ĐỘNG (MCQ) ---
function renderMcqOptionsUI() {
    const isImageMode = optTypeImage.checked;
    mcqOptionsWrapper.innerHTML = "";
    
    const labels = ["A", "B", "C", "D"];
    labels.forEach((label, index) => {
        const hasImg = optionMediaUrls[index];
        let inputField = "";

        if (isImageMode) {
            // Nếu dùng chế độ ẢNH: Đã có ảnh thì hiện ảnh + nút xóa, chưa có thì hiện nút Chọn file
            inputField = hasImg 
                ? `<div class="d-flex align-items-center gap-2 w-100 ms-2 border rounded p-1 bg-white">
                     <img src="${HOST}${hasImg}" class="img-thumbnail" style="max-height: 38px;" alt="Option ${label}">
                     <span class="small text-success flex-grow-1">✓ Đã nạp ảnh</span>
                     <button type="button" class="btn btn-outline-danger btn-sm btn-clear-opt-media" data-index="${index}">Xóa ảnh</button>
                   </div>`
                : `<input type="file" class="form-control option-file-input" data-index="${index}" accept="image/*">`;
        } else {
            // Chế độ TEXT thông thường
            inputField = `<input type="text" class="form-control option-text-input" data-index="${index}" placeholder="Nhập nội dung đáp án ${label}" value="">`;
        }

        mcqOptionsWrapper.innerHTML += `
            <div class="col-md-6">
                <div class="input-group">
                    <span class="input-group-text bg-light fw-bold">${label}</span>
                    <div class="input-group-text">
                        <input class="form-check-input option-correct-radio" type="radio" name="correctAnswer" value="${index}" id="radio-${index}">
                        <label class="form-check-label small ms-1" for="radio-${index}">Đúng</label>
                    </div>
                    ${inputField}
                </div>
            </div>
        `;
    });
    bindOptionFileEvents();
}

// Lắng nghe thay đổi của loại câu hỏi để bật/tắt form tương ứng
questionType.addEventListener("change", () => {
    const type = questionType.value;
    
    // Xử lý khối Media câu hỏi
    if (type.includes("_MEDIA")) {
        mediaSection.classList.remove("d-none");
        updateMediaDOMState();
    } else {
        mediaSection.classList.add("d-none");
        clearQuestionMedia();
    }

    // Xử lý khối Essay vs MCQ
    if (type.includes("ESSAY")) {
        essaySection.classList.remove("d-none");
        mcqSection.classList.add("d-none");
    } else {
        essaySection.classList.add("d-none");
        mcqSection.classList.remove("d-none");
    }
});

// Chuyển đổi qua lại giữa Option chữ và Option ảnh
optTypeText.addEventListener("change", renderMcqOptionsUI);
optTypeImage.addEventListener("change", renderMcqOptionsUI);

// --- HÀM TẢI FILE QUA API CLIENT HỆ THỐNG ---
async function uploadFileAPI(file, endpoint) {
    const res = await apiClient.uploadMultipart(`upload/${endpoint}`, "file", file);
    const json = await safeDecode(res);
    if (!json || !json.url) {
        throw new Error("Không nhận được đường dẫn URL từ server");
    }
    return json.url;
}

// Đính kèm file đa phương tiện của câu hỏi chính
imageFile.addEventListener("change", async (e) => {
    if (e.target.files.length > 0) {
        try {
            uploadedMediaUrl = await uploadFileAPI(e.target.files[0], "image");
            updateMediaDOMState(); // Tải thành công -> Cập nhật ẩn input hiện ảnh luôn
        } catch (err) { alert(err.message); }
    }
});

videoFile.addEventListener("change", async (e) => {
    if (e.target.files.length > 0) {
        try {
            uploadedMediaUrl = await uploadFileAPI(e.target.files[0], "video");
            updateMediaDOMState(); // Tải thành công -> Cập nhật ẩn input hiện video luôn
        } catch (err) { alert(err.message); }
    }
});

function clearQuestionMedia() {
    uploadedMediaUrl = "";
    updateMediaDOMState(); // Trả lại trạng thái trống, hiện các nút upload
}
btnClearMedia.addEventListener("click", clearQuestionMedia);

// Lắng nghe và Đính kèm ảnh cho các Option MCQ
function bindOptionFileEvents() {
    // 1. Lắng nghe sự kiện Upload ảnh cho từng Option
    document.querySelectorAll(".option-file-input").forEach(input => {
        input.addEventListener("change", async (e) => {
            const idx = parseInt(e.target.getAttribute("data-index"));
            if (e.target.files.length > 0) {
                try {
                    const url = await uploadFileAPI(e.target.files[0], "image");
                    optionMediaUrls[idx] = url;
                    renderMcqOptionsUI(); // Re-render để hiển thị ảnh vừa load và ẩn input
                } catch (err) { alert(err.message); }
            }
        });
    });

    // 2. Lắng nghe nút bấm "Xóa ảnh" của từng Option
    document.querySelectorAll(".btn-clear-opt-media").forEach(btn => {
        btn.addEventListener("click", (e) => {
            const idx = parseInt(e.target.getAttribute("data-index"));
            optionMediaUrls[idx] = ""; // Reset url của option đó
            renderMcqOptionsUI(); // Re-render để hiện lại thẻ input cho phép chọn lại
        });
    });
}

// --- TẢI VÀ RENDER DANH SÁCH DỮ LIỆU ---
async function loadCategories() {
    const data = await categoryService.getAll();
    
    // 1. Tạo chuỗi danh sách các danh mục lấy từ Database
    let databaseOptions = "";
    data.forEach(c => {
        databaseOptions += `<option value="${c.id}">${c.name}</option>`;
    });
    
    // 2. Đổ vào ô Chọn danh mục của Form (Cần dòng "Chọn danh mục")
    categoryId.innerHTML = `<option value="">-- Chọn danh mục --</option>` + databaseOptions;
    
    // 3. Đổ vào ô Lọc danh mục ngoài bảng (Cần dòng "Tất cả danh mục")
    filterCategory.innerHTML = `<option value="">-- Tất cả danh mục --</option>` + databaseOptions;
}

async function loadQuestions() {
    const catId = filterCategory.value || null;
    const data = await questionService.getAll(currentPage, pageSize, catId);
    
    table.innerHTML = "";
    data.items.forEach(q => {
        let typeDisplay = "Chưa rõ";
        if (q.type) {
            if (q.type.includes("MCQ")) {
                typeDisplay = "Trắc nghiệm";
            } else if (q.type.includes("ESSAY")) {
                typeDisplay = "Tự luận";
            }
        }

        table.innerHTML += `
            <tr>
                <td>${q.id}</td>
                <td class="text-start">${q.content}</td>
                <td><span class="badge bg-secondary">${typeDisplay}</span></td>
                <td>${q.categoryName || 'N/A'}</td>
                <td><span class="badge bg-info">${q.level}</span></td>
                <td>
                    <button class="btn btn-warning btn-sm me-1" onclick="editQuestion(${q.id})">Sửa</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteQuestion(${q.id})">Xóa</button>
                </td>
            </tr>
        `;
    });

    totalPages = data.totalPages || 1;
    currentPageNum.innerText = currentPage + 1;
    paginationInfo.innerText = `Tổng số câu hỏi: ${data.totalElements} (Trang ${currentPage + 1}/${totalPages})`;
    
    btnPrev.classList.toggle("disabled", currentPage === 0);
    btnNext.classList.toggle("disabled", currentPage >= totalPages - 1);
}

btnPrev.addEventListener("click", () => { if (currentPage > 0) { currentPage--; loadQuestions(); } });
btnNext.addEventListener("click", () => { if (currentPage < totalPages - 1) { currentPage++; loadQuestions(); } });
filterCategory.addEventListener("change", () => { currentPage = 0; loadQuestions(); });

// --- GỬI FORM (CREATE/UPDATE) ---
btnSubmit.addEventListener("click", async () => {
    if (!content.value.trim() || !categoryId.value) {
        alert("Vui lòng điền nội dung câu hỏi và chọn danh mục!");
        return;
    }

    const type = questionType.value;
    const isEssay = type.includes("ESSAY");
    
    // Tự động phân loại lưu vào Column tương ứng dựa vào loại link Media
    const isMedia = type.includes("_MEDIA") && uploadedMediaUrl;
    const isVideo = isMedia && uploadedMediaUrl.toLowerCase().includes("/videos/");

    const request = {
        content: content.value.trim(),
        type: type,
        categoryId: parseInt(categoryId.value),
        level: level.value,
        score: parseFloat(score.value) || 1,
        timeLimit: parseInt(timeLimit.value) || 60,
        imageUrl: isMedia && !isVideo ? uploadedMediaUrl : null,
        videoUrl: isMedia && isVideo ? uploadedMediaUrl : null,
        answer: isEssay ? essayAnswer.value.trim() : null,
        options: null
    };

    if (!isEssay) {
        const optionsList = [];
        const isImageMode = optTypeImage.checked;
        const checkedRadio = document.querySelector('input[name="correctAnswer"]:checked');

        if (!checkedRadio) {
            alert("Vui lòng chọn 1 đáp án chính xác!");
            return;
        }
        const correctIndex = parseInt(checkedRadio.value);
        const labels = ["A", "B", "C", "D"];

        for (let i = 0; i < 4; i++) {
            const opt = {
                label: labels[i],
                isCorrect: (i === correctIndex),
                contentText: null,
                imageUrl: null
            };

            if (isImageMode) {
                if (!optionMediaUrls[i]) {
                    alert(`Đáp án ${labels[i]} thiếu hình ảnh!`);
                    return;
                }
                opt.imageUrl = optionMediaUrls[i];
            } else {
                const textInput = document.querySelector(`.option-text-input[data-index="${i}"]`);
                if (!textInput || !textInput.value.trim()) {
                    alert(`Vui lòng điền nội dung đáp án cho mục ${labels[i]}!`);
                    return;
                }
                opt.contentText = textInput.value.trim();
            }
            optionsList.push(opt);
        }
        request.options = optionsList;
    } else {
        if (!request.answer) {
            alert("Câu hỏi tự luận yêu cầu bắt buộc phải có thông tin đáp án hướng dẫn!");
            return;
        }
    }

    try {
        if (editId) {
            await questionService.update(editId, request);
            alert("Cập nhật câu hỏi thành công!");
        } else {
            await questionService.create(request);
            alert("Thêm câu hỏi thành công!");
        }
        clearForm();
        await loadQuestions();
    } catch (error) {
        alert(error.message);
    }
});

// --- CHỨC NĂNG SỬA CÂU HỎI VÀ NẠP LẠI MEDIA ---
window.editQuestion = async function(id) {
    try {
        const q = await questionService.getDetail(id);
        editId = id;
        formTitle.innerText = `Chỉnh sửa câu hỏi [ID: ${id}]`;
        btnCancel.classList.remove("d-none");
        btnSubmit.innerText = "Cập nhật";

        content.value = q.content;
        categoryId.value = q.categoryId;
        questionType.value = q.type;
        level.value = q.level;
        score.value = q.score;
        timeLimit.value = q.timeLimit;

        // Kích hoạt sự kiện để hiển thị đúng khu vực (Essay/MCQ/Media)
        questionType.dispatchEvent(new Event("change"));

        // Điền dữ liệu media câu hỏi cũ từ cơ sở dữ liệu nếu có
        uploadedMediaUrl = q.imageUrl || q.videoUrl || "";
        updateMediaDOMState(); // Tự động load ảnh lên thẻ img/video và ẩn input đi!

        if (!q.type.includes("ESSAY")) {
            optionMediaUrls = ["", "", "", ""];
            const options = q.options || [];
            const hasImageOption = options.some(o => o.imageUrl);
            
            if (hasImageOption) {
                optTypeImage.checked = true;
            } else {
                optTypeText.checked = true;
            }
            
            // Đổ dữ liệu cũ vào mảng và re-render UI options
            options.forEach((opt, idx) => {
                if (idx < 4) {
                    if (hasImageOption) {
                        optionMediaUrls[idx] = opt.imageUrl || "";
                    }
                }
            });

            renderMcqOptionsUI();

            options.forEach((opt, idx) => {
                if (idx < 4) {
                    if (!hasImageOption) {
                        const txtInput = document.querySelector(`.option-text-input[data-index="${idx}"]`);
                        if (txtInput) txtInput.value = opt.contentText || "";
                    }
                    if (opt.isCorrect) {
                        const radioBtn = document.getElementById(`radio-${idx}`);
                        if (radioBtn) radioBtn.checked = true;
                    }
                }
            });
        } else {
            essayAnswer.value = q.answer || "";
        }
        window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err) { alert("Lỗi tải chi tiết: " + err.message); }
};

window.deleteQuestion = async function(id) {
    if (confirm("Hành động này sẽ xóa vĩnh viễn câu hỏi. Tiếp tục?")) {
        try {
            await questionService.delete(id);
            alert("Xóa thành công!");
            await loadQuestions();
        } catch (err) { alert(err.message); }
    }
};

function clearForm() {
    editId = null;
    formTitle.innerText = "Thêm câu hỏi mới";
    btnCancel.classList.add("d-none");
    btnSubmit.innerText = "Thêm câu hỏi";

    content.value = "";
    score.value = "1";
    timeLimit.value = "60";
    essayAnswer.value = "";
    
    uploadedMediaUrl = "";
    updateMediaDOMState();
    
    optionMediaUrls = ["", "", "", ""];
    optTypeText.checked = true;
    questionType.value = "MCQ_TEXT";
    questionType.dispatchEvent(new Event("change"));
    renderMcqOptionsUI();
}

btnCancel.addEventListener("click", clearForm);

async function init() {
    renderMcqOptionsUI();
    await loadCategories();
    await loadQuestions();
}
init();