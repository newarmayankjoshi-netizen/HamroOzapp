import 'package:flutter/material.dart';
import 'guide_helpers.dart';
import 'transport_guide_nepali_page.dart';

class TransportGuidePage extends StatelessWidget {
  const TransportGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('Using Transport Cards in Australia'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Link to Nepali version
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransportGuideNepaliPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.translate),
                  label: Text('नेपालीमा पढ्नुहोस्'),
                ),
              ),
              SizedBox(height: 12),

              // 1. OPAL Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚉 1. OPAL Card (New South Wales – Sydney, Newcastle, Blue Mountains)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Where it works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Sydney trains, buses, ferries, light rail'),
                      Text('• Newcastle transport'),
                      Text('• Blue Mountains region'),
                      SizedBox(height: 12),
                      Text(
                        'Step‑by‑step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Get an Opal card',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Airport train stations'),
                      Text('   • Convenience stores (7‑Eleven, newsagents)'),
                      Text('   • Opal retailers'),
                      Text('   • Online (delivered to your address)'),
                      SizedBox(height: 8),
                      Text(
                        '2. Choose the right type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Adult'),
                      Text(
                        '   • Concession (only if your university is eligible)',
                      ),
                      Text('   • Child/Youth'),
                      SizedBox(height: 8),
                      Text(
                        '3. Top up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Opal machines at stations'),
                      Text('   • Retail stores'),
                      Text('   • Opal app'),
                      Text('   • Online auto‑top‑up'),
                      SizedBox(height: 8),
                      Text(
                        '4. Tap on and tap off',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Tap on at the start of your trip'),
                      Text('   • Tap off at the end'),
                      Text(
                        '   • Ferries and light rail also require tapping off',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '5. Daily/weekly caps',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '   You never pay more than a set amount per day or week.',
                      ),
                      Text('   Great for students trying to save money.'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 2. MYKI Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚋 2. MYKI Card (Victoria – Melbourne, Geelong, Ballarat)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Where it works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Melbourne trains, trams, buses'),
                      Text('• Regional buses in some cities'),
                      SizedBox(height: 12),
                      Text(
                        'Step‑by‑step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Get a Myki card',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Train stations'),
                      Text('   • 7‑Eleven stores'),
                      Text('   • Myki machines'),
                      Text('   • Online'),
                      SizedBox(height: 8),
                      Text(
                        '2. Choose Myki Money or Myki Pass',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Myki Money: pay‑as‑you‑go'),
                      Text('   • Myki Pass: unlimited travel for 7 or 28 days'),
                      SizedBox(height: 8),
                      Text(
                        '3. Top up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Myki machines'),
                      Text('   • 7‑Eleven'),
                      Text('   • Online'),
                      Text('   • Myki app'),
                      SizedBox(height: 8),
                      Text(
                        '4. Tap on and tap off',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Tap on when boarding'),
                      Text(
                        '   • Tap off when leaving (except trams in the free tram zone)',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '5. Free Tram Zone (Melbourne CBD)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '   You don\'t need to tap on or off inside the CBD free zone.',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 3. GoCard
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚆 3. GoCard (Queensland – Brisbane, Gold Coast, Sunshine Coast)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Where it works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Brisbane trains, buses, ferries'),
                      Text('• Gold Coast trams'),
                      Text('• Sunshine Coast buses'),
                      SizedBox(height: 12),
                      Text(
                        'Step‑by‑step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Get a GoCard',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Train stations'),
                      Text('   • 7‑Eleven'),
                      Text('   • GoCard retailers'),
                      Text('   • Online'),
                      SizedBox(height: 8),
                      Text(
                        '2. Choose the right type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Adult'),
                      Text('   • Concession (students with valid ID)'),
                      SizedBox(height: 8),
                      Text(
                        '3. Top up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • GoCard machines'),
                      Text('   • Retailers'),
                      Text('   • Online'),
                      Text('   • Auto top‑up'),
                      SizedBox(height: 8),
                      Text(
                        '4. Tap on and tap off',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Tap on at the start'),
                      Text('   • Tap off at the end'),
                      Text('   • Fines apply if you forget'),
                      SizedBox(height: 8),
                      Text(
                        '5. Off‑peak discounts',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   Travel outside peak hours to save money.'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 4. MyWay Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚌 4. MyWay Card (ACT – Canberra)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Where it works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Canberra buses'),
                      Text('• Canberra Light Rail'),
                      SizedBox(height: 12),
                      Text(
                        'Step‑by‑step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Get a MyWay card',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Canberra Connect offices'),
                      Text('   • Light rail stations'),
                      Text('   • Online order'),
                      SizedBox(height: 8),
                      Text(
                        '2. Choose the right type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Adult'),
                      Text('   • Concession (students)'),
                      Text('   • Child'),
                      SizedBox(height: 8),
                      Text(
                        '3. Top up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • MyWay recharge machines'),
                      Text('   • Online'),
                      Text('   • Auto top‑up'),
                      Text('   • Retail stores'),
                      SizedBox(height: 8),
                      Text(
                        '4. Tap on and tap off',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Tap on when boarding'),
                      Text('   • Tap off when leaving'),
                      Text('   • Light rail also requires tapping off'),
                      SizedBox(height: 8),
                      Text(
                        '5. Daily caps',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   You won\'t pay more than a set daily amount.'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Extra Tips
              Text(
                '🎒 Extra Tips for Nepalese Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2193b0),
                ),
              ),
              SizedBox(height: 12),
              Card(
                elevation: 2,
                color: Color(0xFFF5F5F5),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save money by:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Using concession cards (if eligible)'),
                      Text('• Travelling off‑peak'),
                      Text('• Using weekly/daily caps'),
                      Text(
                        '• Avoiding airport stations (expensive surcharges)',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Always:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Keep your card topped up'),
                      Text('• Tap on/off properly'),
                      Text('• Register your card online (helps if lost)'),
                      SizedBox(height: 12),
                      Text(
                        'Avoid:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• Sharing cards'),
                      Text('• Forgetting to tap off'),
                      Text('• Using someone else\'s concession card'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
