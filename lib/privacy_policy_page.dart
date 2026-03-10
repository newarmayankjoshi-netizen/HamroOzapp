import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader('Privacy Policy'),
          _buildUpdateDate('Last Updated: 5 February 2026'),
          const SizedBox(height: 24),

          _buildSection(
            'Introduction',
            'Nepalese in Australia ("we", "us", or "our") is committed to protecting your privacy and personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.\n\n'
            'This Privacy Policy complies with the Privacy Act 1988 (Cth) and the Australian Privacy Principles (APPs). We are bound by the APPs, which regulate how we collect, use, disclose, and store personal information, and how individuals can access and correct personal information we hold about them.',
          ),

          _buildSection(
            '1. Information We Collect',
            'We collect information that you provide directly to us and information that is automatically collected when you use our App.',
          ),

          _buildSubSection(
            '1.1 Personal Information You Provide',
            'When you create an account or use our services, we may collect:\n\n'
            '• Name and contact information (email address, phone number)\n'
            '• Profile information (profile picture, bio, date of birth)\n'
            '• Location information (state/territory in Australia)\n'
            '• Languages spoken\n'
            '• Account credentials (username, password - stored encrypted)\n'
            '• Content you post (job listings, room advertisements, marketplace items, event postings, comments)\n'
            '• Communications with us or other users\n'
            '• Payment information (if applicable, processed through secure third-party payment processors)',
          ),

          _buildSubSection(
            '1.2 Automatically Collected Information',
            'When you use the App, we automatically collect:\n\n'
            '• Device information (device type, operating system, unique device identifiers)\n'
            '• Usage data (pages viewed, features used, time spent on App)\n'
            '• Location data (if you grant permission)\n'
            '• Log data (IP address, browser type, access times)\n'
            '• Cookies and similar tracking technologies',
          ),

          _buildSubSection(
            '1.3 Information from Third Parties',
            'If you sign in using Google or Apple Sign-In, we receive:\n\n'
            '• Your name\n'
            '• Email address\n'
            '• Profile picture (if available)\n\n'
            'This information is governed by the third-party provider\'s privacy policy.',
          ),

          _buildSection(
            '2. How We Use Your Information',
            'We use your personal information for the following purposes, in accordance with the APPs:',
          ),

          _buildSubSection(
            '2.1 Primary Purposes',
            '• To create and manage your account (APP 3)\n'
            '• To provide and improve our services (APP 6)\n'
            '• To facilitate connections between community members\n'
            '• To enable job searching, accommodation finding, and marketplace transactions\n'
            '• To organize and promote community events\n'
            '• To communicate with you about your account or our services\n'
            '• To respond to your inquiries and support requests',
          ),

          _buildSubSection(
            '2.2 Secondary Purposes',
            '• To send you relevant notifications and updates (with your consent - APP 7)\n'
            '• To personalize your experience\n'
            '• To analyze usage patterns and improve the App\n'
            '• To detect and prevent fraud, abuse, and security issues\n'
            '• To comply with legal obligations\n'
            '• To enforce our Terms of Service',
          ),

          _buildSection(
            '3. How We Share Your Information',
            'We do not sell your personal information. We may share your information in the following circumstances, in accordance with APP 6:',
          ),

          _buildSubSection(
            '3.1 Public Information',
            'Information you choose to make public through the App (such as job listings, room advertisements, marketplace items, events, and your public profile) will be visible to other users of the App.',
          ),

          _buildSubSection(
            '3.2 Service Providers',
            'We may share your information with trusted third-party service providers who assist us in:\n\n'
            '• Hosting and maintaining the App\n'
            '• Data storage and backup\n'
            '• Payment processing\n'
            '• Analytics and performance monitoring\n'
            '• Customer support\n\n'
            'These providers are contractually obligated to protect your information and use it only for the purposes we specify.',
          ),

          _buildSubSection(
            '3.3 Legal Requirements',
            'We may disclose your information if required by law or if we believe such action is necessary to:\n\n'
            '• Comply with legal processes, court orders, or government requests\n'
            '• Enforce our Terms of Service\n'
            '• Protect our rights, property, or safety, or that of our users or the public\n'
            '• Investigate and prevent illegal activities, fraud, or security issues',
          ),

          _buildSubSection(
            '3.4 Business Transfers',
            'If we are involved in a merger, acquisition, or sale of assets, your personal information may be transferred. We will notify you of any such change and the choices you may have.',
          ),

          _buildSection(
            '4. Data Storage and Security',
            'We take the security of your personal information seriously and implement appropriate technical and organizational measures to protect it.',
          ),

          _buildSubSection(
            '4.1 Security Measures',
            '• Passwords are encrypted using industry-standard hashing (SHA-256)\n'
            '• Data is transmitted using secure SSL/TLS encryption\n'
            '• Access to personal information is restricted to authorized personnel only\n'
            '• Regular security audits and updates\n'
            '• Rate limiting and account lockout to prevent unauthorized access\n'
            '• Secure storage of data in compliance with APP 11',
          ),

          _buildSubSection(
            '4.2 Data Location',
            'Your personal information is stored in Australia. If we transfer data overseas, we will ensure appropriate safeguards are in place in accordance with APP 8.',
          ),

          _buildSubSection(
            '4.3 Data Retention',
            'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. When you delete your account, we will delete or anonymize your personal information within 30 days, except where we are required by law to retain it.',
          ),

          _buildSection(
            '5. Your Rights and Choices',
            'Under the Privacy Act 1988 and the Australian Privacy Principles, you have the following rights:',
          ),

          _buildSubSection(
            '5.1 Access to Your Information (APP 12)',
            'You have the right to request access to the personal information we hold about you. You can access and update most of your information through your account settings. For additional access requests, contact us at privacy@nepaleseaustralia.com.au.',
          ),

          _buildSubSection(
            '5.2 Correction of Information (APP 13)',
            'You have the right to request correction of inaccurate or incomplete personal information. You can update your information through the App or by contacting us.',
          ),

          _buildSubSection(
            '5.3 Deletion of Information',
            'You can request deletion of your account and personal information at any time through the App settings or by contacting us. Please note that some information may be retained as required by law or for legitimate business purposes.',
          ),

          _buildSubSection(
            '5.4 Marketing Communications',
            'You can opt out of marketing communications at any time through:\n\n'
            '• App notification settings\n'
            '• Email unsubscribe links\n'
            '• Contacting us directly\n\n'
            'We comply with the Spam Act 2003 (Cth) for all marketing communications.',
          ),

          _buildSubSection(
            '5.5 Data Portability',
            'You can request a copy of your personal information in a portable format by using the "Export My Data" feature in the App settings.',
          ),

          _buildSection(
            '6. Cookies and Tracking Technologies',
            'We use cookies, web beacons, and similar technologies to:\n\n'
            '• Remember your preferences and settings\n'
            '• Authenticate your account\n'
            '• Analyze App usage and performance\n'
            '• Provide personalized content\n\n'
            'You can control cookie preferences through your device settings. Disabling cookies may limit some App functionality.',
          ),

          _buildSection(
            '7. Children\'s Privacy',
            'Our App is not intended for children under 18 years of age. We do not knowingly collect personal information from children under 18. If we become aware that we have collected personal information from a child under 18, we will take steps to delete such information promptly.\n\n'
            'If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
          ),

          _buildSection(
            '8. Third-Party Links and Services',
            'The App may contain links to third-party websites, services, or applications. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies before providing any information to them.',
          ),

          _buildSection(
            '9. Location Information',
            'If you enable location services, we may collect and use your precise location data to:\n\n'
            '• Show relevant local listings and events\n'
            '• Improve service recommendations\n'
            '• Provide location-based features\n\n'
            'You can disable location services at any time through your device settings. This may limit certain App features.',
          ),

          _buildSection(
            '10. Data Breach Notification',
            'In accordance with the Notifiable Data Breaches (NDB) scheme under the Privacy Act 1988:\n\n'
            '• If we experience a data breach that is likely to result in serious harm to you, we will notify you as soon as practicable\n'
            '• We will also notify the Office of the Australian Information Commissioner (OAIC)\n'
            '• Notifications will include the nature of the breach and steps you can take to protect yourself',
          ),

          _buildSection(
            '11. International Data Transfers',
            'Your personal information is primarily stored and processed in Australia. If we transfer your information overseas, we will:\n\n'
            '• Only transfer to countries with adequate privacy protections (APP 8)\n'
            '• Ensure appropriate safeguards are in place\n'
            '• Obtain your consent where required\n'
            '• Comply with cross-border disclosure requirements',
          ),

          _buildSection(
            '12. Business and Professional Use',
            'If you use the App for business purposes (e.g., posting job listings, advertising rooms), you acknowledge that:\n\n'
            '• You are responsible for complying with applicable privacy laws when collecting information from others\n'
            '• You must obtain necessary consents before sharing personal information of others\n'
            '• You must comply with the APPs if you are an APP entity',
          ),

          _buildSection(
            '13. Changes to This Privacy Policy',
            'We may update this Privacy Policy from time to time to reflect changes in:\n\n'
            '• Our practices\n'
            '• Legal requirements\n'
            '• App features\n\n'
            'We will notify you of material changes by:\n\n'
            '• Posting the updated policy in the App\n'
            '• Sending email notification\n'
            '• Displaying an in-app notice\n\n'
            'Your continued use of the App after changes become effective constitutes acceptance of the updated policy.',
          ),

          _buildSection(
            '14. Contact Us and Complaints',
            'If you have questions, concerns, or complaints about this Privacy Policy or our privacy practices, please contact us:',
          ),

          _buildContactInfo(),

          _buildSection(
            '15. Complaints Process',
            'If you wish to make a complaint about how we have handled your personal information:\n\n'
            '1. Contact our Privacy Officer at privacy@nepaleseaustralia.com.au\n'
            '2. We will investigate your complaint and respond within 30 days\n'
            '3. If you are not satisfied with our response, you can contact the Office of the Australian Information Commissioner (OAIC):\n\n'
            '   • Website: www.oaic.gov.au\n'
            '   • Phone: 1300 363 992\n'
            '   • Email: enquiries@oaic.gov.au',
          ),

          _buildSection(
            '16. Consent',
            'By using the App, you consent to the collection, use, and disclosure of your personal information as described in this Privacy Policy.\n\n'
            'You can withdraw your consent at any time by:\n\n'
            '• Adjusting your privacy settings in the App\n'
            '• Contacting us directly\n'
            '• Deleting your account\n\n'
            'Please note that withdrawing consent may affect your ability to use certain App features.',
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Your Privacy Matters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'We are committed to protecting your privacy and complying with Australian privacy laws. You have control over your personal information and can access, correct, or delete it at any time.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
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

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.email, size: 20),
              SizedBox(width: 8),
              Text(
                'Email:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('privacy@nepaleseaustralia.com.au'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.person, size: 20),
              SizedBox(width: 8),
              Text(
                'Privacy Officer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('Privacy Officer, Nepalese in Australia'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 20),
              SizedBox(width: 8),
              Text(
                'Address:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('[Your Australian Business Address]\nAustralia'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.business, size: 20),
              SizedBox(width: 8),
              Text(
                'ABN:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('[Your Australian Business Number]'),
            ],
          ),
        ],
      ),
    );
  }
}
