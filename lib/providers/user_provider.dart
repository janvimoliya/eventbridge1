import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;
}

class UserTicket {
  const UserTicket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.holderName,
    required this.ticketType,
    required this.quantity,
    required this.amount,
    required this.eventDate,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final String holderName;
  final String ticketType;
  final int quantity;
  final double amount;
  final DateTime eventDate;

  String get qrPayload => '$id|$eventId|$holderName|$ticketType|$quantity';
}

class UserProvider extends ChangeNotifier {
  UserProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthUser? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'en';
  double _textScaleFactor = 1.0;
  double _walletBalance = 0;
  int _eventsAttended = 0;
  double _totalSpent = 0;
  int _earnedLoyaltyPoints = 0;
  int _redeemedLoyaltyPoints = 0;
  double _cashbackEarned = 0;
  EventCategory _favoriteCategory = EventCategory.concert;

  final List<String> _wishlistEventIds = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _wishlistSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _walletSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSubscription;

  final List<UserTicket> _tickets = [];
  final List<WalletTransaction> _allTransactions = [];
  final List<WalletTransaction> _paginatedTransactions = [];
  int _currentTransactionPage = 0;
  static const int _transactionPageSize = 10;
  bool _hasMoreTransactions = false;
  List<AppNotificationModel> _notifications = [];

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  double get textScaleFactor => _textScaleFactor;
  double get walletBalance => _walletBalance;
  List<String> get wishlistEventIds => List.unmodifiable(_wishlistEventIds);
  List<UserTicket> get tickets => List.unmodifiable(_tickets);
  List<WalletTransaction> get transactions =>
      List.unmodifiable(_paginatedTransactions);
  bool get hasMoreTransactions => _hasMoreTransactions;
  int get currentTransactionPage => _currentTransactionPage;
  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get eventsAttended => _eventsAttended;
  double get totalSpent => _totalSpent;
  EventCategory get favoriteCategory => _favoriteCategory;
  int get loyaltyPoints =>
      (_earnedLoyaltyPoints - _redeemedLoyaltyPoints).clamp(0, 999999).toInt();
  double get cashbackEarned => _cashbackEarned;
  double get estimatedCashback => _totalSpent * 0.02;
  double get loyaltyDiscountValue => loyaltyPoints / 10;

