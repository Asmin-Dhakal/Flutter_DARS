# Firebase Cloud Functions Setup Guide

This guide will help you deploy the Cloud Functions that send FCM notifications when orders are created or updated.

## 📋 Prerequisites

1. **Firebase Project** - You already have this set up
2. **Firebase CLI** - Install from https://firebase.google.com/docs/cli
3. **Node.js** - Download from https://nodejs.org/

---

## 🚀 Deployment Steps

### Step 1: Initialize Firebase Functions

```bash
# Navigate to your project directory
cd d:\Learning_Flutter\restaurant_order_app

# Login to Firebase
firebase login

# Initialize functions (if not already done)
firebase init functions
```

During initialization:

- Select your Firebase project
- Choose **JavaScript** or **TypeScript** (JavaScript is fine)
- Press **Y** to install dependencies

### Step 2: Copy the Function Code

The code has been created at:

```
d:\Learning_Flutter\restaurant_order_app\firebase_functions\functions\index.js
```

Copy the contents and **paste into** your Firebase project's `functions/index.js`

### Step 3: Install Required Dependencies

In the `functions` directory, make sure your `package.json` has:

```json
{
  "name": "functions",
  "description": "Cloud Functions for Restaurant Order App",
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  }
}
```

Then run:

```bash
cd functions
npm install
```

### Step 4: Deploy Functions

```bash
# From project root
firebase deploy --only functions
```

Wait for deployment to complete. You should see:

```
✔  Deploy complete!
```

---

## ✅ Verify Deployment

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Functions** (left menu)
3. You should see:
   - ✅ `onOrderCreatedOrUpdated` - Status: **OK**
   - ✅ `cleanupExpiredTokens` - Status: **OK**

---

## 🔐 Set Firestore Security Rules

1. Go to **Firestore Database** in Firebase Console
2. Click **Rules** tab
3. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow reading/writing orders (protected by auth or app logic)
    match /orders/{orderId} {
      allow read, write: if true;
    }

    // Allow saving and reading device tokens
    match /deviceTokens/{tokenId} {
      allow read, write: if true;
    }
  }
}
```

Click **Publish**

---

## 🔔 How It Works Now

### **When App is Running:**

1. App listens to Firestore changes (local notifications)
2. Cloud Function sends FCM notification
3. Both channels work together

### **When App is Background/Killed:**

1. Order created/updated on backend
2. Cloud Function triggers automatically
3. Sends FCM notification to all staff devices
4. Notification appears **even if app is closed**
5. **Tapping notification → Opens app to Order Details**

---

## 📊 Data Flow

```
Admin Creates Order
    ↓
Firestore Updated
    ↓
Cloud Function Triggered
    ↓
Gets all device tokens from 'deviceTokens' collection
    ↓
Sends FCM to all staff members
    ↓
Notification appears (even if app is killed!)
    ↓
User taps → Direct to Order Details Page
```

---

## 🧪 Testing

### Test 1: App in Background

1. Open app and dismiss (go to background)
2. **Create order from backend** (REST API or manually update Firestore)
3. Should see notification immediately ✅

### Test 2: App is Killed

1. **Kill the app** (swipe it closed)
2. **Create order** from another device
3. Should see notification (even though app isn't running) ✅
4. **Tap notification** → Opens app to Order Details

### Test 3: Status Update

1. **Keep app in background**
2. **Mark order as complete**
3. Should see "✅ Order Completed" notification ✅

---

## 🐛 Troubleshooting

### Issue: Notifications not sending

**Check:**

1. Cloud Functions deployed successfully?
   - Go to Firebase Console → Functions → Check status
2. Device tokens in Firestore?
   - Firestore → `deviceTokens` collection → Should have documents
3. Check Cloud Function logs:
   - Firebase Console → Functions → Logs
   - Look for error messages

### Issue: Device tokens not saving

**Check:**

1. App started?
2. Device has internet?
3. Check app logs for: `✅ Device token saved to Firestore`

### Issue: Notifications appear twice

**Why:** Both Firestore listener AND FCM are sending notifications
**Solution:** This is expected and okay. You can disable one if you want:

- To keep only FCM: Stop `firestore_order_service.startListening()` in main_screen.dart
- To keep only Firestore: Comment out Cloud Function deployment

---

## 📱 Test Devices Setup

For best testing:

1. **Install app on 2 devices**
2. **Device 1**: Keep app in foreground
3. **Device 2**: Kill the app
4. **Device 1**: Create/update order
5. **Device 2**: Should see notification immediately ✅

---

## 🔄 Token Refresh

Tokens refresh automatically:

- Everytime app starts → New token saved to Firestore
- Token expires → New one generated and saved
- Old tokens auto-cleaned daily by `cleanupExpiredTokens` function

---

## 📞 Need Help?

Check:

- Cloud Function logs in Firebase Console
- App console logs: Look for "✅" and "⚠️" messages
- Device tokens in Firestore exist: `deviceTokens` collection

Good luck! 🚀
