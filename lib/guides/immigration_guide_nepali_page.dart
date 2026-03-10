import 'package:flutter/material.dart';
import 'guide_helpers.dart';

class ImmigrationGuideNepaliPage extends StatelessWidget {
  const ImmigrationGuideNepaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('अभिवासन गाइड (नेपाली)'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🇳🇵✈️', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'अभिवासन जाँचको समय के हुन्छ भन्ने गाइड',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'यो गाइड नेपाली यात्रीहरूको लागि लेखिएको हो।',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
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
                          Icon(Icons.flight_land, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '१. अवतरण पछी — "Arrivals" चिन्ह पालना गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'विमानबाट उतरेपछी पहेंलो "Arrivals / Baggage Claim" चिन्ह पालना गरी अभिवासन नियन्त्रणतर्फ जानुहोस्।',
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
                          Icon(Icons.account_box, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            '२. अभिवासन (पासपोर्ट नियन्त्रण)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('अभिवासन अधिकारीले जाँच गर्नेछन्:'),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• तपाईंको पासपोर्ट'),
                            Text('• तपाईंको भिसा'),
                            Text('• आगमन कार्ड (यदि आवश्यक छ)'),
                            Text('• तपाईंको अनुहार (पहिचान जाँच)'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('सामान्य प्रश्नहरू:'),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('तपाईं अष्ट्रेलिया किन आउँदै हुनुहुन्छ?'),
                            Text('कति दिन बस्नुहुनेछ?'),
                            Text('कहाँ बस्नुहुनेछ?'),
                            Text('आफ्नो गुजारा गर्न पर्याप्त पैसा छ?'),
                            Text('अष्ट्रेलियामा कोही परिचित छ?'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'नेपाली यात्रीहरूका लागि सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• पासपोर्ट र भिसा सहित राख्नुहोस्'),
                            Text('• छात्रहरूले CoE सहित राख्नुहोस्'),
                            Text(
                              '• कामदार भिसामा नोकरीको पत्र सहित राख्नुहोस्',
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
                          Icon(Icons.luggage, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            '३. सामान सङ्कलन गर्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'अभिवासन पछी, Baggage Claim साइनहरू पालना गरी आफ्नो सामान सङ्कलन गर्नुहोस्।',
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
                          Icon(Icons.shield, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            '४. जैवसुरक्षा र भन्सार (अत्यन्त महत्त्वपूर्ण)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'अष्ट्रेलियाको कठोर नियम छ। तपाईं अवश्य घोषणा गर्नुपर्छ:',
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• खानेकुरा (यदि छ भने)'),
                            Text('• औषधि'),
                            Text('• मीट वा पशु उत्पादन'),
                            Text('• बीज वा गहुँ'),
                            Text('• १०,००० AUD भन्दा बढी नगद'),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'घोषणा न गरे सजाय हुनसक्छ।',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
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
                          Icon(Icons.exit_to_app, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '५. हवाई अड्डा छाड्नुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'भन्सार पछी, तपाईं आगमन हलमा बाहिर निस्कनुहुनेछ। यहाँ SIM कार्ड, मुद्रा विनिमय, ATM, र यातायात छ।',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
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
                        '🌟 नेपाली यात्रीहरूका लागि चेकलिस्ट',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('ह्यान्ड लगेजमा राख्नुपर्नेकुरा:'),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• पासपोर्ट'),
                            Text('• भिसा पत्र'),
                            Text('• रहने ठेगाना'),
                            Text('• CoE (छात्रहरू)'),
                            Text('• नोकरीको पत्र (कामदार)'),
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
                          Icon(Icons.mood, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            '🧘 आत्मविश्वासी रहनुहोस्',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('अभिवासन अधिकारीहरू मैत्रीपूर्ण र पेशेवर हुन्छन्।'),
                      Text('सच्चाँ र स्पष्टतापूर्वक बोल्नुहोस्।'),
                      SizedBox(height: 6),
                      Text('हजारौं नेपाली हरेक महिना अष्ट्रेलिया आउँछन्।'),
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
