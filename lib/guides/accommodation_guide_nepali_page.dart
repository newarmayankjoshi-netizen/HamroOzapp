import 'package:flutter/material.dart';
import 'guide_helpers.dart';

class AccommodationGuideNepaliPage extends StatelessWidget {
  const AccommodationGuideNepaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildGuideAppBar('आवास खोज गाइड (नेपाली)'),
      body: wrapGuideBody(
        context,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text('🏡', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'अष्ट्रेलियामा आवास कसरी खोज्ने',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'नेपाली नयाँ आउनेहरूका लागि चरण-दर-चरण गाइड',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'यो गाइड नेपाल छाड्नुअघदेखि अष्ट्रेलिया आएर पहिलो घर पाउन सम्मको सबै कुरा सिकाउँछ।',
                    style: TextStyle(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              buildStepNepali(
                '१. नेपाल छाड्नुअघ — आवास योजना तयार गर्नुहोस्',
                'उडान अगाडी २–३ हप्ता गर्नुपर्छ:',
                [
                  'जाने सहर (Sydney, Melbourne, Brisbane, Canberra) रिसर्च गर्नुहोस्',
                  'त्यहाँको नेपाली Facebook समूह जोइनुहोस्',
                  'बन्धुबान्धव वा साथीहरूसँग सोधनुहोस्',
                  'पहिलो महिनाको पैसा बचाउनुहोस् (bond + rent)',
                  'सुविधाजनक सुबुर्बको सूची बनाउनुहोस्',
                ],
              ),
              const SizedBox(height: 12),
              buildStepNepali(
                '२. अस्थायी आवास बुक गर्नुहोस् (३–७ दिन)',
                'नेपालबाट कहिले पनि दीर्घकालीन घर बुक नगर्नुहोस्। यसको सट्टा:',
                [
                  'Airbnb, होस्टेल, बजेट होटेल, वा साथीको घर',
                  'यसले तपाईंलाई आएर घर हेर्न समय दिन्छ।',
                ],
              ),
              const SizedBox(height: 12),
              buildStepNepali(
                '३. आएपछी तुरुन्त घर खोज सुरु गर्नुहोस्',
                'यी प्लेटफर्म प्रयोग गर्नुहोस्:',
                [
                  'नेपाली समूह: Kaam Kotha, Nepali Lai Kaam, uNepal',
                  'अन्य: Flatmates.com.au, Facebook Marketplace, Gumtree',
                ],
              ),
              const SizedBox(height: 12),
              buildStepNepali(
                '४. घर मालिकसँग सम्पर्क गर्नुहोस्',
                'विनम्रतापूर्वक सन्देश पठाउनुहोस्:',
                ['कति मानिस बस्छन्? कति किराया? बन्ड कति? कहिले सराउन सक्छु?'],
              ),
              const SizedBox(height: 12),
              buildStepNepali(
                '५. घर हेर्नुहोस् (अत्यन्त महत्त्वपूर्ण)',
                'कहिले पनि पैसा बिना हेरे नदिनुहोस्। हेर्नुहोस्:',
                [
                  'सफाइ, हवा आना, तापक्रम नियन्त्रण, रसोई, पानीघर',
                  'सुरक्षा, जनसंख्या, कीमत',
                  'खतरा: धेरै मानिस, कोई कागजात छैन, स्रोत अप्रमाणित',
                ],
              ),
              const SizedBox(height: 12),
              buildStepNepali('६. खर्च बुझ्नुहोस्', 'साप्ताहिक किराया:', [
                'Sydney: \$180–\$300',
                'Melbourne: \$160–\$280',
                'Brisbane: \$150–\$250',
                'Bond + advance राख्नुपर्छ',
              ]),
              const SizedBox(height: 12),
              buildStepNepali(
                '७. सरल अनुबन्ध हस्ताक्षर गर्नुहोस्',
                'साझा घरमा पनि माग गर्नुहोस्:',
                ['लिखित अनुबन्ध', 'किराया रकम', 'बन्ड', 'नोटिस अवधि (२ हप्ता)'],
              ),
              const SizedBox(height: 12),
              buildStepNepali('८. सराउनुहोस्', 'पैसा दिएपछी:', [
                'बन्ड + advance किराया दिनुहोस्',
                'चाबी लिनुहोस्',
                'घरको फोटो लिनुहोस्',
                'WiFi, मेल दिन, खान पकाउन नियम सोध्नुहोस्',
              ]),
              const SizedBox(height: 12),
              buildStepNepali('९. जालसाजी सावधानी', 'यसबाट सावधान रहनुहोस्:', [
                'पैसा म्याद अगाडि माग्नेहरू',
                'Facebook को नकली बिज्ञापन',
                'धेरै मानिस एक कोठामा',
                'रसीद नदिने मालिक',
              ]),
              const SizedBox(height: 12),
              buildStepNepali(
                '१०. नेपाली विद्यार्थी र कामदारहरूका लागि सुझाव',
                '',
                [
                  'जनसंख्या नजिक रहनुहोस्',
                  'सस्तो घर छोड्नुहोस् — भीडैभाड',
                  'जतो सक्छ देर लिनुहोस्',
                  'वरिष्ठहरूसँग सुझाव लिनुहोस्',
                  'आपतकालीन पैसा राख्नुहोस्',
                ],
              ),
              const SizedBox(height: 16),
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
                    children: const [
                      Text(
                        '✓ छोटो चेकलिस्ट',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'नेपाल छाड्नुअघ: सहर रिसर्च, नेपाली समूह, पैसा बचाउनुहोस्',
                        style: TextStyle(height: 1.5),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'आएपछी: अस्थायी घर, घर खोज, हेरनुहोस्, पैसा दिनुहोस्, सराउनुहोस्',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
