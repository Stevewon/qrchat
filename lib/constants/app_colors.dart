import 'package:flutter/material.dart';

/// 🎨 QRChat 앱 전체 색상 테마 정의
/// 모든 화면에서 일관성 있는 색상을 사용하기 위한 상수 모음
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ===== Primary Colors (파란색 계열) =====
  /// 메인 색상 - Material Blue
  static const Color primary = Color(0xFF2196F3);
  
  /// 진한 파란색 - 버튼, 강조 등에 사용
  static const Color primaryDark = Color(0xFF1976D2);
  
  /// 밝은 파란색 - 호버, 선택 상태 등에 사용
  static const Color primaryLight = Color(0xFF64B5F6);
  
  /// 매우 밝은 파란색 - 배경, 컨테이너 등에 사용
  static const Color primaryContainer = Color(0xFFE3F2FD);

  // ===== Secondary Colors (보조 색상) =====
  /// 보조 색상 - 강조, 포인트 등에 사용
  static const Color secondary = Color(0xFFFF9800);
  
  /// 진한 주황색
  static const Color secondaryDark = Color(0xFFF57C00);
  
  /// 밝은 주황색
  static const Color secondaryLight = Color(0xFFFFB74D);

  // ===== Semantic Colors (의미론적 색상) =====
  /// 성공 메시지 - 초록색
  static const Color success = Color(0xFF4CAF50);
  
  /// 에러 메시지 - 빨간색
  static const Color error = Color(0xFFF44336);
  
  /// 경고 메시지 - 주황색
  static const Color warning = Color(0xFFFF9800);
  
  /// 정보 메시지 - 파란색
  static const Color info = Color(0xFF2196F3);

  // ===== Background Colors =====
  /// 기본 배경색 - 흰색
  static const Color surface = Color(0xFFFFFFFF);
  
  /// 앱 전체 배경색 - 연한 회색
  static const Color background = Color(0xFFFAFAFA);
  
  /// 구분선, 테두리 색상 - 회색
  static const Color divider = Color(0xFFE0E0E0);
  
  /// 카드 배경색 - 흰색
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ===== Text Colors =====
  /// 기본 텍스트 색상 - 검은색
  static const Color textPrimary = Color(0xFF212121);
  
  /// 보조 텍스트 색상 - 회색
  static const Color textSecondary = Color(0xFF757575);
  
  /// 비활성 텍스트 색상 - 연한 회색
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  /// 흰색 텍스트 (어두운 배경용)
  static const Color textWhite = Color(0xFFFFFFFF);

  // ===== Special Colors =====
  /// QKEY 관련 색상 - 파란색 그라데이션의 시작색
  static const Color qkeyPrimary = Color(0xFF2196F3);
  
  /// QKEY 관련 색상 - 파란색 그라데이션의 끝색
  static const Color qkeySecondary = Color(0xFF1976D2);
  
  /// 채팅 말풍선 - 내 메시지
  static const Color chatMyMessage = Color(0xFF2196F3);
  
  /// 채팅 말풍선 - 상대방 메시지
  static const Color chatOtherMessage = Color(0xFFE0E0E0);
  
  /// 온라인 상태 표시
  static const Color statusOnline = Color(0xFF4CAF50);
  
  /// 오프라인 상태 표시
  static const Color statusOffline = Color(0xFF9E9E9E);

  // ===== Gradient Definitions =====
  /// 메인 그라데이션 (파란색)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  /// QKEY 그라데이션 (파란색)
  static const LinearGradient qkeyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [qkeyPrimary, qkeySecondary],
  );
  
  /// 헤더 그라데이션 (파란색)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDark],
  );

  // ===== Opacity Variants =====
  /// Primary 색상 10% 투명도
  static Color get primaryWithOpacity10 => primary.withOpacity(0.1);
  
  /// Primary 색상 20% 투명도
  static Color get primaryWithOpacity20 => primary.withOpacity(0.2);
  
  /// Primary 색상 50% 투명도
  static Color get primaryWithOpacity50 => primary.withOpacity(0.5);

  // ===== Badge Colors =====
  /// 알림 배지 색상
  static const Color badge = Color(0xFFF44336);
  
  /// 새 메시지 배지 색상
  static const Color newMessageBadge = Color(0xFF2196F3);

  // ===== Button Colors =====
  /// 기본 버튼 색상
  static const Color buttonPrimary = primary;
  
  /// 보조 버튼 색상
  static const Color buttonSecondary = secondary;
  
  /// 비활성 버튼 색상
  static const Color buttonDisabled = Color(0xFFE0E0E0);

  // ===== Shadow Colors =====
  /// 그림자 색상
  static const Color shadow = Color(0x1A000000);
  
  /// 진한 그림자 색상
  static const Color shadowDark = Color(0x33000000);
}

/// 🎨 다크모드 색상 (향후 확장용)
class AppColorsDark {
  AppColorsDark._();
  
  static const Color primary = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF42A5F5);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
}
