const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function fixQKeyAmounts() {
  console.log('🔧 QKEY 거래 내역 수정 시작...\n');
  
  try {
    // 1. 10 QKEY 거래 찾기
    const snapshot = await db.collection('qkey_transactions')
      .where('type', '==', 'earn')
      .where('amount', '==', 10)
      .get();
    
    if (snapshot.empty) {
      console.log('✅ 수정할 10 QKEY 거래가 없습니다.');
      return;
    }
    
    console.log(`📊 발견된 10 QKEY 거래: ${snapshot.size}개\n`);
    
    // 2. 배치 업데이트 준비
    const batch = db.batch();
    let updateCount = 0;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const oldAmount = data.amount;
      const oldBalance = data.balanceAfter;
      
      // 새로운 잔액 계산: 기존 잔액에서 (10-2) = 8을 빼기
      const newBalance = oldBalance - 8;
      
      console.log(`📝 문서 ID: ${doc.id}`);
      console.log(`   userId: ${data.userId}`);
      console.log(`   amount: ${oldAmount} → 2 QKEY`);
      console.log(`   balanceAfter: ${oldBalance} → ${newBalance} QKEY`);
      console.log(`   timestamp: ${data.timestamp?.toDate?.() || data.created_at?.toDate?.() || 'N/A'}`);
      console.log('');
      
      // 배치에 추가
      batch.update(doc.ref, {
        amount: 2,
        balanceAfter: newBalance
      });
      
      updateCount++;
    });
    
    // 3. 배치 실행
    console.log(`\n🔄 ${updateCount}개 거래 수정 중...`);
    await batch.commit();
    console.log('✅ 수정 완료!\n');
    
    // 4. 사용자별 실제 잔액 재계산 필요 안내
    console.log('⚠️  주의사항:');
    console.log('   - 거래 내역의 amount와 balanceAfter는 수정되었습니다');
    console.log('   - 하지만 각 사용자의 현재 실제 잔액(users 컬렉션의 qkey_balance)은');
    console.log('     수정되지 않았습니다');
    console.log('   - 사용자가 다음에 QKEY를 적립받으면 자동으로 재계산됩니다\n');
    
    // 5. 영향받은 사용자 목록
    const affectedUsers = new Set();
    snapshot.forEach(doc => {
      affectedUsers.add(doc.data().userId);
    });
    
    console.log(`👥 영향받은 사용자: ${affectedUsers.size}명`);
    console.log(`   사용자 ID: ${Array.from(affectedUsers).join(', ')}\n`);
    
    // 6. 최종 통계
    const finalSnapshot = await db.collection('qkey_transactions')
      .where('type', '==', 'earn')
      .get();
    
    const amountCounts = {};
    finalSnapshot.forEach(doc => {
      const amount = doc.data().amount;
      amountCounts[amount] = (amountCounts[amount] || 0) + 1;
    });
    
    console.log('📊 수정 후 적립량별 통계:');
    Object.entries(amountCounts).sort((a, b) => b[0] - a[0]).forEach(([amount, count]) => {
      console.log(`   ${amount} QKEY: ${count}개`);
    });
    
  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

fixQKeyAmounts();
