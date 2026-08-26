import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'create_order_screen.dart';
import 'rate_order_screen.dart';
import '../privacy_policy_screen.dart';
import '../help_support_screen.dart';
import '../notifications_screen.dart';
import '../profile_edit_screen.dart';
import '../payment/flutterwave_screen.dart';
import '../../services/api_service.dart';

const _blue = Color(0xFF1A3A8F);
const _orange = Color(0xFFE85C1A);
const _green = Color(0xFF10B981);
const _bg = Color(0xFFF5F6FA);

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final token = context.read<AuthProvider>().token;
      context.read<OrderProvider>().loadMyOrders(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();

    final pages = [
      _HomeTab(auth: auth, orders: orders),
      _OrdersTab(auth: auth, orders: orders),
      _TrackTab(orders: orders, auth: auth),
      _WalletTab(auth: auth),
      _ProfileTab(auth: auth),
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
                  _navItem(2, Icons.location_on_rounded, Icons.location_on_outlined, 'Track'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? active : inactive,
                color: selected ? _blue : Colors.grey[400], size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected ? _blue : Colors.grey[400],
                )),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic auth;
  final dynamic orders;
  const _HomeTab({required this.auth, required this.orders});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.inventory_2_outlined, 'label': 'Package', 'color': _blue, 'type': 'Package'},
      {'icon': Icons.fastfood_outlined, 'label': 'Food', 'color': _orange, 'type': 'Food'},
      {'icon': Icons.description_outlined, 'label': 'Documents', 'color': Colors.purple, 'type': 'Documents'},
      {'icon': Icons.more_horiz, 'label': 'Other', 'color': Colors.teal, 'type': 'Other'},
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/logo.png', height: 28,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 28, height: 28,
                                      decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 16))),
                                const SizedBox(width: 8),
                                const Text('Ryaniva',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _blue)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Hello, ${auth.user?.name?.split(' ')[0] ?? 'there'} 👋',
                            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        const Text('Where to?',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: _blue, size: 20),
                                const SizedBox(width: 10),
                                Text('Enter pickup location...',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: services.map((s) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CreateOrderScreen(preselectedType: s['type'] as String))),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: (s['color'] as Color).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(s['label'] as String,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent deliveries',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See all',
                              style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            if (orders.loading)
              const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
                  )))
            else if (orders.orders.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey[200]),
                        const SizedBox(height: 12),
                        Text('No deliveries yet', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('Tap "Where to?" to book your first delivery',
                            style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final count = orders.orders.length > 3 ? 3 : orders.orders.length;
                    if (i >= count) return null;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _OrderCard(order: orders.orders[i], auth: auth, compact: true),
                    );
                  },
                  childCount: orders.orders.length > 3 ? 3 : orders.orders.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final dynamic auth;
  final dynamic orders;
  const _OrdersTab({required this.auth, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => orders.loadMyOrders(auth.token),
          ),
        ],
      ),
      body: orders.loading
          ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
          : orders.orders.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.orders.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderCard(order: orders.orders[i], auth: auth, compact: false),
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final dynamic auth;
  final bool compact;
  const _OrderCard({required this.order, required this.auth, required this.compact});

  Color _statusColor(String s) {
    switch (s) {
      case 'REQUESTED': return Colors.orange;
      case 'ACCEPTED': return _blue;
      case 'PICKED': return _orange;
      case 'DELIVERED': return _green;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.red;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'REQUESTED': return 'Finding rider';
      case 'ACCEPTED': return 'Rider en route';
      case 'PICKED': return 'On the way';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return s;
    }
  }

  IconData _itemIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food': return Icons.fastfood_outlined;
      case 'documents': return Icons.description_outlined;
      case 'package': return Icons.inventory_2_outlined;
      default: return Icons.local_shipping_outlined;
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    String? selectedReason;
    final reasons = ['Changed my mind', 'Wrong address entered', 'Found another option', 'Taking too long', 'Item no longer needed', 'Other'];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancel delivery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Why are you cancelling?', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r, style: const TextStyle(fontSize: 13)),
                value: r, groupValue: selectedReason, dense: true, activeColor: _blue,
                onChanged: (v) => set(() => selectedReason = v),
              )),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Keep order'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: selectedReason == null ? null : () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && selectedReason != null) {
      final token = context.read<AuthProvider>().token;
      final op = context.read<OrderProvider>();
      final result = await op.cancelOrder(order.id, token, cancelReason: selectedReason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? _green : Colors.red,
        ));
        if (result['success']) op.loadMyOrders(token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == 'DELIVERED';
    final isCancellable = ['REQUESTED', 'ACCEPTED', 'PICKED'].contains(order.status as String);
    final statusColor = _statusColor(order.status as String);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_itemIcon(order.itemType as String), color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((order.itemType as String).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(_statusLabel(order.status as String),
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ],
              )),
              Text('₦${(order.price as double).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _orange)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.radio_button_checked, color: _blue, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(order.pickupAddress as String,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(width: 2, height: 10, color: Colors.grey[200]),
            ),
            Row(children: [
              const Icon(Icons.location_on, color: _orange, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(order.dropoffAddress as String,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (!compact) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.straighten, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${order.distanceKm} km', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                const SizedBox(width: 12),
                Icon(Icons.payment, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(order.paymentMethod as String, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
              if (order.status == 'ACCEPTED' || order.status == 'PICKED') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.motorcycle, color: _blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        order.status == 'ACCEPTED' ? 'Rider is heading to pickup' : 'Rider has your item',
                        style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w500),
                      )),
                    ]),
                    if (order.riderName != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.person, color: _blue, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(order.riderName!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        if (order.riderPhone != null)
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse('tel:${order.riderPhone}');
                              if (await canLaunchUrl(uri)) launchUrl(uri);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.call, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Call', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                      ]),
                    ],
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                if (isCancellable) Expanded(child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(context),
                  icon: const Icon(Icons.close, size: 13),
                  label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                )),
                if (isCancellable && isDelivered) const SizedBox(width: 8),
                if (isDelivered) Expanded(child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RateOrderScreen(orderId: order.id, token: auth.token))),
                  icon: const Icon(Icons.star_outline, size: 13),
                  label: const Text('Rate rider', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackTab extends StatefulWidget {
  final dynamic orders;
  final dynamic auth;
  const _TrackTab({required this.orders, required this.auth});
  @override
  State<_TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<_TrackTab> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      widget.orders.loadMyOrders(widget.auth.token);
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final activeOrders = (widget.orders.orders as List).where(
      (o) => ['ACCEPTED', 'PICKED', 'REQUESTED'].contains(o.status as String)
    ).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Track Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => widget.orders.loadMyOrders(widget.auth.token)),
        ],
      ),
      body: activeOrders.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_searching, size: 72, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Text('No active deliveries', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                const SizedBox(height: 6),
                Text('Auto-updates every 10 seconds', style: TextStyle(fontSize: 12, color: Colors.grey[300])),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeOrders.length,
              itemBuilder: (_, i) {
                final order = activeOrders[i];
                final steps = ['REQUESTED', 'ACCEPTED', 'PICKED', 'DELIVERED'];
                final currentStep = steps.indexOf(order.status as String);
                final stepLabels = ['Requested', 'Accepted', 'Picked Up', 'Delivered'];
                final stepIcons = [Icons.receipt_long, Icons.person, Icons.inventory_2, Icons.check_circle];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text((order.itemType as String).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('₦${(order.price as double).toStringAsFixed(0)}',
                              style: const TextStyle(color: _orange, fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.radio_button_checked, color: _blue, size: 13),
                        const SizedBox(width: 6),
                        Expanded(child: Text(order.pickupAddress as String,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(width: 1, height: 10, color: Colors.grey[200]),
                      ),
                      Row(children: [
                        const Icon(Icons.location_on, color: _orange, size: 13),
                        const SizedBox(width: 6),
                        Expanded(child: Text(order.dropoffAddress as String,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i <= currentStep;
                          final isLast = i == 3;
                          return Expanded(
                            child: Row(children: [
                              Expanded(child: Column(children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: isActive ? _blue : Colors.grey[100],
                                    shape: BoxShape.circle,
                                    border: i == currentStep ? Border.all(color: _orange, width: 2) : null,
                                  ),
                                  child: Icon(stepIcons[i],
                                      color: isActive ? Colors.white : Colors.grey[300], size: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(stepLabels[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isActive ? _blue : Colors.grey[400],
                                      fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.normal,
                                    )),
                              ])),
                              if (!isLast)
                                Container(height: 2, width: 16,
                                    margin: const EdgeInsets.only(bottom: 18),
                                    color: i < currentStep ? _blue : Colors.grey[200]),
                            ]),
                          );
                        }),
                      ),
                      if (order.status == 'ACCEPTED' || order.status == 'PICKED') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: _blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Row(children: [
                              const Icon(Icons.motorcycle, color: _blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                order.status == 'ACCEPTED' ? 'Rider is heading to pickup' : 'Rider has your item',
                                style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w500),
                              )),
                            ]),
                            if (order.riderName != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.person, color: _blue, size: 14),
                                const SizedBox(width: 6),
                                Expanded(child: Text(order.riderName!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                if (order.riderPhone != null)
                                  GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse('tel:${order.riderPhone}');
                                      if (await canLaunchUrl(uri)) launchUrl(uri);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.call, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Call', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  ),
                              ]),
                            ],
                          ]),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _WalletTab extends StatefulWidget {
  final dynamic auth;
  const _WalletTab({required this.auth});
  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  double _balance = 0.0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadBalance(); }

  Future<void> _loadBalance() async {
    try {
      final res = await ApiService.get('/wallet', token: widget.auth.token);
      setState(() { _balance = (res['balance'] as num).toDouble(); _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: _loadBalance)],
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
              const Text('Available balance', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              _loading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('₦${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      isScrollControlled: true,
                      builder: (_) => _TopUpSheet(auth: widget.auth, onSuccess: _loadBalance),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  onPressed: _loadBalance,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
}

class _ProfileTab extends StatelessWidget {
  final dynamic auth;
  const _ProfileTab({required this.auth});

  @override
  Widget build(BuildContext context) {
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
                  auth.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _blue),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.name ?? 'Customer',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(auth.user?.phone ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Customer', style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Column(children: [
              _item(Icons.person_outline, 'Edit Profile', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
              _div(),
              _item(Icons.notifications_outlined, 'Notifications', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _div(),
              _item(Icons.help_outline, 'Help & Support', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
              _div(),
              _item(Icons.privacy_tip_outlined, 'Privacy Policy', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              _div(),
              _item(Icons.delete_forever, 'Delete Account', () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Delete Account'),
                        content: const Text('This will permanently delete your account and all your data. This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final success = await context.read<AuthProvider>().deleteAccount();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete account.'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }, color: Colors.red),
                  _div(),
                  _item(Icons.logout, 'Logout', () => auth.logout(), color: Colors.red),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap, {Color color = Colors.black87}) {
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
}

class _TopUpSheet extends StatefulWidget {
  final dynamic auth;
  final VoidCallback onSuccess;
  const _TopUpSheet({required this.auth, required this.onSuccess});
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountController = TextEditingController();
  final List<int> _quickAmounts = [500, 1000, 2000, 5000];
  bool _loading = false;

  Future<void> _processTopUp() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    Navigator.pop(context);
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => FlutterwaveScreen(
        email: 'payments@ryaniva.com.ng',
        phone: widget.auth.user?.phone ?? '',
        name: widget.auth.user?.name ?? 'Ryaniva Customer',
        amount: amount,
        orderId: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
        paymentOption: 'card',
        onPaymentComplete: (success) async {
          if (success) {
            try {
              await ApiService.post('/wallet/topup', {
                'amount': amount,
                'reference': 'wallet_${DateTime.now().millisecondsSinceEpoch}',
              }, token: widget.auth.token);
              widget.onSuccess();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('₦${amount.toStringAsFixed(0)} added to wallet!'),
                  backgroundColor: _green,
                ));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Payment received but wallet update failed. Contact support.')));
              }
            }
          }
        },
      ),
    ));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Up Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Add money to pay for deliveries', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: _quickAmounts.map((a) {
              final sel = _amountController.text == a.toString();
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _amountController.text = a.toString()),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? _blue.withOpacity(0.1) : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? _blue : Colors.transparent),
                  ),
                  child: Text('₦$a', textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                          color: sel ? _blue : Colors.grey[600])),
                ),
              ));
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter custom amount', prefixText: '₦ ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _blue, width: 1.5)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _amountController.text.isEmpty || _loading ? null : _processTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      _amountController.text.isEmpty ? 'Enter amount' : 'Top Up ₦${_amountController.text}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}