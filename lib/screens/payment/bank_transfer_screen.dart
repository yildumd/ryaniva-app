import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class BankTransferScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String token;
  final Function(bool success) onPaymentComplete;

  const BankTransferScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.token,
    required this.onPaymentComplete,
  });

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  bool _loading = true;
  String? _accountNumber;
  String? _bankName;
  String? _error;
  Timer? _timer;
  int _timeLeft = 600;

  @override
  void initState() {
    super.initState();
    _initTransfer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initTransfer() async {
    try {
      final res = await ApiService.post(
        '/orders/${widget.orderId}/bank-transfer',
        {'amount': widget.amount},
        token: widget.token,
      );
      setState(() {
        _accountNumber = res['accountNumber'];
        _bankName = res['bankName'];
        _loading = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            timer.cancel();
          }
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate account number. Please try again.';
        _loading = false;
      });
    }
  }

  String get _formattedTime {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account number copied!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Bank Transfer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentComplete(false);
            Navigator.pop(context);
          },
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1A3A8F)),
                  SizedBox(height: 16),
                  Text('Generating account number...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _initTransfer();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Amount card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text('Amount to Transfer',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('₦${widget.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Expires in $_formattedTime',
                                      style: TextStyle(
                                          color: _timeLeft < 60
                                              ? Colors.red[300]
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Transfer the exact amount to the account below. Your order will be confirmed automatically once payment is received.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account details
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Transfer To',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0D2260))),
                            const SizedBox(height: 16),
                            _detailRow('Bank Name',
                                _bankName ?? 'Wema Bank'),
                            const Divider(height: 24),
                            _detailRow('Account Name',
                                'Ryaniva Business Services'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Account Number',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _accountNumber ?? '0000000000',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: Color(0xFF1A3A8F)),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(
                                      _accountNumber ?? ''),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: blue,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.copy,
                                            color: Colors.white,
                                            size: 16),
                                        SizedBox(width: 6),
                                        Text('Copy',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _detailRow('Amount',
                                '₦${widget.amount.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Warning
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_outlined,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Transfer the EXACT amount shown. Wrong amounts may cause payment failure.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onPaymentComplete(true);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'I Have Made the Transfer',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            widget.onPaymentComplete(false);
                            Navigator.pop(context);
                          },
                          child: Text('Cancel',
                              style:
                                  TextStyle(color: Colors.grey[500])),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}