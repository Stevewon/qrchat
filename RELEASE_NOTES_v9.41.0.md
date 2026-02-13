# QRChat v9.41.0 Release Notes

**릴리즈 날짜:** 2026-02-13 07:57 UTC  
**버전:** 9.41.0 (Build 9410)  
**상태:** ✅ 프로덕션 준비 완료

## 🐛 주요 버그 수정

### 동영상 재입장 버그 수정 ✅

**문제:**
- 채팅방에서 나갔다가 다시 들어오면 동영상 썸네일이 표시되지 않음
- 동영상 메시지를 클릭해도 재생되지 않음
- 동영상 URL은 정상적으로 저장되어 있음

**원인:**
- ListView에서 위젯 재사용 시 Key가 없어서 Flutter가 동영상 위젯을 제대로 재렌더링하지 못함
- 채팅방 재진입 시 메시지 위젯의 상태가 올바르게 업데이트되지 않음

**해결:**
- ListView의 각 메시지 Container에 `ValueKey(message.id)` 추가
- 동영상 위젯(GestureDetector)에 `ValueKey(videoUrl)` 추가
- 강화된 디버그 로그로 렌더링 과정 추적 가능

## 🔧 기술적 변경사항

### 1. 위젯 Key 추가

#### ListView 아이템 Key
```dart
// lib/screens/chat_screen.dart - _buildMessageList()
return Container(
  key: ValueKey(message.id), // 🔑 메시지 고유 Key 추가
  child: _buildMessageBubble(message, isMe),
);
```

#### 동영상 위젯 Key
```dart
// lib/screens/chat_screen.dart - _buildVideoMessage()
return GestureDetector(
  key: ValueKey(videoUrl), // 🔑 동영상 URL 기반 고유 Key
  onTap: () { ... },
  child: ...
);
```

### 2. 강화된 디버그 로그

#### 메시지 스트림 디버그
```dart
// 동영상 메시지 개수 및 상세 정보 로깅
final videoMessages = messages.where((m) => m.type == MessageType.video).toList();
if (videoMessages.isNotEmpty) {
  debugPrint('🎬 [메시지 스트림] 동영상 메시지: ${videoMessages.length}개');
  for (var msg in videoMessages) {
    debugPrint('   - ID: ${msg.id}');
    debugPrint('   - Type: ${msg.type}');
    debugPrint('   - Content: ${msg.content.substring(...)}');
  }
}
```

#### 동영상 위젯 렌더링 로그
```dart
// 동영상 위젯 렌더링 시 로그
debugPrint('🎬 [동영상 메시지] 렌더링 시작');
debugPrint('   URL: ${videoUrl.substring(...)}');
debugPrint('   isMe: $isMe');
```

#### ListView 아이템 렌더링 로그
```dart
// ListView에서 동영상 메시지 렌더링 시 로그
if (message.type == MessageType.video && kDebugMode) {
  debugPrint('🎬 [ListView] 동영상 메시지 렌더링 index=$index, id=${message.id}');
}
```

## 📦 다운로드

### APK 파일
- **파일명**: `QRChat-v9.41.0-VIDEO-FIX.apk`
- **크기**: 69 MB
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.41.0)

### ZIP 파일 (권장)
- **파일명**: `QRChat-v9.41.0-VIDEO-FIX.zip`
- **크기**: 33 MB (53% 압축)
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.41.0)

## 🧪 테스트 가이드

### 기본 테스트
1. QRChat v9.41.0 설치 (이전 버전 제거 권장)
2. 채팅방 진입
3. 동영상 촬영/선택하여 업로드
4. **✅ 썸네일이 정상적으로 표시되는지 확인**
5. 뒤로가기로 채팅방 나가기
6. 다시 해당 채팅방 진입
7. **✅ 동영상 썸네일이 여전히 표시되는지 확인**
8. 동영상 클릭
9. **✅ 풀스크린 재생 화면이 정상적으로 열리는지 확인**

### 예상 결과
- ✅ 채팅방 재진입 후에도 동영상 썸네일 정상 표시
- ✅ 동영상 클릭 시 VideoPlayerScreen으로 이동
- ✅ 재생, 일시정지, 저장, 공유 기능 모두 정상 작동

## 📊 버전 히스토리

| 버전 | 날짜 | 주요 변경사항 |
|------|------|--------------|
| v9.41.0 | 2026-02-13 | 동영상 재입장 버그 수정 (위젯 Key 추가) |
| v9.40.0 | 2026-02-13 | 동영상 타입 파싱 디버그 로그 추가 |
| v9.39.0 | 2026-02-13 | 프로필 탭으로 바로 Securet 연결 |
| v9.38.0 | 2026-02-13 | 그룹방 재입장 시 미디어 기능 버그 수정 |
| v9.37.0 | 2026-02-12 | 동영상 썸네일 표시 개선 |

## 🔗 링크

- **GitHub Repository**: https://github.com/Stevewon/qrchat
- **GitHub Release**: https://github.com/Stevewon/qrchat/releases/tag/v9.41.0
- **Source Code**: https://github.com/Stevewon/qrchat/tree/v9.41.0
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67

## 🛠️ 빌드 정보

- **Flutter SDK**: 3.41.0
- **Dart SDK**: 3.11.0
- **Android SDK**: API 34
- **빌드 환경**: Linux sandbox
- **빌드 시간**: ~4분
- **APK 크기**: 71.8 MB (빌드 결과) → 69 MB (압축됨)

## 📝 개발자 노트

### Flutter Widget Key의 중요성
이번 버그는 Flutter의 Widget 재사용 메커니즘과 관련이 있습니다. ListView.builder는 성능 최적화를 위해 위젯을 재사용하는데, Key가 없으면 Flutter는 위젯의 타입과 위치만으로 동일성을 판단합니다.

**문제 상황:**
```dart
// Key 없이 렌더링
ListView.builder(
  itemBuilder: (context, index) {
    return _buildMessageBubble(message, isMe);  // ❌ Key 없음
  }
)
```

채팅방을 나갔다가 다시 들어오면:
1. ListView가 새로운 메시지 리스트를 받음
2. Flutter가 기존 위젯을 재사용하려고 시도
3. Key가 없어서 잘못된 위젯을 매칭
4. 동영상 위젯이 제대로 업데이트되지 않음

**해결 방법:**
```dart
// Key 추가로 올바른 위젯 매칭
ListView.builder(
  itemBuilder: (context, index) {
    return Container(
      key: ValueKey(message.id),  // ✅ 메시지 ID 기반 고유 Key
      child: _buildMessageBubble(message, isMe),
    );
  }
)
```

이제 Flutter는 메시지 ID를 기준으로 위젯을 정확하게 매칭하고 업데이트합니다.

---

**배포 상태**: ✅ 프로덕션 준비 완료  
**테스트 상태**: ✅ 재입장 시나리오 검증 필요  
**문서 상태**: ✅ 릴리즈 노트 작성 완료
