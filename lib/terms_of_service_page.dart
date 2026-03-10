import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader('Terms of Service'),
          _buildUpdateDate('Last Updated: 5 February 2026'),
          const SizedBox(height: 24),

          _buildSection(
            '1. Acceptance of Terms',
            'By accessing or using the Nepalese in Australia mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must not use the App.\n\n'
            'These Terms constitute a legally binding agreement between you and Nepalese in Australia ("we", "us", or "our"). By creating an account or using any features of the App, you acknowledge that you have read, understood, and agree to be bound by these Terms.',
          ),

          _buildSection(
            '2. Eligibility and User Accounts',
            'You must be at least 18 years of age to use this App. By using the App, you represent and warrant that you are at least 18 years old.\n\n'
            'When you create an account, you agree to:\n'
            '• Provide accurate, current, and complete information\n'
            '• Maintain and promptly update your account information\n'
            '• Keep your password secure and confidential\n'
            '• Notify us immediately of any unauthorized use of your account\n'
            '• Accept responsibility for all activities that occur under your account\n\n'
            'We reserve the right to suspend or terminate accounts that violate these Terms or contain false or misleading information.',
          ),

          _buildSection(
            '3. User Content and Conduct',
            'You are solely responsible for any content you post, upload, or share through the App, including but not limited to job listings, room advertisements, marketplace items, event postings, and comments ("User Content").\n\n'
            'By posting User Content, you represent and warrant that:\n'
            '• You own or have the necessary rights to the content\n'
            '• Your content does not infringe any third-party rights\n'
            '• Your content complies with all applicable Australian laws\n'
            '• Your content is accurate and not misleading\n\n'
            'You grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your User Content within the App.',
          ),

          _buildSection(
            '4. Prohibited Activities',
            'You agree NOT to use the App to:\n'
            '• Post false, misleading, or fraudulent information\n'
            '• Harass, abuse, threaten, or discriminate against others\n'
            '• Violate any Australian federal, state, or local laws\n'
            '• Infringe intellectual property rights\n'
            '• Post spam, unsolicited advertising, or promotional materials\n'
            '• Engage in any form of exploitation or human trafficking\n'
            '• Collect personal information without consent\n'
            '• Impersonate any person or entity\n'
            '• Distribute malware, viruses, or harmful code\n'
            '• Interfere with the App\'s functionality or security\n'
            '• Engage in any illegal activities, including but not limited to violations of the Criminal Code Act 1995 (Cth)\n\n'
            'Violation of these prohibitions may result in immediate account termination and legal action.',
          ),

          _buildSection(
            '5. Job Listings and Employment',
            'Job listings posted on the App must comply with all Australian employment laws, including:\n'
            '• Fair Work Act 2009 (Cth)\n'
            '• Anti-Discrimination Act 1977 (NSW) and equivalent state laws\n'
            '• Work Health and Safety Act 2011 (Cth)\n\n'
            'Employers must not discriminate based on race, gender, age, disability, religion, or any other protected characteristic. All job listings must include accurate descriptions and comply with minimum wage requirements.\n\n'
            'We are not an employment agency and are not responsible for employment relationships formed through the App.',
          ),

          _buildSection(
            '6. Accommodation Listings',
            'Room and accommodation listings must comply with:\n'
            '• Residential Tenancies Act and regulations in the relevant state/territory\n'
            '• Anti-discrimination legislation\n'
            '• Local council regulations\n\n'
            'Landlords and advertisers must provide accurate information about rental properties and must not engage in discriminatory practices. We are not a party to any rental agreements formed through the App.',
          ),

          _buildSection(
            '7. Marketplace and Transactions',
            'The App provides a platform for users to list and purchase goods. We are not involved in transactions between buyers and sellers.\n\n'
            'All transactions must comply with:\n'
            '• Australian Consumer Law\n'
            '• Competition and Consumer Act 2010 (Cth)\n'
            '• State and territory fair trading laws\n\n'
            'Sellers are responsible for accurately describing items, honoring sales, and complying with consumer protection laws. Buyers are responsible for payment and understanding consumer rights.',
          ),

          _buildSection(
            '8. Privacy and Data Protection',
            'Your privacy is important to us. Our collection, use, and disclosure of personal information is governed by our Privacy Policy and complies with:\n'
            '• Privacy Act 1988 (Cth)\n'
            '• Australian Privacy Principles (APPs)\n'
            '• Spam Act 2003 (Cth)\n\n'
            'By using the App, you consent to our collection and use of your information as described in our Privacy Policy. You have the right to access, correct, and request deletion of your personal information.',
          ),

          _buildSection(
            '9. Intellectual Property',
            'All content, features, and functionality of the App, including but not limited to text, graphics, logos, and software, are owned by us or our licensors and are protected by Australian and international copyright, trademark, and other intellectual property laws.\n\n'
            'You may not copy, modify, distribute, sell, or lease any part of the App without our prior written consent.',
          ),

          _buildSection(
            '10. Disclaimers and Warranties',
            'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED.\n\n'
            'To the maximum extent permitted by Australian law, we disclaim all warranties, including but not limited to:\n'
            '• Merchantability and fitness for a particular purpose\n'
            '• Accuracy, reliability, or completeness of content\n'
            '• Uninterrupted or error-free operation\n\n'
            'We do not warrant that the App will meet your requirements or that defects will be corrected. We are not responsible for verifying the accuracy of User Content or the legitimacy of users.',
          ),

          _buildSection(
            '11. Limitation of Liability',
            'To the maximum extent permitted by Australian law, including the Competition and Consumer Act 2010 (Cth):\n\n'
            'We shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, or goodwill, arising from:\n'
            '• Your use or inability to use the App\n'
            '• Unauthorized access to your account or data\n'
            '• User Content or conduct of other users\n'
            '• Transactions between users\n\n'
            'Our total liability shall not exceed the amount you paid us (if any) in the 12 months preceding the claim.\n\n'
            'Nothing in these Terms excludes, restricts, or modifies any guarantee, warranty, term, or condition, right, or remedy implied or imposed by Australian Consumer Law that cannot lawfully be excluded, restricted, or modified.',
          ),

          _buildSection(
            '12. Indemnification',
            'You agree to indemnify, defend, and hold harmless Nepalese in Australia, its officers, directors, employees, and agents from any claims, liabilities, damages, losses, costs, or expenses (including reasonable legal fees) arising from:\n'
            '• Your use of the App\n'
            '• Your violation of these Terms\n'
            '• Your violation of any rights of another person or entity\n'
            '• Your User Content',
          ),

          _buildSection(
            '13. Termination',
            'We reserve the right to suspend or terminate your account and access to the App at any time, with or without notice, for any reason, including but not limited to:\n'
            '• Violation of these Terms\n'
            '• Fraudulent or illegal activity\n'
            '• Requests by law enforcement\n'
            '• Extended periods of inactivity\n\n'
            'You may terminate your account at any time through the App settings. Upon termination, your right to use the App will immediately cease, but certain provisions of these Terms will survive termination.',
          ),

          _buildSection(
            '14. Governing Law and Jurisdiction',
            'These Terms are governed by the laws of New South Wales, Australia, and the Commonwealth of Australia. Any disputes arising from these Terms or your use of the App shall be subject to the exclusive jurisdiction of the courts of New South Wales, Australia.\n\n'
            'If you are a consumer under the Australian Consumer Law, you may have additional rights that cannot be excluded by these Terms.',
          ),

          _buildSection(
            '15. Dispute Resolution',
            'Before commencing legal proceedings, you agree to attempt to resolve any dispute through good faith negotiations. If a dispute cannot be resolved through negotiation within 30 days, either party may refer the matter to mediation in accordance with the Australian Disputes Centre (ADC) Mediation Guidelines.\n\n'
            'Nothing in this clause prevents either party from seeking urgent interlocutory relief from a court.',
          ),

          _buildSection(
            '16. Modifications to Terms',
            'We reserve the right to modify these Terms at any time. We will notify you of material changes by:\n'
            '• Posting the updated Terms in the App\n'
            '• Sending notification to your registered email address\n'
            '• Displaying a notice when you next access the App\n\n'
            'Your continued use of the App after changes become effective constitutes acceptance of the modified Terms. If you do not agree to the changes, you must stop using the App.',
          ),

          _buildSection(
            '17. Severability',
            'If any provision of these Terms is found to be invalid, illegal, or unenforceable by a court of competent jurisdiction, the remaining provisions shall continue in full force and effect. The invalid provision shall be modified to the minimum extent necessary to make it valid and enforceable.',
          ),

          _buildSection(
            '18. Entire Agreement',
            'These Terms, together with our Privacy Policy, constitute the entire agreement between you and us regarding your use of the App and supersede all prior agreements and understandings.',
          ),

          _buildSection(
            '19. Waiver',
            'Our failure to enforce any right or provision of these Terms shall not constitute a waiver of such right or provision. Any waiver of any provision of these Terms must be in writing and signed by us.',
          ),

          _buildSection(
            '20. Third-Party Services',
            'The App may contain links to third-party websites, services, or resources. We are not responsible for the content, policies, or practices of third parties. Your use of third-party services is at your own risk and subject to their respective terms and conditions.',
          ),

          _buildSection(
            '21. Community Standards',
            'We are committed to fostering a safe, respectful, and inclusive community. All users must:\n'
            '• Treat others with respect and dignity\n'
            '• Comply with Australian anti-discrimination laws\n'
            '• Report inappropriate behavior or content\n'
            '• Not engage in harassment, bullying, or hate speech\n\n'
            'We reserve the right to remove content and ban users who violate our community standards.',
          ),

          _buildSection(
            '22. Contact Information',
            'If you have questions about these Terms, please contact us at:\n\n'
            'Email: legal@nepaleseaustralia.com.au\n'
            'Address: [Your Australian Business Address]\n'
            'ABN: [Your Australian Business Number]\n\n'
            'For complaints or disputes, please contact us in writing at the above address.',
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acknowledgment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By using the Nepalese in Australia App, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUpdateDate(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
