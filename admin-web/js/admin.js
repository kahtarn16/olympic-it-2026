const academicYearCard = document.getElementById("academicYearCard");
const classCard = document.getElementById("classCard");
const studentCard = document.getElementById("studentCard");
const categoryCard = document.getElementById("categoryCard");
const questionCard = document.getElementById("questionCard");
const examCard = document.getElementById("examCard");
const resultCard = document.getElementById("resultCard");

academicYearCard?.addEventListener("click", () => {
    window.location.href = "academic.html";
});

classCard?.addEventListener("click", () => {
    window.location.href = "class.html";
});

studentCard?.addEventListener("click", () => {
    window.location.href = "student.html";
});

categoryCard?.addEventListener("click", () => {
    window.location.href = "category.html";
});

questionCard?.addEventListener("click", () => {
    window.location.href = "question.html";
});

examCard?.addEventListener("click", () => {
    window.location.href = "exam.html";
});

resultCard?.addEventListener("click", () => {
    window.location.href = "result.html";
});