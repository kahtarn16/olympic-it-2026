import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Bắt buộc để giới hạn chỉ nhập 1 số

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 4 bộ điều khiển tương ứng cho 4 ô số OTP
  final _otp1 = TextEditingController();
  final _otp2 = TextEditingController();
  final _otp3 = TextEditingController();
  final _otp4 = TextEditingController();

  @override
  void dispose() {
    // Giải phóng bộ nhớ
    _otp1.dispose();
    _otp2.dispose();
    _otp3.dispose();
    _otp4.dispose();
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
            // Giữ nguyên icon trường học đồng bộ với file cũ của bạn
            Image.asset(
              'assets/images/ic_school.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              "Xác thực OTP",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20.0),
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
                children: [
                  const Text(
                    "Nhập mã OTP để xác thực tài khoản",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Hàng chứa 4 ô nhập số OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOtpBox(_otp1, first: true, last: false),
                      SizedBox(width: 10),
                      _buildOtpBox(_otp2, first: false, last: false),
                      SizedBox(width: 10),
                      _buildOtpBox(_otp3, first: false, last: false),
                      SizedBox(width: 10),
                      _buildOtpBox(_otp4, first: false, last: true),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút xác nhận mã OTP
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lấy chuỗi OTP đầy đủ người dùng đã gõ
                        String codeOtp =
                            _otp1.text + _otp2.text + _otp3.text + _otp4.text;
                        if (codeOtp.length < 4) {
                          // Nếu chưa nhập đủ -> Bắn thông báo cảnh báo màu đỏ
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Vui lòng nhập đầy đủ mã OTP gồm 4 số!",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior
                                  .floating, // Hiển thị nổi lên nhìn cho đẹp
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(
                                seconds: 2,
                              ), // Biến mất sau 2 giây
                            ),
                          );
                          return; // Dừng lại không chạy tiếp các logic bên dưới
                        }
                        print("Mã số OTP: $codeOtp");

                        // Xử lý logic kiểm tra OTP hoặc gọi API tại đây
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Xác nhận",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút bấm quay lại màn hình trước
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Quay lại",
                      style: TextStyle(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo ô nhập OTP tự động chuyển con trỏ thông minh khi gõ xong hoặc xóa
  Widget _buildOtpBox(
    TextEditingController controller, {
    required bool first,
    required bool last,
  }) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: controller,
        autofocus: first, // Ô đầu tiên tự động mở bàn phím
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1), // Chỉ cho gõ đúng 1 số
          FilteringTextInputFormatter.digitsOnly, // Chặn không cho gõ chữ
        ],
        onChanged: (value) {
          if (value.length == 1 && !last) {
            FocusScope.of(
              context,
            ).nextFocus(); // Gõ xong tự nhảy sang ô bên phải
          }
          if (value.isEmpty && !first) {
            FocusScope.of(
              context,
            ).previousFocus(); // Bấm xóa tự thụt lùi về ô bên trái
          }
        },
        decoration: InputDecoration(
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
    );
  }
}
