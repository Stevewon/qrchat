const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function checkUserBalance() {
  console.log('🔍 "바보바보" 사용자 QKEY 조회 중...\n');
  
  try {
    // 닉네임으로 사용자 찾기
    const usersSnapshot = await db.collection('users')
      .where('nickname', '==', '바보바보')
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ "바보바보" 사용자를 찾을 수 없습니다.');
      return;
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();
    const userId = userDoc.id;
    
    console.log('👤 사용자 정보:');
    console.log(`   ID: ${userId}`);
    console.log(`   닉네임: ${userData.nickname}`);
    console.log(`   현재 잔액: ${userData.qkey_balance || 0} QKEY\n`);
    
    // 거래 내역 조회
    const transactionsSnapshot = await db.collection('qkey_transactions')
      .where('userId', '==', userId)
      .get();
    
    console.log(`📊 거래 내역: ${transactionsSnapshot.size}건\n`);
    
    // 적립/사용 통계
    let earnTotal = 0;
    let earnCount = 0;
    let useTotal = 0;
    let useCount = 0;
    const amounts = {};
    
    const transactions = [];
    transactionsSnapshot.forEach(doc => {
      const data = doc.data();
      transactions.push({
        ...data,
        id: doc.id,
        timestamp: data.timestamp || data.created_at
      });
    });
    
    // 시간순 정렬
    transactions.sort((a, b) => {
      const timeA = a.timestamp?.toMillis?.() || 0;
      const timeB = b.timestamp?.toMillis?.() || 0;
      return timeA - timeB;
    });
    
    // 통계 계산
    transactions.forEach(data => {
      if (data.type === 'earn') {
        earnTotal += data.amount;
        earnCount++;
        amounts[data.amount] = (amounts[data.amount] || 0) + 1;
      } else if (data.type === 'use') {
        useTotal += data.amount;
        useCount++;
      }
    });
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📈 통계:');
    console.log(`   적립: ${earnCount}건, 총 ${earnTotal} QKEY`);
    console.log(`   사용: ${useCount}건, 총 ${useTotal} QKEY`);
    console.log(`   계산 잔액: ${earnTotal - useTotal} QKEY`);
    console.log(`   실제 잔액: ${userData.qkey_balance || 0} QKEY`);
    console.log(`   차이: ${(userData.qkey_balance || 0) - (earnTotal - useTotal)} QKEY\n`);
    
    console.log('💰 적립량별 통계:');
    Object.entries(amounts).sort((a, b) => b[0] - a[0]).forEach(([amount, count]) => {
      console.log(`   ${amount} QKEY: ${count}건`);
    });
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📋 최근 거래 10건:\n');
    
    transactions.slice(-10).reverse().forEach((data, index) => {
      const date = data.timestamp?.toDate?.() || data.created_at?.toDate?.();
      console.log(`${index + 1}. [${data.type.toUpperCase()}] ${data.amount} QKEY`);
      console.log(`   잔액: ${data.balanceAfter} QKEY`);
      console.log(`   설명: ${data.description || 'N/A'}`);
      console.log(`   시간: ${date?.toLocaleString('ko-KR') || 'N/A'}\n`);
    });
    
  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

checkUserBalance();
