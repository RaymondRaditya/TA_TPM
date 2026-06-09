import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static const _usersBoxName = 'users';
  static const _designsBoxName = 'saved_designs';
  static const _cartBoxName = 'cart_items';
  static const _metaBoxName = 'meta';
  static const _lastUserIdKey = 'last_user_id';
  static const _lastDesignIdKey = 'last_design_id';
  static const _lastCartItemIdKey = 'last_cart_item_id';

  // --- Users Fields ---
  static const tableUsers = 'users';
  static const columnUserId = 'id';
  static const columnUsername = 'username';
  static const columnEmail = 'email';
  static const columnPasswordHash = 'password_hash';
  static const columnBiometricRegistered = 'biometric_registered';
  static const columnPhone = 'phone';
  static const columnAddress = 'address';

  // --- Saved Designs Fields ---
  static const tableSavedDesigns = 'saved_designs';
  static const columnDesignId = 'id';
  static const columnDesignUserId = 'user_id';
  static const columnDesignName = 'design_name';
  static const columnLayoutJsonData = 'layout_json_data';
  static const columnCreatedAt = 'created_at';

  // --- Cart Items Fields ---
  static const tableCartItems = 'cart_items';
  static const columnCartId = 'id';
  static const columnCartItemName = 'item_name';
  static const columnCartItemType = 'item_type';
  static const columnCartItemSize = 'item_size';
  static const columnCartPrice = 'price';
  static const columnCartLayoutData = 'layout_data';
  static const columnCartStickerCount = 'sticker_count';
  static const columnCartColor = 'item_color';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Box<Map>? _usersBox;
  Box<Map>? _designsBox;
  Box<Map>? _cartBox;
  Box<int>? _metaBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _usersBox = await Hive.openBox<Map>(_usersBoxName);
    _designsBox = await Hive.openBox<Map>(_designsBoxName);
    _cartBox = await Hive.openBox<Map>(_cartBoxName);
    _metaBox = await Hive.openBox<int>(_metaBoxName);
    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  int _nextId(Box<Map> box, String metaKey) {
    final stored = _metaBox?.get(metaKey);
    if (stored != null) {
      final next = stored + 1;
      _metaBox?.put(metaKey, next);
      return next;
    }

    final keys = box.keys.whereType<int>();
    final maxId = keys.isEmpty ? 0 : keys.reduce(max);
    final next = maxId + 1;
    _metaBox?.put(metaKey, next);
    return next;
  }

  bool _emailExists(String email, {int? excludeId}) {
    final normalized = email.trim();
    for (final key in _usersBox!.keys) {
      if (excludeId != null && key == excludeId) continue;
      final user = _usersBox!.get(key);
      if (user == null) continue;
      if ((user[columnEmail] as String?)?.trim() == normalized) {
        return true;
      }
    }
    return false;
  }

  bool _usernameExists(String username, {int? excludeId}) {
    final normalized = username.trim();
    for (final key in _usersBox!.keys) {
      if (excludeId != null && key == excludeId) continue;
      final user = _usersBox!.get(key);
      if (user == null) continue;
      if ((user[columnUsername] as String?)?.trim() == normalized) {
        return true;
      }
    }
    return false;
  }

  // =======================================================
  //                 CRUD OPERATIONS: USERS
  // =======================================================

  Future<int> insertUser(Map<String, dynamic> row) async {
    await _ensureInitialized();

    final email = row[columnEmail] as String?;
    if (email == null || email.trim().isEmpty) {
      throw ArgumentError('Email is required');
    }
    if (_emailExists(email)) {
      throw StateError('Email already exists');
    }

    final username = row[columnUsername] as String?;
    if (username != null && _usernameExists(username)) {
      throw StateError('Username already exists');
    }

    final id = row[columnUserId] as int? ?? _nextId(_usersBox!, _lastUserIdKey);
    final record = Map<String, dynamic>.from(row)
      ..[columnUserId] = id
      ..putIfAbsent(columnBiometricRegistered, () => 0);

    await _usersBox!.put(id, record);
    return id;
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    await _ensureInitialized();
    final user = _usersBox!.get(id);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    await _ensureInitialized();
    final normalized = username.trim();
    for (final key in _usersBox!.keys) {
      final user = _usersBox!.get(key);
      if (user == null) continue;
      if ((user[columnUsername] as String?)?.trim() == normalized) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    await _ensureInitialized();
    final normalized = email.trim();
    for (final key in _usersBox!.keys) {
      final user = _usersBox!.get(key);
      if (user == null) continue;
      if ((user[columnEmail] as String?)?.trim() == normalized) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByIdentifier(String identifier) async {
    await _ensureInitialized();
    final normalized = identifier.trim();
    for (final key in _usersBox!.keys) {
      final user = _usersBox!.get(key);
      if (user == null) continue;
      if ((user[columnEmail] as String?)?.trim() == normalized ||
          (user[columnUsername] as String?)?.trim() == normalized) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    await _ensureInitialized();
    final id = row[columnUserId];
    if (id is! int) return 0;
    final existing = _usersBox!.get(id);
    if (existing == null) return 0;

    final nextEmail = row[columnEmail] as String?;
    if (nextEmail != null && _emailExists(nextEmail, excludeId: id)) {
      throw StateError('Email already exists');
    }
    final nextUsername = row[columnUsername] as String?;
    if (nextUsername != null && _usernameExists(nextUsername, excludeId: id)) {
      throw StateError('Username already exists');
    }

    final updated = Map<String, dynamic>.from(existing)..addAll(row);
    await _usersBox!.put(id, updated);
    return 1;
  }

  Future<int> deleteUser(int id) async {
    await _ensureInitialized();
    if (!_usersBox!.containsKey(id)) return 0;
    await _usersBox!.delete(id);
    return 1;
  }

  Future<int> updateBiometricStatus(int userId, bool isEnabled) async {
    await _ensureInitialized();
    final existing = _usersBox!.get(userId);
    if (existing == null) return 0;
    final updated = Map<String, dynamic>.from(existing)
      ..[columnBiometricRegistered] = isEnabled ? 1 : 0;
    await _usersBox!.put(userId, updated);
    return 1;
  }

  // =======================================================
  //            CRUD OPERATIONS: SAVED DESIGNS
  // =======================================================

  Future<int> insertDesign(Map<String, dynamic> row) async {
    await _ensureInitialized();
    final id =
        row[columnDesignId] as int? ?? _nextId(_designsBox!, _lastDesignIdKey);
    final record = Map<String, dynamic>.from(row)..[columnDesignId] = id;
    await _designsBox!.put(id, record);
    return id;
  }

  Future<Map<String, dynamic>?> getDesign(int id) async {
    await _ensureInitialized();
    final design = _designsBox!.get(id);
    return design == null ? null : Map<String, dynamic>.from(design);
  }

  Future<List<Map<String, dynamic>>> getDesignsByUserId(int userId) async {
    await _ensureInitialized();
    final results = <Map<String, dynamic>>[];
    for (final key in _designsBox!.keys) {
      final design = _designsBox!.get(key);
      if (design == null) continue;
      if (design[columnDesignUserId] == userId) {
        results.add(Map<String, dynamic>.from(design));
      }
    }
    return results;
  }

  Future<int> updateDesign(Map<String, dynamic> row) async {
    await _ensureInitialized();
    final id = row[columnDesignId];
    if (id is! int) return 0;
    final existing = _designsBox!.get(id);
    if (existing == null) return 0;
    final updated = Map<String, dynamic>.from(existing)..addAll(row);
    await _designsBox!.put(id, updated);
    return 1;
  }

  Future<int> deleteDesign(int id) async {
    await _ensureInitialized();
    if (!_designsBox!.containsKey(id)) return 0;
    await _designsBox!.delete(id);
    return 1;
  }

  // =======================================================
  //            CRUD OPERATIONS: CART ITEMS
  // =======================================================

  Future<int> insertCartItem(Map<String, dynamic> row) async {
    await _ensureInitialized();
    final id = row[columnCartId] as int? ?? _nextId(_cartBox!, _lastCartItemIdKey);
    final record = Map<String, dynamic>.from(row)..[columnCartId] = id;
    await _cartBox!.put(id, record);
    return id;
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    await _ensureInitialized();
    final results = <Map<String, dynamic>>[];
    for (final key in _cartBox!.keys) {
      final item = _cartBox!.get(key);
      if (item == null) continue;
      results.add(Map<String, dynamic>.from(item));
    }
    return results;
  }

  Future<int> deleteCartItem(int id) async {
    await _ensureInitialized();
    if (!_cartBox!.containsKey(id)) return 0;
    await _cartBox!.delete(id);
    return 1;
  }

  Future<void> clearCart() async {
    await _ensureInitialized();
    await _cartBox!.clear();
    await _metaBox!.put(_lastCartItemIdKey, 0);
  }
}
