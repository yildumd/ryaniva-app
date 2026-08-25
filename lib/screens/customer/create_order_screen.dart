import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../payment/flutterwave_screen.dart';
import '../payment/bank_transfer_screen.dart';
import '../../services/location_storage.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? preselectedType;
  const CreateOrderScreen({super.key, this.preselectedType});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with TickerProviderStateMixin {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  String _paymentMethod = 'CASH';
  String _selectedItemType = 'Package';
  double? _pickupLat, _pickupLng, _dropoffLat, _dropoffLng;
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;
  bool _showRecipientFields = false;
  Timer? _pickupDebounce, _dropoffDebounce;
  FocusNode _pickupFocus = FocusNode();
  FocusNode _dropoffFocus = FocusNode();

  static const blue = Color(0xFF1A3A8F);
  static const orange = Color(0xFFE85C1A);
  static const green = Color(0xFF10B981);
  static const bgGrey = Color(0xFFF5F6FA);

  final _itemTypes = [
    {'label': 'Package', 'icon': Icons.inventory_2_outlined},
    {'label': 'Food', 'icon': Icons.fastfood_outlined},
    {'label': 'Documents', 'icon': Icons.description_outlined},
    {'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedItemType = widget.preselectedType!;
    }
  }

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  double _estimatePrice() {
    if (_pickupLat == null || _dropoffLat == null) return 0;
    final distanceKm = _calcDistance(_pickupLat!, _pickupLng!, _dropoffLat!, _dropoffLng!);
    return (800 + distanceKm * 150).roundToDouble();
  }

  double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLng = (lng2 - lng1) * 3.14159 / 180;
    final a = (dLat / 2) * (dLat / 2) +
        (lat1 * 3.14159 / 180).abs() * (lat2 * 3.14159 / 180).abs() *
            (dLng / 2) * (dLng / 2);
    return R * 2 * (a < 1 ? a : 1);
  }

  Map<String, double> _getJosCoordinates(String address) {
    final a = address.toLowerCase();
    if (a.contains('rayfield')) return {'lat': 9.8734, 'lng': 8.9012};
    if (a.contains('terminus')) return {'lat': 9.8965, 'lng': 8.8583};
    if (a.contains('bukuru')) return {'lat': 9.7934, 'lng': 8.8521};
    if (a.contains('juth') || a.contains('teaching hospital')) return {'lat': 9.9012, 'lng': 8.8734};
    if (a.contains('unijos') || a.contains('university of jos')) return {'lat': 9.9285, 'lng': 8.8921};
    if (a.contains('angwan rogo')) return {'lat': 9.9123, 'lng': 8.8456};
    if (a.contains('tudun wada')) return {'lat': 9.9234, 'lng': 8.8678};
    if (a.contains('nassarawa')) return {'lat': 9.8823, 'lng': 8.8934};
    if (a.contains('vom')) return {'lat': 9.7234, 'lng': 8.8123};
    if (a.contains('farin gada')) return {'lat': 9.9345, 'lng': 8.8234};
    if (a.contains('apata')) return {'lat': 9.8456, 'lng': 8.8345};
    if (a.contains('gwong')) return {'lat': 9.9012, 'lng': 8.8567};
    if (a.contains('lamingo')) return {'lat': 9.9234, 'lng': 8.9123};
    if (a.contains('rikkos')) return {'lat': 9.8901, 'lng': 8.8456};
    if (a.contains('airport')) return {'lat': 9.8678, 'lng': 8.9234};
    if (a.contains('bauchi road')) return {'lat': 9.9567, 'lng': 8.8901};
    if (a.contains('zaria road')) return {'lat': 9.9456, 'lng': 8.8345};
    return {'lat': 9.8965, 'lng': 8.8583};
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );
      final res = await http.get(url, headers: {'User-Agent': 'RyanivaApp/1.0'});
      String address = 'My Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['display_name'] != null) address = data['display_name'];
      }
      if (mounted) {
        setState(() {
          if (isPickup) {
            _pickupController.text = address;
            _pickupLat = position.latitude;
            _pickupLng = position.longitude;
            _showPickupSuggestions = false;
          } else {
            _dropoffController.text = address;
            _dropoffLat = position.latitude;
            _dropoffLng = position.longitude;
            _showDropoffSuggestions = false;
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Try again.')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.trim().length < 3) return [];
    try {
      const apiKey = 'AIzaSyCI8Y_XNplWLmrhYcmyZTj3hQy0dKIYgSM';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&components=country:ng'
        '&location=9.8965,8.8583'
        '&radius=50000'
        '&key=$apiKey',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final results = <Map<String, dynamic>>[];
          for (final p in predictions.take(5)) {
            final placeId = p['place_id'];
            final detailUrl = Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json'
              '?place_id=$placeId&fields=geometry,formatted_address&key=$apiKey',
            );
            final detailRes = await http.get(detailUrl);
            if (detailRes.statusCode == 200) {
              final detail = jsonDecode(detailRes.body);
              if (detail['status'] == 'OK') {
                final loc = detail['result']['geometry']['location'];
                results.add({
                  'display_name': p['description'],
                  'lat': loc['lat'],
                  'lon': loc['lng'],
                });
              }
            }
          }
          return results;
        }
      }
    } catch (e) {
      // silent fail
    }
    return [];
  }

  void _onPickupChanged(String value) {
    _pickupDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _showPickupSuggestions = false);
      return;
    }
    _pickupDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _searchAddress(value);
      if (mounted) setState(() {
        _pickupSuggestions = results;
        _showPickupSuggestions = results.isNotEmpty;
      });
    });
  }

  void _onDropoffChanged(String value) {
    _dropoffDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _showDropoffSuggestions = false);
      return;
    }
    _dropoffDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _searchAddress(value);
      if (mounted) setState(() {
        _dropoffSuggestions = results;
        _showDropoffSuggestions = results.isNotEmpty;
      });
    });
  }

  void _selectPickup(Map<String, dynamic> s) {
    setState(() {
      _pickupController.text = s['display_name'];
      _pickupLat = s['lat'];
      _pickupLng = s['lon'];
      _showPickupSuggestions = false;
    });
    _pickupFocus.unfocus();
  }

  void _selectDropoff(Map<String, dynamic> s) {
    setState(() {
      _dropoffController.text = s['display_name'];
      _dropoffLat = s['lat'];
      _dropoffLng = s['lon'];
      _showDropoffSuggestions = false;
    });
    _dropoffFocus.unfocus();
  }

  Widget _suggestions(List<Map<String, dynamic>> items, Function(Map<String, dynamic>) onTap, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 44),
        itemBuilder: (_, i) {
          final s = items[i];
          final parts = (s['display_name'] as String).split(',');
          return ListTile(
            dense: true,
            leading: Icon(Icons.location_on, color: color, size: 18),
            title: Text(parts[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: parts.length > 1
                ? Text(parts.sublist(1).join(',').trim(), style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () => onTap(s),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final estimatedPrice = _estimatePrice();
    final canConfirm = _pickupController.text.isNotEmpty &&
        _dropoffController.text.isNotEmpty &&
        _recipientNameController.text.isNotEmpty &&
        _recipientPhoneController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bgGrey, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showPickupSuggestions = false;
            _showDropoffSuggestions = false;
          });
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ROUTE CARD (Bolt-style) ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                                  ),
                                  Container(width: 2, height: 36, color: Colors.grey[200]),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _pickupController,
                                  focusNode: _pickupFocus,
                                  onChanged: _onPickupChanged,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    hintText: 'Pickup location',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    suffixIcon: _pickupLat != null
                                        ? const Icon(Icons.check_circle, color: green, size: 16)
                                        : GestureDetector(
                                            onTap: () => _getCurrentLocation(true),
                                            child: const Icon(Icons.my_location, color: blue, size: 16),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showPickupSuggestions)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 0, 16, 8),
                            child: _suggestions(_pickupSuggestions, _selectPickup, blue),
                          ),

                        const Divider(height: 1, indent: 40),

                        // Dropoff
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(width: 2, height: 36, color: Colors.grey[200]),
                                  Container(
                                    width: 12, height: 12,
                                    decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _dropoffController,
                                  focusNode: _dropoffFocus,
                                  onChanged: _onDropoffChanged,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    hintText: 'Drop-off location',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    suffixIcon: _dropoffLat != null
                                        ? const Icon(Icons.check_circle, color: green, size: 16)
                                        : GestureDetector(
                                            onTap: () => _getCurrentLocation(false),
                                            child: const Icon(Icons.my_location, color: orange, size: 16),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showDropoffSuggestions)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 0, 16, 8),
                            child: _suggestions(_dropoffSuggestions, _selectDropoff, orange),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── ITEM TYPE CHIPS ──
                  const Text('What are you sending?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _itemTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final t = _itemTypes[i];
                        final selected = _selectedItemType == t['label'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedItemType = t['label'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? blue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? blue : Colors.grey[200]!),
                              boxShadow: selected
                                  ? [BoxShadow(color: blue.withOpacity(0.2), blurRadius: 8)]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t['icon'] as IconData,
                                    size: 14, color: selected ? Colors.white : Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(t['label'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : Colors.grey[700],
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── RECIPIENT CARD ──
                  GestureDetector(
                    onTap: () => setState(() => _showRecipientFields = !_showRecipientFields),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        border: (_recipientNameController.text.isEmpty || _recipientPhoneController.text.isEmpty)
                            ? Border.all(color: Colors.orange.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: blue.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.person_outline, color: blue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _recipientNameController.text.isEmpty
                                      ? 'Add recipient details'
                                      : _recipientNameController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _recipientNameController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                                  ),
                                ),
                                if (_recipientPhoneController.text.isNotEmpty)
                                  Text(_recipientPhoneController.text,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                if (_recipientNameController.text.isEmpty)
                                  Text('Required — name & phone of recipient',
                                      style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                              ],
                            ),
                          ),
                          Icon(_showRecipientFields ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  if (_showRecipientFields) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _recipientNameController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Recipient name',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              prefixIcon: const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: blue, width: 1.5),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _recipientPhoneController,
                            keyboardType: TextInputType.phone,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Recipient phone number',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: blue, width: 1.5),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── NOTE (optional) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a note for the rider (optional)',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.edit_note, size: 18, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── PAYMENT METHOD ──
                  const Text('Payment method',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _paymentChip('CASH', Icons.money, 'Cash', Colors.green),
                      const SizedBox(width: 8),
                      _paymentChip('CARD', Icons.credit_card, 'Card', orange),
                      const SizedBox(width: 8),
                      _paymentChip('TRANSFER', Icons.account_balance, 'Transfer', blue),
                    ],
                  ),
                ],
              ),
            ),

            // ── STICKY BOTTOM BAR ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (estimatedPrice > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated fare', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                          Text('₦${estimatedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: orange)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('₦800 base + ₦150/km',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (canConfirm && !orders.loading) ? () => _submitOrder(auth, orders) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canConfirm ? orange : Colors.grey[300],
                          foregroundColor: Colors.white,
                          elevation: canConfirm ? 2 : 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: orders.loading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Confirm Delivery',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  if (_paymentMethod != 'CASH') ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.lock_outline, size: 15),
                                  ],
                                ],
                              ),
                      ),
                    ),
                    if (!canConfirm) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pickupController.text.isEmpty || _dropoffController.text.isEmpty
                            ? 'Enter pickup and drop-off locations'
                            : 'Add recipient name and phone number',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentChip(String method, IconData icon, String label, Color color) {
    final selected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey[200]!,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey[400], size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected ? color : Colors.grey[500],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder(AuthProvider auth, OrderProvider orders) async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill pickup and drop-off locations')),
      );
      return;
    }
    if (_recipientNameController.text.trim().isEmpty || _recipientPhoneController.text.trim().isEmpty) {
      setState(() => _showRecipientFields = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add recipient name and phone number')),
      );
      return;
    }

    if (_pickupLat == null) {
      final coords = _getJosCoordinates(_pickupController.text);
      _pickupLat = coords['lat'];
      _pickupLng = coords['lng'];
    }
    if (_dropoffLat == null) {
      final coords = _getJosCoordinates(_dropoffController.text);
      _dropoffLat = coords['lat'];
      _dropoffLng = coords['lng'];
    }

    final result = await orders.createOrder(
      token: auth.token,
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      pickupAddress: _pickupController.text.trim(),
      dropoffLat: _dropoffLat!,
      dropoffLng: _dropoffLng!,
      dropoffAddress: _dropoffController.text.trim(),
      itemType: _selectedItemType,
      paymentMethod: _paymentMethod == 'TRANSFER' ? 'CARD' : _paymentMethod,
      itemNote: _noteController.text.trim(),
      senderPhone: auth.user?.phone ?? '',
      recipientName: _recipientNameController.text.trim(),
      recipientPhone: _recipientPhoneController.text.trim(),
    );

    if (result != null && result['order'] != null && context.mounted) {
      final breakdown = result['breakdown'];
      final order = result['order'];
      final totalAmount = (breakdown['total'] as num).toDouble();

      if (_paymentMethod == 'TRANSFER') {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FlutterwaveScreen(
            email: 'payments@ryaniva.com.ng',
            phone: auth.user?.phone ?? '',
            name: auth.user?.name ?? 'Ryaniva Customer',
            amount: totalAmount,
            orderId: order['id'],
            paymentOption: 'banktransfer',
            onPaymentComplete: (success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '✅ Payment successful!' : '❌ Payment cancelled')),
                );
              }
            },
          ),
        ));
        if (context.mounted) Navigator.pop(context);
        return;
      }

      if (_paymentMethod == 'CARD') {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FlutterwaveScreen(
            email: '${auth.user?.phone ?? ''}@ryaniva.com',
            phone: auth.user?.phone ?? '',
            name: auth.user?.name ?? 'Ryaniva Customer',
            amount: totalAmount,
            orderId: order['id'],
            paymentOption: 'card',
            onPaymentComplete: (success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '✅ Payment successful!' : '❌ Payment cancelled')),
                );
              }
            },
          ),
        ));
        if (context.mounted) Navigator.pop(context);
        return;
      }

      // CASH — show summary
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.green, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Order Placed! 🎉',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('A rider is being assigned to your delivery',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to pay', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Text('₦${breakdown['total']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Please have exact cash ready for the rider',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Track my order', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}