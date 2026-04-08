import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // ── Firebase instances ────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state ────────────────────────────────────────────────────────────
  User? _firebaseUser;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userDob = '';
  String _userGender = '';
  String _profileImage = '';

  bool get isLoggedIn => _firebaseUser != null;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userDob => _userDob;
  String get userGender => _userGender;
  String get profileImage => _profileImage;
  String get userId => _firebaseUser?.uid ?? '';

  // ── Database Sync State ───────────────────────────────────────────────────
  List<Product> _products = [];
  bool _isLoadingProducts = false;

  bool get isLoadingProducts => _isLoadingProducts;
  List<Product> get products => _products.isEmpty ? sampleProducts : _products;

  AppState() {
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      _loadUserProfile(_firebaseUser!.uid).then((_) => notifyListeners());
    }

    _fetchProducts();

    // Rebuild UI whenever Firebase auth state changes
    _auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _clearProfile();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] ?? '';
        _userEmail = data['email'] ?? '';
        _userPhone = data['phone'] ?? '';
        _userDob = data['dob'] ?? '';
        _userGender = data['gender'] ?? '';
        _profileImage = data['profileImage'] ?? '';
      }

      final addrSnapshot =
          await _db.collection('users').doc(uid).collection('addresses').get();
      _addresses.clear();
      for (var doc in addrSnapshot.docs) {
        _addresses.add(Address.fromMap(doc.data(), doc.id));
      }

      // Load Wishlist
      final wishlistDoc = await _db.collection('wishlists').doc(uid).get();
      if (wishlistDoc.exists) {
        final List<dynamic> ids = wishlistDoc.data()?['productIds'] ?? [];
        _wishlistIds = ids.cast<String>().toSet();
      }

      // Load Cart
      final cartDoc = await _db.collection('carts').doc(uid).get();
      if (cartDoc.exists) {
        final List<dynamic> cartData = cartDoc.data()?['items'] ?? [];
        _cart.clear();
        for (var i in cartData) {
          _cart.add(CartItem.fromMap(Map<String, dynamic>.from(i), ''));
        }
      }

      // Load Orders
      final ordersSnapshot = await _db.collection('orders').where('userId', isEqualTo: uid).get();
      _orders.clear();
      for (var doc in ordersSnapshot.docs) {
        _orders.add(Order.fromMap(doc.data(), doc.id));
      }
      // Sort orders newest first
      _orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    } catch (_) {}
  }

  void _clearProfile() {
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _userDob = '';
    _userGender = '';
    _profileImage = '';
    _addresses.clear();
    _wishlistIds.clear();
    _cart.clear();
    _orders.clear();
  }

  // ── Load Products from Firestore ──────────────────────────────────────────
  Future<void> _fetchProducts() async {
    _isLoadingProducts = true;
    notifyListeners();
    try {
      final snapshot = await _db.collection('products').get();
      if (snapshot.docs.isNotEmpty) {
        _products = snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
      } else {
        // If the table is completely empty, upload the dummy products automatically!
        for (var product in sampleProducts) {
          await _db.collection('products').doc(product.id).set(product.toMap());
        }
        final reSnapshot = await _db.collection('products').get();
        _products = reSnapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    _isLoadingProducts = false;
    notifyListeners();
  }

  // ── Seed Dummy Data into Firestore (Run Once) ─────────────────────────────
  Future<void> seedSampleProducts() async {
    if (_products.isNotEmpty) return; // Prevent duplicate uploads if already fetched
    for (var product in sampleProducts) {
      await _db.collection('products').doc(product.id).set(product.toMap());
    }
    await _fetchProducts(); // refresh
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String dob,
    required String gender,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String district,
    required String state,
    required String pincode,
  }) async {
    if (name.trim().isEmpty) return 'Name is required';
    if (!email.contains('@')) return 'Enter a valid email';
    if (phone.trim().length < 10) return 'Enter a valid 10-digit phone number';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (dob.trim().isEmpty) return 'Date of Birth is required';
    if (addressLine1.trim().isEmpty) return 'Address Line 1 is required';
    if (city.trim().isEmpty) return 'City is required';
    if (district.trim().isEmpty) return 'District is required';
    if (state.trim().isEmpty) return 'State is required';
    if (pincode.trim().isEmpty) return 'Pincode is required';

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());

      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'dob': dob.trim(),
        'gender': gender.trim(),
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newAddr = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        phone: phone.trim(),
        addressLine1: addressLine1.trim(),
        addressLine2: addressLine2.trim(),
        city: city.trim(),
        district: district.trim(),
        state: state.trim(),
        pincode: pincode.trim(),
        isDefault: true,
      );

      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .collection('addresses')
          .doc(newAddr.id)
          .set(newAddr.toMap());

      // We do not sign out here, so the user is automatically logged in.
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        return 'This email is already registered.';
      if (e.code == 'weak-password') return 'Password is too weak.';
      if (e.code == 'invalid-email') return 'Enter a valid email address.';
      return e.message ?? 'Sign up failed. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    if (email.trim().isEmpty) return 'Email is required';
    if (password.isEmpty) return 'Password is required';
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential')
        return 'Invalid credentials. Please create an account if you don\'t have one.';
      if (e.code == 'user-not-found')
        return 'Invalid credentials. Please create an account if you don\'t have one.';
      if (e.code == 'wrong-password') return 'Incorrect password.';
      if (e.code == 'invalid-email') return 'Enter a valid email address.';
      if (e.code == 'user-disabled') return 'This account has been disabled.';
      return e.message ?? 'Login failed. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  Future<String?> deleteAccount(String password) async {
    if (_firebaseUser == null) return 'Not logged in';
    final email = _firebaseUser!.email;
    if (email == null || email.isEmpty) return 'Could not find account email.';
    try {
      // Step 1: Re-authenticate silently so Firebase accepts the delete
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final result = await _firebaseUser!.reauthenticateWithCredential(credential);
      // Refresh user reference after re-auth to ensure token is fresh
      final freshUser = result.user ?? _auth.currentUser;
      if (freshUser == null) return 'Could not verify account. Please try again.';

      // Step 2: Delete Firestore data (each wrapped individually so missing docs don't block)
      final uid = freshUser.uid;
      try { await _db.collection('users').doc(uid).delete(); } catch (_) {}
      try { await _db.collection('carts').doc(uid).delete(); } catch (_) {}
      try { await _db.collection('wishlists').doc(uid).delete(); } catch (_) {}
      try {
        final orderSnap = await _db.collection('orders').where('userId', isEqualTo: uid).get();
        for (final doc in orderSnap.docs) { await doc.reference.delete(); }
      } catch (_) {}

      // Step 3: Delete the Firebase Auth account itself
      await freshUser.delete();
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('deleteAccount FirebaseAuthException: code=${e.code} msg=${e.message}');
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        return 'Incorrect password. Please try again.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Session expired. Please log out, log back in, and try again.';
      }
      return e.message ?? 'Failed to delete account.';
    } catch (e) {
      debugPrint('deleteAccount unexpected error: $e');
      return e.toString();
    }
  }

  // ── Update profile extras (DOB, gender, phone) to Firestore ──────────────
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? dob,
    String? gender,
  }) async {
    if (_firebaseUser == null) return 'Not logged in';
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (phone != null && phone.isNotEmpty) updates['phone'] = phone;
      if (dob != null) updates['dob'] = dob;
      if (gender != null) updates['gender'] = gender;

      if (updates.isNotEmpty) {
        await _db
            .collection('users')
            .doc(_firebaseUser!.uid)
            .set(updates, SetOptions(merge: true));
        if (name != null) _userName = name;
        if (phone != null) _userPhone = phone;
        if (dob != null) _userDob = dob;
        if (gender != null) _userGender = gender;
        if (name != null) await _firebaseUser!.updateDisplayName(name);
        notifyListeners();
      }
      return null;
    } catch (_) {
      return 'Failed to update profile. Please try again.';
    }
  }

  // ── Upload Profile Image ──────────────────────────────────────────────────
  Future<String?> uploadProfileImage(File imageFile) async {
    if (_firebaseUser == null) return 'Not logged in';
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      await _db
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set({'profileImage': base64String}, SetOptions(merge: true));

      _profileImage = base64String;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Image logic failed: $e');
      return 'Failed to save profile picture: $e';
    }
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  Set<String> _wishlistIds = {};

  bool isWishlisted(String productId) => _wishlistIds.contains(productId);

  Future<void> toggleWishlist(String productId) async {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    notifyListeners();
    
    if (isLoggedIn) {
      await _db.collection('wishlists').doc(userId).set({
        'productIds': _wishlistIds.toList()
      });
    }
  }

  List<Product> get wishlistProducts =>
      products.where((p) => _wishlistIds.contains(p.id)).toList();

  // ── Cart ──────────────────────────────────────────────────────────────────
  final List<CartItem> _cart = [];

  List<CartItem> get cart => List.unmodifiable(_cart);

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get cartShipping => cartSubtotal > 999 ? 0 : 99;
  double get cartTotal => cartSubtotal + cartShipping;

  Future<void> _syncCartToFirebase() async {
    if (isLoggedIn) {
      await _db.collection('carts').doc(userId).set({
        'items': _cart.map((c) => c.toMap()).toList()
      });
    }
  }

  void addToCart(Product product, String size, String color) {
    final existing = _cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );
    if (existing >= 0) {
      _cart[existing] = _cart[existing].copyWith(
        quantity: _cart[existing].quantity + 1,
      );
    } else {
      _cart.add(CartItem(
        product: product,
        selectedSize: size,
        selectedColor: color,
      ));
    }
    notifyListeners();
    _syncCartToFirebase();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
    _syncCartToFirebase();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      removeFromCart(index);
    } else {
      _cart[index] = _cart[index].copyWith(quantity: qty);
      notifyListeners();
      _syncCartToFirebase();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
    _syncCartToFirebase();
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  final List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  Future<void> placeOrder(Address address, String paymentMethod) async {
    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      items: List.from(_cart),
      totalAmount: cartTotal,
      address: address,
      status: 'Confirmed',
      placedAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );
    _orders.insert(0, order);
    clearCart();
    notifyListeners();

    if (isLoggedIn) {
      final orderMap = order.toMap();
      orderMap['userId'] = userId;
      await _db.collection('orders').doc(order.id).set(orderMap);
    }
  }

  // ── Addresses ─────────────────────────────────────────────────────────────
  final List<Address> _addresses = [];

  List<Address> get addresses => _addresses;

  Future<void> addAddress(Address address) async {
    if (_firebaseUser == null) return;

    if (address.isDefault) {
      for (var a in _addresses) {
        a.isDefault = false;
        _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(a.id)
            .update({'isDefault': false});
      }
    }
    _addresses.add(address);
    notifyListeners();

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .set(address.toMap());
  }

  Future<void> updateAddress(Address address) async {
    if (_firebaseUser == null) return;

    if (address.isDefault) {
      for (var a in _addresses) {
        if (a.id != address.id) {
          a.isDefault = false;
          _db
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .doc(a.id)
              .update({'isDefault': false});
        }
      }
    }

    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      _addresses[index] = address;
      notifyListeners();
    }

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update(address.toMap());
  }

  Future<void> removeAddressAt(int index) async {
    if (_firebaseUser == null) return;
    final addrId = _addresses[index].id;
    _addresses.removeAt(index);
    notifyListeners();

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addrId)
        .delete();
  }

  void removeAddress(int index) => removeAddressAt(index);

  Future<void> setDefaultAddress(int index) async {
    if (_firebaseUser == null) return;
    for (int i = 0; i < _addresses.length; i++) {
      final wasDefault = _addresses[i].isDefault;
      _addresses[i].isDefault = (i == index);
      if (wasDefault != _addresses[i].isDefault) {
        _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(_addresses[i].id)
            .update({'isDefault': _addresses[i].isDefault});
      }
    }
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  List<Product> get searchResults => _searchQuery.isEmpty
      ? []
      : sampleProducts
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
}

