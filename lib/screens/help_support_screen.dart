import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    final faqs = [
      {
        'q': 'How do I request a delivery?',
        'a': 'Tap "Send Package" or any service on the home screen. Enter your pickup and drop-off location, select your payment method and confirm.'
      },
      {
        'q': 'How is the delivery price calculated?',
        'a': '₦800 base fare + ₦150 per kilometer based on actual road distance. You see the full price before confirming.'
      },
      {
        'q': 'Can I cancel an order?',
        'a': 'Yes — you can cancel an order before the rider picks up your item. Once picked up, cancellation is not available.'
      },
      {
        'q': 'What payment methods are accepted?',
        'a': 'We accept Cash on Delivery, Card payment, and Bank Transfer via Flutterwave.'
      },
      {
        'q': 'How do I track my delivery?',
        'a': 'Go to the Track tab at the bottom of the app. Active orders update automatically every 10 seconds.'
      },
      {
        'q': 'How do I rate my rider?',
        'a': 'After your order is delivered, tap "Rate & Tip Rider" on the order card. You can give a star rating, leave a comment and add a tip.'
      },
      {
        'q': 'What areas do you cover?',
        'a': 'We currently operate in Jos, Plateau State. We are expanding to more areas soon.'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Help & Support',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Need help?',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Our team is ready to assist you',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.email_outlined, color: Colors.white, size: 22),
                              const SizedBox(height: 6),
                              const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              const Text('info@ryaniva.com.ng',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.language_outlined, color: Colors.white, size: 22),
                              const SizedBox(height: 6),
                              const Text('Website', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              const Text('ryaniva.com.ng',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text('Frequently Asked Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2260))),
            const SizedBox(height: 16),

            ...faqs.map((faq) => _FAQItem(question: faq['q']!, answer: faq['a']!)),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Can\'t find what you\'re looking for? Email us at info@ryaniva.com.ng and we\'ll get back to you within 24 hours.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(widget.question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        iconColor: blue,
        collapsedIconColor: Colors.grey,
        onExpansionChanged: (val) => setState(() => _expanded = val),
        children: [
          Text(widget.answer,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }
}