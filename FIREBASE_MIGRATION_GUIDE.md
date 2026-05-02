# Firebase Database Migration Guide

## Summary of Changes

This document outlines all changes made to fully integrate your Flutter app with Firebase Firestore, removing all static/hardcoded data.

## Changes Made

### 1. **EventProvider** (`lib/providers/event_provider.dart`)
✅ **Removed:**
- `_seedEvents` list (5 hardcoded events)
- `_defaultCategoryEvents` list (5 more hardcoded events)
- `_seedDefaultCategoryEvents()` method that seeded events to Firebase
- Initialization of `_events` with seed data

✅ **Result:**
- Events now load **only from Firebase** on app startup
- Real-time listening to `events` collection
- All events must be added manually via Firebase Console or admin panel

### 2. **UserProvider** (`lib/providers/user_provider.dart`)
✅ **Removed:**
- Static wallet balance initialization (`double _walletBalance = 6000`)
- Hardcoded welcome credit transaction
- In-memory only wallet operations

✅ **Added:**
- `_walletSubscription` - Real-time sync of wallet balance from Firebase `users` collection
- `_transactionsSubscription` - Real-time sync of wallet transactions
- `_ticketsSubscription` - Real-time sync of user tickets
- `_bindWalletForUser()` - Loads wallet balance from `users/{userId}`
- `_bindTransactionsForUser()` - Loads transactions from `users/{userId}/wallet_transactions`
- `_bindTicketsForUser()` - Loads tickets from `users/{userId}/tickets`

✅ **Updated Methods:**
- `login()` - Now binds all Firebase data (wallet, transactions, tickets)
- `logout()` - Cancels all subscriptions and clears data
- `spendFromWallet()` - Now **async**, persists to Firebase
- `topUpWallet()` - Now **async**, persists to Firebase
- `addTicket()` - Now **async**, persists to Firebase and updates user stats

### 3. **BookingScreen** (`lib/screens/booking_screen.dart`)
✅ **Updated:**
- `_payAndGenerateTicket()` - Now handles async wallet operations with proper error handling
- Uses `await userProvider.spendFromWallet()` instead of synchronous call
- Uses `await userProvider.addTicket()` instead of synchronous call
- Added try-catch for better error handling

### 4. **WalletScreen** (`lib/screens/wallet_screen.dart`)
✅ **Updated:**
- `_topUp()` - Now **async** and handles Firebase persistence
- Added error handling and success feedback

---

## Firebase Database Schema Required

Your Firebase Firestore must have the following structure:

### Users Collection
```
users/
├── {userId}/
│   ├── walletBalance: number
│   ├── eventsAttended: number
│   ├── totalSpent: number
│   ├── favoriteCategory: string
│   ├── updatedAt: timestamp
│   │
│   ├── wallet_transactions/
│   │   └── {transactionId}/
│   │       ├── id: string
│   │       ├── title: string
│   │       ├── amount: number
│   │       ├── timestamp: timestamp
│   │       └── createdAt: timestamp
│   │
│   ├── tickets/
│   │   └── {ticketId}/
│   │       ├── id: string
│   │       ├── eventId: string
│   │       ├── eventTitle: string
│   │       ├── holderName: string
│   │       ├── ticketType: string
│   │       ├── quantity: number
│   │       ├── amount: number
│   │       ├── eventDate: timestamp
│   │       └── createdAt: timestamp
│   │
│   └── wishlists/
│       └── {eventId}/
│           ├── id: string
│           ├── userId: string
│           ├── eventId: string
│           ├── eventName: string
│           ├── eventCategory: string
│           ├── eventDate: timestamp
│           ├── eventImageUrl: string
│           ├── eventLocation: string
│           ├── eventPrice: number
│           ├── organizerName: string
│           ├── priority: string
│           ├── notes: string
│           ├── reminderDays: number
│           ├── reminderEnabled: boolean
│           ├── addedAt: timestamp
│           └── updatedAt: timestamp
```

### Events Collection
```
events/
└── {eventId}/
    ├── title: string
    ├── category: string
    ├── date: timestamp
    ├── location: string
    ├── price: number
    ├── imageUrl: string
    ├── description: string
    ├── schedule: array of strings
    ├── attendees: array of strings
    ├── ticketTypes: map<string, number>
    ├── isTrending: boolean
    ├── hasArVrPreview: boolean
    ├── organizerName: string
    ├── organizerVerified: boolean
    ├── createdAt: timestamp
    └── updatedAt: timestamp
```

---

## Firestore Security Rules

Update your Firestore Security Rules to allow proper access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // User subcollections
      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Public events
    match /events/{document=**} {
      allow read: if true;
      allow write: if request.auth.uid != null && request.auth.token.admin == true;
    }
    
    // Wishlists (legacy fallback)
    match /wishlists/{document=**} {
      allow read, write: if request.auth.uid != null && 
                            request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Initial Setup Checklist

- [ ] Add sample events to Firebase `events` collection
- [ ] Create initial user documents in `users` collection when users sign up
- [ ] Initialize wallet balance in user profile (default: 0 or your custom amount)
- [ ] Set up Firestore security rules as shown above
- [ ] Test user registration flow
- [ ] Test event loading from Firebase
- [ ] Test wallet operations (top-up, spend)
- [ ] Test ticket booking and persistence
- [ ] Test logout and data clearing

---

## API Changes for Developers

### Before (Static Data)
```dart
// Wallet operations were synchronous
userProvider.topUpWallet(500);
bool success = userProvider.spendFromWallet(amount: 100, title: 'Ticket');
userProvider.addTicket(ticket, category);
```

### After (Firebase Persistence)
```dart
// Wallet operations are now asynchronous
try {
  await userProvider.topUpWallet(500);
} catch (e) {
  print('Top-up failed: $e');
}

try {
  bool success = await userProvider.spendFromWallet(
    amount: 100, 
    title: 'Ticket'
  );
} catch (e) {
  print('Spend failed: $e');
}

try {
  await userProvider.addTicket(ticket, category);
} catch (e) {
  print('Ticket add failed: $e');
}
```

---

## Data Migration from Old App

If you had existing static data, follow these steps:

1. **Export old data** from your app
2. **Create documents** in Firebase Firestore matching the schema above
3. **Test thoroughly** before releasing to production

---

## Troubleshooting

### "No events showing up"
- Check if events are in Firebase `events` collection
- Check Firestore security rules allow reading events
- Check EventProvider console logs for errors

### "Wallet balance not loading"
- Ensure user document exists in `users/{userId}` collection
- Check that `walletBalance` field is a number type
- Check security rules allow user to read their own data

### "Tickets not saving"
- Verify user is logged in before attempting to book
- Check that `users/{userId}` document exists
- Ensure security rules allow writing to `users/{userId}/tickets`

---

## Next Steps

1. Add events via Firebase Console
2. Create user profile UI to set initial wallet balance
3. Add admin panel for event management
4. Set up Firebase Cloud Functions for any backend logic
5. Monitor Firestore read/write quotas

