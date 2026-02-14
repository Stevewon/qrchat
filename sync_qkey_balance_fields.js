const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function syncQKeyBalanceFields() {
  console.log('🔄 Starting QKEY balance field sync...\n');
  
  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.size} users\n`);
    
    let syncedCount = 0;
    let skippedCount = 0;
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const data = userDoc.data();
      
      const qkeyBalance = data.qkeyBalance || 0;
      const qkey_balance = data.qkey_balance || 0;
      
      // If they're different, sync qkeyBalance to match qkey_balance
      if (qkeyBalance !== qkey_balance) {
        console.log(`👤 User ${userId} (${data.nickname || 'Unknown'})`);
        console.log(`   OLD qkeyBalance: ${qkeyBalance} QKEY`);
        console.log(`   NEW qkey_balance: ${qkey_balance} QKEY`);
        console.log(`   ⚠️  SYNCING: ${qkeyBalance} → ${qkey_balance}`);
        
        await db.collection('users').doc(userId).update({
          qkeyBalance: qkey_balance
        });
        
        console.log(`   ✅ Synced!\n`);
        syncedCount++;
      } else {
        skippedCount++;
      }
    }
    
    console.log('\n' + '='.repeat(50));
    console.log('📈 SYNC COMPLETE');
    console.log('='.repeat(50));
    console.log(`✅ Synced users: ${syncedCount}`);
    console.log(`⏭️  Skipped users (already synced): ${skippedCount}`);
    console.log(`📊 Total users: ${usersSnapshot.size}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

syncQKeyBalanceFields();
