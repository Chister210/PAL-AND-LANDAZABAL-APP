// Create Admin User Setup Script
// Run this in Firebase Console > Firestore > Run Query

// Step 1: Create a user in Firebase Authentication
// Go to Firebase Console > Authentication > Users > Add User
// Email: admin@intelliplan.app
// Password: [Set a secure password]
// Copy the User UID

// Step 2: Update the user document in Firestore
// Replace USER_UID_HERE with the actual UID from Step 1

db.collection("users").doc("USER_UID_HERE").set({
  name: "Admin User",
  email: "admin@intelliplan.app",
  role: "admin",
  createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  xp: 0,
  level: 1,
  currentStreak: 0,
  longestStreak: 0
}, { merge: true });

// Alternative: If you already have a user and want to make them admin
// Replace USER_UID_HERE with your existing user's UID

db.collection("users").doc("USER_UID_HERE").update({
  role: "admin"
});
