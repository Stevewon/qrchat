#!/usr/bin/env node

/**
 * QRChat 스티커팩 통합 스크립트
 * 
 * 두 개의 "명청이" 스티커팩을 하나로 통합합니다.
 * - Pack 1: meongceongi_26414 (6개 스티커)
 * - Pack 2: meongceongi_35385 (5개 스티커)
 * → 결과: 하나의 통합 팩 (11개 스티커)
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Firebase 프로젝트 ID
const PROJECT_ID = 'qrchat-b7a67';

console.log('🔧 QRChat 스티커팩 통합 스크립트 시작...\n');

// Firebase Admin SDK 초기화
try {
  // 서비스 계정 키 파일이 있는 경우
  if (fs.existsSync('./firebase-service-account.json')) {
    const serviceAccount = require('./firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID
    });
    console.log('✅ Firebase Admin SDK 초기화 완료 (서비스 계정 키)\n');
  } else {
    // Application Default Credentials 사용
    admin.initializeApp({
      projectId: PROJECT_ID
    });
    console.log('✅ Firebase Admin SDK 초기화 완료 (기본 인증)\n');
  }
} catch (error) {
  console.error('❌ Firebase 초기화 실패:', error.message);
  console.error('\n💡 해결 방법:');
  console.error('1. Firebase Console에서 서비스 계정 키 다운로드');
  console.error('2. 파일명을 "firebase-service-account.json"으로 저장');
  console.error('3. 이 스크립트와 같은 폴더에 배치\n');
  console.error('🔗 다운로드 링크:');
  console.error(`   https://console.firebase.google.com/project/${PROJECT_ID}/settings/serviceaccounts/adminsdk\n`);
  process.exit(1);
}

const db = admin.firestore();

async function mergeStickerPacks() {
  try {
    console.log('📦 스티커팩 컬렉션 조회 중...\n');
    
    // 모든 스티커팩 가져오기
    const packsSnapshot = await db.collection('sticker_packs')
      .orderBy('created_at', 'desc')
      .get();
    
    if (packsSnapshot.empty) {
      console.log('⚠️  스티커팩이 없습니다.');
      return;
    }
    
    console.log(`✅ 총 ${packsSnapshot.size}개의 스티커팩 발견\n`);
    
    // "멍청이" 팩들 찾기
    const myeongcheongPacks = [];
    packsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.pack_name === '멍청이') {
        myeongcheongPacks.push({
          id: doc.id,
          data: data
        });
        console.log(`📌 "${data.pack_name}" 팩 발견:`);
        console.log(`   - ID: ${doc.id}`);
        console.log(`   - 스티커 개수: ${data.stickers ? data.stickers.length : 0}개`);
        console.log('');
      }
    });
    
    if (myeongcheongPacks.length < 2) {
      console.log('⚠️  통합할 "멍청이" 팩이 2개 미만입니다.');
      console.log(`   현재 개수: ${myeongcheongPacks.length}개\n`);
      return;
    }
    
    console.log(`\n🔀 ${myeongcheongPacks.length}개의 "멍청이" 팩 통합 시작...\n`);
    
    // 모든 스티커를 하나의 배열로 통합
    let allStickers = [];
    myeongcheongPacks.forEach((pack, index) => {
      const stickers = pack.data.stickers || [];
      console.log(`   팩 ${index + 1} (${pack.id}): ${stickers.length}개 스티커 추가`);
      allStickers = allStickers.concat(stickers);
    });
    
    console.log(`\n✅ 총 ${allStickers.length}개의 스티커 수집 완료\n`);
    
    // 중복 제거 (image_url 기준)
    const uniqueStickers = [];
    const urlSet = new Set();
    
    allStickers.forEach(sticker => {
      if (!urlSet.has(sticker.image_url)) {
        urlSet.add(sticker.image_url);
        uniqueStickers.push(sticker);
      }
    });
    
    if (uniqueStickers.length < allStickers.length) {
      console.log(`🔍 중복 스티커 ${allStickers.length - uniqueStickers.length}개 제거`);
      console.log(`   최종 스티커 개수: ${uniqueStickers.length}개\n`);
    }
    
    // 첫 번째 팩 업데이트 (가장 오래된 팩 유지)
    const primaryPack = myeongcheongPacks[myeongcheongPacks.length - 1]; // 가장 오래된 것
    const primaryPackRef = db.collection('sticker_packs').doc(primaryPack.id);
    
    console.log(`📝 메인 팩 업데이트 중... (ID: ${primaryPack.id})`);
    
    await primaryPackRef.update({
      stickers: uniqueStickers,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ 메인 팩 업데이트 완료\n');
    
    // 나머지 팩들 삭제
    console.log('🗑️  중복 팩 삭제 중...\n');
    
    for (let i = 0; i < myeongcheongPacks.length - 1; i++) {
      const packToDelete = myeongcheongPacks[i];
      console.log(`   - 삭제 중: ${packToDelete.id} (${packToDelete.data.stickers?.length || 0}개 스티커)`);
      
      await db.collection('sticker_packs').doc(packToDelete.id).delete();
      
      console.log(`   ✅ 삭제 완료: ${packToDelete.id}`);
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('🎉 스티커팩 통합 완료!\n');
    console.log('📊 최종 결과:');
    console.log(`   - 팩 이름: 멍청이`);
    console.log(`   - 팩 ID: ${primaryPack.id}`);
    console.log(`   - 총 스티커: ${uniqueStickers.length}개`);
    console.log(`   - 삭제된 팩: ${myeongcheongPacks.length - 1}개`);
    console.log('='.repeat(60) + '\n');
    
    console.log('💡 앱에서 확인:');
    console.log('   1. QRChat 앱 실행');
    console.log('   2. 채팅방에서 스티커 아이콘 클릭');
    console.log('   3. "멍청이" 탭 하나만 있는지 확인');
    console.log(`   4. ${uniqueStickers.length}개의 스티커가 모두 표시되는지 확인\n`);
    
  } catch (error) {
    console.error('\n❌ 오류 발생:', error);
    throw error;
  }
}

// 스크립트 실행
mergeStickerPacks()
  .then(() => {
    console.log('✅ 스크립트 실행 완료\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 스크립트 실행 실패:', error);
    process.exit(1);
  });
