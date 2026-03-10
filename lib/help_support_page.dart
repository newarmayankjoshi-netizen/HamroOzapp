import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  List<FAQItem> _filteredFAQs = [];
  String _selectedCategory = 'All';
  bool _showAIAssistant = false;

  final List<String> _categories = [
    'All',
    'Account',
    'Jobs',
    'Accommodation',
    'Marketplace',
    'Events',
    'Privacy',
    'Safety',
    'Technical',
  ];

  final List<FAQItem> _allFAQs = [
    // Account Questions
    FAQItem(
      category: 'Account',
      question: 'How do I create an account?',
      answer: 'To create an account:\n\n'
          '1. Open the app and tap "Create Account"\n'
          '2. Enter your name, email, and password\n'
          '3. Provide optional information (phone, state)\n'
          '4. Agree to Terms of Service and Privacy Policy\n'
          '5. Tap "Register"\n\n'
          'You can also sign up using Google or Apple Sign-In for faster registration.',
      keywords: ['create', 'account', 'register', 'sign up', 'new user'],
    ),
    FAQItem(
      category: 'Account',
      question: 'How do I reset my password?',
      answer: 'Currently, password reset is available by contacting our support team at support@nepaleseaustralia.com.au.\n\n'
          'Self-service password reset will be available in a future update. For immediate assistance, please email us with your registered email address.',
      keywords: ['password', 'reset', 'forgot', 'change', 'recover'],
    ),
    FAQItem(
      category: 'Account',
      question: 'How do I delete my account?',
      answer: 'To delete your account:\n\n'
          '1. Go to Settings (tap menu icon in top right)\n'
          '2. Scroll to Account section\n'
          '3. Tap "Delete Account"\n'
          '4. Confirm your decision\n\n'
          'Please note: This action is permanent and cannot be undone. All your data will be deleted within 30 days as per Australian privacy laws.',
      keywords: ['delete', 'remove', 'close', 'deactivate', 'account'],
    ),

    // Jobs Questions
    FAQItem(
      category: 'Jobs',
      question: 'How do I post a job listing?',
      answer: 'To post a job:\n\n'
          '1. Go to Jobs tab\n'
          '2. Tap the "+" button\n'
          '3. Fill in job details (title, company, salary, location)\n'
          '4. Add a detailed description\n'
          '5. Tap "Post Job"\n\n'
          'Important: All job listings must comply with Australian employment laws, including Fair Work Act 2009 and anti-discrimination legislation.',
      keywords: ['post', 'job', 'listing', 'employer', 'hire', 'recruit'],
    ),
    FAQItem(
      category: 'Jobs',
      question: 'What employment laws apply to job postings?',
      answer: 'All job listings must comply with:\n\n'
          '• Fair Work Act 2009 (Cth)\n'
          '• Anti-Discrimination Act 1977 (NSW) and equivalent state laws\n'
          '• Work Health and Safety Act 2011 (Cth)\n'
          '• National Employment Standards (NES)\n\n'
          'You must not discriminate based on race, gender, age, disability, religion, or other protected characteristics. All positions must meet minimum wage requirements.',
      keywords: ['employment', 'law', 'legal', 'fair work', 'discrimination', 'compliance'],
    ),
    FAQItem(
      category: 'Jobs',
      question: 'How do I search for jobs?',
      answer: 'To search for jobs:\n\n'
          '1. Go to Jobs tab\n'
          '2. Use the search bar to enter keywords\n'
          '3. Filter by location, salary range, or job type\n'
          '4. Tap on any job to view details\n'
          '5. Contact the employer directly using provided contact information\n\n'
          'Tip: Set up job notifications in Settings to get alerts for new listings matching your criteria.',
      keywords: ['search', 'find', 'job', 'work', 'employment', 'career'],
    ),

    // Accommodation Questions
    FAQItem(
      category: 'Accommodation',
      question: 'How do I list a room or property?',
      answer: 'To list accommodation:\n\n'
          '1. Go to Rooms tab\n'
          '2. Tap the "+" button\n'
          '3. Enter property details (address, rent, bond, availability)\n'
          '4. Add photos and amenities\n'
          '5. Include rental terms\n'
          '6. Tap "Post Listing"\n\n'
          'All listings must comply with Residential Tenancies Act in your state/territory.',
      keywords: ['list', 'room', 'rent', 'property', 'accommodation', 'house', 'apartment'],
    ),
    FAQItem(
      category: 'Accommodation',
      question: 'What are my rights as a tenant in Australia?',
      answer: 'Tenant rights in Australia include:\n\n'
          '• Right to a written tenancy agreement\n'
          '• Right to a safe and secure property\n'
          '• Protection from unfair rent increases\n'
          '• Right to reasonable notice before entry\n'
          '• Right to request repairs\n'
          '• Protection of your bond money\n\n'
          'Rights vary by state/territory. Contact your local tenancy authority for specific information. For NSW: Fair Trading NSW, VIC: Consumer Affairs Victoria.',
      keywords: ['tenant', 'rights', 'rental', 'lease', 'bond', 'landlord'],
    ),

    // Marketplace Questions
    FAQItem(
      category: 'Marketplace',
      question: 'How do I buy or sell items?',
      answer: 'To sell items:\n'
          '1. Go to Marketplace tab\n'
          '2. Tap "+" to add item\n'
          '3. Add photos, title, description, and price\n'
          '4. Select category and condition\n'
          '5. Post listing\n\n'
          'To buy items:\n'
          '1. Browse or search marketplace\n'
          '2. Tap item to view details\n'
          '3. Contact seller using provided contact info\n'
          '4. Arrange meeting in a safe, public location\n\n'
          'Safety tip: Meet in public places and never send money before seeing the item.',
      keywords: ['buy', 'sell', 'marketplace', 'item', 'product', 'trade'],
    ),
    FAQItem(
      category: 'Marketplace',
      question: 'What items are prohibited?',
      answer: 'You cannot sell:\n\n'
          '• Illegal items or services\n'
          '• Weapons or ammunition\n'
          '• Stolen goods\n'
          '• Counterfeit items\n'
          '• Adult content\n'
          '• Alcohol or tobacco (without proper licensing)\n'
          '• Prescription medications\n'
          '• Animals (unless proper documentation)\n\n'
          'All items must comply with Australian Consumer Law and relevant state/territory regulations.',
      keywords: ['prohibited', 'banned', 'illegal', 'not allowed', 'restricted'],
    ),

    // Events Questions
    FAQItem(
      category: 'Events',
      question: 'How do I create a community event?',
      answer: 'To create an event:\n\n'
          '1. Go to Events tab\n'
          '2. Tap "+" button\n'
          '3. Enter event details (name, date, time, location)\n'
          '4. Add description and cover image\n'
          '5. Set ticket information (if applicable)\n'
          '6. Tap "Create Event"\n\n'
          'Your event will be visible to all community members. For large events, ensure you have necessary permits and insurance.',
      keywords: ['create', 'event', 'organize', 'party', 'gathering', 'meetup'],
    ),

    // Privacy Questions
    FAQItem(
      category: 'Privacy',
      question: 'How is my personal information protected?',
      answer: 'We protect your information through:\n\n'
          '• SHA-256 password encryption\n'
          '• SSL/TLS secure data transmission\n'
          '• Regular security audits\n'
          '• Limited access to authorized personnel only\n'
          '• Compliance with Privacy Act 1988 and APPs\n'
          '• Data stored in Australia\n\n'
          'You can access, correct, or delete your information anytime through your profile settings.',
      keywords: ['privacy', 'security', 'data', 'protection', 'personal information', 'safe'],
    ),
    FAQItem(
      category: 'Privacy',
      question: 'Can I control who sees my information?',
      answer: 'Yes! Control your privacy through Settings:\n\n'
          '• Profile Visibility: Make profile public or private\n'
          '• Contact Information: Show/hide phone number\n'
          '• Location: Show/hide your state\n'
          '• Notifications: Control what alerts you receive\n\n'
          'You decide what information is visible to other users.',
      keywords: ['control', 'privacy', 'settings', 'visibility', 'show', 'hide'],
    ),

    // Safety Questions
    FAQItem(
      category: 'Safety',
      question: 'How do I stay safe when meeting people from the app?',
      answer: 'Safety guidelines:\n\n'
          '• Meet in public places during daylight\n'
          '• Tell someone where you\'re going\n'
          '• Use your own transportation\n'
          '• Trust your instincts\n'
          '• Never share financial information upfront\n'
          '• Video call before meeting in person\n'
          '• Report suspicious behavior immediately\n\n'
          'For emergencies in Australia, call 000. For non-emergencies, contact local police.',
      keywords: ['safety', 'safe', 'meeting', 'scam', 'fraud', 'suspicious'],
    ),
    FAQItem(
      category: 'Safety',
      question: 'How do I report inappropriate content or users?',
      answer: 'To report:\n\n'
          '1. Tap the three dots (...) on the content or profile\n'
          '2. Select "Report"\n'
          '3. Choose reason (spam, harassment, inappropriate content, fraud)\n'
          '4. Provide additional details\n'
          '5. Submit report\n\n'
          'Our team reviews all reports within 24 hours. For urgent safety concerns, contact us directly at safety@nepaleseaustralia.com.au',
      keywords: ['report', 'flag', 'inappropriate', 'harassment', 'abuse', 'spam'],
    ),

    // Technical Questions
    FAQItem(
      category: 'Technical',
      question: 'The app is running slowly. What should I do?',
      answer: 'Try these solutions:\n\n'
          '1. Clear app cache (Settings → Clear Cache)\n'
          '2. Close and restart the app\n'
          '3. Check your internet connection\n'
          '4. Update to the latest app version\n'
          '5. Restart your device\n'
          '6. Disable auto-download images in Settings\n\n'
          'If issues persist, contact support with your device model and OS version.',
      keywords: ['slow', 'performance', 'lag', 'crash', 'freeze', 'loading'],
    ),
    FAQItem(
      category: 'Technical',
      question: 'I\'m not receiving notifications. How do I fix this?',
      answer: 'Check these settings:\n\n'
          '1. App Settings → Notifications (ensure enabled)\n'
          '2. Device Settings → Notifications → Allow notifications for this app\n'
          '3. Check notification types are enabled (Jobs, Rooms, Events, etc.)\n'
          '4. Ensure internet connection is active\n'
          '5. Try disabling and re-enabling notifications\n\n'
          'For iOS: Settings → Notifications → Nepalese in Australia\n'
          'For Android: Settings → Apps → Nepalese in Australia → Notifications',
      keywords: ['notifications', 'alerts', 'not receiving', 'enable', 'push'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _allFAQs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFAQs = _selectedCategory == 'All'
            ? _allFAQs
            : _allFAQs.where((faq) => faq.category == _selectedCategory).toList();
      } else {
        // AI-powered search: match against question, answer, and keywords
        final lowerQuery = query.toLowerCase();
        _filteredFAQs = _allFAQs.where((faq) {
          final matchesCategory = _selectedCategory == 'All' || faq.category == _selectedCategory;
          final matchesSearch = faq.question.toLowerCase().contains(lowerQuery) ||
              faq.answer.toLowerCase().contains(lowerQuery) ||
              faq.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
          return matchesCategory && matchesSearch;
        }).toList();

        // Sort by relevance (keyword matches first, then question matches)
        _filteredFAQs.sort((a, b) {
          final aKeywordMatch = a.keywords.any((k) => k.toLowerCase() == lowerQuery);
          final bKeywordMatch = b.keywords.any((k) => k.toLowerCase() == lowerQuery);
          if (aKeywordMatch && !bKeywordMatch) return -1;
          if (!aKeywordMatch && bKeywordMatch) return 1;
          return 0;
        });
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterFAQs(_searchController.text);
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@nepaleseaustralia.com.au',
      query: 'subject=Help Request&body=Please describe your issue:',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '1300123456');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          Semantics(
            button: true,
            label: _showAIAssistant ? 'Hide AI assistant' : 'Show AI assistant',
            hint: 'Toggles AI help banner',
            child: IconButton(
              icon: Icon(_showAIAssistant ? Icons.close : Icons.smart_toy),
              onPressed: () {
                setState(() {
                  _showAIAssistant = !_showAIAssistant;
                });
              },
              tooltip: 'AI Assistant',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Assistant Banner
          if (_showAIAssistant)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.smart_toy, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Assistant: Type your question below and I\'ll find the best answers for you!',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search help',
                hintText: 'Search for help... (e.g., "how to post a job")',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterFAQs('');
                        },
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterFAQs,
            ),
          ),

          // Category Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    toggled: isSelected,
                    label: category,
                    onTap: () => _selectCategory(category),
                    child: ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onSelected: (_) => _selectCategory(category),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results Count
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${_filteredFAQs.length} result${_filteredFAQs.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // FAQ List
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different keywords or contact support',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFAQs[index];
                      return _FAQCard(faq: faq);
                    },
                  ),
          ),

          // Contact Support Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email, size: 20),
                        label: const Text('Email Us'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchPhone,
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Call Us'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'support@nepaleseaustralia.com.au • 1300 123 456',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Business Hours: Mon-Fri 9AM-5PM AEST',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQCard extends StatefulWidget {
  final FAQItem faq;

  const _FAQCard({required this.faq});

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Semantics(
        button: true,
        toggled: _isExpanded,
        label: '${widget.faq.category} question: ${widget.faq.question}',
        hint: _isExpanded ? 'Double tap to collapse answer' : 'Double tap to expand answer',
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(widget.faq.category),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.faq.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.faq.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.faq.answer,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Account':
        return Colors.blue;
      case 'Jobs':
        return Colors.green;
      case 'Accommodation':
        return Colors.orange;
      case 'Marketplace':
        return Colors.purple;
      case 'Events':
        return Colors.pink;
      case 'Privacy':
        return Colors.teal;
      case 'Safety':
        return Colors.red;
      case 'Technical':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class FAQItem {
  final String category;
  final String question;
  final String answer;
  final List<String> keywords;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.keywords,
  });
}
