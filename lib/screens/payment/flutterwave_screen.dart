import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlutterwaveScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String name;
  final double amount;
  final String orderId;
  final String paymentOption;
  final Function(bool success) onPaymentComplete;

  const FlutterwaveScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.name,
    required this.amount,
    required this.orderId,
    required this.onPaymentComplete,
    this.paymentOption = 'card',
  });

  @override
  State<FlutterwaveScreen> createState() => _FlutterwaveScreenState();
}

class _FlutterwaveScreenState extends State<FlutterwaveScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static const String _flutterwavePublicKey =
      'FLWPUBK-de7f05a23d41637e5223b1d4939f4dd9-X';

  String _sanitize(String input) {
    return input
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\n', '')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    final ref =
        'ryaniva_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';

    String safeEmail = _sanitize(widget.email);
    if (safeEmail.isEmpty ||
        !safeEmail.contains('@') ||
        !safeEmail.contains('.')) {
      safeEmail = 'customer@ryaniva.com';
    }

    String safePhone = _sanitize(widget.phone);
    if (safePhone.isEmpty) safePhone = '08000000000';

    String safeName = _sanitize(widget.name);
    if (safeName.isEmpty) safeName = 'Ryaniva Customer';

    // Set payment options based on selection
    final paymentOptions = widget.paymentOption == 'banktransfer'
        ? 'banktransfer'
        : widget.paymentOption == 'ussd'
            ? 'ussd'
            : 'card, banktransfer, ussd';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ryaniva Payment</title>
  <script src="https://checkout.flutterwave.com/v3.js"></script>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: #f8f9fa;
    }
    .container { text-align: center; padding: 24px; }
    .logo { font-size: 24px; font-weight: bold; color: #1A3A8F; margin-bottom: 8px; }
    .amount { font-size: 32px; font-weight: bold; color: #E85C1A; margin: 16px 0; }
    .method { font-size: 13px; color: #6B7280; margin-bottom: 8px; }
    .btn {
      background: #1A3A8F;
      color: white;
      border: none;
      padding: 16px 40px;
      border-radius: 12px;
      font-size: 16px;
      cursor: pointer;
      width: 100%;
      margin-top: 16px;
    }
    .cancel {
      background: transparent;
      color: #666;
      border: 1px solid #ddd;
      padding: 12px 40px;
      border-radius: 12px;
      font-size: 14px;
      cursor: pointer;
      width: 100%;
      margin-top: 8px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">RYANIVA</div>
    <p style="color:#666; margin:0;">Delivery Payment</p>
    <div class="amount">₦${widget.amount.toStringAsFixed(0)}</div>
    <p class="method">${widget.paymentOption == 'banktransfer' ? '🏦 Bank Transfer' : widget.paymentOption == 'ussd' ? '📱 USSD' : '💳 Card Payment'}</p>
    <p style="color:#888; font-size:13px;">Order #${widget.orderId.substring(0, 8)}</p>
    <button class="btn" onclick="payWithFlutterwave()">Pay Now</button>
    <button class="cancel" onclick="cancelPayment()">Cancel</button>
  </div>

  <script>
    function payWithFlutterwave() {
      FlutterwaveCheckout({
        public_key: "$_flutterwavePublicKey",
        tx_ref: "$ref",
        amount: ${widget.amount},
        currency: "NGN",
        payment_options: "$paymentOptions",
        customer: {
          email: "$safeEmail",
          phone_number: "$safePhone",
          name: "$safeName",
        },
        customizations: {
          title: "Ryaniva Business Services",
          description: "Delivery Payment",
          logo: "",
        },
        callback: function (data) {
          window.FlutterwaveFlutter.postMessage("success:" + data.transaction_id);
        },
        onclose: function () {
          window.FlutterwaveFlutter.postMessage("cancelled");
        },
      });
    }

    function cancelPayment() {
      window.FlutterwaveFlutter.postMessage("cancelled");
    }

    window.onload = function () {
      setTimeout(payWithFlutterwave, 500);
    }
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterwaveFlutter',
        onMessageReceived: (JavaScriptMessage message) {
          final msg = message.message;
          if (msg.startsWith('success:')) {
            widget.onPaymentComplete(true);
            if (mounted) Navigator.pop(context);
          } else if (msg == 'cancelled') {
            widget.onPaymentComplete(false);
            if (mounted) Navigator.pop(context);
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadHtmlString(htmlContent,
          baseUrl: 'https://ryaniva-backend.onrender.com');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        foregroundColor: Colors.white,
        title: Text(
          widget.paymentOption == 'banktransfer'
              ? 'Bank Transfer'
              : widget.paymentOption == 'ussd'
                  ? 'USSD Payment'
                  : 'Card Payment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentComplete(false);
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1A3A8F)),
                  SizedBox(height: 16),
                  Text('Loading secure payment...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}