import 'package:flutter/material.dart';
import 'guide_helpers.dart';
import 'immigration_guide_nepali_page.dart';

class ImmigrationGuidePage extends StatelessWidget {
  const ImmigrationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar(
        'Guide: What to Expect During Immigration Check',
      ),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🇦🇺✈️', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guide: What to Expect During Immigration Check When Entering Australia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'This guide explains exactly what happens from the moment you step off the plane until you exit the airport. It\'s written for Nepalese travellers arriving in Australia for the first time.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ImmigrationGuideNepaliPage(),
                        ),
                      );
                    },
                    icon: Text('🇳🇵', style: TextStyle(fontSize: 18)),
                    label: Text('नेपालीमा पढ्नुहोस्'),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flight_land, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '1. After Landing — Follow the "Arrivals" Signs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Once you get off the plane, follow the yellow "Arrivals / Baggage Claim" signs. You will walk towards Immigration / Passport Control.',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_box, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            '2. Immigration (Passport Control)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('At immigration, an officer will check:'),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Your passport'),
                            Text('• Your visa (electronically linked)'),
                            Text('• Your arrival card (if required)'),
                            Text('• Your face (identity check)'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Common questions they may ask:'),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Why are you coming to Australia?'),
                            Text('How long will you stay?'),
                            Text('Where will you stay?'),
                            Text(
                              'Do you have enough money to support yourself?',
                            ),
                            Text('Do you know anyone in Australia?'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tips for Nepalese travellers:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keep your passport, visa grant letter, and address of your accommodation ready.',
                            ),
                            Text(
                              'If you\'re a student, keep your CoE (Confirmation of Enrolment) handy.',
                            ),
                            Text(
                              'If you\'re on a work visa, keep your job offer letter or sponsor details.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_travel, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            '3. Collect Your Baggage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'After immigration, follow the signs to Baggage Claim.',
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Look for your flight number on the screens'),
                            Text('Collect your bags'),
                            Text('Use a trolley if needed (usually free)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '4. Biosecurity & Customs (Very Important in Australia)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Australia has strict rules about what you can bring in. You MUST declare if you have:',
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Food (even snacks, dried food, noodles, pickles)',
                            ),
                            Text('• Medicines'),
                            Text('• Wood items'),
                            Text('• Seeds or plants'),
                            Text('• Animal products'),
                            Text('• Cash over AUD 10,000'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Declaring is not a problem — hiding is.'),
                      SizedBox(height: 8),
                      Text('If you declare:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Officers will check your items'),
                            Text('• If allowed, they return them'),
                            Text('• If not allowed, they dispose of them'),
                            Text(
                              '• You will NOT get fined if you declared honestly',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('If you don\'t declare:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• You can be fined up to AUD 2,664'),
                            Text(
                              '• In serious cases, your visa can be cancelled',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            '5. Baggage Scan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your bags may be scanned or checked by a dog. This is normal — don\'t panic.',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '6. Exit the Airport',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'After customs, you walk out into the arrivals hall.',
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SIM card shops'),
                            Text('Currency exchange'),
                            Text('ATMs'),
                            Text('Transport options (Uber, taxi, train, bus)'),
                            Text('Friends or family waiting'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                color: Colors.grey[50],
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌟 Quick Checklist for Nepalese Travellers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Keep these documents in your hand luggage:'),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Passport'),
                            Text('• Visa grant letter'),
                            Text('• Address of your stay'),
                            Text('• CoE (students)'),
                            Text('• Job offer/sponsor letter (workers)'),
                            Text('• Return ticket (if visitor visa)'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Do NOT pack these in checked luggage:'),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Passport'),
                            Text('• Visa documents'),
                            Text('• Money'),
                            Text('• Electronics'),
                            Text('• Medicines you need during travel'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mood, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            '🧘 Tips to Stay Confident',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Immigration officers are friendly and professional',
                      ),
                      Text(
                        'They are not trying to reject you — they just verify your details',
                      ),
                      Text('Speak clearly and honestly'),
                      SizedBox(height: 6),
                      Text(
                        'If you don\'t understand a question, say:\n"Sorry, could you repeat that?"',
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Keep calm — thousands of Nepalese enter Australia every month without issues',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
