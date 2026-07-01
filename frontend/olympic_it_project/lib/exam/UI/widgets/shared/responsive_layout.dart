import 'package:flutter/material.dart';

// Breakpoint chuẩn cho toàn app — thay đổi ở đây sẽ ảnh hưởng toàn bộ
// Phone:   < 600px
// Tablet:  600px – 1024px
// Desktop: > 1024px
class AppBreakpoint {
  static const double phone = 600;
  static const double tablet = 1024;

  // Max width cho content trên tablet/desktop
  // Giới hạn để không bị dãn quá rộng, căn giữa màn hình
  static const double contentMaxWidth = 700;
}

// Enum phân loại thiết bị — dùng để switch layout
enum DeviceType { phone, tablet, desktop }

// Extension tiện lợi để lấy DeviceType từ constraints
extension DeviceTypeX on BoxConstraints {
  DeviceType get deviceType {
    if (maxWidth < AppBreakpoint.phone) return DeviceType.phone;
    if (maxWidth < AppBreakpoint.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Kiểm tra nhanh
  bool get isPhone => deviceType == DeviceType.phone;
  bool get isTabletOrAbove => maxWidth >= AppBreakpoint.phone;
}

// Widget wrapper dùng chung — bọc ngoài màn hình thi
// Tự động căn giữa và giới hạn width trên tablet/desktop
// Phone: chiếm toàn màn hình
// Tablet/Desktop: max 700px, căn giữa
class ResponsiveExamLayout extends StatelessWidget {
  final Widget child;

  // Màu nền phía sau content (chỉ thấy trên tablet/desktop hai bên lề)
  final Color backgroundColor;

  const ResponsiveExamLayout({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFF0F4F8),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone: không cần wrapper, chiếm toàn màn hình
        if (constraints.isPhone) {
          return child;
        }

        // Tablet/Desktop: căn giữa, giới hạn max width, thêm lề hai bên
        return Container(
          color: backgroundColor, // lề hai bên trên tablet/desktop
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoint.contentMaxWidth,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// Lấy font size responsive — scale theo chiều rộng màn hình
// Tránh dùng số cứng, gọi hàm này thay vì hardcode fontSize
double responsiveFontSize(
  BuildContext context, {
  required double phone,      // font size trên phone
  double? tablet,             // font size trên tablet (mặc định phone * 1.1)
  double? desktop,            // font size trên desktop (mặc định phone * 1.2)
}) {
  final width = MediaQuery.of(context).size.width;

  if (width < AppBreakpoint.phone) return phone;
  if (width < AppBreakpoint.tablet) return tablet ?? phone * 1.1;
  return desktop ?? phone * 1.2;
}

// Lấy padding responsive theo kích thước màn hình
EdgeInsets responsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width < AppBreakpoint.phone) {
    // Phone: padding nhỏ
    return const EdgeInsets.all(12.0);
  } else if (width < AppBreakpoint.tablet) {
    // Tablet: padding vừa
    return const EdgeInsets.all(24);
  } else {
    // Desktop: padding lớn
    return const EdgeInsets.all(32);
  }
}