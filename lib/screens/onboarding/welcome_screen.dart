import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const darkBlue = Color(0xFF0D2260);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png', height: 80),
                          const SizedBox(height: 12),
                          const Text('RYANIVA',
                            style: TextStyle(color: Colors.white, fontSize: 28,
                                fontWeight: FontWeight.bold, letterSpacing: 3)),
                          const SizedBox(height: 4),
                          Text('BUSINESS SERVICES',
                            style: TextStyle(color: Colors.white.withOpacity(0.6),
                                fontSize: 12, letterSpacing: 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: orange.withOpacity(0.5), width: 0.5),
                      ),
                      child: Text('Now live in Jos, Nigeria',
                        style: TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text('Connecting Places,\nDelivering Possibilities.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 26,
                            fontWeight: FontWeight.bold, height: 1.3)),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Request a rider in seconds. Track every move in real time. Pay your way — cash or card.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.6),
                            fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 80),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a1a5c),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
                      ),
                      child: Column(
                        children: [
                          Container(width: 36, height: 4,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 14),
                          Image.asset('assets/images/logo.png', height: 36),
                          const SizedBox(height: 6),
                          Text('Welcome to Ryaniva',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                          const SizedBox(height: 10),
                          _mockInput('Phone Number', '0801 234 5678'),
                          const SizedBox(height: 5),
                          _mockInput('Password', '••••••••'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Sign In', textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _statBox('3', 'User roles', orange),
                          const SizedBox(width: 8),
                          _statBox('60s', 'Match time', orange),
                          const SizedBox(width: 8),
                          _statBox('24/7', 'Tracking', orange),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _featureRow(Icons.map_outlined, blue, 'Real-time GPS tracking',
                              'Watch your rider on a live map from pickup to your door.'),
                          const SizedBox(height: 12),
                          _featureRow(Icons.payments_outlined, orange, 'Pay your way',
                              'Cash on delivery or Paystack — card, bank transfer, USSD.'),
                          const SizedBox(height: 12),
                          _featureRow(Icons.calculate_outlined, blue, 'Transparent pricing',
                              '₦500 base fare + ₦80/km. See the exact price before you confirm.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: darkBlue,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                      label: const Text('Get Started',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('I already have an account', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockInput(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
          Text(value, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _statBox(String number, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
        child: Column(
          children: [
            Text(number, style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.55),
                    fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}