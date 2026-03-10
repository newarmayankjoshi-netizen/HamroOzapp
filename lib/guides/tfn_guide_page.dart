import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'guide_helpers.dart';
import 'tfn_guide_nepali_page.dart';

class TFNGuidePage extends StatelessWidget {
  final String title;
  final String? link;

  const TFNGuidePage({super.key, required this.title, this.link});

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: buildGuideAppBar(title),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('🇦🇺', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Apply for a Tax File Number (TFN)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'For Australian Residents',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  // Button to open Nepali translation page
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TFNGuideNepaliPage(link: link),
                        ),
                      );
                    },
                    icon: Text('🇳🇵', style: TextStyle(fontSize: 18)),
                    label: Text('नेपालीमा पढ्नुहोस्'),
                  ),
                  if (link != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (link == null) return;
                        final uri = Uri.parse(link!);
                        bool opened = false;
                        try {
                          opened = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          opened = false;
                        }
                        if (!opened) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Could not open link')),
                          );
                        }
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),

              // Eligibility
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
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "1. Check if You're Eligible",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can apply for a TFN if:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• You live in Australia'),
                            Text('• You are 15 years or older'),
                            Text('• You have the required identity documents'),
                            SizedBox(height: 6),
                            Text(
                              'A TFN is free and you only need to apply once.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Apply Online
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
                          Icon(Icons.public, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '3. Apply Online',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Go to the ATO TFN application page'),
                            Text('• Select "Australian residents"'),
                            Text('• Fill in your personal details'),
                            Text('• Submit the form'),
                            Text(
                              '• Save or print the application summary (you\'ll need it for identity check)',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      if (link != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(link!);
                              bool opened = false;
                              try {
                                opened = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                opened = false;
                              }
                              if (!opened) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open link'),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.open_in_new),
                            label: Text('Open ATO TFN page'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Verify at Australia Post
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
                          Icon(Icons.local_post_office, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            '4. Verify Your Identity at Australia Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Within 30 days of submitting the online form:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Visit a participating Australia Post outlet',
                            ),
                            Text('• Bring your identity documents'),
                            Text('• Bring your printed application summary'),
                            SizedBox(height: 6),
                            Text(
                              'Australia Post will verify your identity and send your application to the ATO. This service is free.',
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Gungahlin Post Office supports TFN identity checks, so it\'s convenient for you.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Receive TFN
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
                          Icon(Icons.mail_outline, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            '5. Receive Your TFN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The ATO will mail your TFN to your postal address',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Processing time: up to 28 days',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Keep your TFN safe and do not share it unless necessary (e.g., employer, bank, ATO).',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Quick Summary
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
                        'Quick Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Table(
                        columnWidths: {0: FixedColumnWidth(40)},
                        children: [
                          TableRow(
                            children: [Text('1'), Text('Check eligibility')],
                          ),
                          TableRow(
                            children: [
                              Text('2'),
                              Text('Gather identity documents'),
                            ],
                          ),
                          TableRow(
                            children: [Text('3'), Text('Apply online via ATO')],
                          ),
                          TableRow(
                            children: [
                              Text('4'),
                              Text('Verify identity at Australia Post'),
                            ],
                          ),
                          TableRow(
                            children: [Text('5'), Text('Wait for TFN letter')],
                          ),
                        ],
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
