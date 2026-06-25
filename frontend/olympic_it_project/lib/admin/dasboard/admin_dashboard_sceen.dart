import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ==========================================
  // 1. KHAI BÁO CÁC BIẾN QUẢN LÝ TRẠNG THÁI (STATE)
  // ==========================================
  String _selectedMenu = 'Lớp học'; // Mục đang được chọn mặc định
  bool _isSidebarExpanded = true;    // Trạng thái đóng/mở rộng Sidebar (Responsive)

  // Danh sách các mục menu Sidebar cố định (Đã bỏ Trường học)
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Bảng điều khiển', 'icon': Icons.dashboard_outlined},
    {'title': 'Lớp học', 'icon': Icons.class_outlined},
    {'title': 'Quản lý người dùng', 'icon': Icons.people_outline},
    {'title': 'Chủ đề câu hỏi', 'icon': Icons.topic_outlined},
    {'title': 'Câu hỏi', 'icon': Icons.help_outline},
    {'title': 'Gói câu hỏi', 'icon': Icons.inventory_2_outlined},
    {'title': 'Cuộc thi', 'icon': Icons.emoji_events_outlined},
    {'title': 'Quản lý sinh viên', 'icon': Icons.school_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền xám nhạt tinh tế
      body: Column(
        children: [
          // TOPBAR PHÍA TRÊN
          _buildTopbar(),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SIDEBAR DI CHUYỂN BÊN TRÁI
                _buildSidebar(),
                
                // NỘI DUNG THAY ĐỔI LINH HOẠT THEO MENU
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildMainContentView(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. LOGIC & GIAO DIỆN THANH TOPBAR
  // ==========================================
  Widget _buildTopbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Nút bấm thu gọn / mở rộng Sidebar nhanh
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trường Cao Đẳng Kỹ Thuật Cao Thắng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Khoa Công nghệ thông tin',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          // Profile Admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.account_circle, color: Color(0xFF1E3A8A), size: 20),
                SizedBox(width: 8),
                Text('Admin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. LOGIC & GIAO DIỆN THANH SIDEBAR
  // ==========================================

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 260 : 70,
      // Khi đã dùng border, toàn bộ thuộc tính màu nền (color) và viền (border) phải gom vào trong BoxDecoration
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          final isSelected = _selectedMenu == item['title'];
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(
                item['icon'], 
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                size: 20,
              ),
              title: _isSidebarExpanded 
                  ? Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                      ),
                    )
                  : null,
              dense: true,
              horizontalTitleGap: _isSidebarExpanded ? 12 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                setState(() {
                  _selectedMenu = item['title'];
                });
              },
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 4. TRẠM TRUNG CHUYỂN VIEW NỘI DUNG (SLOT)
  // ==========================================
  Widget _buildMainContentView() {
    // Key này giúp AnimatedSwitcher nhận diện để làm hiệu ứng fade-in khi đổi tab
    return Container(
      key: ValueKey<String>(_selectedMenu),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'Giao diện: $_selectedMenu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khung tổng Dashboard đã khóa cứng logic điều hướng.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}