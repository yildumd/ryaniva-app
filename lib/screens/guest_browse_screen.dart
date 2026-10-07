import 'package:flutter/material.dart';
import 'auth/register_screen.dart';

const _blue = Color(0xFF1A3A8F);
const _orange = Color(0xFFE85C1A);
const _bg = Color(0xFFF5F6FA);

class GuestBrowseScreen extends StatelessWidget {
  const GuestBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Explore Ryaniva',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fast delivery across Jos',
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Packages, food, documents and more — delivered in minutes.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7),
                          fontSize: 14, height: 1.5)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pricing section
            const Text('Transparent Pricing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _priceRow('Base fare', '₦800', 'Starting price for every delivery'),
                const Divider(height: 24),
                _priceRow('Per kilometer', '₦150/km', 'Added based on distance'),
                const Divider(height: 24),
                _priceRow('Example (5km)', '₦1,550', '₦800 + (5 × ₦150)'),
              ]),
            ),

            const SizedBox(height: 24),

            // Services section
            const Text('What we deliver',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _serviceCard(Icons.inventory_2_outlined, 'Packages', _blue),
                _serviceCard(Icons.fastfood_outlined, 'Food', _orange),
                _serviceCard(Icons.description_outlined, 'Documents', Colors.purple),
                _serviceCard(Icons.more_horiz, 'Other items', Colors.teal),
              ],
            ),

            const SizedBox(height: 24),

            // How it works
            const Text('How it works',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _step('1', 'Create an account', 'Sign up in under a minute'),
                _step('2', 'Book a delivery', 'Enter pickup and dropoff location'),
                _step('3', 'Rider picks up', 'A verified rider collects your item'),
                _step('4', 'Track in real time', 'Watch your delivery on a live map'),
                _step('5', 'Pay your way', 'Cash, card or bank transfer'),
              ]),
            ),

            const SizedBox(height: 24),

            // Service area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _blue.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.location_on, color: _blue, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Currently serving Jos, Plateau State, Nigeria',
                      style: TextStyle(fontSize: 13, color: _blue,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Account & Book Delivery',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String price, String desc) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ])),
      Text(price, style: const TextStyle(fontWeight: FontWeight.w800,
          fontSize: 18, color: _orange)),
    ]);
  }

  Widget _serviceCard(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600,
            fontSize: 13, color: color)),
      ]),
    );
  }

  Widget _step(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
          child: Center(child: Text(number,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ])),
      ]),
    );
  }
}