const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function recalculateUserBalances() {
  console.log('🔧 사용자 QKEY 잔액 재계산 시작...\n');
  
  try {
    // 영향받은 사용자들 (fix_qkey_amounts.js에서 확인된 사용자)
    const affectedUserIds = ['1770301221720', '1770363136308', '1770434260975', '1770305983347'];
    
    console.log(`👥 총 ${affectedUserIds.length}명의 잔액 재계산\n`);
    
    for (const userId of affectedUserIds) {
      console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`👤 사용자 ID: ${userId}`);
      
      // 1. 현재 잔액 조회
      const userDoc = await db.collection('users').doc(userId).get();
      const currentBalance = userDoc.data()?.qkey_balance || 0;
      console.log(`   💰 현재 기록된 잔액: ${currentBalance} QKEY`);
      
      // 2. 모든 거래 내역 조회 및 재계산
      const transactions = await db.collection('qkey_transactions')
        .where('userId', '==', userId)
        .get();
      
      let calculatedBalance = 0;
      let earnCount = 0;
      let useCount = 0;
      
      // timestamp 또는 created_at으로 정렬 (수동)
      const sortedTransactions = [];
      transactions.forEach(doc => {
        const data = doc.data();
        sortedTransactions.push({
          ...data,
          id: doc.id,
          timestamp: data.timestamp || data.created_at
        });
      });
      
      // 시간순 정렬
      sortedTransactions.sort((a, b) => {
        const timeA = a.timestamp?.toMillis?.() || 0;
        const timeB = b.timestamp?.toMillis?.() || 0;
        return timeA - timeB;
      });
      
      sortedTransactions.forEach(data => {
        if (data.type === 'earn') {
          calculatedBalance += data.amount;
          earnCount++;
        } else if (data.type === 'use') {
          calculatedBalance -= data.amount;
          useCount++;
        }
      });
      
      console.log(`   📊 거래 내역: ${transactions.size}건 (적립: ${earnCount}, 사용: ${useCount})`);
      console.log(`   🧮 재계산된 잔액: ${calculatedBalance} QKEY`);
      
      // 3. 차이 확인
      const difference = currentBalance - calculatedBalance;
      if (difference !== 0) {
        console.log(`   ⚠️  차이: ${difference > 0 ? '+' : ''}${difference} QKEY`);
        
        // 4. 잔액 업데이트
        await db.collection('users').doc(userId).update({
          qkey_balance: calculatedBalance
        });
        console.log(`   ✅ 잔액 업데이트 완료: ${currentBalance} → ${calculatedBalance} QKEY`);
      } else {
        console.log(`   ✅ 잔액 정확함 (업데이트 불필요)`);
      }
    }
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n✅ 모든 사용자 잔액 재계산 완료!\n');
    
  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

recalculateUserBalances();