  void login(AuthUser user) {
    _currentUser = user;
    _languageCode = _normalizeLanguageCode(user.languageCode);
    _bindWishlistForUser(user.uid);
    _bindWalletForUser(user.uid);
    _bindTicketsForUser(user.uid);
    _bindTransactionsForUser(user.uid);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String photoUrl,
    Uint8List? photoBytes,
    String? photoFileExtension,
    bool removePhoto = false,
  }) async {
    if (_currentUser == null) {
      throw Exception('No active user found. Please login again.');
    }

    final updatedUser = await _authService.updateProfile(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      photoBytes: photoBytes,
      photoFileExtension: photoFileExtension,
      removePhoto: removePhoto,
    );

    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_currentUser == null) {
      throw Exception('No active user found. Please login again.');
    }

    final updatedUser = await _authService.getProfile(uid: _currentUser!.uid);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _wishlistSubscription?.cancel();
      _wishlistSubscription = null;
      _walletSubscription?.cancel();
      _walletSubscription = null;
      _transactionsSubscription?.cancel();
      _transactionsSubscription = null;
      _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
      _wishlistEventIds.clear();
      _tickets.clear();
      _allTransactions.clear();
      _paginatedTransactions.clear();
      _currentUser = null;
      _walletBalance = 0;
      _earnedLoyaltyPoints = 0;
      _redeemedLoyaltyPoints = 0;
      _cashbackEarned = 0;
      notifyListeners();
    }
  }

  void setThemeMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.9, 1.4);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    _languageCode = normalized;
    notifyListeners();

    try {
      await _authService.updateLanguagePreference(languageCode: normalized);
    } catch (_) {
      // Keep the in-memory locale change even if the preference cannot be saved.
    }
  }

  Future<void> toggleWishlist(EventModel event) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Please login to manage wishlist.');
    }

    final docId = _wishlistDocId(user.uid, event.id);
    final primaryDocRef = _wishlistCollectionForUser(user.uid).doc(event.id);
    final legacyDocRef = _firestore.collection('wishlists').doc(docId);

    if (_wishlistEventIds.contains(event.id)) {
      await _runWishlistWriteWithFallback(
        primaryWrite: () => primaryDocRef.delete(),
        legacyWrite: () => legacyDocRef.delete(),
      );
      return;
    }

    final payload = <String, dynamic>{
      'id': docId,
      'userId': user.uid,
      'eventId': event.id,
      'eventName': event.title,
      'eventCategory': event.category.name,
      'eventDate': Timestamp.fromDate(event.date),
      'eventImageUrl': event.imageUrl,
      'eventLocation': event.location,
      'eventPrice': event.price,
      'organizerId': _organizerIdFromEvent(event),
      'organizerName': event.organizerName,
      'priority': 'high',
      'notes': '',
      'reminderDays': 1,
      'reminderEnabled': false,
      'addedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _runWishlistWriteWithFallback(
      primaryWrite: () => primaryDocRef.set(payload, SetOptions(merge: true)),
      legacyWrite: () => legacyDocRef.set(payload, SetOptions(merge: true)),
    );
  }

  bool isWishlisted(String eventId) => _wishlistEventIds.contains(eventId);

  void addNotification(AppNotificationModel notification) {
    _notifications = [notification, ..._notifications];
    notifyListeners();
  }

  Future<void> initializeNotifications(NotificationService service) async {
    _notifications = await service.fetchDefaultNotifications();
    notifyListeners();
  }

  Future<void> topUpWallet(double amount) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null && _currentUser == null) {
      throw Exception('Please login to top up wallet.');
    }

    final userId = firebaseUser?.uid ?? _currentUser!.uid;
    final txnId = 'topup_${DateTime.now().millisecondsSinceEpoch}';
    final newBalance = _walletBalance + amount;

    // Apply local optimistic update
    _allTransactions.insert(
      0,
      WalletTransaction(
        id: txnId,
        title: 'Wallet Top-up',
        amount: amount,
        timestamp: DateTime.now(),
      ),
    );
    _walletBalance = newBalance;
    notifyListeners();

    final userPayload = _buildUserPayload(
      walletBalance: newBalance,
      totalSpent: _totalSpent,
      eventsAttended: _eventsAttended,
    );

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userPayload, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet_transactions')
          .doc(txnId)
          .set({
            'id': txnId,
            'userId': userId,
            'title': 'Wallet Top-up',
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      // Rollback local state on failure and surface error
      _allTransactions.removeWhere((t) => t.id == txnId);
      _walletBalance = (_walletBalance - amount).clamp(0, double.infinity);
      notifyListeners();
      debugPrint('Failed to persist wallet top-up: $error');
      throw Exception('Failed to persist wallet top-up: $error');
    }
  }

  Future<bool> spendFromWallet({
    required double amount,
    required String title,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null && _currentUser == null) {
      throw Exception('Please login to spend from wallet.');
    }

    if (_walletBalance < amount) {
      return false;
    }

    final userId = firebaseUser?.uid ?? _currentUser!.uid;
    final txnId = 'purchase_${DateTime.now().millisecondsSinceEpoch}';
    final newBalance = _walletBalance - amount;

    // Optimistic local update
    _allTransactions.insert(
      0,
      WalletTransaction(
        id: txnId,
        title: title,
        amount: -amount,
        timestamp: DateTime.now(),
      ),
    );

    _walletBalance = newBalance;
    notifyListeners();

    final userPayload = _buildUserPayload(
      walletBalance: newBalance,
      totalSpent: _totalSpent,
      eventsAttended: _eventsAttended,
    );

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userPayload, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet_transactions')
          .doc(txnId)
          .set({
            'id': txnId,
            'userId': userId,
            'title': title,
            'amount': -amount,
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      // Rollback optimistic changes
      _allTransactions.removeWhere((t) => t.id == txnId);
      _walletBalance = (_walletBalance + amount).clamp(0, double.infinity);
      notifyListeners();
      debugPrint('Failed to persist wallet spend: $error');
      throw Exception('Failed to persist wallet spend: $error');
    }

    return true;
  }

  Future<void> finalizeBookingRewards({
    required double amount,
    required String title,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null && _currentUser == null) {
      throw Exception('Please login to apply booking rewards.');
    }

    final userId = firebaseUser?.uid ?? _currentUser!.uid;
    final rewardId = 'reward_${DateTime.now().millisecondsSinceEpoch}';
    final cashback = amount * 0.02;
    final pointsEarned = amount <= 0
        ? 0
        : ((amount / 100).floor().clamp(1, 999999));

    _totalSpent += amount;
    _earnedLoyaltyPoints += pointsEarned;
    _cashbackEarned += cashback;
    _walletBalance += cashback;
    _allTransactions.insert(
      0,
      WalletTransaction(
        id: rewardId,
        title: 'Cashback reward - $title',
        amount: cashback,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    final userPayload = _buildUserPayload(
      walletBalance: _walletBalance,
      totalSpent: _totalSpent,
      eventsAttended: _eventsAttended,
    );

    _firestore
        .collection('users')
        .doc(userId)
        .set(userPayload, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Failed to persist booking rewards: $error');
        });

    _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .doc(rewardId)
        .set({
          'id': rewardId,
          'userId': userId,
          'title': 'Cashback reward - $title',
          'amount': cashback,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        })
        .catchError((error) {
          debugPrint('Failed to save cashback transaction: $error');
        });
  }

  Future<void> redeemLoyaltyPoints({required int points}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null && _currentUser == null) {
      throw Exception('Please login to redeem points.');
    }

    if (points <= 0) {
      throw Exception('Enter a valid number of points.');
    }

    if (points > loyaltyPoints) {
      throw Exception('Not enough loyalty points available.');
    }

    final discountValue = points / 10;
    if (discountValue <= 0) {
      throw Exception('Not enough points for redemption.');
    }

    final userId = firebaseUser?.uid ?? _currentUser!.uid;
    final txnId = 'redeem_${DateTime.now().millisecondsSinceEpoch}';

    _redeemedLoyaltyPoints += points;
    _walletBalance += discountValue;
    _allTransactions.insert(
      0,
      WalletTransaction(
        id: txnId,
        title: 'Loyalty redemption',
        amount: discountValue,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    final userPayload = _buildUserPayload(
      walletBalance: _walletBalance,
      totalSpent: _totalSpent,
      eventsAttended: _eventsAttended,
    );

    _firestore
        .collection('users')
        .doc(userId)
        .set(userPayload, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Failed to persist redeemed points: $error');
        });

    _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .doc(txnId)
        .set({
          'id': txnId,
          'userId': userId,
          'title': 'Loyalty redemption',
          'amount': discountValue,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        })
        .catchError((error) {
          debugPrint('Failed to save loyalty redemption transaction: $error');
        });
  }

  Future<void> addTicket(UserTicket ticket, EventCategory category) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null && _currentUser == null) {
      throw Exception('Please login to add ticket.');
    }

    final userId = firebaseUser?.uid ?? _currentUser!.uid;

    // Apply optimistic local state
    _tickets.insert(0, ticket);
    _eventsAttended += 1;
    _favoriteCategory = category;
    notifyListeners();

    try {
      // Persist user profile
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            _buildUserPayload(
              walletBalance: _walletBalance,
              totalSpent: _totalSpent,
              eventsAttended: _eventsAttended,
            ),
            SetOptions(merge: true),
          );

      // Persist ticket in user's subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tickets')
          .doc(ticket.id)
          .set({
            'id': ticket.id,
            'userId': userId,
            'eventId': ticket.eventId,
            'eventTitle': ticket.eventTitle,
            'holderName': ticket.holderName,
            'ticketType': ticket.ticketType,
            'quantity': ticket.quantity,
            'amount': ticket.amount,
            'eventDate': Timestamp.fromDate(ticket.eventDate),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Persist top-level booking for admin visibility
      await _firestore.collection('bookings').doc(ticket.id).set({
        'id': ticket.id,
        'userId': userId,
        'userName': ticket.holderName,
        'eventId': ticket.eventId,
        'eventName': ticket.eventTitle,
        'ticketType': ticket.ticketType,
        'tickets': ticket.quantity,
        'amount': ticket.amount,
        'paymentStatus': 'Paid',
        'date': Timestamp.now(),
        'eventDate': Timestamp.fromDate(ticket.eventDate),
        'qrData': ticket.qrPayload,
        'isCancelled': false,
        'isRefunded': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user stats atomically
      await _firestore.collection('users').doc(userId).set({
        'totalBookings': FieldValue.increment(1),
        'eventsAttended': FieldValue.increment(1),
        'favoriteCategory': category.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      // Rollback optimistic changes and propagate error so caller can handle it
      _tickets.removeWhere((t) => t.id == ticket.id);
      _eventsAttended = (_eventsAttended - 1).clamp(0, 999999);
      notifyListeners();
      debugPrint('Failed to persist ticket/booking: $error');
      throw Exception('Failed to persist ticket/booking: $error');
    }
  }

  Future<void> refreshTickets() async {
    if (_currentUser == null) {
      debugPrint('No active user to refresh tickets');
      return;
    }

    debugPrint('Manually refreshing tickets for user: ${_currentUser!.uid}');
    _bindTicketsForUser(_currentUser!.uid);
  }

  void _loadMoreTransactions() {
    _currentTransactionPage++;
    _updatePaginatedTransactions();
  }

  void _updatePaginatedTransactions() {
    final startIndex = _currentTransactionPage * _transactionPageSize;
    final endIndex = startIndex + _transactionPageSize;

    _paginatedTransactions.clear();
    if (startIndex < _allTransactions.length) {
      _paginatedTransactions.addAll(
        _allTransactions.sublist(
          startIndex,
          endIndex > _allTransactions.length
              ? _allTransactions.length
              : endIndex,
        ),
      );
    }

    _hasMoreTransactions = endIndex < _allTransactions.length;
    notifyListeners();
  }

  void loadMoreTransactions() {
    _loadMoreTransactions();
  }

  Map<String, dynamic> _buildUserPayload({
    required double walletBalance,
    required double totalSpent,
    required int eventsAttended,
  }) {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Please login again.');
    }

    return {
      'id': user.uid,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'languageCode': _normalizeLanguageCode(user.languageCode),
      'role': user.isOrganizer ? 'organizer' : 'user',
      'isOrganizer': user.isOrganizer,
      'isVerifiedOrganizer': false,
      'isBlocked': false,
      'themeMode': _themeMode.name,
      'walletBalance': walletBalance,
      'totalSpent': totalSpent,
      'eventsAttended': eventsAttended,
      'earnedLoyaltyPoints': _earnedLoyaltyPoints,
      'redeemedLoyaltyPoints': _redeemedLoyaltyPoints,
      'cashbackEarned': _cashbackEarned,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  List<EventModel> personalizedRecommendations(List<EventModel> allEvents) {
    final preferred = allEvents
        .where((e) => e.category == _favoriteCategory)
        .toList();
    final fromWishlist = allEvents
        .where((e) => _wishlistEventIds.contains(e.id))
        .toList();

    final merged = <EventModel>{...preferred, ...fromWishlist};
    if (merged.isNotEmpty) {
      return merged.toList();
    }

    return allEvents.take(3).toList();
  }

  void _bindWishlistForUser(String userId) {
    _wishlistSubscription?.cancel();
    _bindWishlistFromUserSubcollection(userId);
  }

  void _bindWishlistFromUserSubcollection(String userId) {
    _wishlistSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlists')
        .snapshots()
        .listen(
          (snapshot) {
            _wishlistEventIds
              ..clear()
              ..addAll(
                snapshot.docs
                    .map((doc) => (doc.data()['eventId'] ?? '').toString())
                    .where((eventId) => eventId.isNotEmpty),
              );
            notifyListeners();
          },
          onError: (error) {
            if (_isPermissionDeniedError(error)) {
              _bindWishlistFromLegacyCollection(userId);
              return;
            }
            debugPrint('Failed to sync wishlist: $error');
          },
        );
  }

  void _bindWishlistFromLegacyCollection(String userId) {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            _wishlistEventIds
              ..clear()
              ..addAll(
                snapshot.docs
                    .map((doc) => (doc.data()['eventId'] ?? '').toString())
                    .where((eventId) => eventId.isNotEmpty),
              );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to sync wishlist: $error');
          },
        );
  }

  void _bindWalletForUser(String userId) {
    _walletSubscription?.cancel();
    _walletSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() ?? {};
              _walletBalance = _toDouble(data['walletBalance']);
              _eventsAttended = _toInt(data['eventsAttended']);
              _totalSpent = _toDouble(data['totalSpent']);
              final storedPoints = _toInt(data['earnedLoyaltyPoints']);
              _earnedLoyaltyPoints = storedPoints > 0
                  ? storedPoints
                  : (_toDouble(data['totalSpent']) / 100).floor();
              _redeemedLoyaltyPoints = _toInt(data['redeemedLoyaltyPoints']);
              _cashbackEarned = _toDouble(data['cashbackEarned']);
              final favCatStr = (data['favoriteCategory'] ?? '').toString();
              if (favCatStr.isNotEmpty) {
                _favoriteCategory = EventCategory.values.firstWhere(
                  (cat) => cat.name == favCatStr,
                  orElse: () => EventCategory.concert,
                );
              }
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('Failed to sync wallet: $error');
          },
        );
  }

  void _bindTransactionsForUser(String userId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _allTransactions.clear();
            final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final timestamp =
                  _parseTimestamp(data['timestamp']) ?? DateTime.now();

              // Only include transactions from the last 30 days
              if (timestamp.isAfter(thirtyDaysAgo) ||
                  timestamp.day == thirtyDaysAgo.day &&
                      timestamp.month == thirtyDaysAgo.month &&
                      timestamp.year == thirtyDaysAgo.year) {
                _allTransactions.add(
                  WalletTransaction(
                    id: (data['id'] ?? '').toString(),
                    title: (data['title'] ?? '').toString(),
                    amount: _toDouble(data['amount']),
                    timestamp: timestamp,
                  ),
                );
              }
            }

            // Reset pagination and load first page
            _currentTransactionPage = 0;
            _updatePaginatedTransactions();
          },
          onError: (error) {
            if (_isPermissionDeniedError(error)) {
              _bindTransactionsFromLegacyCollection(userId);
              return;
            }
            debugPrint('Failed to sync transactions: $error');
          },
        );
  }

  void _bindTransactionsFromLegacyCollection(String userId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _allTransactions.clear();
            final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final timestamp =
                  _parseTimestamp(data['timestamp']) ?? DateTime.now();

              // Only include transactions from the last 30 days
              if (timestamp.isAfter(thirtyDaysAgo) ||
                  timestamp.day == thirtyDaysAgo.day &&
                      timestamp.month == thirtyDaysAgo.month &&
                      timestamp.year == thirtyDaysAgo.year) {
                _allTransactions.add(
                  WalletTransaction(
                    id: (data['id'] ?? '').toString(),
                    title: (data['title'] ?? '').toString(),
                    amount: _toDouble(data['amount']),
                    timestamp: timestamp,
                  ),
                );
              }
            }

            // Reset pagination and load first page
            _currentTransactionPage = 0;
            _updatePaginatedTransactions();
          },
          onError: (error) {
            if (_isPermissionDeniedError(error)) {
              _allTransactions.clear();
              _paginatedTransactions.clear();
              _hasMoreTransactions = false;
              _currentTransactionPage = 0;
              notifyListeners();
              return;
            }
            debugPrint('Failed to sync transactions: $error');
          },
        );
  }

  void _bindTicketsForUser(String userId) {
    _ticketsSubscription?.cancel();

    debugPrint('Setting up tickets listener for user: $userId');

    _ticketsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              'Tickets listener update: ${snapshot.docs.length} tickets',
            );
            _tickets.clear();
            for (final doc in snapshot.docs) {
              final data = doc.data();
              _tickets.add(
                UserTicket(
                  id: (data['id'] ?? '').toString(),
                  eventId: (data['eventId'] ?? '').toString(),
                  eventTitle: (data['eventTitle'] ?? '').toString(),
                  holderName: (data['holderName'] ?? '').toString(),
                  ticketType: (data['ticketType'] ?? '').toString(),
                  quantity: _toInt(data['quantity']),
                  amount: _toDouble(data['amount']),
                  eventDate:
                      _parseTimestamp(data['eventDate']) ?? DateTime.now(),
                ),
              );
            }
            debugPrint('Tickets updated: ${_tickets.length}');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Tickets listener error: $error');
            if (_isPermissionDeniedError(error)) {
              debugPrint(
                'Permission denied, falling back to legacy collection',
              );
              _bindTicketsFromLegacyCollection(userId);
              return;
            }
            debugPrint('Failed to sync tickets: $error');
          },
        );
  }

  void _bindTicketsFromLegacyCollection(String userId) {
    _ticketsSubscription?.cancel();
    _ticketsSubscription = _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _tickets.clear();
            for (final doc in snapshot.docs) {
              final data = doc.data();
              _tickets.add(
                UserTicket(
                  id: (data['id'] ?? '').toString(),
                  eventId: (data['eventId'] ?? '').toString(),
                  eventTitle: (data['eventTitle'] ?? '').toString(),
                  holderName: (data['holderName'] ?? '').toString(),
                  ticketType: (data['ticketType'] ?? '').toString(),
                  quantity: _toInt(data['quantity']),
                  amount: _toDouble(data['amount']),
                  eventDate:
                      _parseTimestamp(data['eventDate']) ?? DateTime.now(),
                ),
              );
            }
            notifyListeners();
          },
          onError: (error) {
            if (_isPermissionDeniedError(error)) {
              _tickets.clear();
              notifyListeners();
              return;
            }
            debugPrint('Failed to sync tickets: $error');
          },
        );
  }

  CollectionReference<Map<String, dynamic>> _wishlistCollectionForUser(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('wishlists');
  }

  Future<void> _runWishlistWriteWithFallback({
    required Future<void> Function() primaryWrite,
    required Future<void> Function() legacyWrite,
  }) async {
    try {
      await primaryWrite();
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }

    try {
      await legacyWrite();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw Exception(
          'Unable to update wishlist due to Firestore security rules. Allow signed-in users to write under users/{uid}/wishlists or wishlists where request.auth.uid matches the owner.',
        );
      }
      rethrow;
    }
  }

  bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  String _wishlistDocId(String userId, String eventId) => '${userId}_$eventId';

  String _organizerIdFromEvent(EventModel event) {
    final source = event.organizerName.trim().toLowerCase();
    if (source.isEmpty) {
      return 'unknown_organizer';
    }
    return source
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}

String _normalizeLanguageCode(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'hi':
      return 'hi';
    case 'gu':
      return 'gu';
    default:
      return 'en';
  }
}
