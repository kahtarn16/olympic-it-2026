import 'package:flutter/material.dart';
import 'package:olympic_it_project/features/home/pressentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildBanner(),
              _buildContestInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          /// Icon menu bên trái
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu, color: Colors.blue, size: 28),
              ),
            ),
          ),

          /// Logo nằm giữa
          Expanded(
            child: Center(
              child: Image.asset(
                "assets/images/logo_1.png",
                width: 65,
                height: 65,
              ),
            ),
          ),

          /// Icon profile bên phải
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.blue, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _MenuItem(title: "Trang chủ", selected: true),
          _MenuItem(title: "Cuộc thi"),
          _MenuItem(title: "Thể lệ"),
          _MenuItem(title: "Lịch trình"),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: AssetImage("assets/images/banner_home.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildContestInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "CUỘC THI OLYMPIC TIN HỌC 2026",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Những tài năng hội tụ, thách thức bản thân và chinh phục đỉnh cao công nghệ",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: Call API đăng ký
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(140, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tham gia ngay",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 15),
              OutlinedButton(
                onPressed: () {
                  // TODO: Điều hướng chi tiết
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 50),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tìm hiểu thêm",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final bool selected;

  const _MenuItem({required this.title, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? Colors.black : Colors.grey,
      ),
    );
  }
}

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFDCE8FF)),
            child: Center(
              child: Text(
                "Olympic Tin Học 2026",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Trang chủ"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text("Cuộc thi"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text("Thể lệ"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text("Lịch trình"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
