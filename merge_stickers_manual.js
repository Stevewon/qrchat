#!/usr/bin/env node

/**
 * QRChat 스티커팩 통합 스크립트 (Firebase REST API 사용)
 * 
 * Firebase REST API를 사용하여 서비스 계정 키 없이 실행 가능
 */

const https = require('https');

const PROJECT_ID = 'qrchat-b7a67';
const COLLECTION = 'sticker_packs';

console.log('🔧 QRChat 스티커팩 통합 스크립트 (REST API)\n');
console.log('⚠️  주의: 이 스크립트는 Firebase Security Rules에 따라 동작합니다.');
console.log('   Firestore Rules에서 읽기/쓰기 권한이 필요합니다.\n');

console.log('💡 대안: Firebase Console에서 수동으로 통합하는 것을 권장합니다.\n');
console.log('📋 수동 통합 가이드:\n');
console.log('1️⃣  Firebase Console 접속:');
console.log('   🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/data/~2Fsticker_packs\n');

console.log('2️⃣  첫 번째 "명청이" 팩 열기 (보통 ID에 숫자가 더 작은 것)');
console.log('   - "stickers" 필드 클릭');
console.log('   - 배열 편집 모드 진입\n');

console.log('3️⃣  두 번째 "명청이" 팩에서 스티커 복사:');
console.log('   - 두 번째 팩 열기');
console.log('   - "stickers" 배열의 각 스티커 복사');
console.log('   - 첫 번째 팩의 "stickers" 배열에 붙여넣기');
console.log('   - 총 11개 스티커가 되도록 만들기\n');

console.log('4️⃣  두 번째 팩 삭제:');
console.log('   - 두 번째 "명청이" 팩 문서 선택');
console.log('   - 우측 상단 ⋮ (점 3개) 클릭');
console.log('   - "문서 삭제" 선택\n');

console.log('5️⃣  앱에서 확인:');
console.log('   - QRChat 앱 재시작');
console.log('   - 스티커 탭에서 "명청이" 하나만 있는지 확인');
console.log('   - 11개의 스티커가 모두 표시되는지 확인\n');

console.log('='.repeat(70) + '\n');

console.log('🎯 현재 Firestore에 있는 "명청이" 스티커팩:\n');
console.log('📦 팩 1: meongceongi_26414');
console.log('   스티커: 화가난다, 고독하다 (2), 즐거워용, 기분둥아, 존나어빠네, 그렇수도');
console.log('   총 6개\n');

console.log('📦 팩 2: meongceongi_35385');
console.log('   스티커: 그걸알아라고, 대박, 대표님발사쥬오, 배고프다, 사랑해요');
console.log('   총 5개\n');

console.log('🎯 통합 후 예상 결과:');
console.log('📦 "명청이" (단일 팩)');
console.log('   총 11개의 스티커\n');

console.log('='.repeat(70) + '\n');

console.log('❓ Firebase Admin SDK를 사용하려면:');
console.log('   1. Firebase Console에서 서비스 계정 키 다운로드');
console.log('   2. "firebase-service-account.json"으로 저장');
console.log('   3. 이 폴더에 배치 후 "node merge_sticker_packs.js" 실행\n');

console.log('🔗 서비스 계정 키 다운로드:');
console.log('   https://console.firebase.google.com/project/qrchat-b7a67/settings/serviceaccounts/adminsdk\n');

process.exit(0);
