#!/usr/bin/env node

/**
 * QKEY 거래 내역 적립량 일괄 변경 스크립트
 * 기존 적립 거래의 amount를 10 → 2로 변경
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'qrchat-b7a67'
});

const db = admin.firestore();

async function updateQKeyAmounts() {
  try {
    console.log('🔧 QKEY 거래 내역 적립량 변경 스크립트 시작...\n');
    
    // 1. 모든 적립 거래 조회 (type = 'earn')
    console.log('📦 적립 거래 내역 조회 중...\n');
    
    const snapshot = await db.collection('qkey_transactions')
      .where('type', '==', 'earn')
      .get();
    
    if (snapshot.empty) {
      console.log('⚠️  적립 거래 내역이 없습니다.\n');
      process.exit(0);
    }
    
    console.log(`✅ 총 ${snapshot.size}개의 적립 거래 발견\n`);
    
    // 2. amount가 10인 거래만 필터링
    const transactionsToUpdate = [];
    const batch = db.batch();
    let batchCount = 0;
    let updateCount = 0;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const amount = data.amount;
      
      // amount가 10인 경우만 2로 변경
      if (amount === 10) {
        transactionsToUpdate.push({
          id: doc.id,
          userId: data.userId,
          amount: amount,
          balanceAfter: data.balanceAfter,
          timestamp: data.timestamp
        });
        
        // balanceAfter 재계산 (10 -> 2이므로 -8)
        const newBalanceAfter = data.balanceAfter - 8;
        
        batch.update(doc.ref, {
          amount: 2
          // balanceAfter는 변경하지 않음 (과거 잔액이므로)
        });
        
        updateCount++;
        batchCount++;
        
        // Firestore batch는 최대 500개까지만 가능
        if (batchCount >= 500) {
          console.log(`⚠️  500개 제한으로 인해 일괄 처리를 나눕니다.`);
        }
      }
    });
    
    if (transactionsToUpdate.length === 0) {
      console.log('✅ 변경할 거래 내역이 없습니다. (모두 이미 2개로 설정됨)\n');
      process.exit(0);
    }
    
    console.log(`🔄 변경할 거래: ${transactionsToUpdate.length}개\n`);
    console.log('📋 변경 내용:');
    console.log('   amount: 10 → 2');
    console.log('   (balanceAfter는 변경하지 않음)\n');
    
    // 3. 배치 커밋
    console.log('💾 Firestore 업데이트 중...\n');
    
    await batch.commit();
    
    console.log('='.repeat(70));
    console.log('✅ QKEY 거래 내역 업데이트 완료!\n');
    console.log('📊 결과:');
    console.log(`   - 전체 적립 거래: ${snapshot.size}개`);
    console.log(`   - 변경된 거래: ${updateCount}개`);
    console.log(`   - 변경 없음: ${snapshot.size - updateCount}개\n`);
    console.log('='.repeat(70) + '\n');
    
    console.log('💡 참고 사항:');
    console.log('   - amount: 10 → 2로 변경됨');
    console.log('   - balanceAfter: 변경되지 않음 (과거 시점의 잔액)');
    console.log('   - 사용자의 현재 잔액은 별도로 조정 필요\n');
    
    console.log('⚠️  다음 단계:');
    console.log('   1. 사용자 현재 잔액 재계산 필요');
    console.log('   2. 앱 재빌드 및 배포 (earnAmountPerInterval = 2)\n');
    
  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

updateQKeyAmounts();
