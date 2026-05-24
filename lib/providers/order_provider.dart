import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  String _error = '';

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String get error => _error;

  Future<Map<String, dynamic>?> createOrder({
    required String token,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String itemType,
    required String paymentMethod,
    String? itemNote,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.post('/orders', {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'itemType': itemType,
        'paymentMethod': paymentMethod,
        if (itemNote != null) 'itemNote': itemNote,
      }, token: token);
      return res;
    } catch (e) {
      _error = 'Failed to create order';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyOrders(String token) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/orders/my', token: token);
      _orders = (res as List).map((o) => Order.fromJson(o)).toList();
    } catch (e) {
      _error = 'Failed to load orders';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyOrders(String token) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/orders/nearby', token: token);
      _orders = (res as List).map((o) => Order.fromJson(o)).toList();
    } catch (e) {
      _error = 'Failed to load nearby orders';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRiderOrders(String token) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/orders/my-rider-orders', token: token);
      _orders = (res as List).map((o) => Order.fromJson(o)).toList();
    } catch (e) {
      _error = 'Failed to load rider orders';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder(String orderId, String token) async {
    try {
      final res = await ApiService.patch(
          '/orders/$orderId/accept', {}, token: token);
      return res['status'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatus(String orderId, String status, String token) async {
    try {
      await ApiService.patch(
          '/orders/$orderId/status', {'status': status}, token: token);
      return true;
    } catch (e) {
      return false;
    }
  }
}