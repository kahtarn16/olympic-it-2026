import { studentService } from "./service/student_service.js";
import { academicYearService } from "./service/academic_year_service.js";
import { classesService } from "./service/classes_service.js";

const createYear = document.getElementById("createYear");
const createClass = document.getElementById("createClass");

const selectYear = document.getElementById("academicYear");
const selectClass = document.getElementById("class");

const table = document.getElementById("studentTable");

const username = document.getElementById("username");
const password = document.getElementById("password");
const email = document.getElementById("email");
const fullName = document.getElementById("fullName");

const btnAdd = document.getElementById("btnAdd");

let editId = null;


async function loadAcademicYears() {
    const data = await academicYearService.getAll();

    createYear.innerHTML = `
        <option value="">
            -- Chọn khóa --
        </option>
    `;

    selectYear.innerHTML = `
        <option value="">
            -- Chọn khóa --
        </option>
    `;

    data.forEach(item => {
        const option = `
            <option value="${item.id}">
                ${item.yearName}
            </option>
        `;

        createYear.innerHTML += option;
        selectYear.innerHTML += option;
    });
}


async function loadClasses(yearId, target) {

    target.innerHTML = `
        <option value="">
            -- Chọn lớp --
        </option>
    `;

    if (!yearId) {
        return;
    }

    const data = await classesService.getAll(yearId);

    data.forEach(item => {
        target.innerHTML += `
            <option value="${item.id}">
                ${item.className}
            </option>
        `;
    });
}


async function loadStudents() {

    const classId = selectClass.value || null;

    const data = await studentService.getAll(classId);

    table.innerHTML = "";

    data.forEach(item => {

        table.innerHTML += `
            <tr>
                <td>${item.id}</td>
                <td>${item.username}</td>
                <td>${item.email}</td>
                <td>${item.fullName}</td>
                <td>${item.className}</td>
                <td>
                    <button class="btn btn-warning btn-sm me-2"
                        onclick="editStudent(
                            ${item.id},
                            '${item.username}',
                            '${item.email}',
                            '${item.fullName}',
                            ${item.classId}
                        )">
                        Sửa
                    </button>

                    ${
                        item.status === "LOCKED"
                        ?
                        `
                        <button class="btn btn-success btn-sm"
                            onclick="unlockStudent(${item.id})">
                            Mở khóa
                        </button>
                        `
                        :
                        `
                        <button class="btn btn-danger btn-sm"
                            onclick="lockStudent(${item.id})">
                            Khóa
                        </button>
                        `
                    }

                </td>
            </tr>
        `;
    });
}


createYear.addEventListener("change", async () => {
    await loadClasses(createYear.value, createClass);
});


selectYear.addEventListener("change", async () => {

    await loadClasses(
        selectYear.value,
        selectClass
    );

});


selectClass.addEventListener("change", async () => {
    await loadStudents();
});


btnAdd.addEventListener("click", async () => {

    const data = {
        username: username.value.trim(),
        password: password.value.trim(),
        email: email.value.trim(),
        fullName: fullName.value.trim(),
        classId: createClass.value
    };


    if (!data.username ||
        !data.email ||
        !data.fullName ||
        !data.classId ||
        (!editId && !data.password)) {

        alert("Vui lòng nhập đầy đủ thông tin");
        return;
    }


    try {

        if (editId) {

            await studentService.update(
                editId,
                {
                    username: data.username,
                    email: data.email,
                    fullName: data.fullName,
                    classId: data.classId
                }
            );

            alert("Cập nhật thành công");

        } else {

            await studentService.create(data);

            alert("Thêm sinh viên thành công");
        }


        clearForm();

        await loadStudents();

    } catch(error) {
        alert(error.message);
    }

});


window.editStudent = function(
    id,
    user,
    mail,
    name,
    classId
) {

    editId = id;

    username.value = user;
    email.value = mail;
    fullName.value = name;

    password.value = "";

    createClass.value = classId;

    btnAdd.innerText = "Cập nhật";
};


window.lockStudent = async function(id) {

    if (!confirm("Khóa sinh viên này?")) {
        return;
    }

    await studentService.lock(id);

    await loadStudents();
};


window.unlockStudent = async function(id) {

    if (!confirm("Mở khóa sinh viên này?")) {
        return;
    }

    await studentService.unlock(id);

    await loadStudents();
};


function clearForm() {

    editId = null;

    username.value = "";
    password.value = "";
    email.value = "";
    fullName.value = "";

    createClass.value = "";

    btnAdd.innerText = "Thêm sinh viên";
}


async function init() {

    await loadAcademicYears();

}


init();