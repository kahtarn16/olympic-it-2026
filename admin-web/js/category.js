import { categoryService } from "./service/category_service.js";

const categoryName = document.getElementById("categoryName");
const btnAdd = document.getElementById("btnAdd");
const table = document.getElementById("categoryTable");

let editId = null;

async function loadCategories() {
    try {
        const data = await categoryService.getAll();
        table.innerHTML = "";

        data.forEach(item => {
            table.innerHTML += `
                <tr>
                    <td>${item.id}</td>
                    <td class="text-start ps-4">${item.name}</td>
                    <td>
                        <button class="btn btn-warning btn-sm me-2"
                            onclick="editCategory(${item.id}, '${item.name.replace(/'/g, "\\'")}')">
                            Sửa
                        </button>
                        <button class="btn btn-danger btn-sm"
                            onclick="deleteCategory(${item.id})">
                            Xóa
                        </button>
                    </td>
                </tr>
            `;
        });
    } catch (error) {
        alert("Lỗi tải danh mục: " + error.message);
    }
}

btnAdd.addEventListener("click", async () => {
    const nameValue = categoryName.value.trim();

    if (!nameValue) {
        alert("Vui lòng nhập tên danh mục");
        return;
    }

    try {
        if (editId) {
            await categoryService.update(editId, nameValue);
            alert("Cập nhật danh mục thành công");
        } else {
            await categoryService.create(nameValue);
            alert("Thêm danh mục thành công");
        }

        clearForm();
        await loadCategories();
    } catch (error) {
        alert(error.message);
    }
});

window.editCategory = function(id, name) {
    editId = id;
    categoryName.value = name;
    btnAdd.innerText = "Cập nhật";
};

window.deleteCategory = async function(id) {
    if (!confirm("Bạn có chắc chắn muốn xóa danh mục này?")) {
        return;
    }

    try {
        await categoryService.delete(id);
        alert("Xóa danh mục thành công");
        await loadCategories();
    } catch (error) {
        alert(error.message);
    }
};

function clearForm() {
    editId = null;
    categoryName.value = "";
    btnAdd.innerText = "Thêm danh mục";
}

// Khởi tạo màn hình
async function init() {
    await loadCategories();
}

init();