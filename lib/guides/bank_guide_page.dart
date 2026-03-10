import 'package:flutter/material.dart';
import 'guide_helpers.dart';
import 'bank_guide_nepali_page.dart';

class BankGuidePage extends StatelessWidget {
  final String title;

  const BankGuidePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('How to Open a Bank Account'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🇦🇺💳', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Open a Bank Account in Australia',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'For Nepalese Newcomers',
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
                          builder: (_) => BankGuideNepaliPage(),
                        ),
                      );
                    },
                    icon: Text('🇳🇵', style: TextStyle(fontSize: 18)),
                    label: Text('नेपालीमा पढ्नुहोस्'),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 1. Choose a Bank
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
                            '1. Choose a Bank',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Major banks:'),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Commonwealth Bank (CBA) – popular for international students',
                            ),
                            Text('• ANZ'),
                            Text('• Westpac'),
                            Text('• NAB'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'What to look for:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• No monthly fees (many banks waive fees for students)',
                            ),
                            Text('• Easy mobile app'),
                            Text('• Nepalese-friendly onboarding'),
                            Text(
                              '• ATM availability near your suburb (e.g., Gungahlin, Civic)',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 2. Decide When to Apply
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
                          Icon(Icons.schedule, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            '2. Decide When to Apply',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('You can open an account before arrival:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Apply online from Nepal'),
                            Text('• Activate the account after you land'),
                            Text(
                              '• Bring your passport to the bank branch for identity verification',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Or after arrival:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Apply online or visit a branch'),
                            Text(
                              '• Use your passport + visa + address in Australia',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 3. Documents You Need
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
                            '3. Documents You Need',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Banks follow the Australian "100-point ID system." For Nepalese newcomers, the most common combination is:',
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Required:'),
                            Text('• Nepalese passport'),
                            Text('• Australian visa (student, work, PR, etc.)'),
                            Text(
                              "• Australian address (temporary is fine: friend's house, hotel, Airbnb)",
                            ),
                            SizedBox(height: 6),
                            Text('Optional (helps if you have them):'),
                            Text('• TFN (not mandatory, but recommended)'),
                            Text("• Student ID (if you're a student)"),
                            Text('• Driver licence (if you have one)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 4. Apply Online
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
                            '4. Apply Online (Most Common Method)',
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
                            Text("• Visit the bank's website"),
                            Text('• Select "Open an account"'),
                            Text('• Choose account type (Everyday/Student)'),
                            Text('• Enter your personal details'),
                            Text('• Upload passport details'),
                            Text('• Provide your Australian address'),
                            Text('• Submit the application'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You will receive a confirmation email, instructions for identity verification, and your new account number.',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 5. Verify
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
                          Icon(Icons.verified_user, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '5. Verify Your Identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Within 30 days, visit a bank branch with:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Your passport'),
                            Text('• Your visa'),
                            Text('• Your application confirmation email'),
                            Text(
                              'The bank staff will verify your identity and activate your account.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 6. Receive Debit Card
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
                          Icon(Icons.credit_card, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            '6. Receive Your Debit Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'After activation, your debit card will be mailed to your address (3–7 business days). You can also pick it up at a branch.',
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Activate it via the bank app, set your PIN, and add to Apple Pay/Google Wallet.',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 7. Mobile Banking
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
                          Icon(Icons.phone_android, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            '7. Set Up Mobile Banking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Download your bank's app (e.g., CommBank, ANZ, Westpac, NAB). Use it to check balance, transfer money, pay bills, receive salary, and send money to Nepal.",
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Top 5 Banks
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
                            'Top 5 Banks',
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
                            children: [Text('1'), Text('Choose a bank')],
                          ),
                          TableRow(
                            children: [
                              Text('2'),
                              Text('Apply online (before or after arrival)'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('3'),
                              Text('Prepare passport + visa + address'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('4'),
                              Text('Verify identity at a branch'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('5'),
                              Text('Receive and activate debit card'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('6'),
                              Text('Set up mobile banking'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('7'),
                              Text('Start using your account'),
                            ],
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
