# 🎁 그룹 채팅 랜덤 보상 시스템 구현 가이드

## 📋 개요
- **기능**: 3인 이상 그룹 채팅에서 2분 이상 대화 시 랜덤 구체 등장
- **보상**: 1~10 QKEY 랜덤 지급
- **출금**: 10,000 QKEY 모으면 출금 신청 가능

---

## ✅ 이미 완성된 파일들

### 1️⃣ 모델 파일
- **파일**: `lib/models/reward_event.dart`
- **크기**: 4.3 KB
- **내용**: RewardEvent 모델, RewardEventStatus enum

### 2️⃣ 서비스 파일
- **파일**: `lib/services/reward_event_service.dart`
- **크기**: 8 KB
- **내용**: 
  - 대화 추적 로직
  - 이벤트 생성 로직
  - 선착순 클릭 처리 (Firestore Transaction)
  - QKEY 지급 연동

### 3️⃣ 위젯 파일
- **파일**: `lib/widgets/floating_reward_orb.dart`
- **크기**: 10.5 KB
- **내용**:
  - FloatingRewardOrb (떠다니는 구체)
  - RewardClaimedAnimation (획득 애니메이션)
  - OrbSpawnParticles (생성 파티클)

---

## 🔧 그룹 채팅 화면 통합 방법

### Step 1: Import 추가

`lib/screens/group_chat_screen.dart` 파일 상단에 추가:

```dart
import '../models/reward_event.dart';
import '../services/reward_event_service.dart';
import '../widgets/floating_reward_orb.dart';
```

### Step 2: State 변수 추가

`_GroupChatScreenState` 클래스에 추가:

```dart
class _GroupChatScreenState extends State<GroupChatScreen> {
  // 기존 변수들...
  
  // 🎁 보상 이벤트 관련
  List<RewardEvent> _activeRewardEvents = [];
  StreamSubscription<List<RewardEvent>>? _rewardEventsSubscription;
  bool _showClaimedAnimation = false;
  int _claimedAmount = 0;

  // ... 나머지 코드
}
```

### Step 3: initState 수정

```dart
@override
void initState() {
  super.initState();
  // 기존 초기화 코드...
  
  // 🎁 보상 이벤트 스트림 구독
  _listenToRewardEvents();
}
```

### Step 4: 보상 이벤트 리스너 추가

```dart
/// 보상 이벤트 스트림 구독
void _listenToRewardEvents() {
  _rewardEventsSubscription = RewardEventService
      .getActiveEvents(widget.chatRoom.id)
      .listen((events) {
    if (mounted) {
      setState(() {
        _activeRewardEvents = events;
      });
    }
  });
}
```

### Step 5: dispose 수정

```dart
@override
void dispose() {
  // 기존 dispose 코드...
  
  // 🎁 보상 이벤트 구독 해제
  _rewardEventsSubscription?.cancel();
  
  super.dispose();
}
```

### Step 6: 메시지 전송 시 이벤트 트리거

`_sendMessage` 메소드 끝에 추가:

```dart
Future<void> _sendMessage() async {
  // 기존 메시지 전송 코드...
  
  // 🎁 보상 이벤트 트리거 (비동기)
  RewardEventService.onMessageSent(
    chatRoomId: widget.chatRoom.id,
    participantCount: widget.chatRoom.participants.length,
  );
}
```

### Step 7: UI에 구체 위젯 추가

