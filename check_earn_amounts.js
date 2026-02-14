#!/usr/bin/env node

/**
 * QKEY 적립 거래 통계 조회
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'qrchat-b7a67'
});

const db = admin.firestore();

async function checkEarnAmounts() {
  try {
    console.log('📊 QKEY 적립 거래 통계 조회 중...\n');
    
    const snapshot = await db.collection('qkey_transactions')
      .where('type', '==', 'earn')
      .get();
    
    if (snapshot.empty) {
      console.log('⚠️  적립 거래 내역이 없습니다.\n');
      process.exit(0);
    }
    
    console.log(`✅ 총 ${snapshot.size}개의 적립 거래 발견\n`);
    
    // amount별 통계
    const amountStats = {};
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const amount = data.amount;
      
      if (!amountStats[amount]) {
        amountStats[amount] = {
          count: 0,
          userIds: new Set()
        };
      }
      
      amountStats[amount].count++;
      amountStats[amount].userIds.add(data.userId);
    });
    
    console.log('='.repeat(70));
    console.log('📊 적립량별 통계:\n');
    
    Object.keys(amountStats).sort((a, b) => parseInt(b) - parseInt(a)).forEach(amount => {
      const stat = amountStats[amount];
      console.log(`💰 ${amount} QKEY:`);
      console.log(`   - 거래 수: ${stat.count}개`);
      console.log(`   - 사용자 수: ${stat.userIds.size}명`);
      console.log('');
    });
    
    console.log('='.repeat(70) + '\n');
    
    // 샘플 데이터 5개 출력
    console.log('📋 최근 적립 거래 샘플 (5개):\n');
    
    const recentDocs = snapshot.docs.slice(0, 5);
    recentDocs.forEach((doc, index) => {
      const data = doc.data();
      const timestamp = data.timestamp?.toDate?.() || new Date(data.timestamp._seconds * 1000);
      
      console.log(`${index + 1}. 문서 ID: ${doc.id}`);
      console.log(`   userId: ${data.userId}`);
      console.log(`   amount: ${data.amount} QKEY`);
      console.log(`   balanceAfter: ${data.balanceAfter} QKEY`);
      console.log(`   description: ${data.description || '(없음)'}`);
      console.log(`   timestamp: ${timestamp.toLocaleString('ko-KR')}`);
      console.log('');
    });
    
    console.log('='.repeat(70) + '\n');
    
    // 변경 예상
    const amount10Count = amountStats[10]?.count || 0;
    const amount20Count = amountStats[20]?.count || 0;
    
    if (amount10Count > 0 || amount20Count > 0) {
      console.log('🔄 변경 예상:\n');
      
      if (amount10Count > 0) {
        console.log(`   - 10 QKEY → 2 QKEY: ${amount10Count}개 거래`);
      }
      
      if (amount20Count > 0) {
        console.log(`   - 20 QKEY → 2 QKEY: ${amount20Count}개 거래`);
      }
      
      console.log('');
    } else {
      console.log('✅ 이미 모든 거래가 2 QKEY로 설정되어 있습니다.\n');
    }
    
  } catch (error) {
    console.error('❌ 오류:', error);
  } finally {
    process.exit(0);
  }
}

checkEarnAmounts();
