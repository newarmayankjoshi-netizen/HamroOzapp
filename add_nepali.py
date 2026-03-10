#!/usr/bin/env python3
import sys

file_path = 'lib/guides_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Mapping (exact English title -> Nepali translation)
map = [
    ("Buying Your First Car", "आपको पहिलो कार किन्नु"),
    ("Car Insurance Explained", "कार बीमा व्याख्या गरिएको"),
    ("When to Start Applying", "कहिले आवेदन गर्न सुरु गर्ने"),
    ("Application Process", "आवेदन प्रक्रिया"),
    ("Networking Strategies", "नेटवर्किङ रणनीतिहरु"),
    ("Work Rights and Visa Sponsorship", "काम अधिकार र भिसा प्रायोजन"),
    ("When to Upgrade", "कहिले अपग्रेड गर्ने"),
    ("Choosing the Right Suburb", "सही गाउँ चयन गर्नु"),
    ("Renting Process in Australia", "अष्ट्रेलियामा भाडामा दिने प्रक्रिया"),
    ("Partner Visa Options", "साथीदार भिसा विकल्पहरु"),
    ("Bringing Partner to Australia (Visitor)", "साथीदारलाई अष्ट्रेलियामा ल्याउनु (दर्शक)"),
    ("Adjusting Finances as a Couple", "दम्पतीको रूपमा वित्त समायोजन गर्नु"),
    ("Support and Integration", "सहायता र एकीकरण"),
    ("Healthcare and Birth Options", "स्वास्थ्य सेवा र जन्म विकल्पहरु"),
    ("Government Support and Payments", "सरकार सहायता र भुक्तानीहरु"),
    ("Baby Essentials and Costs", "बच्चाको आवश्यकता र लागतहरु"),
    ("Childcare Options", "शिशु देखभाल विकल्पहरु"),
    ("Visitor Visa (Subclass 600)", "दर्शक भिसा (उप श्रेणी 600)"),
    ("Increasing Approval Chances", "अनुमोदन सम्भावना बढाउनु"),
    ("Planning Their Visit", "उनीहरुको भ्रमण योजना गर्नु"),
    ("Saving for Deposit", "जमा को लागि बचत गर्नु"),
    ("Getting a Home Loan", "गृह ऋण पाउनु"),
    ("House Hunting and Buying Process", "घर खोज्ने र खरिद प्रक्रिया"),
    ("PR Pathways Overview", "PR मार्गहरु अवलोकन"),
    ("Points Test Breakdown", "अंक परीक्षा विभाजन"),
    ("Step-by-Step Application Process", "चरणबद्ध आवेदन प्रक्रिया"),
    ("Tips for Successful Application", "सफल आवेदनको लागि सुझावहरु"),
    ("Eligibility Requirements", "योग्यता आवश्यकताहरु"),
    ("Citizenship Test", "नागरिकता परीक्षा"),
    ("Citizenship Ceremony", "नागरिकता समारोह"),
    ("Benefits of Citizenship", "नागरिकता को लाभहरु"),
    ("Why Give Back?", "किन फिर्ता गर्ने?"),
    ("Ways to Get Involved", "संलग्न हुन तरिकाहरु"),
    ("Volunteering Opportunities", "स्वयंसेवक अवसरहरु"),
    ("Leadership and Advocacy", "नेतृत्व र अधिवक्ता"),
]

count = 0
for eng, nep in map:
    before = f"GuideSection(\n                title: '{eng}',"
    after = f"GuideSection(\n                title: '{eng}',\n                nepaliTitle: '{nep}',"
    if before in content:
        content = content.replace(before, after)
        count += 1
        print(f"Updated: {eng}")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\nTotal updated: {count} sections")
