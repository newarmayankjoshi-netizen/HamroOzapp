import 'package:flutter/material.dart';
import 'guide_helpers.dart';
import 'transport_navigation_guide_nepali_page.dart';

class TransportNavigationGuidePage extends StatelessWidget {
  const TransportNavigationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('Transportation and Navigation Guide'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransportNavigationGuideNepaliPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.translate),
                  label: Text('नेपालीमा पढ्नुहोस्'),
                ),
              ),
              SizedBox(height: 12),

              Text(
                '🚍 Transport & Navigation Guide for Nepalese Students in Australia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This guide explains how to use buses, trains, trams, timetables, concession cards, Google Maps, and airport transport in a simple, step‑by‑step way.',
                style: TextStyle(color: Colors.black54),
              ),
              SizedBox(height: 16),

              // 1. Buses, Trains, Trams
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚆 1. How to Use Buses, Trains, and Trams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Buses',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('• Bus stops are marked with a pole or shelter'),
                      Text('• Check the route number on the bus'),
                      Text('• Enter from the front door'),
                      Text(
                        '• Tap your transport card (Opal/Myki/GoCard/MyWay)',
                      ),
                      Text('• Press the stop button before your stop'),
                      Text(
                        '• Exit from the back or front door depending on the bus',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Buses may not stop unless you wave your hand'),
                      Text('• Always tap off unless your city says otherwise'),
                      SizedBox(height: 12),
                      Text(
                        'Trains',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('• Stations have platforms with clear signs'),
                      Text(
                        '• Check the direction (e.g., "City Circle", "Flinders Street", "Central")',
                      ),
                      Text('• Tap on at the station gate'),
                      Text('• Wait behind the yellow line'),
                      Text('• Tap off when you exit'),
                      SizedBox(height: 8),
                      Text(
                        'Tips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Trains run less frequently at night'),
                      Text(
                        '• Some cities have express trains that skip stations',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Trams (Melbourne, Adelaide, Gold Coast)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('• Enter from any door'),
                      Text(
                        '• Tap on using Myki (Melbourne) or GoCard (Gold Coast)',
                      ),
                      Text('• Tap off when leaving'),
                      Text(
                        '• Melbourne CBD has a Free Tram Zone — no tapping needed',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Trams can get crowded during peak hours'),
                      Text(
                        '• Always check if your stop is inside the free zone',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 2. Timetables
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 2. How to Read Timetables',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Most students struggle with this at first. Here's the simple way:",
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Where to find timetables',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Google Maps'),
                      Text(
                        '• Transport apps (Opal, Myki, Translink, Transport Canberra)',
                      ),
                      Text('• Bus stop displays'),
                      Text('• Train station screens'),
                      SizedBox(height: 12),
                      Text(
                        'What to look for',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Route number (e.g., Bus 300, Tram 86)'),
                      Text('• Direction (towards city or suburb)'),
                      Text('• Departure time'),
                      Text('• Platform number (for trains)'),
                      SizedBox(height: 12),
                      Text(
                        'Peak vs Off‑Peak',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Peak = more expensive, more crowded'),
                      Text('• Off‑peak = cheaper, quieter'),
                      SizedBox(height: 12),
                      Text(
                        'Important tip',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "If the timetable says \"Every 10 minutes\", it means the bus/tram comes regularly — you don't need exact times.",
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 3. Concession Cards
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎓 3. How to Buy Concession Cards (Student Discounts)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Each state has different rules. Many Nepalese students don't know this and end up paying full fare.",
                      ),
                      SizedBox(height: 12),
                      Text(
                        'NSW (Sydney)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '• International students usually cannot get concession',
                      ),
                      Text('• Must use Adult Opal'),
                      Text(
                        '• Some universities offer limited concessions — check your uni',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'VIC (Melbourne)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '• International students can get a concession if they buy the iUSEpass',
                      ),
                      Text('• Apply through your university'),
                      SizedBox(height: 12),
                      Text(
                        'QLD (Brisbane, Gold Coast)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• International students can get concession'),
                      Text('• Must register your student ID with Translink'),
                      SizedBox(height: 12),
                      Text(
                        'ACT (Canberra)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• International students can get concession'),
                      Text('• Use MyWay Concession'),
                      SizedBox(height: 12),
                      Text(
                        'How to apply:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Visit your university website'),
                      Text('• Provide student ID'),
                      Text('• Link your transport card'),
                      Text('• Wait for approval'),
                      SizedBox(height: 12),
                      Text(
                        'Warning:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Using someone else's concession card can result in heavy fines.",
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 4. Google Maps
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🗺️ 4. How to Use Google Maps Effectively',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Google Maps is the easiest way to navigate Australia.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Steps:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Open Google Maps'),
                      Text('• Enter your destination'),
                      Text('• Tap Directions'),
                      Text('• Select the public transport icon'),
                      Text('• Choose the best route'),
                      Text('• Follow the step‑by‑step instructions'),
                      SizedBox(height: 12),
                      Text(
                        'What Google Maps shows:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Which bus/train/tram to take'),
                      Text('• Exact departure time'),
                      Text('• Platform number'),
                      Text('• Walking directions'),
                      Text('• Tap on/off reminders'),
                      Text('• Real‑time delays'),
                      SizedBox(height: 12),
                      Text(
                        'Tips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Save your home and university as favourites'),
                      Text('• Download offline maps'),
                      Text('• Use "Depart at" or "Arrive by" to plan ahead'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 5. Airport Transport
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✈️ 5. Airport to City Transport Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Every city has different airport transport. Here's the simple breakdown:",
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Sydney',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Airport Train (expensive but fast)'),
                      Text('• Bus 420 (cheap but slower)'),
                      Text('• Uber, Ola, Didi'),
                      Text('• Shuttle buses'),
                      SizedBox(height: 12),
                      Text(
                        'Melbourne',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• SkyBus (airport to city)'),
                      Text('• Public buses (cheaper)'),
                      Text('• Uber, Ola, Didi'),
                      SizedBox(height: 12),
                      Text(
                        'Brisbane',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Airtrain (fast)'),
                      Text('• Public buses'),
                      Text('• Uber, Ola, Didi'),
                      SizedBox(height: 12),
                      Text(
                        'Canberra',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Bus Route 3 or 11'),
                      Text('• Uber, Ola, Didi'),
                      Text('• Airport shuttle'),
                      SizedBox(height: 12),
                      Text(
                        'Tips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '• Avoid airport train stations if you want to save money (Sydney surcharge is high)',
                      ),
                      Text(
                        '• Always check Google Maps for the cheapest option',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
