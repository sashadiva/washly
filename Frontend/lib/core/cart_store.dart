import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// A single global cart, shared across screens.
///
/// An order can only target one laundromat, so the cart is scoped to one
/// laundromat at a time. Adding an item from a different laundromat requires
/// clearing the current cart first (the UI confirms this).
class CartStore extends ChangeNotifier {
  int? _laundromatId;
  String? _laundromatName;
  final Map<int, CartItem> _items = {};

  int? get laundromatId => _laundromatId;
  String? get laundromatName => _laundromatName;

  List<CartItem> get items => _items.values.toList(growable: false);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Total quantity across all lines (pieces or kg).
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// True if any line is priced by weight (final price set at the laundromat).
  bool get hasKilo => _items.values.any((item) => item.isKilo);

  CartItem? itemFor(int serviceId) => _items[serviceId];

  /// True if adding for [laundromatId] would replace items from another store.
  bool wouldReplace(int laundromatId) =>
      _items.isNotEmpty && _laundromatId != null && _laundromatId != laundromatId;

  /// Add or update a line. Callers must ensure the cart isn't holding another
  /// laundromat's items (use [wouldReplace] + [clear], or [startFresh]).
  void setItem(
    int laundromatId,
    String laundromatName,
    CartItem item,
  ) {
    if (_laundromatId != laundromatId) {
      _items.clear();
      _laundromatId = laundromatId;
      _laundromatName = laundromatName;
    } else {
      _laundromatName = laundromatName;
    }
    _items[item.serviceId] = item;
    notifyListeners();
  }

  /// Decrement a line by one; removes it at zero. Clears store scope when empty.
  void decrement(int serviceId) {
    final item = _items[serviceId];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(serviceId);
    }
    if (_items.isEmpty) {
      _laundromatId = null;
      _laundromatName = null;
    }
    notifyListeners();
  }

  void increment(int serviceId) {
    final item = _items[serviceId];
    if (item == null) return;
    item.quantity++;
    notifyListeners();
  }

  void removeItem(int serviceId) {
    _items.remove(serviceId);
    if (_items.isEmpty) {
      _laundromatId = null;
      _laundromatName = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _laundromatId = null;
    _laundromatName = null;
    notifyListeners();
  }
}
