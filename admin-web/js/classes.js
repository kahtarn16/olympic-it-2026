import { classesService } from "./service/classes_service.js";
import { academicYearService } from "./service/academic_year_service.js";

const table = document.getElementById("classTable");
const selectYear = document.getElementById("academicYear");
const inputName = document.getElementById("className");
const btnAdd = document.getElementById("btnAdd");

let academicYears = [];

async function loadAcademicYears() {
    try {
        const data = await academicYearService.getAll();
        academicYears = data;
        selectYear.innerHTML = "";
        data.forEach(item => {
            selectYear.innerHTML += `
                <option value="${item.id}">
                    ${item.yearName}
                </option>
            `;
        });
    } catch(error) {
        alert(error.message);
    }
}
async function loadClasses(academicYearId = null) {
    try {
        const data = await classesService.getAll(academicYearId);
        table.innerHTML = "";
        data.forEach(item => {
            const year = academicYears.find(
                x => x.id == item.academicYearId
            );
            table.innerHTML += `
                <tr>
                    <td>
                        ${item.id}
                    </td>
                    <td>
                        ${item.className}
                    </td>
                    <td>
                        ${year ? year.yearName : ""}
                    </td>
                    <td>
                        <button
                            class="btn btn-warning btn-sm me-2"
                            onclick="editClass(${item.id}, '${item.className}', ${item.academicYearId})">
                            Sửa
                        </button>
                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteClass(${item.id})">
                            Xóa
                        </button>
                    </td>
                </tr>
            `;
        });
    } catch(error) {
        alert(error.message);
    }
}
selectYear.addEventListener("change", async () => {
    const academicYearId = selectYear.value;
    await loadClasses(academicYearId);
});
btnAdd.addEventListener("click", async () => {
    const className = inputName.value.trim();
    const academicYearId = selectYear.value;
    if(!className){
        alert("Vui lòng nhập tên lớp");
        return;
    }
    try {
        await classesService.create(
            className,
            academicYearId
        );
        inputName.value = "";
        await loadClasses(academicYearId);
    } catch(error) {
        alert(error.message);
    }
});
window.deleteClass = async function(id) {
    if(!confirm("Bạn có chắc muốn xóa lớp này?")){
        return;
    }
    try {
        await classesService.delete(id);
        await loadClasses(
            selectYear.value
        );
    } catch(error) {

        alert(error.message);
    }
};
window.editClass = async function(
    id,
    oldName,
    academicYearId
) {
    const newName = prompt(
        "Nhập tên lớp mới:",
        oldName
    );
    if(!newName || newName === oldName){
        return;
    }
    try {
        await classesService.update(
            id,
            newName,
            academicYearId
        );
        await loadClasses(
            selectYear.value
        );
    } catch(error) {
        alert(error.message);
    }
};
async function init(){
    await loadAcademicYears();
    await loadClasses(
        selectYear.value
    );
}
init();