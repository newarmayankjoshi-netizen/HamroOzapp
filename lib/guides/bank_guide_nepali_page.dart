import 'package:flutter/material.dart';
import 'guide_helpers.dart';

class BankGuideNepaliPage extends StatelessWidget {
  const BankGuideNepaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('बैंक खोल्ने गाइड (नेपाली)'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🇳🇵', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'बैंक खाता कसरी खोल्ने',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'नेपालबाट नयाँ आउनेहरूका लागि',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

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
                          Icon(Icons.account_balance, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            '1. बैंक छनौट गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'प्रमुख बैंकहरू: Commonwealth Bank (CBA), ANZ, NAB, Westpac, Bank Australia',
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
                          Icon(Icons.badge_outlined, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            '2. कागजातहरू',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'पासपोर्ट, भिसा, र अष्ट्रेलियाली ठेगाना आवश्यक हुन्छ।',
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
                          Icon(Icons.public, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '3. अनलाइन आवेदन',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'बैंकको वेबसाइटमा गएर "Open an account" रोज्नुहोस् र निर्देशनहरू पालना गर्नुहोस्।',
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
                          Icon(Icons.account_balance, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            'Top 5 बैंकहरू',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      bankLinkRow(
                        context,
                        'Commonwealth Bank (CBA)',
                        'https://www.commbank.com.au/banking/bank-accounts.html',
                      ),
                      bankLinkRow(
                        context,
                        'ANZ (Australia & New Zealand Banking Group)',
                        'https://www.anz.com.au/personal/bank-accounts/open-account/',
                      ),
                      bankLinkRow(
                        context,
                        'NAB (National Australia Bank)',
                        'https://www.nab.com.au/personal/bank-accounts/open-account',
                      ),
                      bankLinkRow(
                        context,
                        'Westpac',
                        'https://www.westpac.com.au/personal-banking/bank-accounts/open-account/',
                      ),
                      bankLinkRow(
                        context,
                        'Bank Australia (Customer‑owned)',
                        'https://www.bankaust.com.au/support/opening-a-bank-australia-account',
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
