#!/usr/bin/env node

/**
 * Firestore 스티커팩 조회 스크립트
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'qrchat-b7a67'
});

const db = admin.firestore();

async function listStickerPacks() {
  try {
    console.log('📦 Firestore 스티커팩 조회 중...\n');
    
    const snapshot = await db.collection('sticker_packs')
      .orderBy('created_at', 'desc')
      .get();
    
    if (snapshot.empty) {
      console.log('⚠️  스티커팩이 없습니다.\n');
      return;
    }
    
    console.log(`✅ 총 ${snapshot.size}개의 스티커팩 발견\n`);
    console.log('='.repeat(70) + '\n');
    
    snapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`📌 스티커팩 ${index + 1}:`);
      console.log(`   문서 ID: ${doc.id}`);
      console.log(`   팩 이름: ${data.pack_name || '(이름 없음)'}`);
      console.log(`   스티커 개수: ${data.stickers ? data.stickers.length : 0}개`);
      
      if (data.stickers && data.stickers.length > 0) {
        console.log(`   스티커 목록:`);
        data.stickers.slice(0, 5).forEach((sticker, idx) => {
          console.log(`      ${idx + 1}. ${sticker.sticker_name || '(이름 없음)'}`);
        });
        if (data.stickers.length > 5) {
          console.log(`      ... 외 ${data.stickers.length - 5}개`);
        }
      }
      
      console.log('');
    });
    
    console.log('='.repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ 오류:', error);
  } finally {
    process.exit(0);
  }
}

listStickerPacks();
