import 'package:flutter/material.dart';
import 'guide_helpers.dart';

class TransportGuideNepaliPage extends StatelessWidget {
  const TransportGuideNepaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('अष्ट्रेलियामा ट्रान्सपोर्ट कार्ड प्रयोग'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. OPAL Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚉 १. OPAL कार्ड (New South Wales – Sydney, Newcastle, Blue Mountains)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'कहाँ काम गर्छ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• सिड्नी ट्रेन, बस, फेरी, लाइट रेल'),
                      Text('• न्यूक्यासल यातायात'),
                      Text('• ब्लु माउन्टेन्स क्षेत्र'),
                      SizedBox(height: 12),
                      Text(
                        'चरण‑दर‑चरण',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '१. Opal कार्ड प्राप्त गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • एयरपोर्ट ट्रेन स्टेशनहरू'),
                      Text('   • सुविधा स्टोरहरू (7‑Eleven, न्युजएजेन्ट्स)'),
                      Text('   • Opal रिटेलरहरू'),
                      Text('   • अनलाइन (तपाईंको ठेगानामा डेलिभर गरिन्छ)'),
                      SizedBox(height: 8),
                      Text(
                        '२. सही प्रकार छान्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • वयस्क'),
                      Text(
                        '   • छुट (केवल यदि तपाईंको विश्वविद्यालय योग्य छ भने)',
                      ),
                      Text('   • बालबालिका/युवा'),
                      SizedBox(height: 8),
                      Text(
                        '३. टप अप गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • स्टेशनहरूमा Opal मेसिनहरू'),
                      Text('   • रिटेल स्टोरहरू'),
                      Text('   • Opal एप'),
                      Text('   • अनलाइन स्वत:‑टप‑अप'),
                      SizedBox(height: 8),
                      Text(
                        '४. ट्याप अन र ट्याप अफ गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • आफ्नो यात्राको सुरुमा ट्याप अन गर्नुहोस्'),
                      Text('   • अन्त्यमा ट्याप अफ गर्नुहोस्'),
                      Text('   • फेरी र लाइट रेलमा पनि ट्याप अफ आवश्यक छ'),
                      SizedBox(height: 8),
                      Text(
                        '५. दैनिक/साप्ताहिक सीमा',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '   तपाईंले प्रति दिन वा हप्ता निर्धारित रकम भन्दा बढी तिर्नु पर्दैन।',
                      ),
                      Text('   पैसा बचाउन खोज्ने विद्यार्थीहरूको लागि उत्तम।'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 2. MYKI Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚋 २. MYKI कार्ड (Victoria – Melbourne, Geelong, Ballarat)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'कहाँ काम गर्छ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• मेलबर्न ट्रेन, ट्राम, बस'),
                      Text('• केही शहरहरूमा क्षेत्रीय बसहरू'),
                      SizedBox(height: 12),
                      Text(
                        'चरण‑दर‑चरण',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '१. Myki कार्ड प्राप्त गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • ट्रेन स्टेशनहरू'),
                      Text('   • 7‑Eleven स्टोरहरू'),
                      Text('   • Myki मेसिनहरू'),
                      Text('   • अनलाइन'),
                      SizedBox(height: 8),
                      Text(
                        '२. Myki Money वा Myki Pass छान्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Myki Money: तिर्दै‑जानु'),
                      Text('   • Myki Pass: ७ वा २८ दिनको लागि असीमित यात्रा'),
                      SizedBox(height: 8),
                      Text(
                        '३. टप अप गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Myki मेसिनहरू'),
                      Text('   • 7‑Eleven'),
                      Text('   • अनलाइन'),
                      Text('   • Myki एप'),
                      SizedBox(height: 8),
                      Text(
                        '४. ट्याप अन र ट्याप अफ गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • चढ्दा ट्याप अन गर्नुहोस्'),
                      Text(
                        '   • छोड्दा ट्याप अफ गर्नुहोस् (free tram zone मा ट्राम बाहेक)',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '५. नि:शुल्क ट्राम जोन (Melbourne CBD)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '   CBD free zone भित्र तपाईंले ट्याप अन वा अफ गर्न आवश्यक छैन।',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 3. GoCard
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚆 ३. GoCard (Queensland – Brisbane, Gold Coast, Sunshine Coast)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'कहाँ काम गर्छ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• ब्रिस्बेन ट्रेन, बस, फेरी'),
                      Text('• गोल्ड कोस्ट ट्रामहरू'),
                      Text('• सनसाइन कोस्ट बसहरू'),
                      SizedBox(height: 12),
                      Text(
                        'चरण‑दर‑चरण',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '१. GoCard प्राप्त गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • ट्रेन स्टेशनहरू'),
                      Text('   • 7‑Eleven'),
                      Text('   • GoCard रिटेलरहरू'),
                      Text('   • अनलाइन'),
                      SizedBox(height: 8),
                      Text(
                        '२. सही प्रकार छान्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • वयस्क'),
                      Text('   • छुट (वैध ID भएका विद्यार्थीहरू)'),
                      SizedBox(height: 8),
                      Text(
                        '३. टप अप गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • GoCard मेसिनहरू'),
                      Text('   • रिटेलरहरू'),
                      Text('   • अनलाइन'),
                      Text('   • स्वत: टप‑अप'),
                      SizedBox(height: 8),
                      Text(
                        '४. ट्याप अन र ट्याप अफ गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • सुरुमा ट्याप अन गर्नुहोस्'),
                      Text('   • अन्त्यमा ट्याप अफ गर्नुहोस्'),
                      Text('   • बिर्सिएमा जरिवाना लाग्छ'),
                      SizedBox(height: 8),
                      Text(
                        '५. अफ‑पिक छुट',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   पैसा बचाउन पिक घण्टा बाहिर यात्रा गर्नुहोस्।'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 4. MyWay Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚌 ४. MyWay कार्ड (ACT – Canberra)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'कहाँ काम गर्छ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• क्यानबेरा बसहरू'),
                      Text('• क्यानबेरा लाइट रेल'),
                      SizedBox(height: 12),
                      Text(
                        'चरण‑दर‑चरण',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '१. MyWay कार्ड प्राप्त गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • Canberra Connect कार्यालयहरू'),
                      Text('   • लाइट रेल स्टेशनहरू'),
                      Text('   • अनलाइन अर्डर'),
                      SizedBox(height: 8),
                      Text(
                        '२. सही प्रकार छान्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • वयस्क'),
                      Text('   • छुट (विद्यार्थीहरू)'),
                      Text('   • बालबालिका'),
                      SizedBox(height: 8),
                      Text(
                        '३. टप अप गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • MyWay रिचार्ज मेसिनहरू'),
                      Text('   • अनलाइन'),
                      Text('   • स्वत: टप‑अप'),
                      Text('   • रिटेल स्टोरहरू'),
                      SizedBox(height: 8),
                      Text(
                        '४. ट्याप अन र ट्याप अफ गर्नुहोस्',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('   • चढ्दा ट्याप अन गर्नुहोस्'),
                      Text('   • छोड्दा ट्याप अफ गर्नुहोस्'),
                      Text('   • लाइट रेलमा पनि ट्याप अफ आवश्यक छ'),
                      SizedBox(height: 8),
                      Text(
                        '५. दैनिक सीमा',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '   तपाईंले दैनिक निर्धारित रकम भन्दा बढी तिर्नु पर्दैन।',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Extra Tips
              Text(
                '🎒 नेपाली विद्यार्थीहरूको लागि अतिरिक्त सुझावहरू',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2193b0),
                ),
              ),
              SizedBox(height: 12),
              Card(
                elevation: 2,
                color: Color(0xFFF5F5F5),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'पैसा बचाउनुहोस्:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• छुट कार्डहरू प्रयोग गरेर (यदि योग्य छ भने)'),
                      Text('• अफ‑पिक यात्रा गरेर'),
                      Text('• साप्ताहिक/दैनिक सीमा प्रयोग गरेर'),
                      Text(
                        '• एयरपोर्ट स्टेशनहरूबाट बच्न (महँगो अतिरिक्त शुल्क)',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'सधैं:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• आफ्नो कार्ड टप अप राख्नुहोस्'),
                      Text('• सही तरिकाले ट्याप अन/अफ गर्नुहोस्'),
                      Text(
                        '• आफ्नो कार्ड अनलाइन दर्ता गर्नुहोस् (हराएमा मद्दत गर्छ)',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'नगर्नुहोस्:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• कार्डहरू साझेदारी गर्न'),
                      Text('• ट्याप अफ गर्न बिर्सन'),
                      Text('• अरूको छुट कार्ड प्रयोग गर्न'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Link to English version
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.translate),
                  label: Text('Read in English'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
