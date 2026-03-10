import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'guide_helpers.dart';

class TFNGuideNepaliPage extends StatelessWidget {
  final String? link;

  const TFNGuideNepaliPage({super.key, this.link});

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: buildGuideAppBar('TFN गाइड (नेपाली)'),
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
                          'कर फाइल नम्बर (TFN) कसरी आवेदन गर्ने',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'अष्ट्रेलियाका बासिन्दाका लागि',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (link != null)
                    TextButton.icon(
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
                            SnackBar(content: Text('लिङ्क खोल्न सकिएन')),
                          );
                        }
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text('आवेदन गर्नुहोस्'),
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
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '१. योग्यताका लागि जाँच गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'तपाईं TFN का लागि आवेदन गर्न सक्नुहुन्छ यदि:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• तपाईं अष्ट्रेलियामा बस्नुहुन्छ'),
                            Text('• तपाईं १५ वर्ष वा बढी हुनुहुन्छ'),
                            Text('• तपाईंंसँग आवश्यक परिचय कागजातहरू छन्'),
                            SizedBox(height: 6),
                            Text(
                              'TFN निःशुल्क छ र एक पटक मात्र आवेदन गर्नुपर्छ।',
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
                            '२. आफ्नो परिचय कागजातहरू तयार गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'कम्तिमा एउटा निम्न मध्ये एक कागजात आवश्यक हुन्छ:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• अष्ट्रेलियाली पासपोर्ट'),
                            Text('• अष्ट्रेलियाली जन्म प्रमाणपत्र'),
                            Text('• अष्ट्रेलियाली ड्राइभिङ लाइसेन्स'),
                            Text('• मेडिकेयर कार्ड'),
                            SizedBox(height: 6),
                            Text(
                              'यदि तपाईंसँग अष्ट्रेलियाली पासपोर्ट छैन भने, दुई वा बढी कागजात देखाउनु पर्न सक्छ।',
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
                          Icon(Icons.public, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '३. अनलाइन आवेदन गर्नुहोस्',
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
                            Text('• ATO TFN आवेदन पृष्ठमा जानुहोस्'),
                            Text('• "Australian residents" छनौट गर्नुहोस्'),
                            Text('• आफ्नो व्यक्तिगत विवरण भर्नुहोस्'),
                            Text('• फारम पेश गर्नुहोस्'),
                            Text(
                              '• आवेदन सारांश सुरक्षित गर्नुहोस् वा प्रिन्ट गर्नुहोस् (पहिचान जाँचका लागि)',
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
                                  SnackBar(content: Text('लिङ्क खोल्न सकिएन')),
                                );
                              }
                            },
                            icon: Icon(Icons.open_in_new),
                            label: Text('ATO TFN पृष्ठ खोल्नुहोस्'),
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
                          Icon(Icons.local_post_office, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            '४. अष्ट्रेलिया पोस्टमा आफ्नो पहिचान प्रमाणित गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'अनलाइन फारम पेश गरेको ३० दिन भित्र:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• सहभागी अष्ट्रेलिया पोस्ट आउटलेटमा जानुहोस्',
                            ),
                            Text('• आफ्नो परिचय कागजातहरू ल्याउनुहोस्'),
                            Text(
                              '• आफ्नो प्रिन्ट गरिएको आवेदन सारांश ल्याउनुहोस्',
                            ),
                            SizedBox(height: 6),
                            Text(
                              'अष्ट्रेलिया पोस्टले तपाईंको पहिचान प्रमाणित गरी ATO लाई पठाउनेछ। यो सेवा निःशुल्क छ।',
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Gungahlin पोस्ट अफिस TFN पहिचान जाँच समर्थन गर्छ।',
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
                            '५. तपाइँको TFN प्राप्त गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ATO ले तपाइँको TFN तपाइँको ठेगानामा पठाउनेछ',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'प्रोसेसिङ समय: २८ दिन सम्म',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'TFN सुरक्षित राख्नुहोस् र आवश्यक बाहेक नबताउनुहोस् (जस्तै: रोजगारदाता, बैंक, ATO)।',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

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
                        'छोटो सारांश',
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
                            children: [
                              Text('1'),
                              Text('योग्यता जाँच गर्नुहोस्'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('2'),
                              Text('पहिचान कागजातहरू जम्मा गर्नुहोस्'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('3'),
                              Text('ATO मार्फत अनलाइन आवेदन गर्नुहोस्'),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('4'),
                              Text(
                                'अष्ट्रेलिया पोस्टमा पहिचान पुष्टि गर्नुहोस्',
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('5'),
                              Text('TFN लेटरको प्रतिक्षा गर्नुहोस्'),
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