`build` 메소드의 Scaffold body를 Stack으로 감싸고 구체 추가:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      // AppBar 코드...
    ),
    body: Stack(
      children: [
        // 기존 채팅 UI (Column)
        Column(
          children: [
            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                // 기존 코드...
              ),
            ),
            // 입력창
            Container(
              // 기존 코드...
            ),
          ],
        ),

        // 🎁 떠다니는 보상 구체들
        ..._activeRewardEvents.map((event) => FloatingRewardOrb(
              event: event,
              onTap: () => _claimReward(event),
            )),

        // 🎉 보상 획득 애니메이션
        if (_showClaimedAnimation)
          RewardClaimedAnimation(
            amount: _claimedAmount,
            onComplete: () {
              setState(() {
                _showClaimedAnimation = false;
              });
            },
          ),
      ],
    ),
  );
}
```

### Step 8: 보상 클릭 처리 메소드 추가

```dart
/// 보상 구체 클릭 처리
Future<void> _claimReward(RewardEvent event) async {
  try {
    // 현재 사용자 정보 가져오기
    final currentUser = await SecuretAuthService.getCurrentUser();
    if (currentUser == null) return;

    // 보상 획득 시도
    final success = await RewardEventService.claimReward(
      eventId: event.id,
      user: currentUser,
    );

    if (success && mounted) {
      // 성공 애니메이션 표시
      setState(() {
        _claimedAmount = event.rewardAmount;
        _showClaimedAnimation = true;
      });

      // 성공 피드백
      HapticFeedback.mediumImpact();
      
      // 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${event.rewardAmount} QKEY를 획득했습니다!'),
          backgroundColor: Colors.amber[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      // 실패 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 다른 사용자가 먼저 획득했습니다'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ 보상 획득 오류: $e');
  }
}
```

---

## 🔥 Firestore 보안 규칙 추가

`firestore.rules` 파일에 추가:

```javascript
// 보상 이벤트 컬렉션
match /reward_events/{eventId} {
  // 읽기: 해당 채팅방 참여자만
  allow read: if request.auth != null;
  
  // 생성: 서버에서만 (클라이언트에서는 생성 불가)
  allow create: if false;
  
  // 업데이트: 클릭 처리 시에만 (status를 claimed로 변경)
  allow update: if request.auth != null 
    && resource.data.status == 'active'
    && request.resource.data.status == 'claimed'
    && request.resource.data.claimedByUserId == request.auth.uid;
  
  // 삭제: 불가
  allow delete: if false;
}
```

---

## 🧪 테스트 방법

### 1️⃣ 수동 이벤트 생성 (테스트용)

Firestore 콘솔에서 직접 생성:

```json
{
  "chatRoomId": "your-chat-room-id",
  "rewardAmount": 5,
  "createdAt": "현재 시간",
  "expiresAt": "현재 시간 + 30초",
  "status": "active",
  "positionX": 0.5,
  "positionY": 0.5,
  "claimedByUserId": null,
  "claimedByNickname": null,
  "claimedAt": null
}
```

### 2️⃣ 실제 대화 테스트

1. 3명 이상 그룹 채팅 생성
2. 2분 동안 계속 메시지 전송
3. 구체가 랜덤으로 등장하는지 확인
4. 구체 클릭 시 QKEY 지급 확인

### 3️⃣ 로그 확인

```dart
// 서비스 로그 확인
debugPrint('🎁 대화 지속 시간: ${duration}초');
debugPrint('🎉 보상 이벤트 생성! 채팅방: $chatRoomId, 보상: ${rewardAmount} QKEY');
debugPrint('✅ ${user.nickname}님이 ${result} QKEY 획득!');
```

---

## ⚙️ 설정 값 조정

`lib/services/reward_event_service.dart` 에서 조정 가능:

```dart
/// 최소 참여자 수
static const int minParticipants = 3;

/// 대화 지속 시간 (초)
static const int conversationDuration = 120; // 2분

/// 이벤트 생성 확률 (0.0 ~ 1.0)
static const double eventProbability = 0.3; // 30%

/// 이벤트 만료 시간 (초)
static const int eventExpiration = 30; // 30초

/// 이벤트 생성 쿨다운 (초)
static const int eventCooldownSeconds = 300; // 5분

/// 최소 보상 QKEY
static const int minReward = 1;

/// 최대 보상 QKEY
static const int maxReward = 10;
```

---

## 🎨 UI 커스터마이징

### 구체 색상 변경

`lib/widgets/floating_reward_orb.dart`:

```dart
gradient: RadialGradient(
  colors: [
    Colors.amber[200]!,  // 밝은 금색
    Colors.amber[400]!,  // 중간 금색
    Colors.orange[600]!, // 진한 주황색
  ],
  stops: const [0.0, 0.5, 1.0],
),
```

### 구체 크기 변경

```dart
Container(
  width: 60,  // 기본 60
  height: 60, // 기본 60
  // ...
)
```

### 애니메이션 속도 변경

```dart
// 상하 떠다니기 속도
_floatingController = AnimationController(
  duration: const Duration(seconds: 3), // 3초 → 원하는 값
  vsync: this,
)..repeat(reverse: true);

// 회전 속도
_rotationController = AnimationController(
  duration: const Duration(seconds: 10), // 10초 → 원하는 값
  vsync: this,
)..repeat();
```

---

## 🐛 트러블슈팅

### 문제 1: 구체가 나타나지 않음
- **원인**: 참여자 수 부족 또는 대화 시간 부족
- **해결**: 로그 확인 (`debugPrint` 메시지 체크)

### 문제 2: 클릭해도 QKEY가 지급되지 않음
- **원인**: 이미 다른 사용자가 클릭함
- **해결**: Firestore에서 이벤트 상태 확인

### 문제 3: 구체가 너무 자주 생성됨
- **원인**: `eventProbability`가 너무 높음
- **해결**: 확률 값 낮추기 (예: 0.3 → 0.1)

### 문제 4: 구체가 화면 밖에 생성됨
- **원인**: positionX, positionY 값이 범위를 벗어남
- **해결**: 0.3 ~ 0.7 범위로 제한 (이미 적용됨)

---

## 📊 통계 확인

### 채팅방 통계 조회

```dart
final stats = await RewardEventService.getChatRoomStats(chatRoomId);
print('총 이벤트 수: ${stats['totalEvents']}');
print('획득된 이벤트: ${stats['claimedEvents']}');
print('만료된 이벤트: ${stats['expiredEvents']}');
print('총 지급 QKEY: ${stats['totalRewards']}');
```

### 사용자 보상 히스토리

```dart
final history = await RewardEventService.getUserRewardHistory(userId);
for (var event in history) {
  print('${event.claimedAt}: ${event.rewardAmount} QKEY');
}
```

---

## 🚀 다음 단계

### 옵션 기능 추가 (선택 사항)

1. **보상 배수 이벤트**
   - 특정 시간대에 2배 보상
   - 주말 특별 이벤트

2. **레어 구체**
   - 1% 확률로 50~100 QKEY 지급
   - 다른 색상 (보라색, 다이아몬드 등)

3. **연속 획득 보너스**
   - 연속으로 3개 획득 시 추가 보너스

4. **그룹별 리더보드**
   - 채팅방별 최다 획득자 표시
   - 월간 랭킹

---

## ✅ 체크리스트

배포 전 확인 사항:

- [ ] Firestore 보안 규칙 적용
- [ ] 그룹 채팅 화면에 코드 통합
- [ ] 테스트 (3인 이상 그룹, 2분 대화)
- [ ] 클릭 동시성 테스트
- [ ] QKEY 지급 확인
- [ ] 출금 시스템 연동 확인
- [ ] 로그 메시지 제거 또는 프로덕션 모드 분기
- [ ] 성능 테스트 (여러 채팅방 동시 사용)

---

**문의**: 추가 기능이나 문제 발생 시 이슈 등록

**업데이트**: 2026-02-16
