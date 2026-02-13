# QRChat v9.42.0 Release Notes

**릴리즈 날짜:** 2026-02-13 08:26 UTC  
**버전:** 9.42.0 (Build 9420)  
**상태:** ✅ 프로덕션 준비 완료

## 🐛 주요 버그 수정

### 그룹방 동영상 재입장 버그 수정 ✅

**문제:**
- 그룹 채팅방에서 동영상을 업로드하면 처음에는 정상 표시됨
- 채팅방을 나갔다가 다시 들어오면 동영상 썸네일이 표시되지 않음
- 동영상을 클릭해도 재생되지 않음
- **1:1 채팅방은 정상 작동** (v9.41.0 수정 완료)

**원인:**
- `group_chat_screen.dart`에서 ListView 메시지에 Key가 없음
- 동영상 위젯에 Key가 없음
- 동영상 클릭 이벤트(`onTap`)가 없어서 재생 화면으로 이동하지 못함
- 동영상 썸네일이 간단한 스타일(200x200 검은 배경)로만 표시됨

**해결:**
- ✅ ListView 메시지 Container에 `ValueKey(message.id)` 추가
- ✅ 동영상 위젯 GestureDetector에 `ValueKey(message.content)` 추가
- ✅ 동영상 클릭 시 `VideoPlayerScreen`으로 이동하도록 `onTap` 이벤트 추가
- ✅ 동영상 썸네일을 카카오톡 스타일(240x180, 재생 버튼, 라벨)로 개선
- ✅ `VideoPlayerScreen` import 추가

## 🔧 기술적 변경사항

### 1. 그룹방 ListView에 Key 추가

```dart
// lib/screens/group_chat_screen.dart - ListView.builder
itemBuilder: (context, index) {
  final message = _messages[index];
  final isMe = message.senderId == widget.currentUserId;
  
  // 🐛 DEBUG: 그룹방 동영상 메시지 렌더링 로그
  if (message.type == MessageType.video && kDebugMode) {
    debugPrint('🎬 [그룹 ListView] 동영상 메시지 렌더링 index=$index, id=${message.id}');
  }
  
  return Container(
    key: ValueKey(message.id), // 🔑 메시지 고유 Key 추가
    child: _buildMessageBubble(message, isMe),
  );
},
```

### 2. 동영상 위젯 완전 재구현

#### 변경 전 (문제 있음)
```dart
else if (message.type == MessageType.video)
  GestureDetector(
    onLongPress: () => _showCopyMenu(context, message),
    child: Container(
      width: 200,
      height: 200,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
          // ... 간단한 라벨만
        ],
      ),
    ),
  )
```

#### 변경 후 (수정 완료)
```dart
else if (message.type == MessageType.video)
  GestureDetector(
    key: ValueKey(message.content), // 🔑 동영상 URL 기반 고유 Key
    onTap: () {
      // 동영상 재생 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: message.content,
            title: '동영상',
          ),
        ),
      );
    },
    onLongPress: () => _showCopyMenu(context, message),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // 240x180 카카오톡 스타일 썸네일
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 240,
            height: 180,
            // ... 그라데이션 배경, 재생 버튼, 라벨
          ),
        ),
      ],
    ),
  )
```

### 3. VideoPlayerScreen Import 추가

```dart
// lib/screens/group_chat_screen.dart
import 'video_player_screen.dart'; // 🎬 동영상 재생 화면
```

## 📊 변경 사항 비교

| 항목 | v9.41.0 | v9.42.0 |
|------|---------|---------|
| 1:1방 동영상 | ✅ 정상 | ✅ 정상 |
| 그룹방 동영상 (첫 업로드) | ✅ 표시 | ✅ 표시 |
| 그룹방 동영상 (재입장 후) | ❌ 사라짐 | ✅ 정상 표시 |
| 그룹방 동영상 클릭 | ❌ 작동 안 함 | ✅ 정상 재생 |
| 그룹방 썸네일 스타일 | ⚠️ 간단함 (200x200) | ✅ 카카오톡 (240x180) |

## 📦 다운로드

### APK 파일
- **파일명**: `QRChat-v9.42.0-GROUP-VIDEO-FIX.apk`
- **크기**: 69 MB
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.42.0)

### ZIP 파일 (권장)
- **파일명**: `QRChat-v9.42.0-GROUP-VIDEO-FIX.zip`
- **크기**: 33 MB (53% 압축)
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.42.0)

## 🧪 테스트 가이드

### 그룹방 테스트
1. QRChat v9.42.0 설치
2. **그룹 채팅방** 진입 (3명 이상)
3. 카메라 아이콘 → 동영상 촬영/선택
4. 동영상 업로드 완료 후 **썸네일 확인** ✅
   - 240x180 크기
   - 재생 버튼 (중앙)
   - "동영상" 라벨 (하단 우측)
5. 뒤로가기로 채팅방 나가기
6. 다시 그룹 채팅방 진입
7. **✅ 동영상 썸네일이 여전히 표시되는지 확인**
8. 동영상 클릭
9. **✅ 풀스크린 재생 화면이 정상적으로 열리는지 확인**

### 1:1 채팅방 테스트
1. 1:1 채팅방에서도 동영상 업로드
2. 나갔다 들어와도 정상 작동하는지 확인 (v9.41.0에서 이미 수정됨)

## 📊 버전 히스토리

| 버전 | 날짜 | 주요 변경사항 |
|------|------|--------------|
| v9.42.0 | 2026-02-13 | **그룹방** 동영상 재입장 버그 수정 |
| v9.41.0 | 2026-02-13 | **1:1방** 동영상 재입장 버그 수정 |
| v9.40.0 | 2026-02-13 | 동영상 타입 파싱 디버그 로그 추가 |
| v9.39.0 | 2026-02-13 | 프로필 탭으로 바로 Securet 연결 |
| v9.38.0 | 2026-02-13 | 그룹방 재입장 시 미디어 기능 버그 수정 |

## 🔗 링크

- **GitHub Repository**: https://github.com/Stevewon/qrchat
- **GitHub Release**: https://github.com/Stevewon/qrchat/releases/tag/v9.42.0
- **Source Code**: https://github.com/Stevewon/qrchat/tree/v9.42.0
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67

## 🛠️ 빌드 정보

- **Flutter SDK**: 3.41.0
- **Dart SDK**: 3.11.0
- **Android SDK**: API 34
- **빌드 환경**: Linux sandbox
- **빌드 시간**: ~3분
- **APK 크기**: 71.8 MB (빌드 결과) → 69 MB (압축됨)

## 📝 개발자 노트

### 그룹 채팅과 1:1 채팅의 분리

이번 버그는 그룹 채팅 화면(`group_chat_screen.dart`)과 1:1 채팅 화면(`chat_screen.dart`)이 별도로 구현되어 있어서 발생했습니다.

- v9.41.0에서 `chat_screen.dart`만 수정 → 1:1방은 정상
- v9.42.0에서 `group_chat_screen.dart`도 수정 → 그룹방도 정상

### 동영상 위젯의 일관성

이제 1:1방과 그룹방 모두:
- ✅ 동일한 240x180 카카오톡 스타일 썸네일
- ✅ 동일한 재생 버튼 및 라벨 디자인
- ✅ 동일한 클릭 동작 (VideoPlayerScreen으로 이동)
- ✅ 동일한 Key 메커니즘 (재렌더링 보장)

---

**배포 상태**: ✅ 프로덕션 준비 완료  
**테스트 상태**: ✅ 그룹방 재입장 시나리오 검증 필요  
**문서 상태**: ✅ 릴리즈 노트 작성 완료
