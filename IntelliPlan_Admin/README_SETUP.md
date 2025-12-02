# IntelliPlan Admin Panel

## Setup Instructions

### 1. Firebase Configuration

Update the Firebase configuration in both `login.html` and `js/app.js`:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

**To get your Firebase config:**
1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your IntelliPlan project
3. Go to Project Settings > General
4. Scroll down to "Your apps" section
5. Click on the Web app (</>) icon
6. Copy the firebaseConfig object

### 2. Create an Admin User

To create an admin user in your Firebase project:

**Option A: Using Firebase Console**
1. Go to Firebase Console > Authentication
2. Create a new user with email/password
3. Note the User UID
4. Go to Firestore Database
5. Find the user document in the `users` collection
6. Add a field: `role` with value `admin`

**Option B: Using the provided script**
1. Open Firebase Console > Firestore
2. Navigate to the `users` collection
3. Find your user document
4. Add field: `role` = `admin` (type: string)

### 3. Deploy to Firebase Hosting (Optional)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase Hosting in this directory
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### 4. Local Testing

Simply open `login.html` in a web browser. Make sure you've:
1. Updated Firebase configuration
2. Created an admin user
3. Enabled Email/Password authentication in Firebase Console

### 5. Security Rules

Make sure your Firestore security rules allow admin users to read data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || isAdmin());
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Tasks collection
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Teams collection
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Admin can read all
    match /{document=**} {
      allow read: if isAdmin();
    }
  }
}
```

## Features

- **User Management**: View all users, their activity, levels, and streaks
- **Task Analytics**: Monitor task completion trends and statistics
- **Study Techniques**: Track usage of Pomodoro, Spaced Repetition, and Active Recall
- **Gamification**: View achievement unlocks and points economy
- **Real-time Data**: All data is fetched directly from Firebase Firestore
- **Secure Authentication**: Only users with admin role can access

## Admin Panel Structure

```
IntelliPlan_Admin/
├── index.html          # Main dashboard
├── login.html          # Admin login page
├── css/
│   └── styles.css      # Styling
├── js/
│   └── app.js          # Firebase integration & logic
├── assets/
│   └── logo.svg        # App logo
└── README_SETUP.md     # This file
```

## Troubleshooting

### "Access denied" error
- Make sure your user has `role: "admin"` in the Firestore users collection

### Data not loading
- Check Firebase configuration is correct
- Verify Firestore security rules allow admin access
- Check browser console for errors

### Can't log in
- Ensure Email/Password authentication is enabled in Firebase Console
- Verify the email/password are correct
- Check that the user exists in Firebase Authentication

## Support

For issues or questions, contact the development team.
