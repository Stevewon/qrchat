const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addQkeyToUser() {
  try {
    console.log('🔍 "바보바보" 사용자 찾는 중...');
    
    // 닉네임으로 사용자 찾기
    const usersSnapshot = await db.collection('users')
      .where('nickname', '==', '바보바보')
      .limit(1)
      .get();
    
    if (usersSnapshot.empty) {
      console.error('❌ "바보바보" 사용자를 찾을 수 없습니다.');
      process.exit(1);
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    console.log('✅ 사용자 찾음:');
    console.log(`   ID: ${userId}`);
    console.log(`   닉네임: ${userData.nickname}`);
    console.log(`   현재 QKEY: ${userData.qkeyBalance || 0}`);
    
    // 현재 잔액에 1000 추가
    const currentBalance = userData.qkeyBalance || 0;
    const newBalance = currentBalance + 1000;
    
    // Firestore 업데이트
    await db.collection('users').doc(userId).update({
      qkeyBalance: newBalance,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`\n✅ QKEY 1000개 추가 완료!`);
    console.log(`   이전 잔액: ${currentBalance}`);
    console.log(`   새 잔액: ${newBalance}`);
    
    // 트랜잭션 기록 생성
    const transactionRef = await db.collection('qkey_transactions').add({
      userId: userId,
      type: 'admin_add',
      amount: 1000,
      balance: newBalance,
      description: '테스트용 QKEY 지급 (바보바보)',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      adminNote: '출금 테스트를 위한 수동 지급'
    });
    
    console.log(`\n📝 트랜잭션 기록 생성됨: ${transactionRef.id}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  }
}

addQkeyToUser();
