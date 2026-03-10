import 'package:flutter/material.dart';
import 'guide_helpers.dart';
import 'accommodation_guide_nepali_page.dart';

class AccommodationGuidePage extends StatelessWidget {
  const AccommodationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('How to Find Accommodation'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How to Find Accommodation in Australia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Step‑by‑Step Guide for Nepalese Newcomers',
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
                          builder: (_) => const AccommodationGuideNepaliPage(),
                        ),
                      );
                    },
                    icon: const Text('🇳🇵', style: TextStyle(fontSize: 18)),
                    label: const Text('नेपालीमा पढ्नुहोस्'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'This guide covers everything from preparing before you fly to securing your first room or rental after landing.',
                    style: TextStyle(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              buildStep(
                '1. Before Leaving Nepal — Prepare Your Accommodation Plan',
                'Do this at least 2–3 weeks before your flight:',
                [
                  'Research the city you\'re going to (Sydney, Melbourne, Brisbane, Canberra, etc.)',
                  'Join Nepalese Facebook groups for that city',
                  'Ask friends or relatives if they know anyone renting rooms',
                  'Save money for the first month (bond: 2–4 weeks rent, advance: 2 weeks, total: AUD 600–1500)',
                  'Create a list of suburbs you prefer (close to transport, university, workplace, safe)',
                ],
              ),
              const SizedBox(height: 12),
              buildStep(
                '2. Book Temporary Stay for 3–7 Days',
                'Never book a long‑term room from Nepal without seeing it. Instead, book: Airbnb, Hostel, Budget hotel, or Stay with a friend.',
                [
                  'This gives you time to inspect rooms in person after landing.',
                ],
              ),
              const SizedBox(height: 12),
              buildStep(
                '3. After Landing — Start Searching for Rooms Immediately',
                'Use these platforms:',
                [
                  'Nepalese Community Apps: Kaam Kotha, Nepali Lai Kaam, uNepal',
                  'Mainstream: Flatmates.com.au, Facebook Marketplace, Facebook Groups, Gumtree, Realestate.com.au',
                  'Search filters: Suburb, Budget, Room type, Move‑in date, Furnished/unfurnished',
                ],
              ),
              const SizedBox(height: 12),
              buildStep(
                '4. Contact Room Owners',
                'When you find a room you like, message the owner politely.',
                [
                  'Ask: How many people live here? Private or shared? What\'s included in rent? Minimum stay? Bond? Move‑in date?',
                ],
              ),
              const SizedBox(height: 12),
              buildStep(
                '5. Inspect the Room (Very Important)',
                'Never pay without inspecting. Check: Cleanliness, ventilation, heating/cooling, kitchen, bathroom, safety, public transport, noise level.',
                [
                  'Red flags: Too many people, no written agreement, owner refuses inspection, very cheap rent',
                ],
              ),
              const SizedBox(height: 12),
              buildStep('6. Understand the Costs', 'Typical weekly rent:', [
                'Sydney: \$180–\$300 | Melbourne: \$160–\$280',
                'Brisbane: \$150–\$250 | Canberra: \$180–\$300',
                'You may pay: Bond (2–4 weeks), Advance rent (2 weeks), Key deposit (\$50–\$100)',
              ]),
              const SizedBox(height: 12),
              buildStep(
                '7. Sign a Simple Agreement',
                'Even for shared rooms, ask for: Written agreement, Rent amount, Bond, Notice period (2 weeks), House rules.',
                ['This protects you from unfair eviction or rent increases.'],
              ),
              const SizedBox(height: 12),
              buildStep('8. Move In', 'Once you agree:', [
                'Pay bond + advance rent, Take photos of room before moving in, Get keys',
                'Ask about: WiFi password, Rubbish days, Laundry rules, Kitchen sharing',
              ]),
              const SizedBox(height: 12),
              buildStep('9. Avoid Common Scams', 'Be careful of:', [
                'People asking for money before inspection',
                'Fake listings on Facebook',
                'Rooms with 6–10 people in one bedroom',
                'Owners refusing receipts',
                'Always trust your instincts.',
              ]),
              const SizedBox(height: 12),
              buildStep('10. Tips for Nepalese Students & Workers', '', [
                'Stay close to public transport',
                'Avoid very cheap rooms — usually overcrowded',
                'Don\'t rush; take 2–3 days to find a good place',
                'Ask seniors or friends for recommendations',
                'Keep emergency money for the first month',
              ]),
              const SizedBox(height: 16),
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
                    children: const [
                      Text(
                        '✓ Quick Summary Checklist',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Before flying: Research suburbs, Join Nepalese groups, Save money',
                        style: TextStyle(height: 1.5),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'After landing: Book temporary stay, Search for rooms, Inspect in person, Pay bond + rent, Move in safely',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
