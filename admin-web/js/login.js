import { authService } from "./service/auth_service.js";
import { LoginRequest } from "./dto/auth/login_request.js";

const form = document.getElementById("loginForm");
const btnLogin = document.getElementById("btnLogin");

form.addEventListener("submit", async (event) => {
    event.preventDefault();

    const username = document.getElementById("username").value.trim();
    const password = document.getElementById("password").value;

    if (!username || !password) {
        alert("Vui lòng nhập đầy đủ thông tin.");
        return;
    }

    try {
        btnLogin.disabled = true;
        btnLogin.textContent = "Đang đăng nhập...";

        await authService.login(
            new LoginRequest(username, password)
        );

        window.location.href = "admin.html";
    } catch (error) {
        alert(error.message || "Đăng nhập thất bại.");
    } finally {
        btnLogin.disabled = false;
        btnLogin.textContent = "Đăng nhập";
    }
});