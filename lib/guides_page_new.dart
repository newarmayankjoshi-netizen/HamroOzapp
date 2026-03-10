import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

// Import all guide pages
import 'guides/tfn_guide_page.dart';
import 'guides/bank_guide_page.dart';
import 'guides/immigration_guide_page.dart';
import 'guides/accommodation_guide_page.dart';
import 'guides/transport_guide_page.dart';
import 'guides/transport_navigation_guide_page.dart';

final _urlRegExp = RegExp(r"(https?:\/\/[\w\-\.\/~\?\#\&\=\%\+\:;,@]+)");

class GuidesPage extends StatelessWidget {
  GuidesPage({super.key});

  final List<Map<String, dynamic>> guides = [
    {
      "title": "How to Apply for TFN",
      "subtitle": "Tax File Number for working legally in Australia",
      "content":
          "A TFN is required to work in Australia. You can apply online through the ATO website. You will need your passport, visa details, and Australian address.",
      "link":
          "https://www.ato.gov.au/individuals-and-families/tax-file-number/apply-for-a-tfn",
      "icon": Icons.assignment,
      "color": Color.fromRGBO(33, 147, 176, 0.85),
    },
    {
      "title": "How to Open a Bank Account",
      "subtitle": "ANZ, CBA, NAB, Westpac — what you need",
      "content":
          "Most banks allow you to open an account with your passport and visa. You can start online and verify your identity in-branch within 30 days.",
      "icon": Icons.account_balance,
      "color": Color.fromRGBO(109, 213, 237, 0.85),
    },
    {
      "title": "How to Find Accommodation",
      "subtitle": "Rooms, rentals, inspections, and safety tips",
      "content":
          "Use platforms like Flatmates, Facebook groups, and Nepalese community apps. Always inspect the property and avoid paying deposits before viewing.",
      "icon": Icons.home,
      "color": Color.fromRGBO(33, 147, 176, 0.85),
    },
    {
      "title": "Things to know during Immigration Check",
      "subtitle": "Entering Australia — immigration & customs",
      "content":
          "Guide: What to Expect During Immigration Check When Entering Australia",
      "icon": Icons.flight_takeoff,
      "color": Color.fromRGBO(109, 213, 237, 0.85),
    },
    {
      "title": "Using Transport Cards in Australia",
      "subtitle": "Opal, Myki, Go Card — public transport essentials",
      "content":
          "Guide to using public transport cards across Australian cities",
      "icon": Icons.directions_transit,
      "color": Color.fromRGBO(33, 147, 176, 0.85),
    },
    {
      "title": "Transportation and Navigation Guide",
      "subtitle": "Buses, trains, trams, maps, and airport transport",
      "content":
          "Step-by-step guide to transport, timetables, concessions, and navigation",
      "icon": Icons.map,
      "color": Color.fromRGBO(109, 213, 237, 0.85),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Text(
                    "Essential Guides",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6dd5ed), Color(0xFF2193b0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.only(left: 18, right: 18, top: 100, bottom: 20),
          itemCount: guides.length,
          itemBuilder: (context, index) {
            return GuideCard(
              title: guides[index]["title"]!,
              subtitle: guides[index]["subtitle"]!,
              content: guides[index]["content"]!,
              link: guides[index]["link"],
              icon: guides[index]["icon"] as IconData,
              color: guides[index]["color"] as Color,
            );
          },
        ),
      ),
    );
  }
}

class GuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String content;
  final String? link;
  final IconData icon;
  final Color color;

  const GuideCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.link,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GuideDetailPage(title: title, content: content, link: link),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(46),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(255, 255, 255, 0.7), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1),
                          letterSpacing: 1.05,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1565C0),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Color(0xFF1976D2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideDetailPage extends StatelessWidget {
  final String title;
  final String content;
  final String? link;

  const GuideDetailPage({
    super.key,
    required this.title,
    required this.content,
    this.link,
  });

  @override
  Widget build(BuildContext context) {
    // Route to appropriate guide page based on title
    if (title == 'How to Apply for TFN') {
      return TFNGuidePage(title: title, link: link);
    }

    if (title == 'How to Open a Bank Account') {
      return BankGuidePage(title: title);
    }

    if (title == 'Things to know during Immigration Check') {
      return ImmigrationGuidePage();
    }

    if (title == 'How to Find Accommodation') {
      return AccommodationGuidePage();
    }

    if (title == 'Using Transport Cards in Australia') {
      return TransportGuidePage();
    }

    if (title == 'Transportation and Navigation Guide') {
      return TransportNavigationGuidePage();
    }

    // Fallback for any other guides with simple content
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Color(0xFF2193b0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            children: _linkify(content, context),
            style: TextStyle(fontSize: 18, height: 1.5, color: Colors.black),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _linkify(String text, BuildContext context) {
    final List<TextSpan> spans = [];
    int start = 0;
    final matches = _urlRegExp.allMatches(text);
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              final messenger = ScaffoldMessenger.of(context);
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
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}
