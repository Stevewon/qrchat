#!/usr/bin/env node

/**
 * QKEY Transactions 컬렉션 구조 확인 스크립트
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'qrchat-b7a67'
});

const db = admin.firestore();

async function checkQkeyTransactions() {
  try {
    console.log('📦 QKEY Transactions 컬렉션 조회 중...\n');
    
    const snapshot = await db.collection('qkey_transactions')
      .limit(5)
      .get();
    
    if (snapshot.empty) {
      console.log('⚠️  QKEY 거래 내역이 없습니다.\n');
      console.log('💡 거래 내역이 없으면 인덱스가 필요 없습니다.');
      console.log('   앱에서 QKEY를 적립하거나 사용한 후 다시 확인하세요.\n');
      process.exit(0);
    }
    
    console.log(`✅ 총 ${snapshot.size}개의 거래 내역 발견\n`);
    console.log('='.repeat(70) + '\n');
    
    const firstDoc = snapshot.docs[0];
    const data = firstDoc.data();
    
    console.log('📌 첫 번째 거래 내역 구조:\n');
    console.log(`문서 ID: ${firstDoc.id}`);
    console.log('필드 목록:');
    
    Object.keys(data).forEach(key => {
      const value = data[key];
      let type = typeof value;
      
      if (value && value.constructor.name === 'Timestamp') {
        type = 'Timestamp';
      } else if (Array.isArray(value)) {
        type = 'Array';
      }
      
      console.log(`  - ${key}: ${type}`);
    });
    
    console.log('\n' + '='.repeat(70) + '\n');
    
    console.log('🎯 필요한 인덱스 구조:\n');
    
    if (data.userId && data.created_at) {
      console.log('✅ userId와 created_at 필드 확인됨!\n');
      console.log('📋 생성할 인덱스:\n');
      console.log('컬렉션 ID: qkey_transactions');
      console.log('필드:');
      console.log('  1. userId (오름차순)');
      console.log('  2. created_at (내림차순)');
      console.log('쿼리 범위: 컬렉션\n');
    } else {
      console.log('⚠️  예상되는 필드가 없습니다!\n');
      console.log('실제 데이터:');
      console.log(JSON.stringify(data, null, 2));
      console.log('');
    }
    
    console.log('='.repeat(70) + '\n');
    
    console.log('🔗 Firebase Console에서 인덱스 생성:\n');
    console.log('1. 아래 URL로 이동:');
    console.log('   https://console.firebase.google.com/project/qrchat-b7a67/firestore/indexes\n');
    console.log('2. "색인 추가" 또는 "복합 색인 추가" 버튼 클릭\n');
    console.log('3. 위의 인덱스 구조대로 입력\n');
    console.log('4. "만들기" 버튼 클릭\n');
    console.log('5. 5~10분 대기 (빌드 완료)\n');
    
  } catch (error) {
    console.error('❌ 오류:', error);
  } finally {
    process.exit(0);
  }
}

checkQkeyTransactions();
