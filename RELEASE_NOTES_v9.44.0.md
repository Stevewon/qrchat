# QRChat v9.44.0 Release Notes

**릴리즈 날짜**: 2026-02-13 08:58 UTC  
**버전**: 9.44.0 (Build 9440)  
**플랫폼**: Android  
**빌드 도구**: Flutter 3.41.0 / Dart 3.11.0

---

## 🎨 주요 개선사항

### ✨ 카카오톡 스타일 프로필 화면 개편

#### 1. **우측 상단 설정(톱니바퀴) 아이콘 추가**
- **위치**: AppBar 우측 상단
- **기능**: 설정 메뉴를 바텀시트로 표시
- **디자인**: iOS/카카오톡 스타일 DraggableScrollableSheet

#### 2. **프로필 화면 간소화**
**남긴 항목** (프로필 화면):
- ✅ 프로필 사진 + 닉네임 + 상태 메시지
- ✅ Securet 보안 연동 배지 (그라데이션 카드 스타일)
- ✅ My QR Code

**설정으로 이동한 항목**:
- ⚙️ 알림음 설정
- ⚙️ About 정보
- ⚙️ 스티커 관리자
- ⚙️ 로그아웃
- ⚙️ 회원탈퇴

#### 3. **Securet 배지 디자인 개선**
- **변경 전**: 작은 회색 배지
- **변경 후**: 
  - 블루 그라데이션 카드 (Color(0xFF1976D2) → Color(0xFF42A5F5))
  - 그림자 효과 추가 (boxShadow)
  - "Securet 보안 연동 중" 텍스트
  - 우측에 verified_user 아이콘

---

## 🎯 UI/UX 개선 사항

### Before (v9.43.0):
```
[프로필 화면]
├─ 프로필 헤더
├─ Securet 연동 (작은 배지)
├─ My QR Code
├─ 알림음 설정
├─ About
├─ [두꺼운 구분선]
├─ 스티커 관리자 버튼
├─ 로그아웃 버튼
└─ 회원탈퇴 버튼
```

### After (v9.44.0):
```
[프로필 화면]                    [설정 바텀시트]
├─ [⚙️ 설정 아이콘]           ├─ 제목: "설정"
├─ 프로필 헤더                  ├─ 알림음 설정 (Switch)
├─ Securet 보안 연동 카드       ├─ About 정보
└─ My QR Code                   ├─ [구분선]
                                ├─ 스티커 관리자 버튼
                                ├─ 로그아웃 버튼
                                └─ 회원탈퇴 버튼
```

---

## 📱 사용자 경험 개선

### 1. **깔끔한 프로필 화면**
- 불필요한 항목 제거로 시각적 혼란 감소
- Securet 연동 상태가 눈에 띄게 강조
- 카카오톡과 유사한 친숙한 UI

### 2. **설정 접근성 향상**
- 우측 상단 톱니바퀴 아이콘으로 직관적 접근
- 바텀시트로 빠른 설정 변경 가능
- 드래그 가능한 시트로 사용자 제어권 강화

### 3. **Securet 배지 강조**
- 그라데이션 + 그림자 효과로 프리미엄 느낌
- "보안 연동 중" 텍스트로 상태 명확화
- 사용자의 보안 기능 사용 독려

---

## 🔧 기술 세부사항

### 코드 변경 사항

#### AppBar 추가
```dart
appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.settings, color: Colors.black87),
      onPressed: () {
        _showSettingsBottomSheet();
      },
    ),
  ],
),
```

#### 설정 바텀시트
```dart
void _showSettingsBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        // 설정 메뉴 UI
      ),
    ),
  );
}
```

#### Securet 배지 그라데이션
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1976D2).withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  // ...
)
```

---

## 📦 배포 파일
- **APK**: `QRChat-v9.44.0-KAKAO-PROFILE.apk` (69 MB)
- **ZIP**: `QRChat-v9.44.0-KAKAO-PROFILE.zip` (33 MB, 압축률 53%)
- **다운로드**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html

---

## 🔍 테스트 시나리오

### 1. 프로필 화면 확인
1. QRChat 실행 → 하단 탭 "프로필" 클릭
2. **우측 상단에 톱니바퀴 아이콘 확인** ✅
3. Securet 보안 연동 카드가 **블루 그라데이션**으로 표시됨 확인 ✅
4. My QR Code 항목만 표시되고, 다른 설정은 숨겨짐 확인 ✅

### 2. 설정 바텀시트 확인
1. 우측 상단 톱니바퀴 클릭
2. **바텀시트가 아래에서 올라옴** ✅
3. 드래그로 높이 조절 가능 확인 ✅
4. 알림음 설정, About, 스티커 관리자, 로그아웃, 회원탈퇴 항목 표시 확인 ✅

### 3. 기능 동작 확인
1. 설정 바텀시트에서 알림음 Switch 토글 → 스낵바 표시 확인
2. 스티커 관리자 클릭 → 바텀시트 닫히고 스티커 화면 이동 확인
3. 로그아웃 클릭 → 바텀시트 닫히고 로그인 화면 이동 확인
4. 회원탈퇴 클릭 → 바텀시트 닫히고 탈퇴 확인 다이얼로그 표시 확인

---

## 🏷️ Git 정보
- **Commit**: e2dff47
- **Tag**: v9.44.0
- **Branch**: main

---

## 📊 버전 히스토리
| 버전 | 내용 |
|------|------|
| v9.41.0 | 1:1 채팅 동영상 재입장 버그 수정 |
| v9.42.0 | 그룹방 동영상 재입장 버그 수정 |
| v9.43.0 | 친구추가 스낵바 및 푸쉬알림 기능 확인 |
| **v9.44.0** | **카카오톡 스타일 프로필 화면 개편** |

---

## ✅ 주요 변경 사항 요약

| 항목 | v9.43.0 | v9.44.0 |
|------|---------|---------|
| 프로필 화면 항목 수 | 8개 | 3개 (간소화) |
| 설정 아이콘 | ❌ | ✅ 우측 상단 |
| Securet 배지 디자인 | 작은 회색 배지 | 블루 그라데이션 카드 |
| 설정 접근 | 스크롤 필요 | 톱니바퀴 1탭 |
| UI 스타일 | 일반 | 카카오톡 스타일 |

---

**이 버전은 사용자 요청에 따라 프로필 화면을 카카오톡 스타일로 대폭 개편하여 깔끔하고 직관적인 UI를 제공합니다.**
