import { authService } from "./service/auth_service.js";

const btnLogout = document.getElementById("btnLogout");
console.log(btnLogout);

btnLogout.addEventListener("click", async () => {
    console.log("clicked");

    if (!confirm("Bạn có chắc chắn muốn đăng xuất?")) {
        return;
    }

    console.log("before logout");

    await authService.logout();

    console.log("after logout");

    window.location.href = "index.html";
});