// ── Sample Data ──────────────────────────────────────────────────────────────

const List<String> categories = [
  'All',
  'Sarees',
  'Lehengas',
  'Suits',
  'Kurtis',
  "Men's Ethnic",
  "Men's Casual",
  'Footwear',
  "Kids' Wear",
];

// Gender-based groupings for section headers
const Map<String, List<String>> genderSections = {
  'Women': [
    'Sarees',
    'Lehengas',
    'Suits',
    'Kurtis',
  ],
  "Men": ["Men's Ethnic", "Men's Casual", 'Footwear'],
  'Kids': ["Kids' Wear"],
};

List<String> categoriesForGender(String gender) => genderSections[gender] ?? [];

const List<Map<String, dynamic>> banners = [
  {
    'title': 'Kanjivaram Silk',
    'subtitle': 'Pure silk, pure tradition — Up to 30% OFF',
    'tag': 'BRIDAL COLLECTION',
    'gradient': [Color(0xFF2E5B8A), Color(0xFF1C3F66)],
    'image':
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400',
  },
  {
    'title': 'Festive Lehengas',
    'subtitle': 'Crafted for every celebration',
    'tag': 'NEW ARRIVALS',
    'gradient': [Color(0xFF2A8F8F), Color(0xFF1C6666)],
    'image':
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
  },
  {
    'title': "Men's Ethnic Wear",
    'subtitle': 'Silk dhotis & kurtas from ₹1499',
    'tag': 'TRENDING',
    'gradient': [Color(0xFF2A8F8F), Color(0xFF1C6666)],
    'image':
        'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=400',
  },
  {
    'title': 'Premium Footwear',
    'subtitle': 'Kolhapuri, formal & sports — all styles',
    'tag': 'BEST SELLERS',
    'gradient': [Color(0xFFBF7E20), Color(0xFF1C3F66)],
    'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
  },
];

