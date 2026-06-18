import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Biến kiểm soát ẩn/hiện mật khẩu của từng ô
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Giữ nguyên icon trường học đồng bộ với các màn trước
            Image.asset(
              'assets/images/ic_school.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Đặt lại mật khẩu",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái tiêu đề
                children: [
                  // --- Ô 1: MẬT KHẨU MỚI ---
                  const Text(
                    "Mật khẩu mới",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscurePassword,
                    decoration: InputDecoration(
                      hintText: "Nhập mật khẩu mới",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscurePassword = !_isObscurePassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Ô 2: XÁC NHẬN MẬT KHẨU ---
                  const Text(
                    "Xác nhận mật khẩu",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _isObscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: "Nhập lại mật khẩu mới",
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscureConfirmPassword = !_isObscureConfirmPassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- NÚT HOÀN THÀNH (CÓ KIỂM TRA LOGIC) ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        String pass = _passwordController.text;
                        String confirmPass = _confirmPasswordController.text;

                        // 1. Kiểm tra bỏ trống
                        if (pass.isEmpty || confirmPass.isEmpty) {
                          _showErrorSnackBar("Vui lòng nhập đầy đủ 2 ô mật khẩu!");
                          return;
                        }

                        // 2. Kiểm tra độ dài mật khẩu (Ví dụ tối thiểu 6 ký tự)
                        if (pass.length < 6) {
                          _showErrorSnackBar("Mật khẩu phải có ít nhất 6 ký tự!");
                          return;
                        }

                        // 3. Kiểm tra trùng khớp
                        if (pass != confirmPass) {
                          _showErrorSnackBar("Mật khẩu xác nhận không trùng khớp!");
                          return;
                        }

                        // 4. Nếu mọi thứ OK -> Gửi mật khẩu mới lên server
                        print("Đổi mật khẩu thành công với: $pass");
                        
                        // Sau khi thành công, có thể hiện thông báo xanh rồi quay về màn Đăng nhập
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Hoàn thành",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm helper dùng chung để bắn thông báo lỗi nhanh
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}