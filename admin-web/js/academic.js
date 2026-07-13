import { academicYearService } from "./service/academic_year_service.js";

const table = document.getElementById("academicYearTable");
const inputName = document.getElementById("academicYearName");
const btnAdd = document.getElementById("btnAdd");


async function loadAcademicYears() {
    try {
        const data = await academicYearService.getAll();
        table.innerHTML = "";
        data.forEach(item => {
            table.innerHTML += `
                <tr>
                    <td>${item.id}</td>
                    <td>
                        ${item.yearName}
                    </td>
                    <td>
                        <button 
                            class="btn btn-warning btn-sm me-2"
                            onclick="editAcademicYear(${item.id}, '${item.yearName}')">
                            Sửa
                        </button>
                        <button 
                            class="btn btn-danger btn-sm"
                            onclick="deleteAcademicYear(${item.id})">
                            Xóa
                        </button>

                    </td>
                </tr>
            `;
        });
    } catch (error) {
        alert(error.message);
    }
}
btnAdd.addEventListener("click", async () => {
    const name = inputName.value.trim();
    if (!name) {
        alert("Vui lòng nhập tên khóa");
        return;
    }
    try {
        await academicYearService.create(name);
        inputName.value = "";
        await loadAcademicYears();
    } catch (error) {
        alert(error.message);
    }
});
window.deleteAcademicYear = async function (id) {
    if (!confirm("Bạn có chắc muốn xóa?")) {
        return;
    }
    try {
        await academicYearService.delete(id);
        await loadAcademicYears();
    } catch (error) {
        alert(error.message);
    }
};
window.editAcademicYear = async function (id, oldName) {
    const newName = prompt(
        "Nhập tên khóa mới:",
        oldName
    );
    if (!newName || newName === oldName) {
        return;
    }
    try {
        await academicYearService.update(
            id,
            newName
        );
        await loadAcademicYears();
    } catch (error) {
        alert(error.message);
    }
};

loadAcademicYears();