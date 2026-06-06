import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackScreen extends StatefulWidget {
  final String email;
  final double amount;
  final String orderId;
  final Function(bool success) onPaymentComplete;

  const PaystackScreen({
    super.key,
    required this.email,
    required this.amount,
    required this.orderId,
    required this.onPaymentComplete,
  });

  @override
  State<PaystackScreen> createState() => _PaystackScreenState();
}

class _PaystackScreenState extends State<PaystackScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  // Replace with Mrs Magit's live key when she gets her account
  static const String _paystackPublicKey = 'pk_test_xxxxxxxxxxxxxxxxxxxx';

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    final amountInKobo = (widget.amount * 100).toInt();
    final ref = 'ryaniva_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ryaniva Payment</title>
  <script src="https://js.paystack.co/v1/inline.js"></script>
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
    .container {
      text-align: center;
      padding: 24px;
    }
    .logo { font-size: 24px; font-weight: bold; color: #1A3A8F; margin-bottom: 8px; }
    .amount { font-size: 32px; font-weight: bold; color: #E85C1A; margin: 16px 0; }
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
    <p style="color:#888; font-size:13px;">Order #${widget.orderId.substring(0, 8)}</p>
    <button class="btn" onclick="payWithPaystack()">Pay Now</button>
    <button class="cancel" onclick="cancelPayment()">Cancel</button>
  </div>

  <script>
    function payWithPaystack() {
      var handler = PaystackPop.setup({
        key: '$_paystackPublicKey',
        email: '${widget.email}',
        amount: $amountInKobo,
        ref: '$ref',
        currency: 'NGN',
        callback: function(response) {
          window.PaystackFlutter.postMessage('success:' + response.reference);
        },
        onClose: function() {
          window.PaystackFlutter.postMessage('cancelled');
        }
      });
      handler.openIframe();
    }

    function cancelPayment() {
      window.PaystackFlutter.postMessage('cancelled');
    }

    window.onload = function() {
      setTimeout(payWithPaystack, 500);
    }
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaystackFlutter',
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
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        foregroundColor: Colors.white,
        title: const Text('Secure Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
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