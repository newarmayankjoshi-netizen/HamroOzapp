import 'package:flutter/material.dart';
import 'guide_helpers.dart';

class TransportNavigationGuideNepaliPage extends StatelessWidget {
  const TransportNavigationGuideNepaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('यातायात र नेभिगेसन गाइड (नेपाली)'),
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
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.translate),
                  label: Text('Read in English'),
                ),
              ),
              SizedBox(height: 12),

              Text(
                '🚍 अष्ट्रेलियामा नेपाली विद्यार्थीका लागि यातायात र नेभिगेसन गाइड',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'यो गाइडले बस, ट्रेन, ट्राम, टाइमटेबल, कन्सेसन कार्ड, Google Maps, र एयरपोर्ट यातायात कसरी प्रयोग गर्ने भनेर सरल चरणहरूमा बताउँछ।',
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
                        '🚆 १. बस, ट्रेन र ट्राम कसरी प्रयोग गर्ने',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('बस', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text('• बस स्टप पोल वा आश्रयस्थलले चिनिन्छ'),
                      Text('• बसको रुट नम्बर जाँच गर्नुहोस्'),
                      Text('• अगाडिको ढोकाबाट प्रवेश गर्नुहोस्'),
                      Text(
                        '• आफ्नो ट्रान्सपोर्ट कार्ड ट्याप गर्नुहोस् (Opal/Myki/GoCard/MyWay)',
                      ),
                      Text('• आफ्नो स्टप आउँदा स्टप बटन थिच्नुहोस्'),
                      Text('• बस अनुसार अगाडि वा पछाडिबाट बाहिर निस्कनुहोस्'),
                      SizedBox(height: 8),
                      Text(
                        'सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• हात नहल्लाए बस रोक्दैन'),
                      Text('• तपाईंको शहरले फरक नभनेसम्म ट्याप अफ गर्नुहोस्'),
                      SizedBox(height: 12),
                      Text(
                        'ट्रेन',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('• स्टेसनमा स्पष्ट संकेतसहित प्लेटफर्म हुन्छ'),
                      Text(
                        '• दिशा जाँच गर्नुहोस् (उदा. "City Circle", "Flinders Street", "Central")',
                      ),
                      Text('• गेटमा ट्याप अन गर्नुहोस्'),
                      Text('• पहेंलो रेखा पछाडि पर्खनुहोस्'),
                      Text('• बाहिर निस्कँदा ट्याप अफ गर्नुहोस्'),
                      SizedBox(height: 8),
                      Text(
                        'सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• राति ट्रेन कम चल्छ'),
                      Text('• केही शहरमा एक्सप्रेस ट्रेनले स्टेसन छोड्छ'),
                      SizedBox(height: 12),
                      Text(
                        'ट्राम (मेलबर्न, एडिलेड, गोल्ड कोस्ट)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('• जुनसुकै ढोकाबाट प्रवेश गर्न सकिन्छ'),
                      Text(
                        '• Myki (मेलबर्न) वा GoCard (गोल्ड कोस्ट) ट्याप गर्नुहोस्',
                      ),
                      Text('• बाहिर निस्कँदा ट्याप अफ गर्नुहोस्'),
                      Text(
                        '• मेलबर्न CBD मा Free Tram Zone छ — ट्याप गर्न पर्दैन',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• पिक घण्टामा ट्राम भीडभाड हुन सक्छ'),
                      Text(
                        '• तपाईंको स्टप फ्री जोन भित्र छ कि छैन जाँच गर्नुहोस्',
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
                        '📅 २. टाइमटेबल कसरी पढ्ने',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'धेरै विद्यार्थीलाई सुरुमा गाह्रो हुन्छ। सजिलो तरिका:',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'टाइमटेबल कहाँ भेटिन्छ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Google Maps'),
                      Text(
                        '• ट्रान्सपोर्ट एप्स (Opal, Myki, Translink, Transport Canberra)',
                      ),
                      Text('• बस स्टप डिस्प्लेहरू'),
                      Text('• ट्रेन स्टेसन स्क्रिनहरू'),
                      SizedBox(height: 12),
                      Text(
                        'के हेर्ने',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• रुट नम्बर (जस्तै Bus 300, Tram 86)'),
                      Text('• दिशा (सहरतर्फ वा उपनगरतर्फ)'),
                      Text('• प्रस्थान समय'),
                      Text('• प्लेटफर्म नम्बर (ट्रेनका लागि)'),
                      SizedBox(height: 12),
                      Text(
                        'पिक vs अफ‑पिक',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• पिक = महँगो, बढी भीड'),
                      Text('• अफ‑पिक = सस्तो, कम भीड'),
                      SizedBox(height: 12),
                      Text(
                        'महत्वपूर्ण टिप',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'यदि "Every 10 minutes" लेखिएको छ भने नियमित अन्तरालमा बस/ट्राम आउँछ — ठ्याक्कै समय चाहिँदैन।',
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
                        '🎓 ३. कन्सेसन कार्ड (विद्यार्थी छुट) कसरी पाउने',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'प्रत्येक राज्यका नियम फरक छन्। धेरै विद्यार्थीले पूरा भाडा तिर्छन्।',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'NSW (Sydney)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '• अन्तर्राष्ट्रिय विद्यार्थीले प्रायः छुट पाउँदैनन्',
                      ),
                      Text('• Adult Opal प्रयोग गर्नुपर्छ'),
                      Text(
                        '• केही विश्वविद्यालयले सीमित छुट दिन सक्छ — आफ्नो uni जाँच गर्नुहोस्',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'VIC (Melbourne)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• iUSEpass किनेपछि छुट पाउन सकिन्छ'),
                      Text('• विश्वविद्यालयमार्फत आवेदन गर्नुहोस्'),
                      SizedBox(height: 12),
                      Text(
                        'QLD (Brisbane, Gold Coast)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• अन्तर्राष्ट्रिय विद्यार्थीलाई छुट उपलब्ध छ'),
                      Text('• Translink मा आफ्नो student ID दर्ता गर्नुपर्छ'),
                      SizedBox(height: 12),
                      Text(
                        'ACT (Canberra)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• अन्तर्राष्ट्रिय विद्यार्थीलाई छुट उपलब्ध छ'),
                      Text('• MyWay Concession प्रयोग गर्नुहोस्'),
                      SizedBox(height: 12),
                      Text(
                        'आवेदन प्रक्रिया:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• आफ्नो विश्वविद्यालयको वेबसाइट हेर्नुहोस्'),
                      Text('• विद्यार्थी परिचयपत्र उपलब्ध गराउनुहोस्'),
                      Text('• आफ्नो ट्रान्सपोर्ट कार्ड लिंक गर्नुहोस्'),
                      Text('• स्वीकृतिको लागि पर्खनुहोस्'),
                      SizedBox(height: 12),
                      Text(
                        'चेतावनी:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'अरूको कन्सेसन कार्ड प्रयोग गर्दा ठूलो जरिवाना लाग्न सक्छ।',
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
                        '🗺️ ४. Google Maps प्रभावकारी रूपमा कसरी प्रयोग गर्ने',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Google Maps अष्ट्रेलिया नेभिगेसनका लागि सबैभन्दा सजिलो हो।',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'चरणहरू:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Google Maps खोल्नुहोस्'),
                      Text('• गन्तव्य राख्नुहोस्'),
                      Text('• Directions थिच्नुहोस्'),
                      Text('• सार्वजनिक यातायात आइकन छान्नुहोस्'),
                      Text('• सबैभन्दा राम्रो रुट छान्नुहोस्'),
                      Text('• चरण‑दर‑चरण निर्देशन अनुसरण गर्नुहोस्'),
                      SizedBox(height: 12),
                      Text(
                        'Google Maps ले के देखाउँछ:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• कुन बस/ट्रेन/ट्राम लिनु पर्ने'),
                      Text('• ठ्याक्कै प्रस्थान समय'),
                      Text('• प्लेटफर्म नम्बर'),
                      Text('• हिँडाइ निर्देशनहरू'),
                      Text('• ट्याप अन/अफ सम्झना'),
                      Text('• रियल‑टाइम ढिलाइ'),
                      SizedBox(height: 12),
                      Text(
                        'सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• घर र विश्वविद्यालयलाई favourites मा राख्नुहोस्'),
                      Text('• अफलाइन नक्सा डाउनलोड गर्नुहोस्'),
                      Text(
                        '• "Depart at" वा "Arrive by" प्रयोग गरेर योजना बनाउनुहोस्',
                      ),
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
                        '✈️ ५. एयरपोर्टबाट सहर जाने विकल्प',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('हरेक सहरको एयरपोर्ट यातायात फरक हुन्छ। सरल सूची:'),
                      SizedBox(height: 12),
                      Text(
                        'Sydney',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Airport Train (महँगो तर छिटो)'),
                      Text('• Bus 420 (सस्तो तर ढिलो)'),
                      Text('• Uber, Ola, Didi'),
                      Text('• Shuttle बसहरू'),
                      SizedBox(height: 12),
                      Text(
                        'Melbourne',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• SkyBus (airport to city)'),
                      Text('• सार्वजनिक बस (सस्तो)'),
                      Text('• Uber, Ola, Didi'),
                      SizedBox(height: 12),
                      Text(
                        'Brisbane',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Airtrain (छिटो)'),
                      Text('• सार्वजनिक बस'),
                      Text('• Uber, Ola, Didi'),
                      SizedBox(height: 12),
                      Text(
                        'Canberra',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('• Bus Route 3 वा 11'),
                      Text('• Uber, Ola, Didi'),
                      Text('• Airport shuttle'),
                      SizedBox(height: 12),
                      Text(
                        'सुझाव:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '• पैसा बचाउन एयरपोर्ट ट्रेन स्टेशनहरूबाट जोगिनुहोस् (Sydney surcharge उच्च हुन्छ)',
                      ),
                      Text(
                        '• सस्तो विकल्पका लागि Google Maps सधैं जाँच गर्नुहोस्',
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
