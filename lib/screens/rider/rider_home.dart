import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../profile_edit_screen.dart';
import '../notifications_screen.dart';
import '../help_support_screen.dart';
import '../privacy_policy_screen.dart';

const _blue = Color(0xFF1A3A8F);
const _orange = Color(0xFFE85C1A);
const _green = Color(0xFF10B981);
const _bg = Color(0xFFF5F6FA);

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});
  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  bool _isOnline = false;
  bool _profileLoaded = false;
  bool _hasProfile = false;
  Map<String, dynamic>? _riderProfile;
  String _selectedBike = 'Motorcycle';
  List<Order> _activeOrders = [];
  int _currentIndex = 0;
  Timer? _locationTimer;
  final List<String> _bikeTypes = ['Motorcycle', 'Scooter', 'Bicycle'];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _loadProfile());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthProvider>().token;
    try {
      final data = await ApiService.get('/riders/profile', token: token);
      if (!mounted) return;
      if (data['id'] != null) {
        setState(() {
          _riderProfile = data;
          _hasProfile = true;
          _isOnline = data['isOnline'] ?? false;
          _profileLoaded = true;
        });
        _loadOrders();
        _loadActiveOrders();
        if (_isOnline) _startLocationTracking();
      } else {
        if (!mounted) return;
        setState(() { _hasProfile = false; _profileLoaded = true; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _hasProfile = false; _profileLoaded = true; });
    }
  }

  Future<void> _loadOrders() async {
    final token = context.read<AuthProvider>().token;
    await context.read<OrderProvider>().loadNearbyOrders(token);
  }

  Future<void> _loadActiveOrders() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.get('/orders/my-rider-orders', token: token);
      if (res is List && mounted) {
        setState(() { _activeOrders = res.map((o) => Order.fromJson(o)).toList(); });
      }
    } catch (e) {}
  }

  Future<void> _registerRider() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.post('/riders/register', {'vehicle': _selectedBike}, token: token);
      if (res['rider'] != null && mounted) {
        setState(() { _riderProfile = res['rider']; _hasProfile = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created! Awaiting admin approval.'), backgroundColor: _green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create profile'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleOnline() async {
    final token = context.read<AuthProvider>().token;
    final endpoint = _isOnline ? '/riders/offline' : '/riders/online';
    try {
      await ApiService.patch(endpoint, {}, token: token);
      setState(() => _isOnline = !_isOnline);
      if (_isOnline) {
        _loadOrders();
        _startLocationTracking();
      } else {
        _stopLocationTracking();
      }
    } catch (e) {}
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      await ApiService.patch('/riders/location', {
        'lat': position.latitude,
        'lng': position.longitude,
      }, token: token);
    } catch (e) {}
  }

  void _startLocationTracking() {
    _sendLocation();
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && mounted) _sendLocation();
    });
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.patch('/orders/$orderId/status', {'status': status}, token: token);
      if (res['message'] != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: _green),
        );
        await _loadActiveOrders();
        await _loadOrders();
        await _loadProfile();
      }
    } catch (e) {}
  }

  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!_profileLoaded) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2)),
      );
    }
    if (!_hasProfile) return _buildSetupScreen(auth);
    if (_riderProfile?['status'] == 'PENDING') return _buildPendingScreen();
    if (_riderProfile?['status'] == 'SUSPENDED') return _buildSuspendedScreen();

    final pages = [
      _buildHomeTab(context, auth),
      _buildOrdersTab(context),
      _buildEarningsTab(),
      _buildWalletTab(),
      _buildProfileTab(context, auth),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                  _navItem(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
                  _navItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Earnings'),
                  _navItem(3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallet'),
                  _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? active : inactive, color: selected ? _blue : Colors.grey[400], size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? _blue : Colors.grey[400],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, dynamic auth) {
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Image.asset('assets/images/logo.png', height: 28,
                            errorBuilder: (_, __, ___) => Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                              child: const Icon(Icons.motorcycle, color: Colors.white, size: 16),
                            )),
                        const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Ryaniva Rider',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _blue)),
                          Text('Hello, ${auth.user?.name?.split(' ')[0] ?? ''}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ]),
                      ]),
                      Row(children: [
                        GestureDetector(
                          onTap: () { _loadOrders(); _loadActiveOrders(); },
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                            child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => auth.logout(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                            child: const Icon(Icons.logout_rounded, size: 18, color: Colors.black87),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── ONLINE TOGGLE ──
                  GestureDetector(
                    onTap: _toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _isOnline ? _green.withOpacity(0.08) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isOnline ? _green.withOpacity(0.3) : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (_isOnline ? _green : Colors.grey[400]!).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.motorcycle_outlined,
                              color: _isOnline ? _green : Colors.grey[400], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isOnline ? 'You are Online' : 'You are Offline',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _isOnline ? _green : Colors.grey[600],
                                )),
                            Text(_isOnline ? 'Receiving delivery requests' : 'Tap to go online and earn',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          ],
                        )),
                        Switch(
                          value: _isOnline,
                          onChanged: (_) => _toggleOnline(),
                          activeColor: _green,
                          trackColor: WidgetStateProperty.resolveWith((s) =>
                              s.contains(WidgetState.selected) ? _green.withOpacity(0.3) : Colors.grey[200]),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // ── STATS ROW ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                _statPill('${_riderProfile?['totalTrips'] ?? 0}', 'Trips', Icons.check_circle_outline, _green),
                const SizedBox(width: 8),
                _statPill('${_riderProfile?['rating'] ?? 5.0}⭐', 'Rating', Icons.star_outline, Colors.amber),
                const SizedBox(width: 8),
                _statPill('${_activeOrders.length}', 'Active', Icons.local_shipping_outlined, _blue),
              ]),
            ),

            // ── ORDERS HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Orders (${orders.orders.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (_activeOrders.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('My Orders (${_activeOrders.length})',
                            style: const TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),

            // ── ORDER LIST ──
            Expanded(
              child: !_isOnline
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 12),
                        Text('Go online to receive orders', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('Toggle the switch above', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                      ],
                    ))
                  : orders.loading
                      ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
                      : orders.orders.isEmpty
                          ? Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                Text('No orders nearby', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                              ],
                            ))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.orders.length,
                              itemBuilder: (ctx, i) {
                                final order = orders.orders[i];
                                return _orderCard(
                                  order: order,
                                  action: ElevatedButton(
                                    onPressed: () async {
                                      final success = await orders.acceptOrder(
                                          order.id, context.read<AuthProvider>().token);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(success ? '✅ Order accepted!' : 'Could not accept'),
                                          backgroundColor: success ? _green : Colors.red,
                                        ));
                                        if (success) {
                                          _loadOrders();
                                          _loadActiveOrders();
                                          setState(() => _currentIndex = 1);
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: _loadActiveOrders),
        ],
      ),
      body: _activeOrders.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 72, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Text('No active orders', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activeOrders.length,
              itemBuilder: (ctx, i) {
                final order = _activeOrders[i];
                final isPicked = order.status == 'PICKED';
                return _orderCard(
                  order: order,
                  showStatus: true,
                  action: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order.id, isPicked ? 'DELIVERED' : 'PICKED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPicked ? _orange : _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(isPicked ? 'Delivered ✓' : 'Picked Up',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEarningsTab() {
    final totalTrips = _riderProfile?['totalTrips'] ?? 0;
    final rating = _riderProfile?['rating'] ?? 5.0;
    final totalTips = (_riderProfile?['totalTips'] ?? 0.0) as num;
    final bonusEligible = _riderProfile?['bonusEligible'] ?? false;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly Salary', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 6),
              const Text('Paid by Ryaniva',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Contact admin for salary details',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
            children: [
              _earningsCard('$totalTrips', 'Completed Trips', Icons.check_circle, _green),
              _earningsCard('$rating ⭐', 'My Rating', Icons.star, Colors.amber),
              _earningsCard('₦${totalTips.toStringAsFixed(0)}', 'Total Tips', Icons.volunteer_activism, _orange),
              _earningsCard(bonusEligible ? 'Eligible ✅' : 'Not Yet',
                  'Bonus Status', Icons.emoji_events, bonusEligible ? _green : Colors.grey),
            ],
          ),
          if (bonusEligible) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.emoji_events, color: _green, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🏆 Bonus Eligible!',
                      style: TextStyle(fontWeight: FontWeight.w700, color: _green)),
                  const SizedBox(height: 4),
                  Text('4.5+ rating and 20+ trips. Contact admin to claim.',
                      style: TextStyle(color: Colors.green[700], fontSize: 12)),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bonus Rules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              _bonusRule('⭐', 'Maintain a 4.5+ star rating'),
              _bonusRule('🏍️', 'Complete 20+ deliveries'),
              _bonusRule('💰', 'Tips go directly to you'),
              _bonusRule('🎁', '10% bonus from 11th delivery per day'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildWalletTab() {
    final totalTips = (_riderProfile?['totalTips'] ?? 0.0) as num;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tips Balance', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Text('₦${totalTips.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Total tips received from customers',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tip History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 20),
              Center(child: Column(children: [
                Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Text('No transactions yet', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, dynamic auth) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: _blue.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Text(
                  auth.user?.name?.substring(0, 1).toUpperCase() ?? 'R',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _blue),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.name ?? 'Rider',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(auth.user?.phone ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Ryaniva Rider',
                      style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _profileStat('${_riderProfile?['totalTrips'] ?? 0}', 'Trips'),
            const SizedBox(width: 8),
            _profileStat('${_riderProfile?['rating'] ?? 5.0}', 'Rating'),
            const SizedBox(width: 8),
            _profileStat(_riderProfile?['vehicle'] ?? 'N/A', 'Vehicle'),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Column(children: [
              _profileItem(Icons.person_outline, 'Edit Profile', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
              _div(),
              _profileItem(Icons.notifications_outlined, 'Notifications', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _div(),
              _profileItem(Icons.help_outline, 'Help & Support', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
              _div(),
              _profileItem(Icons.privacy_tip_outlined, 'Privacy Policy', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              _div(),
              _profileItem(Icons.logout, 'Logout', () => auth.logout(), color: Colors.red),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statPill(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ])),
        ]),
      ),
    );
  }

  Widget _earningsCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 22),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
      ]),
    );
  }

  Widget _bonusRule(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ]),
    );
  }

  Widget _profileStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _blue)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.black87}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: (color == Colors.red ? Colors.red : _blue).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color == Colors.red ? Colors.red : _blue, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      trailing: color != Colors.red ? const Icon(Icons.chevron_right, color: Colors.grey, size: 18) : null,
      onTap: onTap,
    );
  }

  Widget _div() => const Divider(height: 1, indent: 68);

  Widget _orderCard({
    required Order order,
    required Widget action,
    bool showStatus = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _blue.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_outlined, color: _blue, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.itemType.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (showStatus)
                  Text(order.status,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: order.status == 'PICKED' ? _orange : _blue,
                      )),
              ]),
            ]),
            Text('₦${order.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _orange)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.radio_button_checked, color: _blue, size: 13),
            const SizedBox(width: 6),
            Expanded(child: Text(order.pickupAddress,
                style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(width: 1, height: 10, color: Colors.grey[200]),
          ),
          Row(children: [
            const Icon(Icons.location_on, color: _orange, size: 13),
            const SizedBox(width: 6),
            Expanded(child: Text(order.dropoffAddress,
                style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          if (order.senderPhone != null && order.senderPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _contactRow(Icons.person_outline, 'Sender', order.senderPhone!, _blue),
          ],
          if (order.recipientName != null && order.recipientName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _contactRow(Icons.person, 'Recipient', '${order.recipientName} • ${order.recipientPhone ?? ''}', _orange),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.straighten, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${order.distanceKm} km • ${order.paymentMethod}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            const Spacer(),
            action,
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(order.pickupLat, order.pickupLng, 'Pickup'),
              icon: const Icon(Icons.navigation_outlined, size: 13),
              label: const Text('Pickup', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue, side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(order.dropoffLat, order.dropoffLng, 'Dropoff'),
              icon: const Icon(Icons.location_on_outlined, size: 13),
              label: const Text('Dropoff', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange, side: const BorderSide(color: _orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      GestureDetector(
        onTap: () async {
          final phone = value.contains('•') ? value.split('•').last.trim() : value;
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.call, color: Colors.white, size: 11),
            SizedBox(width: 3),
            Text('Call', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildSetupScreen(dynamic auth) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 40),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: _blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.motorcycle, size: 40, color: _blue),
            ),
            const SizedBox(height: 20),
            const Text('Set Up Your Rider Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Select your vehicle type to start delivering',
                style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            ..._bikeTypes.map((bike) {
              final sel = _selectedBike == bike;
              return GestureDetector(
                onTap: () => setState(() => _selectedBike = bike),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel ? _blue.withOpacity(0.06) : _bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? _blue : Colors.grey[200]!, width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.motorcycle, color: sel ? _blue : Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(bike, style: TextStyle(
                        fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        color: sel ? _blue : Colors.black87, fontSize: 15)),
                    const Spacer(),
                    if (sel) const Icon(Icons.check_circle, color: _orange, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _registerRider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPendingScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_empty, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text('Profile Under Review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Your profile is awaiting admin approval. We\'ll notify you once approved.',
                style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue, side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.block, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text('Account Suspended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Please contact Ryaniva support to resolve this.',
                style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}