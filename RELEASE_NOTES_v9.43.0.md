# QRChat v9.43.0 Release Notes

**릴리즈 날짜**: 2026-02-13 08:40 UTC  
**버전**: 9.43.0 (Build 9430)  
**플랫폼**: Android  
**빌드 도구**: Flutter 3.41.0 / Dart 3.11.0

---

## 📱 주요 개선사항

### ✅ 친구추가 요청 성공 알림
- **기능**: 검색에서 친구추가 버튼 클릭 시 **"친구추가를 요청하였습니다"** 녹색 스낵바 표시
- **구현 위치**: `lib/screens/friend_search_screen.dart` line 136
- **동작 확인**: 
  ```dart
  _showSnackBar('친구추가를 요청하였습니다', isSuccess: true);
  ```
- **UI 색상**: 성공 시 녹색 배경, 실패 시 빨간색 배경
- **표시 시간**: 2초

### 🔔 푸쉬알림 2회당 1회 소리 기능 확인
- **기능**: 수신자가 앱을 내려놓거나 다른 창에 있을 때 푸쉬알림 소리가 2회당 1회 재생
- **구현 위치**: `lib/services/local_notification_service.dart`
- **로직**:
  ```dart
  static int _notificationCount = 0;
  
  Future<void> showNotification(...) async {
    _notificationCount++;
    bool shouldPlaySound = (_notificationCount % 2 == 0);
    
    if (shouldPlaySound) {
      await playNotificationSound();
      print('🔊 알림음 재생 (2회당 1회)');
    } else {
      print('🔇 알림음 생략 (다음 알림에서 재생)');
    }
  }
  ```
- **알림음 파일**: `sounds/notification.mp3` (기본), `sounds/default.mp3` (폴백)

### 📋 적용 지점 확인
1. **백그라운드 푸쉬**: `firebase_notification_service.dart` line 26
2. **포그라운드 푸쉬**: `firebase_notification_service.dart` line 164
3. **Firestore 트리거**: `firebase_notification_service.dart` line 282

---

## 🐛 주석 수정
- `friend_search_screen.dart` line 162: ~~"에러 스낵바 표시 (성공 메시지는 제거)"~~ → **"스낵바 표시 (성공 시 녹색, 실패 시 빨간색)"**
- 기능은 정상 작동하고 있었으나 주석이 잘못 기재되어 있던 문제 수정

---

## 📦 배포 파일
- **APK**: `QRChat-v9.43.0-NOTIFICATION-FIX.apk` (69 MB)
- **ZIP**: `QRChat-v9.43.0-NOTIFICATION-FIX.zip` (33 MB, 압축률 53%)
- **다운로드**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html

---

## 🔍 테스트 시나리오

### 친구추가 스낵바 테스트
1. QRChat 실행 → 친구 탭 → 돋보기 아이콘 클릭
2. 닉네임 검색 → 친구추가 버튼 클릭
3. **하단에 "친구추가를 요청하였습니다" 녹색바** 표시 확인

### 푸쉬알림 소리 테스트
1. 두 개의 디바이스(A, B) 준비
2. 디바이스 B에서 앱을 백그라운드로 전환 또는 종료
3. 디바이스 A에서 B에게 메시지 전송
   - **1번째 메시지**: 알림 표시, 소리 없음
   - **2번째 메시지**: 알림 표시, 소리 재생 ✅
   - **3번째 메시지**: 알림 표시, 소리 없음
   - **4번째 메시지**: 알림 표시, 소리 재생 ✅
4. 로그 확인: `adb logcat | grep "알림음"`
   ```
   🔇 알림음 생략 (다음 알림에서 재생)
   🔊 알림음 재생 (2회당 1회)
   ```

---

## 🏷️ Git 정보
- **Commit**: 1ae4e57
- **Tag**: v9.43.0
- **Branch**: main

---

## 📊 버전 히스토리
| 버전 | 내용 |
|------|------|
| v9.39.0 | 프로필 탭으로 바로 Securet 연결 (팝업 제거) |
| v9.40.0 | 동영상 재입장 버그 진단 (디버그 버전) |
| v9.41.0 | 1:1 채팅 동영상 재입장 버그 수정 (ValueKey 추가) |
| v9.42.0 | 그룹방 동영상 재입장 버그 수정 |
| v9.43.0 | 친구추가 스낵바 및 푸쉬알림 소리 기능 정상 확인 |

---

## ✅ 확인된 기능
1. ✅ 친구추가 요청 시 녹색 스낵바 표시
2. ✅ 푸쉬알림 2회당 1회 소리 재생
3. ✅ 백그라운드/포그라운드/종료 상태 모두 지원
4. ✅ 1:1 및 그룹 채팅 동영상 재생
5. ✅ Securet 바로 연결

---

**이 버전은 사용자가 보고한 두 가지 기능이 정상 작동하고 있음을 확인하고, 잘못된 주석을 수정한 안정화 릴리즈입니다.**