const List<Product> sampleProducts = [
  // ── Sarees ────────────────────────────────────────────────────────────────
  Product(
    id: 'p001',
    name: 'Kanjivaram Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 12999,
    originalPrice: 18000,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'
    ],
    description:
        'Exquisite handwoven Kanjivaram pure silk saree with zari border. A bridal masterpiece celebrating centuries of Tamil weaving tradition.',
    sizes: ['Free Size'],
    colors: ['Red/Gold', 'Blue/Silver', 'Green/Gold', 'Pink/Gold'],
    rating: 4.9,
    reviewCount: 312,
    isFeatured: true,
    tags: ['bridal', 'silk', 'kanjivaram', 'traditional'],
  ),
  Product(
    id: 'p002',
    name: 'Banarasi Georgette Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 7499,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600'
    ],
    description:
        'Lightweight Banarasi georgette saree with intricate floral motifs and gold zari work. Perfect for festive occasions.',
    sizes: ['Free Size'],
    colors: ['Pink', 'Purple', 'Teal', 'Maroon'],
    rating: 4.7,
    reviewCount: 189,
    isNew: true,
    tags: ['banarasi', 'georgette', 'festive'],
  ),
  Product(
    id: 'p003',
    name: 'Chettinad Cotton Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 2999,
    originalPrice: 3999,
    imageUrl:
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600',
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600'
    ],
    description:
        'Handwoven Chettinad cotton saree with traditional checks and temple border. Comfortable daily wear with a heritage touch.',
    sizes: ['Free Size'],
    colors: ['White/Black', 'Cream/Red', 'Blue/White'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['cotton', 'chettinad', 'daily wear'],
  ),
  Product(
    id: 'p004',
    name: 'Chiffon Printed Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 1999,
    imageUrl:
        'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80'
    ],
    description:
        'Lightweight chiffon saree with digital floral print and contrast border. Easy to drape, perfect for parties and office wear.',
    sizes: ['Free Size'],
    colors: ['Blue Floral', 'Pink Floral', 'Orange Floral', 'Purple'],
    rating: 4.5,
    reviewCount: 167,
    isNew: true,
    tags: ['chiffon', 'printed', 'party', 'office'],
  ),
  // ── Lehengas ──────────────────────────────────────────────────────────────
  Product(
    id: 'p005',
    name: 'Bridal Lehenga Choli',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 24999,
    originalPrice: 35000,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600',
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600'
    ],
    description:
        'Stunning bridal lehenga in heavy embroidered silk with mirror work. Comes with matching blouse and dupatta. Every bride\'s dream.',
    sizes: ['S', 'M', 'L', 'XL', 'Custom'],
    colors: ['Red/Gold', 'Peach/Gold', 'Pink/Silver'],
    rating: 4.9,
    reviewCount: 87,
    isFeatured: true,
    tags: ['bridal', 'lehenga', 'wedding', 'embroidered'],
  ),
  Product(
    id: 'p006',
    name: 'Floral Printed Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 8999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600'
    ],
    description:
        'Flirty floral-print lehenga in lightweight crepe. Perfect for sangeet, mehndi, or festive celebrations.',
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    colors: ['Pastel Pink', 'Sky Blue', 'Mint Green'],
    rating: 4.6,
    reviewCount: 143,
    isNew: true,
    tags: ['floral', 'sangeet', 'festive'],
  ),
  // ── Suits ─────────────────────────────────────────────────────────────────
  Product(
    id: 'p007',
    name: 'Anarkali Suit Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 5499,
    originalPrice: 7500,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop'
    ],
    description:
        'Floor-length Anarkali in georgette with detailed embroidery at neckline and hem. Includes churidar and printed dupatta.',
    sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    colors: ['Navy Blue', 'Wine', 'Bottle Green', 'Black'],
    rating: 4.7,
    reviewCount: 198,
    isFeatured: true,
    tags: ['anarkali', 'suit', 'embroidered'],
  ),
  Product(
    id: 'p008',
    name: 'Patiala Salwar Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 3299,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800'
    ],
    description:
        'Comfortable cotton Patiala suit with vibrant phulkari embroidery. Ideal for daily wear and casual gatherings.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Orange', 'Yellow', 'Pink', 'Green'],
    rating: 4.4,
    reviewCount: 156,
    tags: ['patiala', 'cotton', 'casual'],
  ),
  // ── Kurtis ────────────────────────────────────────────────────────────────
  Product(
    id: 'p009',
    name: 'Block Print Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1499,
    originalPrice: 1999,
    imageUrl: 'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600'
    ],
    description:
        'Handblock-printed A-line kurti in soft cotton. Traditional Rajasthani prints in earthy tones. Pairs well with palazzo or jeans.',
    sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    colors: ['Indigo', 'Rust', 'Olive', 'Maroon'],
    rating: 4.5,
    reviewCount: 302,
    isNew: true,
    tags: ['kurti', 'block print', 'casual', 'cotton'],
  ),
  Product(
    id: 'p010',
    name: 'Chikankari Straight Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2199,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80'
    ],
    description:
        'Elegant straight-cut kurti with intricate chikankari embroidery in fine lucknowi cotton. A wardrobe essential.',
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    colors: ['White', 'Powder Blue', 'Mint', 'Peach'],
    rating: 4.6,
    reviewCount: 278,
    tags: ['chikankari', 'kurti', 'elegant'],
  ),
  // ── Men's Wear ────────────────────────────────────────────────────────────
  Product(
    id: 'p011',
    name: 'Silk Dhoti Set',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 3999,
    originalPrice: 5499,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600'
    ],
    description:
        'Premium pure silk dhoti with matching angavastram. Perfect for temple visits, weddings, and traditional functions.',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    colors: ['Cream/Gold', 'White/Silver', 'Yellow/Gold'],
    rating: 4.8,
    reviewCount: 134,
    isFeatured: true,
    tags: ['dhoti', 'silk', 'traditional', 'men'],
  ),
  Product(
    id: 'p012',
    name: 'Nehru Jacket Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 4599,
    originalPrice: 6000,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80'
    ],
    description:
        'Stylish Nehru jacket paired with straight kurta in rich Dupion silk. A sophisticated look for festivities and weddings.',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    colors: ['Beige/Brown', 'Grey/White', 'Navy/Gold'],
    rating: 4.7,
    reviewCount: 89,
    isNew: true,
    tags: ['kurta', 'nehru jacket', 'men', 'festive'],
  ),
  // ── Footwear ──────────────────────────────────────────────────────────────
  Product(
    id: 'p013',
    name: 'Kolhapuri Leather Sandal',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 1899,
    originalPrice: 2499,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600'
    ],
    description:
        'Handcrafted genuine leather Kolhapuri sandal with traditional T-strap design. Durable and stylish for daily wear.',
    sizes: ['UK 5', 'UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10'],
    colors: ['Tan', 'Brown', 'Black'],
    rating: 4.6,
    reviewCount: 187,
    tags: ['kolhapuri', 'leather', 'handcrafted', 'sandal'],
  ),
  Product(
    id: 'p014',
    name: 'Sports Running Shoe',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 2999,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80'
    ],
    description:
        'Lightweight EVA sole running shoe with breathable mesh upper. Anti-skid grip and cushioned footbed for maximum comfort.',
    sizes: ['UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11'],
    colors: ['Black/White', 'Blue/White', 'Red/Black'],
    rating: 4.4,
    reviewCount: 263,
    isNew: true,
    tags: ['sports', 'running', 'shoe'],
  ),
  Product(
    id: 'p015',
    name: 'Formal Oxford Shoe',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3499,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80'
    ],
    description:
        'Premium leather oxford with cushioned insole. Classic cap-toe design for office and formal events.',
    sizes: ['UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10'],
    colors: ['Black', 'Dark Brown', 'Tan'],
    rating: 4.7,
    reviewCount: 145,
    isFeatured: true,
    tags: ['formal', 'oxford', 'leather', 'office'],
  ),
  // ── Kids ──────────────────────────────────────────────────────────────────
  Product(
    id: 'p020',
    name: "Girl's Pattu Pavadai",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1999,
    originalPrice: 2799,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600'
    ],
    description:
        'Traditional Kanjivaram silk Pattu Pavadai for girls. Comes with matching blouse. Ideal for temple visits and festivals.',
    sizes: ['1-2Y', '2-3Y', '3-4Y', '4-5Y', '5-6Y', '6-8Y'],
    colors: ['Red/Gold', 'Green/Gold', 'Pink/Silver'],
    rating: 4.9,
    reviewCount: 89,
    tags: ['kids', 'pavadai', 'silk', 'traditional'],
  ),
  Product(
    id: 'p021',
    name: "Boy's Dhoti Kurta",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1499,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Adorable cotton dhoti kurta set for boys. Complete with accessories. Perfect for Puja, Diwali and festive occasions.',
    sizes: ['1-2Y', '2-3Y', '3-4Y', '4-5Y', '5-6Y', '6-8Y'],
    colors: ['White/Gold', 'Cream/Red', 'Yellow/Green'],
    rating: 4.7,
    reviewCount: 134,
    isNew: true,
    tags: ['kids', 'dhoti', 'kurta', 'boys'],
  ),
  Product(
    id: 'p024',
    name: 'Zari Blouse Piece',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 1499,
    originalPrice: 2000,
    imageUrl:
        'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80'
    ],
    description:
        'Ready-to-stitch silk blouse piece with heavy zari border. Sold separately to match your favourite saree.',
    sizes: ['0.8 meter', '1 meter'],
    colors: ['Gold', 'Silver', 'Copper'],
    rating: 4.4,
    reviewCount: 203,
    tags: ['blouse', 'zari', 'silk'],
  ),
  Product(
    id: 'p025',
    name: 'Bandhani Tie-Dye Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 4499,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80',
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80'
    ],
    description:
        'Authentic Gujarati Bandhani tie-dye saree in vibrant colors. Each piece is unique, handcrafted by skilled artisans of Kutch.',
    sizes: ['Free Size'],
    colors: ['Red/Yellow', 'Green/Yellow', 'Blue/White', 'Pink/Orange'],
    rating: 4.8,
    reviewCount: 145,
    isNew: true,
    tags: ['bandhani', 'tie-dye', 'gujarati', 'artisan'],
  ),
  Product(
    id: 'p026',
    name: 'Mysore Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 8999,
    originalPrice: 12000,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80',
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80'
    ],
    description:
        'Premium quality Mysore Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 201,
    isFeatured: true,
    tags: ['silk', 'mysore', 'bridal'],
  ),
  Product(
    id: 'p027',
    name: 'Pochampally Ikat Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 5499,
    imageUrl:
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80',
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80'
    ],
    description:
        'Premium quality Pochampally Ikat Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 178,
    isNew: true,
    tags: ['ikat', 'pochampally'],
  ),
  Product(
    id: 'p028',
    name: 'Linen Handloom Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 3499,
    originalPrice: 4500,
    imageUrl:
        'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'
    ],
    description:
        'Premium quality Linen Handloom Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 143,
    tags: ['linen', 'handloom'],
  ),
  Product(
    id: 'p029',
    name: 'Organza Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 6999,
    imageUrl:
        'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'
    ],
    description:
        'Premium quality Organza Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 234,
    isFeatured: true,
    tags: ['organza', 'festive'],
  ),
  Product(
    id: 'p030',
    name: 'Dhakai Jamdani Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 9999,
    originalPrice: 14000,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'
    ],
    description:
        'Premium quality Dhakai Jamdani Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 89,
    isFeatured: true,
    tags: ['jamdani', 'traditional'],
  ),
  Product(
    id: 'p031',
    name: 'Kalamkari Cotton Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 2499,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600'
    ],
    description:
        'Premium quality Kalamkari Cotton Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 312,
    isNew: true,
    tags: ['kalamkari', 'cotton'],
  ),
  Product(
    id: 'p032',
    name: 'Sambalpuri Ikat Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 7499,
    originalPrice: 10000,
    imageUrl:
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600',
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600'
    ],
    description:
        'Premium quality Sambalpuri Ikat Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 156,
    tags: ['sambalpuri', 'ikat'],
  ),
  Product(
    id: 'p033',
    name: 'Patola Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 15999,
    imageUrl:
        'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80'
    ],
    description:
        'Premium quality Patola Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 67,
    isFeatured: true,
    tags: ['patola', 'silk', 'bridal'],
  ),
  Product(
    id: 'p034',
    name: 'Chanderi Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 4999,
    originalPrice: 6800,
    imageUrl:
        'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80'
    ],
    description:
        'Premium quality Chanderi Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 189,
    isNew: true,
    tags: ['chanderi', 'silk'],
  ),
  Product(
    id: 'p035',
    name: 'Net Embroidered Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 3999,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80',
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80'
    ],
    description:
        'Premium quality Net Embroidered Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 223,
    tags: ['net', 'embroidered', 'party'],
  ),
  Product(
    id: 'p036',
    name: 'Cotton Tant Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 1799,
    originalPrice: 2400,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80',
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80'
    ],
    description:
        'Premium quality Cotton Tant Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 267,
    isNew: true,
    tags: ['tant', 'cotton', 'bengal'],
  ),
  Product(
    id: 'p037',
    name: 'Kanchi Pattu Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 11999,
    imageUrl:
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80',
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80'
    ],
    description:
        'Premium quality Kanchi Pattu Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 134,
    isFeatured: true,
    tags: ['kanchi', 'silk', 'bridal'],
  ),
  Product(
    id: 'p038',
    name: 'Uppada Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 9499,
    originalPrice: 13000,
    imageUrl:
        'https://images.unsplash.com/photo-1600091166971-7f9faad6c2d2?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'
    ],
    description:
        'Premium quality Uppada Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 98,
    tags: ['uppada', 'silk'],
  ),
  Product(
    id: 'p039',
    name: 'Phulkari Silk Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 6499,
    imageUrl:
        'https://images.unsplash.com/photo-1631947430066-48c30d57b943?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'
    ],
    description:
        'Premium quality Phulkari Silk Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    isNew: true,
    tags: ['phulkari', 'silk', 'festive'],
  ),
  Product(
    id: 'p040',
    name: 'Tant Cotton Saree',
    brand: 'Siva Silks',
    category: 'Sarees',
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
      'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'
    ],
    description:
        'Premium quality Tant Cotton Saree from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 345,
    tags: ['tant', 'cotton'],
  ),
  Product(
    id: 'p041',
    name: 'Designer Party Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 12999,
    originalPrice: 18000,
    imageUrl:
        'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80'
    ],
    description:
        'Premium quality Designer Party Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 156,
    isFeatured: true,
    tags: ['designer', 'party'],
  ),
  Product(
    id: 'p042',
    name: 'Cotton Ghagra Choli',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 4999,
    imageUrl:
        'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80'
    ],
    description:
        'Premium quality Cotton Ghagra Choli from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    isNew: true,
    tags: ['cotton', 'casual'],
  ),
  Product(
    id: 'p043',
    name: 'Silk Sharara Set',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 8999,
    originalPrice: 12500,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80'
    ],
    description:
        'Premium quality Silk Sharara Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 112,
    isFeatured: true,
    tags: ['sharara', 'silk', 'festive'],
  ),
  Product(
    id: 'p044',
    name: 'Navratri Chaniya Choli',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 3999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80'
    ],
    description:
        'Premium quality Navratri Chaniya Choli from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 234,
    isNew: true,
    tags: ['navratri', 'chaniya'],
  ),
  Product(
    id: 'p045',
    name: 'Embroidered Net Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 14999,
    originalPrice: 21000,
    imageUrl:
        'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop'
    ],
    description:
        'Premium quality Embroidered Net Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 78,
    isFeatured: true,
    tags: ['net', 'embroidered', 'bridal'],
  ),
  Product(
    id: 'p046',
    name: 'Indo-Western Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 9499,
    imageUrl:
        'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop'
    ],
    description:
        'Premium quality Indo-Western Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 143,
    tags: ['indo-western', 'fusion'],
  ),
  Product(
    id: 'p047',
    name: 'Kids Lehenga Choli',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 2499,
    originalPrice: 3500,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600'
    ],
    description:
        'Premium quality Kids Lehenga Choli from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 189,
    isNew: true,
    tags: ['kids', 'festive'],
  ),
  Product(
    id: 'p048',
    name: 'Velvet Bridal Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 29999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600'
    ],
    description:
        'Premium quality Velvet Bridal Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 45,
    isFeatured: true,
    tags: ['velvet', 'bridal', 'luxury'],
  ),
  Product(
    id: 'p049',
    name: 'Patiala Lehenga Set',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 5999,
    originalPrice: 8200,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600',
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600'
    ],
    description:
        'Premium quality Patiala Lehenga Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 167,
    tags: ['patiala', 'casual'],
  ),
  Product(
    id: 'p050',
    name: 'Mirror Work Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 11499,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600'
    ],
    description:
        'Premium quality Mirror Work Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 123,
    isFeatured: true,
    isNew: true,
    tags: ['mirror', 'festive'],
  ),
  Product(
    id: 'p051',
    name: 'Palazzo Set with Dupatta',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 3499,
    originalPrice: 4800,
    imageUrl:
        'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80'
    ],
    description:
        'Premium quality Palazzo Set with Dupatta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 276,
    isNew: true,
    tags: ['palazzo', 'casual'],
  ),
  Product(
    id: 'p052',
    name: 'Sharara Gharara Set',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 7999,
    imageUrl:
        'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80'
    ],
    description:
        'Premium quality Sharara Gharara Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 134,
    tags: ['gharara', 'festive'],
  ),
  Product(
    id: 'p053',
    name: 'Lehenga Saree Fusion',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 8499,
    originalPrice: 11500,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80'
    ],
    description:
        'Premium quality Lehenga Saree Fusion from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 98,
    isFeatured: true,
    tags: ['fusion', 'modern'],
  ),
  Product(
    id: 'p054',
    name: 'Rajasthani Bandhej Lehenga',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 6999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80'
    ],
    description:
        'Premium quality Rajasthani Bandhej Lehenga from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 145,
    isNew: true,
    tags: ['bandhej', 'rajasthani'],
  ),
  Product(
    id: 'p055',
    name: 'Silk Kaftan Dress',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 5499,
    originalPrice: 7500,
    imageUrl:
        'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop'
    ],
    description:
        'Premium quality Silk Kaftan Dress from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 178,
    tags: ['kaftan', 'silk'],
  ),
  Product(
    id: 'p056',
    name: 'Anarkali Floor Gown',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 7499,
    imageUrl:
        'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop'
    ],
    description:
        'Premium quality Anarkali Floor Gown from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    isFeatured: true,
    tags: ['anarkali', 'gown'],
  ),
  Product(
    id: 'p057',
    name: 'Half Saree Langa',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 6499,
    originalPrice: 8800,
    imageUrl:
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600'
    ],
    description:
        'Premium quality Half Saree Langa from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 112,
    isNew: true,
    tags: ['half-saree', 'langa'],
  ),
  Product(
    id: 'p058',
    name: 'Georgette Lehenga Set',
    brand: 'Siva Silks',
    category: 'Lehengas',
    price: 9999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=600',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600'
    ],
    description:
        'Premium quality Georgette Lehenga Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 89,
    isFeatured: true,
    tags: ['georgette', 'bridal'],
  ),
  Product(
    id: 'p059',
    name: 'Punjabi Salwar Kameez',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 2999,
    originalPrice: 4200,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80'
    ],
    description:
        'Premium quality Punjabi Salwar Kameez from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 345,
    isNew: true,
    tags: ['punjabi', 'cotton'],
  ),
  Product(
    id: 'p060',
    name: 'Embroidered Georgette Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 6499,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80'
    ],
    description:
        'Premium quality Embroidered Georgette Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 178,
    isFeatured: true,
    tags: ['georgette', 'embroidered'],
  ),
  Product(
    id: 'p061',
    name: 'Cotton Palazzo Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 2499,
    originalPrice: 3400,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop'
    ],
    description:
        'Premium quality Cotton Palazzo Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 234,
    isNew: true,
    tags: ['palazzo', 'cotton', 'casual'],
  ),
  Product(
    id: 'p062',
    name: 'Straight Cut Suit Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 3999,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop'
    ],
    description:
        'Premium quality Straight Cut Suit Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    tags: ['straight cut', 'daily wear'],
  ),
  Product(
    id: 'p063',
    name: 'Kashmiri Embroidery Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 8999,
    originalPrice: 12500,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70'
    ],
    description:
        'Premium quality Kashmiri Embroidery Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 112,
    isFeatured: true,
    tags: ['kashmiri', 'embroidered'],
  ),
  Product(
    id: 'p064',
    name: 'Silk Suit with Dupatta',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 5499,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70'
    ],
    description:
        'Premium quality Silk Suit with Dupatta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 167,
    isNew: true,
    tags: ['silk', 'festive'],
  ),
  Product(
    id: 'p065',
    name: 'Printed Rayon Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 1999,
    originalPrice: 2800,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600'
    ],
    description:
        'Premium quality Printed Rayon Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 289,
    tags: ['rayon', 'printed', 'casual'],
  ),
  Product(
    id: 'p066',
    name: 'Designer Party Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 11999,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'
    ],
    description:
        'Premium quality Designer Party Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 89,
    isFeatured: true,
    tags: ['designer', 'party'],
  ),
  Product(
    id: 'p067',
    name: 'Lucknowi Chikankari Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 7499,
    originalPrice: 10200,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop'
    ],
    description:
        'Premium quality Lucknowi Chikankari Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 145,
    isFeatured: true,
    isNew: true,
    tags: ['chikankari', 'lucknowi'],
  ),
  Product(
    id: 'p068',
    name: 'Linen Kurta Trouser Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 3499,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800'
    ],
    description:
        'Premium quality Linen Kurta Trouser Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 212,
    tags: ['linen', 'trouser'],
  ),
  Product(
    id: 'p069',
    name: 'Phulkari Suit Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 5999,
    originalPrice: 8200,
    imageUrl:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&h=800&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80'
    ],
    description:
        'Premium quality Phulkari Suit Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    isNew: true,
    tags: ['phulkari', 'punjabi'],
  ),
  Product(
    id: 'p070',
    name: 'Bandhani Suit Piece',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 4499,
    imageUrl:
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&h=800',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80'
    ],
    description:
        'Premium quality Bandhani Suit Piece from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 178,
    tags: ['bandhani', 'festive'],
  ),
  Product(
    id: 'p071',
    name: 'Heavy Bridal Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 17999,
    originalPrice: 25000,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop'
    ],
    description:
        'Premium quality Heavy Bridal Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 67,
    isFeatured: true,
    tags: ['bridal', 'silk', 'luxury'],
  ),
  Product(
    id: 'p072',
    name: 'Casual Kurti Palazzo',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 2199,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop'
    ],
    description:
        'Premium quality Casual Kurti Palazzo from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 312,
    isNew: true,
    tags: ['casual', 'palazzo'],
  ),
  Product(
    id: 'p073',
    name: 'Office Wear Suit Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 4999,
    originalPrice: 6800,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70'
    ],
    description:
        'Premium quality Office Wear Suit Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['office', 'formal'],
  ),
  Product(
    id: 'p074',
    name: 'Velvet Embroidered Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 9499,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70'
    ],
    description:
        'Premium quality Velvet Embroidered Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 123,
    isFeatured: true,
    tags: ['velvet', 'embroidered'],
  ),
  Product(
    id: 'p075',
    name: 'Chanderi Suit Set',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 6499,
    originalPrice: 8800,
    imageUrl:
        'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70',
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600'
    ],
    description:
        'Premium quality Chanderi Suit Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    isNew: true,
    tags: ['chanderi', 'silk'],
  ),
  Product(
    id: 'p076',
    name: 'Net Embroidered Suit',
    brand: 'Siva Silks',
    category: 'Suits',
    price: 7999,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'
    ],
    description:
        'Premium quality Net Embroidered Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 134,
    isFeatured: true,
    tags: ['net', 'party'],
  ),
  Product(
    id: 'p077',
    name: 'Rayon A-Line Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 999,
    originalPrice: 1500,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80'
    ],
    description:
        'Premium quality Rayon A-Line Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 456,
    isNew: true,
    tags: ['rayon', 'casual', 'office'],
  ),
  Product(
    id: 'p078',
    name: 'Embroidered Silk Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2999,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80'
    ],
    description:
        'Premium quality Embroidered Silk Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 234,
    tags: ['silk', 'embroidered', 'festive'],
  ),
  Product(
    id: 'p079',
    name: 'Cotton Printed Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 849,
    originalPrice: 1200,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop'
    ],
    description:
        'Premium quality Cotton Printed Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 567,
    isNew: true,
    tags: ['cotton', 'printed', 'casual'],
  ),
  Product(
    id: 'p080',
    name: 'Anarkali Long Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2499,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop'
    ],
    description:
        'Premium quality Anarkali Long Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['anarkali', 'festive'],
  ),
  Product(
    id: 'p081',
    name: 'Tie-Dye Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop'
    ],
    description:
        'Premium quality Tie-Dye Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 312,
    isNew: true,
    tags: ['tie-dye', 'colorful'],
  ),
  Product(
    id: 'p082',
    name: 'Chanderi Kurti Set',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 3499,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70'
    ],
    description:
        'Premium quality Chanderi Kurti Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 178,
    tags: ['chanderi', 'silk'],
  ),
  Product(
    id: 'p083',
    name: 'Denim Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1499,
    originalPrice: 2100,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600'
    ],
    description:
        'Premium quality Denim Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 234,
    isNew: true,
    tags: ['denim', 'western', 'fusion'],
  ),
  Product(
    id: 'p084',
    name: 'Mirror Work Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1999,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750'
    ],
    description:
        'Premium quality Mirror Work Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 289,
    tags: ['mirror', 'festive', 'embroidered'],
  ),
  Product(
    id: 'p085',
    name: 'Khadi Kurta',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1799,
    originalPrice: 2500,
    imageUrl: 'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600'
    ],
    description:
        'Premium quality Khadi Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 212,
    isNew: true,
    tags: ['khadi', 'organic', 'casual'],
  ),
  Product(
    id: 'p086',
    name: 'Designer Tunic Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 3999,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80'
    ],
    description:
        'Premium quality Designer Tunic Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 145,
    isFeatured: true,
    tags: ['designer', 'tunic', 'party'],
  ),
  Product(
    id: 'p087',
    name: 'Straight Kurta With Pant',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2799,
    originalPrice: 3900,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80'
    ],
    description:
        'Premium quality Straight Kurta With Pant from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    tags: ['straight', 'pant', 'office'],
  ),
  Product(
    id: 'p088',
    name: 'Batik Print Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1399,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80'
    ],
    description:
        'Premium quality Batik Print Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 267,
    isNew: true,
    tags: ['batik', 'printed'],
  ),
  Product(
    id: 'p089',
    name: 'Floral Georgette Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1899,
    originalPrice: 2600,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop'
    ],
    description:
        'Premium quality Floral Georgette Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    tags: ['georgette', 'floral', 'party'],
  ),
  Product(
    id: 'p090',
    name: 'Ikat Woven Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2299,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop',
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop'
    ],
    description:
        'Premium quality Ikat Woven Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 178,
    isNew: true,
    tags: ['ikat', 'handloom'],
  ),
  Product(
    id: 'p091',
    name: 'Embellished Party Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 4499,
    originalPrice: 6200,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop'
    ],
    description:
        'Premium quality Embellished Party Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 156,
    isFeatured: true,
    tags: ['embellished', 'party'],
  ),
  Product(
    id: 'p092',
    name: 'Peplum Fusion Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2099,
    imageUrl:
        'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70'
    ],
    description:
        'Premium quality Peplum Fusion Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 212,
    tags: ['peplum', 'fusion', 'western'],
  ),
  Product(
    id: 'p093',
    name: 'Short A-Line Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 1199,
    originalPrice: 1700,
    imageUrl:
        'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70',
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600'
    ],
    description:
        'Premium quality Short A-Line Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 345,
    isNew: true,
    tags: ['short', 'casual'],
  ),
  Product(
    id: 'p094',
    name: 'Layered Frill Kurti',
    brand: 'Siva Silks',
    category: 'Kurtis',
    price: 2699,
    imageUrl:
        'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1559163499-413811fb2344?w=600',
      'https://images.unsplash.com/photo-1614676471928-2ed0ad1061a4?w=600&h=750'
    ],
    description:
        'Premium quality Layered Frill Kurti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['frill', 'layered', 'trendy'],
  ),
  Product(
    id: 'p095',
    name: 'Cotton Kurta Pyjama',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 1999,
    originalPrice: 2800,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80'
    ],
    description:
        'Premium quality Cotton Kurta Pyjama from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    isNew: true,
    tags: ['kurta', 'cotton', 'casual'],
  ),
  Product(
    id: 'p096',
    name: 'Sherwani Set',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 14999,
    originalPrice: 21000,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80'
    ],
    description:
        'Premium quality Sherwani Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 67,
    isFeatured: true,
    tags: ['sherwani', 'wedding', 'luxury'],
  ),
  Product(
    id: 'p097',
    name: 'Linen Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 2499,
    originalPrice: 3400,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop'
    ],
    description:
        'Premium quality Linen Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 198,
    tags: ['linen', 'casual', 'office'],
  ),
  Product(
    id: 'p098',
    name: 'Pathani Suit',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 3499,
    originalPrice: 4800,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop'
    ],
    description:
        'Premium quality Pathani Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    isNew: true,
    tags: ['pathani', 'traditional'],
  ),
  Product(
    id: 'p099',
    name: 'Embroidered Bandhgala',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 8999,
    originalPrice: 12500,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop'
    ],
    description:
        'Premium quality Embroidered Bandhgala from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 89,
    isFeatured: true,
    tags: ['bandhgala', 'festive'],
  ),
  Product(
    id: 'p100',
    name: 'Dhoti Pant Set',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 2999,
    originalPrice: 4200,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70'
    ],
    description:
        'Premium quality Dhoti Pant Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 178,
    tags: ['dhoti', 'pant', 'fusion'],
  ),
  Product(
    id: 'p101',
    name: 'Raw Silk Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 3999,
    originalPrice: 5500,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600'
    ],
    description:
        'Premium quality Raw Silk Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    isNew: true,
    tags: ['raw silk', 'festive'],
  ),
  Product(
    id: 'p102',
    name: 'Jodhpuri Suit',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 12999,
    originalPrice: 18000,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600'
    ],
    description:
        'Premium quality Jodhpuri Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 78,
    isFeatured: true,
    tags: ['jodhpuri', 'wedding'],
  ),
  Product(
    id: 'p103',
    name: 'Indo Western Blazer Set',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 9499,
    originalPrice: 13200,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600'
    ],
    description:
        'Premium quality Indo Western Blazer Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 112,
    isFeatured: true,
    tags: ['blazer', 'indo-western'],
  ),
  Product(
    id: 'p104',
    name: 'Cotton Shorts Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 1799,
    originalPrice: 2500,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80'
    ],
    description:
        'Premium quality Cotton Shorts Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 234,
    isNew: true,
    tags: ['cotton', 'casual', 'shorts'],
  ),
  Product(
    id: 'p105',
    name: 'Velvet Festive Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 5499,
    originalPrice: 7500,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80'
    ],
    description:
        'Premium quality Velvet Festive Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 134,
    tags: ['velvet', 'festive'],
  ),
  Product(
    id: 'p106',
    name: 'Angrakha Style Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 4999,
    originalPrice: 6800,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80'
    ],
    description:
        'Premium quality Angrakha Style Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 167,
    isNew: true,
    tags: ['angrakha', 'traditional'],
  ),
  Product(
    id: 'p107',
    name: 'Printed Silk Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 3299,
    originalPrice: 4500,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop'
    ],
    description:
        'Premium quality Printed Silk Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 189,
    tags: ['printed', 'silk'],
  ),
  Product(
    id: 'p108',
    name: 'Long Achkan Set',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 11499,
    originalPrice: 16000,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop'
    ],
    description:
        'Premium quality Long Achkan Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 89,
    isFeatured: true,
    tags: ['achkan', 'festive', 'wedding'],
  ),
  Product(
    id: 'p109',
    name: 'Casual Linen Jacket',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 4499,
    originalPrice: 6200,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop'
    ],
    description:
        'Premium quality Casual Linen Jacket from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 145,
    isNew: true,
    tags: ['linen', 'jacket', 'casual'],
  ),
  Product(
    id: 'p110',
    name: 'Festive Kurta Churidar',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 5999,
    originalPrice: 8200,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70'
    ],
    description:
        'Premium quality Festive Kurta Churidar from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 123,
    tags: ['churidar', 'festive'],
  ),
  Product(
    id: 'p111',
    name: 'Mandarin Collar Kurta',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 3799,
    originalPrice: 5200,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600'
    ],
    description:
        'Premium quality Mandarin Collar Kurta from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 156,
    isNew: true,
    tags: ['mandarin', 'modern'],
  ),
  Product(
    id: 'p112',
    name: 'Designer Wedding Sherwani',
    brand: 'Siva Silks',
    category: "Men's Ethnic",
    price: 24999,
    originalPrice: 35000,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600'
    ],
    description:
        'Premium quality Designer Wedding Sherwani from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 45,
    isFeatured: true,
    tags: ['sherwani', 'wedding', 'luxury'],
  ),
  Product(
    id: 'p113',
    name: 'Cotton T-Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 599,
    originalPrice: 899,
    imageUrl: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600'
    ],
    description:
        'Premium quality Cotton T-Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 567,
    isNew: true,
    tags: ['tshirt', 'casual', 'cotton'],
  ),
  Product(
    id: 'p114',
    name: 'Slim Fit Jeans',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1999,
    originalPrice: 2800,
    imageUrl: 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80'
    ],
    description:
        'Premium quality Slim Fit Jeans from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 345,
    tags: ['jeans', 'casual', 'denim'],
  ),
  Product(
    id: 'p115',
    name: 'Linen Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1499,
    originalPrice: 2100,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80'
    ],
    description:
        'Premium quality Linen Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 289,
    isNew: true,
    tags: ['linen', 'shirt', 'casual'],
  ),
  Product(
    id: 'p116',
    name: 'Polo T-Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 899,
    originalPrice: 1299,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80'
    ],
    description:
        'Premium quality Polo T-Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 456,
    tags: ['polo', 'casual'],
  ),
  Product(
    id: 'p117',
    name: 'Cargo Pants',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1799,
    originalPrice: 2500,
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop'
    ],
    description:
        'Premium quality Cargo Pants from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    isNew: true,
    tags: ['cargo', 'casual', 'outdoor'],
  ),
  Product(
    id: 'p118',
    name: 'Formal Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop'
    ],
    description:
        'Premium quality Formal Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 312,
    tags: ['formal', 'shirt', 'office'],
  ),
  Product(
    id: 'p119',
    name: 'Chino Trousers',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1699,
    originalPrice: 2400,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop'
    ],
    description:
        'Premium quality Chino Trousers from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 267,
    isNew: true,
    tags: ['chino', 'formal', 'casual'],
  ),
  Product(
    id: 'p120',
    name: 'Denim Jacket',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 2999,
    originalPrice: 4200,
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70'
    ],
    description:
        'Premium quality Denim Jacket from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 178,
    tags: ['denim', 'jacket', 'casual'],
  ),
  Product(
    id: 'p121',
    name: 'Sweatshirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1499,
    originalPrice: 2100,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600'
    ],
    description:
        'Premium quality Sweatshirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 345,
    isNew: true,
    tags: ['sweatshirt', 'winter', 'casual'],
  ),
  Product(
    id: 'p122',
    name: 'Track Suit',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 2499,
    originalPrice: 3500,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600'
    ],
    description:
        'Premium quality Track Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    tags: ['track', 'sports', 'casual'],
  ),
  Product(
    id: 'p123',
    name: 'Printed Casual Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1199,
    originalPrice: 1700,
    imageUrl: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600'
    ],
    description:
        'Premium quality Printed Casual Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 389,
    isNew: true,
    tags: ['printed', 'shirt', 'casual'],
  ),
  Product(
    id: 'p124',
    name: 'Shorts Set',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1299,
    originalPrice: 1800,
    imageUrl: 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80'
    ],
    description:
        'Premium quality Shorts Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 312,
    tags: ['shorts', 'summer', 'casual'],
  ),
  Product(
    id: 'p125',
    name: 'V-Neck Sweater',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1899,
    originalPrice: 2700,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80'
    ],
    description:
        'Premium quality V-Neck Sweater from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 189,
    isNew: true,
    tags: ['sweater', 'winter', 'casual'],
  ),
  Product(
    id: 'p126',
    name: 'Hoodie',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1999,
    originalPrice: 2800,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80'
    ],
    description:
        'Premium quality Hoodie from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['hoodie', 'winter', 'casual'],
  ),
  Product(
    id: 'p127',
    name: 'Oxford Formal Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1699,
    originalPrice: 2400,
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop'
    ],
    description:
        'Premium quality Oxford Formal Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 267,
    isNew: true,
    tags: ['oxford', 'formal'],
  ),
  Product(
    id: 'p128',
    name: 'Bermuda Shorts',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 999,
    originalPrice: 1400,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop'
    ],
    description:
        'Premium quality Bermuda Shorts from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 345,
    tags: ['bermuda', 'casual', 'summer'],
  ),
  Product(
    id: 'p129',
    name: 'Athletic Joggers',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1599,
    originalPrice: 2200,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop',
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop'
    ],
    description:
        'Premium quality Athletic Joggers from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 289,
    isNew: true,
    tags: ['joggers', 'sports', 'casual'],
  ),
  Product(
    id: 'p130',
    name: 'Striped Casual Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1399,
    originalPrice: 1950,
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70'
    ],
    description:
        'Premium quality Striped Casual Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 234,
    tags: ['striped', 'shirt', 'casual'],
  ),
  Product(
    id: 'p131',
    name: 'Ethnic Print Shirt',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 1799,
    originalPrice: 2500,
    imageUrl:
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70',
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600'
    ],
    description:
        'Premium quality Ethnic Print Shirt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 198,
    isNew: true,
    tags: ['ethnic', 'printed'],
  ),
  Product(
    id: 'p132',
    name: 'Relaxed Fit Jeans',
    brand: 'Siva Silks',
    category: "Men's Casual",
    price: 2299,
    originalPrice: 3200,
    imageUrl:
        'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600',
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600'
    ],
    description:
        'Premium quality Relaxed Fit Jeans from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 178,
    tags: ['jeans', 'relaxed', 'casual'],
  ),
  Product(
    id: 'p133',
    name: 'Ladies Ethnic Jutti',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 1299,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80'
    ],
    description:
        'Premium quality Ladies Ethnic Jutti from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    isNew: true,
    tags: ['jutti', 'ethnic', 'ladies'],
  ),
  Product(
    id: 'p134',
    name: 'Bridal Heels',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3499,
    originalPrice: 4800,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop'
    ],
    description:
        'Premium quality Bridal Heels from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    tags: ['heels', 'bridal', 'ladies'],
  ),
  Product(
    id: 'p135',
    name: 'Casual Sneakers',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 2499,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop'
    ],
    description:
        'Premium quality Casual Sneakers from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 345,
    isNew: true,
    tags: ['sneakers', 'casual', 'unisex'],
  ),
  Product(
    id: 'p136',
    name: 'Mojari Ethnic Shoes',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 1899,
    originalPrice: 2600,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop'
    ],
    description:
        'Premium quality Mojari Ethnic Shoes from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['mojari', 'ethnic', 'mens'],
  ),
  Product(
    id: 'p137',
    name: 'Wedding Wedges',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 2999,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70'
    ],
    description:
        'Premium quality Wedding Wedges from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 178,
    isNew: true,
    tags: ['wedges', 'wedding', 'ladies'],
  ),
  Product(
    id: 'p138',
    name: 'Leather Loafers',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3999,
    originalPrice: 5500,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'
    ],
    description:
        'Premium quality Leather Loafers from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 134,
    tags: ['loafers', 'leather', 'formal'],
  ),
  Product(
    id: 'p139',
    name: 'Flat Ethnic Sandals',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 999,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600'
    ],
    description:
        'Premium quality Flat Ethnic Sandals from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 412,
    isNew: true,
    tags: ['sandals', 'ethnic', 'ladies'],
  ),
  Product(
    id: 'p140',
    name: 'Kids Ethnic Footwear',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 799,
    originalPrice: 1100,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600'
    ],
    description:
        'Premium quality Kids Ethnic Footwear from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['kids', 'ethnic', 'footwear'],
  ),
  Product(
    id: 'p141',
    name: 'Mens Dress Shoes',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 4499,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80'
    ],
    description:
        'Premium quality Mens Dress Shoes from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    isNew: true,
    tags: ['dress', 'formal', 'mens'],
  ),
  Product(
    id: 'p142',
    name: 'Embroidered Flats',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 1499,
    originalPrice: 2100,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80'
    ],
    description:
        'Premium quality Embroidered Flats from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 267,
    tags: ['flats', 'embroidered', 'ladies'],
  ),
  Product(
    id: 'p143',
    name: 'Traditional Nagra',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 2199,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80'
    ],
    description:
        'Premium quality Traditional Nagra from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    isNew: true,
    tags: ['nagra', 'traditional', 'mens'],
  ),
  Product(
    id: 'p144',
    name: 'Platform Heels',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3299,
    originalPrice: 4600,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop'
    ],
    description:
        'Premium quality Platform Heels from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 167,
    tags: ['platform', 'heels', 'ladies'],
  ),
  Product(
    id: 'p145',
    name: 'Beach Flip Flops',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 599,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop'
    ],
    description:
        'Premium quality Beach Flip Flops from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 567,
    isNew: true,
    tags: ['flipflops', 'casual', 'unisex'],
  ),
  Product(
    id: 'p146',
    name: 'Running Shoes Womens',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3199,
    originalPrice: 4500,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop'
    ],
    description:
        'Premium quality Running Shoes Womens from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 189,
    tags: ['running', 'sports', 'ladies'],
  ),
  Product(
    id: 'p147',
    name: 'Ankle Boots',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 4999,
    imageUrl:
        'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70'
    ],
    description:
        'Premium quality Ankle Boots from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 123,
    isNew: true,
    tags: ['boots', 'winter', 'ladies'],
  ),
  Product(
    id: 'p148',
    name: 'Mens Chappals',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 799,
    originalPrice: 1100,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'
    ],
    description:
        'Premium quality Mens Chappals from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 345,
    tags: ['chappals', 'casual', 'mens'],
  ),
  Product(
    id: 'p149',
    name: 'Block Heel Pumps',
    brand: 'Siva Silks',
    category: 'Footwear',
    price: 3699,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
      'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600'
    ],
    description:
        'Premium quality Block Heel Pumps from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    isNew: true,
    tags: ['pumps', 'formal', 'ladies'],
  ),
  Product(
    id: 'p150',
    name: 'Gold Plated Bangle Set',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80'
    ],
    description:
        'Premium quality Gold Plated Bangle Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 312,
    isNew: true,
    tags: ['bangles', 'gold', 'ladies'],
  ),
  Product(
    id: 'p151',
    name: 'Pearl Necklace',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 2999,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80'
    ],
    description:
        'Premium quality Pearl Necklace from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 189,
    tags: ['pearl', 'necklace', 'elegant'],
  ),
  Product(
    id: 'p152',
    name: 'Maang Tikka',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 899,
    originalPrice: 1299,
    imageUrl:
        'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop'
    ],
    description:
        'Premium quality Maang Tikka from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 267,
    isNew: true,
    tags: ['maang tikka', 'bridal'],
  ),
  Product(
    id: 'p153',
    name: 'Chandbali Earrings',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 1499,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop'
    ],
    description:
        'Premium quality Chandbali Earrings from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 234,
    tags: ['chandbali', 'earrings', 'festive'],
  ),
  Product(
    id: 'p154',
    name: 'Antique Choker Set',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 3499,
    originalPrice: 4900,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop'
    ],
    description:
        'Premium quality Antique Choker Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 145,
    isFeatured: true,
    tags: ['choker', 'antique', 'bridal'],
  ),
  Product(
    id: 'p155',
    name: 'Bangles Set of 12',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 699,
    imageUrl:
        'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70'
    ],
    description:
        'Premium quality Bangles Set of 12 from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 456,
    isNew: true,
    tags: ['bangles', 'festive'],
  ),
  Product(
    id: 'p156',
    name: 'Temple Jewellery Set',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 5999,
    originalPrice: 8500,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600'
    ],
    description:
        'Premium quality Temple Jewellery Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 112,
    isFeatured: true,
    tags: ['temple', 'traditional', 'bridal'],
  ),
  Product(
    id: 'p157',
    name: 'Silver Anklet Pair',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 799,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600'
    ],
    description:
        'Premium quality Silver Anklet Pair from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 345,
    isNew: true,
    tags: ['anklet', 'silver', 'casual'],
  ),
  Product(
    id: 'p158',
    name: 'Layered Necklace',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 1999,
    originalPrice: 2800,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600'
    ],
    description:
        'Premium quality Layered Necklace from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 198,
    tags: ['layered', 'necklace', 'modern'],
  ),
  Product(
    id: 'p159',
    name: 'Nose Ring Nath',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 599,
    imageUrl:
        'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80'
    ],
    description:
        'Premium quality Nose Ring Nath from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 312,
    isNew: true,
    tags: ['nath', 'traditional'],
  ),
  Product(
    id: 'p160',
    name: 'Polki Earrings',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 2499,
    originalPrice: 3500,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80'
    ],
    description:
        'Premium quality Polki Earrings from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 167,
    tags: ['polki', 'earrings', 'bridal'],
  ),
  Product(
    id: 'p161',
    name: 'Gold Plated Bead Necklace',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 1799,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80'
    ],
    description:
        'Premium quality Gold Plated Bead Necklace from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    isNew: true,
    tags: ['bead', 'necklace', 'casual'],
  ),
  Product(
    id: 'p162',
    name: 'Oxidised Cuff Bracelet',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 999,
    originalPrice: 1400,
    imageUrl:
        'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop'
    ],
    description:
        'Premium quality Oxidised Cuff Bracelet from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 289,
    tags: ['cuff', 'bracelet', 'casual'],
  ),
  Product(
    id: 'p163',
    name: 'Bridal Jewellery Set',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 8999,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&q=80',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop'
    ],
    description:
        'Premium quality Bridal Jewellery Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.9,
    reviewCount: 78,
    isFeatured: true,
    tags: ['bridal', 'full set', 'luxury'],
  ),
  Product(
    id: 'p164',
    name: 'Ghungroo Jhumki',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 749,
    originalPrice: 1050,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop'
    ],
    description:
        'Premium quality Ghungroo Jhumki from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 312,
    isNew: true,
    tags: ['ghungroo', 'jhumki', 'festive'],
  ),
  Product(
    id: 'p165',
    name: 'Diamond Cut Ring',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 3299,
    imageUrl:
        'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70'
    ],
    description:
        'Premium quality Diamond Cut Ring from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 145,
    tags: ['ring', 'diamond cut'],
  ),
  Product(
    id: 'p166',
    name: 'Arm Cuff Vanki',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&fit=crop',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70',
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600'
    ],
    description:
        'Premium quality Arm Cuff Vanki from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 189,
    isNew: true,
    tags: ['vanki', 'armcuff', 'bridal'],
  ),
  Product(
    id: 'p167',
    name: 'Statement Necklace',
    brand: 'Siva Silks',
    category: 'Jewellery',
    price: 2799,
    imageUrl:
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=70',
    additionalImages: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600',
      'https://images.unsplash.com/photo-1573408301185-9519f94815b7?w=600'
    ],
    description:
        'Premium quality Statement Necklace from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 167,
    isFeatured: true,
    tags: ['statement', 'necklace', 'party'],
  ),
  Product(
    id: 'p168',
    name: 'Potli Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1199,
    originalPrice: 1700,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Potli Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    isNew: true,
    tags: ['potli', 'bag', 'ethnic'],
  ),
  Product(
    id: 'p169',
    name: 'Silk Stole',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1499,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Silk Stole from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 198,
    tags: ['stole', 'silk', 'casual'],
  ),
  Product(
    id: 'p170',
    name: 'Embroidered Wallet',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 899,
    originalPrice: 1299,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Embroidered Wallet from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 289,
    isNew: true,
    tags: ['wallet', 'embroidered'],
  ),
  Product(
    id: 'p171',
    name: 'Hair Accessories Set',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 699,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Hair Accessories Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 345,
    tags: ['hair', 'accessory'],
  ),
  Product(
    id: 'p172',
    name: 'Zardozi Evening Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 3499,
    originalPrice: 4900,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Zardozi Evening Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 145,
    isNew: true,
    tags: ['evening bag', 'zardozi', 'party'],
  ),
  Product(
    id: 'p173',
    name: 'Cotton Tote Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 799,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Cotton Tote Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.2,
    reviewCount: 412,
    tags: ['tote', 'cotton', 'casual'],
  ),
  Product(
    id: 'p174',
    name: 'Silk Belt',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 999,
    originalPrice: 1400,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Silk Belt from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    isNew: true,
    tags: ['belt', 'silk', 'ethnic'],
  ),
  Product(
    id: 'p175',
    name: 'Pashmina Shawl',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 4999,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Pashmina Shawl from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 112,
    isFeatured: true,
    tags: ['pashmina', 'shawl', 'winter'],
  ),
  Product(
    id: 'p176',
    name: 'Embroidered Headband',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 549,
    originalPrice: 790,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Embroidered Headband from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 345,
    isNew: true,
    tags: ['headband', 'embroidered'],
  ),
  Product(
    id: 'p177',
    name: 'Bridal Hand Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 2999,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Bridal Hand Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 167,
    tags: ['handbag', 'bridal'],
  ),
  Product(
    id: 'p178',
    name: 'Rajasthani Sling Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1699,
    originalPrice: 2400,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Rajasthani Sling Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    isNew: true,
    tags: ['sling', 'rajasthani'],
  ),
  Product(
    id: 'p179',
    name: 'Silk Saree Bag',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1299,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Silk Saree Bag from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    tags: ['saree bag', 'silk'],
  ),
  Product(
    id: 'p180',
    name: 'Beaded Clutch',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 2199,
    originalPrice: 3100,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Beaded Clutch from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    isNew: true,
    tags: ['beaded', 'clutch', 'party'],
  ),
  Product(
    id: 'p181',
    name: 'Velvet Jewellery Box',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1799,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Velvet Jewellery Box from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['jewellery box', 'velvet'],
  ),
  Product(
    id: 'p182',
    name: 'Fancy Tassel Earring Holder',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 699,
    originalPrice: 999,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Fancy Tassel Earring Holder from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 267,
    isNew: true,
    tags: ['earring holder', 'storage'],
  ),
  Product(
    id: 'p183',
    name: 'Traditional Payal Set',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 899,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Traditional Payal Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 312,
    tags: ['payal', 'anklet', 'traditional'],
  ),
  Product(
    id: 'p184',
    name: 'Mirror Embroidered Pouch',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1099,
    originalPrice: 1550,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
    ],
    description:
        'Premium quality Mirror Embroidered Pouch from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 234,
    isNew: true,
    tags: ['pouch', 'mirror work'],
  ),
  Product(
    id: 'p185',
    name: 'Batua Ethnic Purse',
    brand: 'Siva Silks',
    category: 'Accessories',
    price: 1399,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600'
    ],
    description:
        'Premium quality Batua Ethnic Purse from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    tags: ['batua', 'purse', 'ethnic'],
  ),
  Product(
    id: 'p186',
    name: "Girl's Silk Frock",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1299,
    originalPrice: 1800,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Girl\'s Silk Frock from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 178,
    isNew: true,
    tags: ['frock', 'silk', 'girls'],
  ),
  Product(
    id: 'p187',
    name: "Boy's Cotton Kurta Set",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 999,
    originalPrice: 1400,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Boy\'s Cotton Kurta Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['kurta', 'boys', 'cotton'],
  ),
  Product(
    id: 'p188',
    name: 'Baby Jhabla Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 799,
    originalPrice: 1100,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Baby Jhabla Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 312,
    isNew: true,
    tags: ['baby', 'jhabla', 'newborn'],
  ),
  Product(
    id: 'p189',
    name: "Girl's Anarkali Dress",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1799,
    originalPrice: 2500,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Girl\'s Anarkali Dress from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 145,
    tags: ['anarkali', 'girls', 'festive'],
  ),
  Product(
    id: 'p190',
    name: "Boy's Sherwani Set",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 2499,
    originalPrice: 3500,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Boy\'s Sherwani Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 112,
    isNew: true,
    tags: ['sherwani', 'boys', 'wedding'],
  ),
  Product(
    id: 'p191',
    name: 'Baby Jaipuri Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 899,
    originalPrice: 1250,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Baby Jaipuri Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 267,
    tags: ['jaipuri', 'baby', 'printed'],
  ),
  Product(
    id: 'p192',
    name: "Girl's Lehenga Choli",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 2199,
    originalPrice: 3100,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Girl\'s Lehenga Choli from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 134,
    isNew: true,
    tags: ['lehenga', 'girls', 'festive'],
  ),
  Product(
    id: 'p193',
    name: "Boy's Ethnic Kurta Pyjama",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1299,
    originalPrice: 1800,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Boy\'s Ethnic Kurta Pyjama from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 189,
    tags: ['kurta pyjama', 'boys'],
  ),
  Product(
    id: 'p194',
    name: 'Kids Party Wear Frock',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1499,
    originalPrice: 2100,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Kids Party Wear Frock from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 156,
    isNew: true,
    tags: ['party', 'frock', 'girls'],
  ),
  Product(
    id: 'p195',
    name: 'Toddler Dhoti Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 699,
    originalPrice: 999,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Toddler Dhoti Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['toddler', 'dhoti', 'boys'],
  ),
  Product(
    id: 'p196',
    name: 'Kids Cotton Salwar Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1099,
    originalPrice: 1550,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Kids Cotton Salwar Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 198,
    isNew: true,
    tags: ['salwar', 'kids', 'cotton'],
  ),
  Product(
    id: 'p197',
    name: "Girl's Half Saree Set",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 2999,
    originalPrice: 4200,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Girl\'s Half Saree Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.8,
    reviewCount: 89,
    tags: ['half saree', 'girls', 'teen'],
  ),
  Product(
    id: 'p198',
    name: "Boy's Pathani Suit",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1799,
    originalPrice: 2500,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Boy\'s Pathani Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 134,
    isNew: true,
    tags: ['pathani', 'boys', 'ethnic'],
  ),
  Product(
    id: 'p199',
    name: 'Kids Navratri Chaniya',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1599,
    originalPrice: 2200,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Kids Navratri Chaniya from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 167,
    tags: ['navratri', 'chaniya', 'girls'],
  ),
  Product(
    id: 'p200',
    name: 'Baby Kimono Onesie',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 699,
    originalPrice: 990,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Baby Kimono Onesie from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 289,
    isNew: true,
    tags: ['baby', 'kimono', 'comfortable'],
  ),
  Product(
    id: 'p201',
    name: 'School Uniform Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1199,
    originalPrice: 1700,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality School Uniform Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.3,
    reviewCount: 345,
    tags: ['school', 'uniform'],
  ),
  Product(
    id: 'p202',
    name: 'Kids Ethnic Jacket Set',
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 1899,
    originalPrice: 2650,
    imageUrl: 'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600'
    ],
    description:
        'Premium quality Kids Ethnic Jacket Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    isNew: true,
    tags: ['jacket', 'ethnic', 'festive'],
  ),
  Product(
    id: 'p203',
    name: "Teen Boy's Formal Suit",
    brand: 'Siva Silks',
    category: "Kids' Wear",
    price: 3499,
    originalPrice: 4900,
    imageUrl: 'https://images.unsplash.com/photo-1519278409-1f56fdda7fe5?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1543269664-76bc3997d9ea?w=600'
    ],
    description:
        'Premium quality Teen Boy\'s Formal Suit from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 89,
    tags: ['formal', 'teen', 'boys'],
  ),
  Product(
    id: 'p204',
    name: 'Kalamkari Wall Hanging',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1999,
    originalPrice: 2800,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Kalamkari Wall Hanging from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 134,
    isNew: true,
    tags: ['kalamkari', 'wall art', 'decor'],
  ),
  Product(
    id: 'p205',
    name: 'Embroidered Cushion Set',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1499,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Embroidered Cushion Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 198,
    tags: ['cushion', 'embroidered', 'home'],
  ),
  Product(
    id: 'p206',
    name: 'Silk Curtain Pair',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 3999,
    originalPrice: 5500,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Silk Curtain Pair from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 112,
    isNew: true,
    tags: ['curtain', 'silk', 'home'],
  ),
  Product(
    id: 'p207',
    name: 'Madhubani Painting Print',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 2499,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Madhubani Painting Print from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 89,
    tags: ['madhubani', 'art', 'decor'],
  ),
  Product(
    id: 'p208',
    name: 'Handloom Cotton Towel Set',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 799,
    originalPrice: 1100,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Handloom Cotton Towel Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 345,
    isNew: true,
    tags: ['towel', 'cotton', 'handloom'],
  ),
  Product(
    id: 'p209',
    name: 'Block Print Pillow Cover Set',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1299,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Block Print Pillow Cover Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['pillow', 'block print'],
  ),
  Product(
    id: 'p210',
    name: 'Brass Dhiya Set',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1199,
    originalPrice: 1700,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Brass Dhiya Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 178,
    isNew: true,
    tags: ['dhiya', 'brass', 'puja'],
  ),
  Product(
    id: 'p211',
    name: 'Zari Sofa Runner',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 2199,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Zari Sofa Runner from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 145,
    tags: ['sofa runner', 'zari'],
  ),
  Product(
    id: 'p212',
    name: 'Hand Painted Pot',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 899,
    originalPrice: 1250,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Hand Painted Pot from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 267,
    isNew: true,
    tags: ['pot', 'hand painted', 'decor'],
  ),
  Product(
    id: 'p213',
    name: 'Wooden Handicraft Box',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1799,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Wooden Handicraft Box from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 156,
    tags: ['wooden', 'handicraft', 'box'],
  ),
  Product(
    id: 'p214',
    name: 'Phulkari Cushion Cover',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1099,
    originalPrice: 1550,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Phulkari Cushion Cover from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.4,
    reviewCount: 189,
    isNew: true,
    tags: ['phulkari', 'cushion', 'home'],
  ),
  Product(
    id: 'p215',
    name: 'Door Hanging Toran',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 799,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Door Hanging Toran from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 312,
    tags: ['toran', 'decor', 'traditional'],
  ),
  Product(
    id: 'p216',
    name: 'Embroidered Tablecloth',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 2299,
    originalPrice: 3200,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Embroidered Tablecloth from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 145,
    isNew: true,
    tags: ['tablecloth', 'embroidered'],
  ),
  Product(
    id: 'p217',
    name: 'Handmade Diwan Set',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 5999,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Handmade Diwan Set from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.7,
    reviewCount: 78,
    tags: ['diwan', 'handmade', 'furniture'],
  ),
  Product(
    id: 'p218',
    name: 'Terracotta Candle Stand',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1299,
    originalPrice: 1800,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Terracotta Candle Stand from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 167,
    isNew: true,
    tags: ['candle', 'terracotta', 'decor'],
  ),
  Product(
    id: 'p219',
    name: 'Jaipuri Print Bedsheet',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 1599,
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Jaipuri Print Bedsheet from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.5,
    reviewCount: 234,
    tags: ['bedsheet', 'jaipuri', 'cotton'],
  ),
  Product(
    id: 'p220',
    name: 'Ethnic Lamp Shade',
    brand: 'Siva Silks',
    category: 'Home Decor',
    price: 2499,
    originalPrice: 3500,
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    additionalImages: [
      'https://images.unsplash.com/photo-1555041469-a786023492125-27b2c045efd7?w=600'
    ],
    description:
        'Premium quality Ethnic Lamp Shade from Siva Silks. Expertly crafted with finest materials.',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Standard'],
    rating: 4.6,
    reviewCount: 123,
    isNew: true,
    tags: ['lamp shade', 'ethnic', 'home'],
  ),

//Total new products: 195
];

const List<Review> sampleReviews = [
  Review(
    id: 'r1',
    userName: 'Priya M.',
    userAvatar: 'P',
    rating: 5,
    comment:
        'Absolutely love these! Super comfortable and stylish. Got compliments all day. Sizing is true to size.',
    date: null,
    size: 'UK 7',
    verified: true,
  ),
  Review(
    id: 'r2',
    userName: 'Rahul K.',
    userAvatar: 'R',
    rating: 4,
    comment:
        'Great quality for the price. Delivery was quick and packaging was excellent. Slightly stiff at first but broke in nicely.',
    date: null,
    size: 'UK 9',
    verified: true,
  ),
  Review(
    id: 'r3',
    userName: 'Sneha T.',
    userAvatar: 'S',
    rating: 5,
    comment: 'Perfect fit! Exactly as described. Will definitely buy again.',
    date: null,
    verified: false,
  ),
];
