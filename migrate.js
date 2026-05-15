/**
 * Firebase Firestore Data Migration Script
 * 
 * Migrates legacy top-level collections (wishlists, bookings, tickets) 
 * to user subcollections with correct userId references.
 * 
 * Usage:
 * 1. Download serviceAccountKey.json from Firebase Console > Project Settings > Service Accounts
 * 2. Place it in this directory (eventbridge1/)
 * 3. Run: node migrate.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ ERROR: serviceAccountKey.json not found in this directory.');
  console.error('📋 Steps to get it:');
  console.error('   1. Go to Firebase Console > Project Settings (gear icon)');
  console.error('   2. Click "Service Accounts" tab');
  console.error('   3. Click "Generate New Private Key"');
  console.error('   4. Save the JSON file as serviceAccountKey.json in this directory');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath))
});

const db = admin.firestore();
let migratedCount = 0;
let skippedCount = 0;
let errorCount = 0;

/**
 * Migrate wishlists from top-level to users/{uid}/wishlists/
 */
async function migrateWishlists() {
  console.log('\n📌 Migrating wishlists...');
  
  const snap = await db.collection('wishlists').get();
  console.log(`   Found ${snap.size} wishlist documents`);
  
  for (const doc of snap.docs) {
    try {
      const data = doc.data();
      
      // Extract email to find the real Firebase UID
      const email = data.email || data.userEmail || data.ownerEmail;
      const userId = data.userId;
      
      if (!email && !userId) {
        console.warn(`   ⚠️  SKIP: Wishlist ${doc.id} has no email or userId field`);
        skippedCount++;
        continue;
      }
      
      let uid = userId;
      
      // If userId doesn't look like a Firebase UID (should be 28+ chars alphanumeric),
      // try to find the real uid using email
      if (!uid || uid.length < 20) {
        if (email) {
          const users = await db.collection('users').where('email', '==', email).get();
          if (users.empty) {
            console.warn(`   ⚠️  SKIP: No user found with email ${email}`);
            skippedCount++;
            continue;
          }
          uid = users.docs[0].id;
        } else {
          console.warn(`   ⚠️  SKIP: Wishlist ${doc.id} has invalid userId and no email`);
          skippedCount++;
          continue;
        }
      }
      
      // Migrate to users/{uid}/wishlists/{docId}
      await db
        .collection('users')
        .doc(uid)
        .collection('wishlists')
        .doc(doc.id)
        .set({
          ...data,
          userId: uid,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      
      // Delete legacy doc
      await doc.ref.delete();
      console.log(`   ✅ MIGRATED: ${doc.id} -> users/${uid}/wishlists/`);
      migratedCount++;
    } catch (error) {
      console.error(`   ❌ ERROR migrating ${doc.id}: ${error.message}`);
      errorCount++;
    }
  }
}

/**
 * Migrate bookings from top-level to users/{uid}/bookings/ (optional)
 * Most keep bookings at top-level for admin access; only migrate if needed
 */
async function migrateBookings() {
  console.log('\n📌 Validating bookings...');
  
  const snap = await db.collection('bookings').get();
  console.log(`   Found ${snap.size} booking documents`);
  
  for (const doc of snap.docs) {
    try {
      const data = doc.data();
      const userId = data.userId;
      
      if (!userId || userId.length < 20) {
        console.warn(`   ⚠️  WARNING: Booking ${doc.id} has invalid userId: "${userId}"`);
        console.log(`      Fix: Open Firebase console and update this booking's userId field`);
        skippedCount++;
        continue;
      }
      
      // Verify user exists
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.warn(`   ⚠️  WARNING: Booking ${doc.id} references non-existent user ${userId}`);
        skippedCount++;
        continue;
      }
      
      console.log(`   ✅ VALID: ${doc.id} -> users/${userId}`);
      migratedCount++;
    } catch (error) {
      console.error(`   ❌ ERROR checking ${doc.id}: ${error.message}`);
      errorCount++;
    }
  }
}

/**
 * Audit tickets collection
 */
async function auditTickets() {
  console.log('\n📌 Auditing tickets...');
  
  const snap = await db.collection('tickets').get();
  console.log(`   Found ${snap.size} ticket documents`);
  
  for (const doc of snap.docs) {
    try {
      const data = doc.data();
      const userId = data.userId;
      
      if (!userId || userId.length < 20) {
        console.warn(`   ⚠️  WARNING: Ticket ${doc.id} has invalid userId: "${userId}"`);
        skippedCount++;
        continue;
      }
      
      console.log(`   ✅ VALID: ${doc.id} -> users/${userId}`);
      migratedCount++;
    } catch (error) {
      console.error(`   ❌ ERROR checking ${doc.id}: ${error.message}`);
      errorCount++;
    }
  }
}

/**
 * Main migration runner
 */
async function runMigration() {
  console.log('🚀 Starting Firestore Data Migration');
  console.log('=====================================\n');
  
  try {
    await migrateWishlists();
    await migrateBookings();
    await auditTickets();
    
    console.log('\n\n📊 Migration Summary:');
    console.log('=====================================');
    console.log(`✅ Migrated: ${migratedCount}`);
    console.log(`⚠️  Skipped:  ${skippedCount}`);
    console.log(`❌ Errors:   ${errorCount}`);
    console.log('=====================================\n');
    
    if (errorCount === 0) {
      console.log('✨ Migration complete! All data is now properly organized.\n');
    } else {
      console.log('⚠️  Some errors occurred. Review the warnings above.\n');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ FATAL ERROR:', error);
    process.exit(1);
  }
}

// Run the migration
runMigration();
