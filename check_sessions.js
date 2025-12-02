// Quick script to check what's in study_sessions
const admin = require('firebase-admin');
const serviceAccount = require('./intelliplan_app/android/app/google-services.json');

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: serviceAccount.project_id,
    clientEmail: `firebase-adminsdk-r6igr@${serviceAccount.project_id}.iam.gserviceaccount.com`,
    privateKey: "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  })
});

const db = admin.firestore();

async function checkSessions() {
  try {
    const usersSnapshot = await db.collection('users').get();
    
    for (const userDoc of usersSnapshot.docs) {
      console.log(`\n👤 User: ${userDoc.id}`);
      
      const sessionsSnapshot = await db.collection('users').doc(userDoc.id).collection('study_sessions').get();
      
      const techniques = {};
      sessionsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const tech = data.technique || 'undefined';
        techniques[tech] = (techniques[tech] || 0) + 1;
      });
      
      console.log(`Total sessions: ${sessionsSnapshot.docs.length}`);
      console.log('By technique:', techniques);
      
      // Show some recent sessions
      const recent = sessionsSnapshot.docs.slice(0, 5);
      console.log('\nRecent sessions:');
      recent.forEach(doc => {
        const data = doc.data();
        console.log(`  - ${data.technique} | ${data.topic || 'No topic'} | ${data.createdAt?.toDate?.()}`);
      });
    }
  } catch (error) {
    console.error('Error:', error);
  }
  
  process.exit(0);
}

checkSessions();
