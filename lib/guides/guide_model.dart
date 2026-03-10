class Guide {
  final String emoji;
  final String title;
  final String nepaliTitle;
  final String subtitle;
  final List<GuideSection> sections;

  Guide({
    required this.emoji,
    required this.title,
    required this.nepaliTitle,
    required this.subtitle,
    required this.sections, 
  });
}

class GuideSection {
  final String title;
  final String nepaliTitle;
  final String content;
  final String? nepaliContent;

  GuideSection({
    required this.title,
    required this.nepaliTitle,
    required this.content,
    this.nepaliContent,
  });
}
// ------------------------------------------------------------
// ALL GUIDES (Batch 1 + Batch 2)
// ------------------------------------------------------------

final List<Guide> allGuides = [
  Guide(
  emoji: "🛬",
  title: "Airport & Immigration",
  nepaliTitle: "एयरपोर्ट र इमिग्रेशन",
  subtitle: "Arrival process, documents, customs, SmartGate, biosecurity",
  sections: [
    // -----------------------------
    // SECTION 1 — BEFORE LANDING
    // -----------------------------
    GuideSection(
      title: "Before Landing: What You Must Prepare",
      nepaliTitle: "अष्ट्रेलिया झर्नु अघि तयारी",
      content: """
**Key Things to Prepare Before Landing**
- Keep your passport and visa confirmation easily accessible.
- Fill out the Digital Passenger Declaration (if required).
- Keep your CoE (students), job offer (workers), and accommodation details ready.
- Carry a pen to fill any forms.
- Ensure your phone has enough battery for immigration checks.

**Recommended Folder Setup**
Create a small travel folder containing:
- Passport
- Visa grant letter (PDF + print)
- CoE (students)
- OSHC/OVHC insurance certificate
- Return/onward ticket (if applicable)
- Accommodation booking confirmation
- Emergency contact numbers

**Important Tip**
Immigration officers appreciate clear, honest answers.  
Do not memorize scripts — just answer naturally.
""",
      nepaliContent: """
**झर्नु अघि तयारी**
- राहदानी र भिसा confirmation सजिलै निकाल्न मिल्ने ठाउँमा राख्नुहोस्।
- Digital Passenger Declaration (जरुरी भए) भर्नुहोस्।
- CoE, job offer, accommodation विवरण तयार राख्नुहोस्।
- फारम भर्न कलम साथमा राख्नुहोस्।
- फोनमा battery पर्याप्त राख्नुहोस्।

**साना कागजातहरू एकै ठाउँमा राख्ने**
- राहदानी
- भिसा grant letter
- CoE (विद्यार्थी)
- OSHC/OVHC बीमा
- Accommodation booking
- Emergency नम्बरहरू

**महत्वपूर्ण सुझाव**
इमिग्रेशनमा सत्य र सरल उत्तर दिनुहोस्।  
Script जस्तो बोल्न आवश्यक छैन।
""",
    ),

    // -----------------------------
    // SECTION 2 — IMMIGRATION PROCESS
    // -----------------------------
    GuideSection(
      title: "Step-by-Step Immigration Process",
      nepaliTitle: "इमिग्रेशन प्रक्रिया: चरण-दर-चरण",
      content: """
**1. Disembark the Aircraft**
Follow signs for "Arrivals" or "Baggage Claim".

**2. SmartGate (If Eligible)**
SmartGate uses facial recognition to verify your identity.
Eligibility:
- E-passport
- Age 16+
- Certain nationalities (Nepal is NOT eligible yet)

If not eligible → go to manual counter.

**3. Manual Immigration Counter**
You will:
- Present passport
- Present arrival card (if required)
- Answer simple questions:
  - Why are you coming to Australia?
  - Where will you stay?
  - How long will you stay?
  - Do you have enough funds?

**4. Visa Verification**
Your visa is checked electronically — no stamp required.

**5. Proceed to Baggage Claim**
Follow the screens to find your carousel.

**6. Customs & Biosecurity**
Australia is extremely strict about:
- Food
- Seeds
- Meat
- Dairy
- Plants
- Soil

Declare everything honestly.

**7. Exit to Arrivals Hall**
You can now:
- Buy SIM card
- Meet your pickup
- Use train/bus/Uber
""",
      nepaliContent: """
**१. विमानबाट ओर्लिने**
"Arrivals" वा "Baggage Claim" संकेत पछ्याउनुहोस्।

**२. SmartGate (योग्य भए)**
- Facial recognition प्रयोग हुन्छ।
- नेपाली पासपोर्ट SmartGate मा eligible छैन।

**३. Manual Counter**
तपाईंले:
- राहदानी देखाउनुहुन्छ
- Arrival card दिनुहुन्छ
- सरल प्रश्नको उत्तर दिनुहुन्छ:
  - किन आउनुभएको?
  - कहाँ बस्नुहुन्छ?
  - कति समय बस्नुहुन्छ?
  - पैसा कति छ?

**४. भिसा जाँच**
भिसा इलेक्ट्रोनिक रूपमा verify हुन्छ।

**५. सामान लिनुहोस्**
स्क्रिनमा देखिएको carousel मा जानुहोस्।

**६. भन्सार र बायोसेक्युरिटी**
अष्ट्रेलिया कडा छ:
- खाना
- बीउ
- मासु
- दूध
- बिरुवा
- माटो

सबै कुरा declare गर्नुहोस्।

**७. Arrivals Hall**
अब तपाईं:
- SIM किन्न
- Pickup भेट्न
- Train/bus/Uber प्रयोग गर्न सक्नुहुन्छ।
""",
    ),

    // -----------------------------
    // SECTION 3 — CUSTOMS & BIOSECURITY
    // -----------------------------
    GuideSection(
      title: "Customs & Biosecurity Rules",
      nepaliTitle: "भन्सार र बायोसेक्युरिटी नियम",
      content: """
**Strictly Prohibited Items**
- Fresh fruits and vegetables
- Meat and dairy products
- Seeds, plants, soil
- Traditional homemade food (pickles, gundruk, sukuti)

**Allowed If Declared**
- Packed snacks
- Tea bags
- Sealed spices
- Chocolates

**Penalties**
- False declaration: up to \$420 on the spot
- Serious violations: thousands in fines

**Why Australia Is Strict**
Australia protects its agriculture from pests and diseases.  
Even small mistakes can cause big problems.

**Tip**
When unsure → ALWAYS declare.
""",
      nepaliContent: """
**कडा रूपमा प्रतिबन्धित**
- ताजा फलफूल, तरकारी
- मासु, दूधजन्य पदार्थ
- बीउ, बिरुवा, माटो
- घरमै बनाएको खाना (अचार, गुन्द्रुक, सुकुटी)

**Declare गरे मात्र अनुमति**
- Packed snacks
- Tea bags
- Sealed मसला
- Chocolates

**जरिवाना**
- झुटो घोषणा: \$420 सम्म तुरुन्तै
- गम्भीर गल्ती: हजारौँ जरिवाना

**किन कडा छ?**
अष्ट्रेलियाको कृषि सुरक्षित राख्न।

**सुझाव**
शंका भए → Declare गर्नुहोस्।
""",
    ),

    // -----------------------------
    // SECTION 4 — AFTER IMMIGRATION
    // -----------------------------
    GuideSection(
      title: "After Immigration: What To Do Next",
      nepaliTitle: "इमिग्रेशनपछि के गर्ने?",
      content: """
**1. Buy a SIM Card**
Best options:
- Telstra (best coverage)
- Optus (good + cheaper)
- Vodafone (budget)

**2. Transport Options**
- Train
- Bus
- Uber / Ola / Didi
- Airport shuttle

**3. Contact Family**
Send a quick message that you arrived safely.

**4. Check-in to Accommodation**
Keep your passport ready for verification.

**5. Essentials to Buy**
- Bedding
- Toiletries
- Basic groceries
- Power adapter (AU plug)

**6. Avoid Scams**
Do NOT accept:
- Random job offers
- Random room offers
- People asking for money
""",
      nepaliContent: """
**१. SIM किन्नुहोस्**
- Telstra (सबैभन्दा राम्रो)
- Optus (सस्तो + राम्रो)
- Vodafone (बजेट)

**२. यातायात विकल्प**
- ट्रेन
- बस
- Uber/Ola/Didi
- Shuttle

**३. परिवारलाई खबर गर्नुहोस्**

**४. Accommodation मा check-in गर्नुहोस्**

**५. आवश्यक सामान किन्नुहोस्**
- Bedding
- Toiletries
- Groceries
- AU plug adapter

**६. Scams बाट बच्नुहोस्**
- Random job offer
- Random room offer
- पैसा माग्ने मानिस
""",
    ),
  ],
),

Guide(
  emoji: "💼",
  title: "Finding First Part-Time Job",
  nepaliTitle: "पहिलो अंशकालीन काम खोज्नु",
  subtitle: "Resume, job search, interviews, workplace expectations",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — UNDERSTANDING THE AUSTRALIAN JOB MARKET
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding the Australian Job Market",
      nepaliTitle: "अष्ट्रेलियाको काम बजार बुझ्ने",
      content: """
**Common Part-Time Jobs for Students**
- Retail (Coles, Woolworths, Kmart, Big W)
- Hospitality (cafes, restaurants, bars)
- Delivery (Uber Eats, DoorDash, Menulog)
- Cleaning (houses, offices)
- Warehouse & packing jobs
- Customer service roles

**What Employers Look For**
- Reliability (showing up on time)
- Communication skills
- Basic English understanding
- Positive attitude
- Ability to work in a team

**Important Reality**
Most newcomers do NOT get a job in the first week.  
It usually takes:
- 2–6 weeks for first interview  
- 1–3 months for first stable job  

Consistency is more important than luck.
""",
      nepaliContent: """
**विद्यार्थीका लागि सामान्य कामहरू**
- Retail (Coles, Woolworths, Kmart)
- Cafe/restaurant काम
- Delivery (Uber Eats, DoorDash)
- Cleaning
- Warehouse/packing
- Customer service

**नियोक्ताले के हेर्छन्?**
- समयमै आउने
- Communication skill
- आधारभूत अंग्रेजी
- Positive attitude
- Teamwork

**यथार्थता**
पहिलो हप्तामै काम पाउनु दुर्लभ हुन्छ।  
सामान्यतया:
- २–६ हप्तामा इन्टरभ्यू
- १–३ महिनामा स्थिर काम

धैर्य र निरन्तरता सबैभन्दा महत्वपूर्ण।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — CREATING A PROFESSIONAL RESUME
    // ------------------------------------------------------------
    GuideSection(
      title: "Creating a Professional Resume",
      nepaliTitle: "प्रोफेशनल रिजुमे बनाउने",
      content: """
**Resume Format (1 Page Only)**
1. Contact Information  
2. Summary (2–3 lines)  
3. Skills  
4. Work Experience (if any)  
5. Education  
6. Availability  

**Essential Resume Tips**
- Use an Australian phone number.
- Use a simple Gmail address.
- Keep formatting clean and modern.
- Use bullet points, not long paragraphs.
- Highlight customer service and teamwork.

**Skills Employers Love**
- Communication  
- Time management  
- Fast learner  
- Problem solving  
- Multitasking  

**Common Resume Mistakes**
- Spelling errors  
- Too long (more than 1 page)  
- Adding unnecessary personal details  
- Using fancy fonts  
""",
      nepaliContent: """
**रिजुमे फर्म्याट (१ पेज)**
१. Contact जानकारी  
२. Summary (२–३ लाइन)  
३. Skills  
४. अनुभव (भए)  
५. Education  
६. Availability  

**महत्वपूर्ण टिप्स**
- अष्ट्रेलियाली फोन नम्बर राख्नुहोस्।
- सरल Gmail प्रयोग गर्नुहोस्।
- Clean formatting राख्नुहोस्।
- Bullet points प्रयोग गर्नुहोस्।
- Customer service र teamwork देखाउनुहोस्।

**नियोक्ताले मन पराउने कौशल**
- Communication  
- Time management  
- Fast learner  
- Problem solving  
- Multitasking  

**सामान्य गल्तीहरू**
- Spelling गल्ती  
- १ पेजभन्दा लामो  
- अनावश्यक व्यक्तिगत विवरण  
- Fancy fonts  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — WHERE TO FIND JOBS
    // ------------------------------------------------------------
    GuideSection(
      title: "Where to Find Jobs",
      nepaliTitle: "काम कहाँ खोज्ने?",
      content: """
**Online Job Platforms**
- Seek.com.au
- Indeed.com.au
- Jora.com
- LinkedIn Jobs

**Company Websites**
- Coles Careers
- Woolworths Careers
- Kmart Careers
- McDonald's Careers
- KFC Careers

**Walk-In Applications**
Best for:
- Cafes
- Restaurants
- Small shops
- Local businesses

**Community Sources**
- Facebook groups
- Nepali community pages
- WhatsApp groups
- University job boards

**Tip**
Walk-in applications work best between **2 PM – 4 PM** (quiet hours).
""",
      nepaliContent: """
**अनलाइन प्लेटफर्म**
- Seek
- Indeed
- Jora
- LinkedIn

**कम्पनी वेबसाइट**
- Coles
- Woolworths
- Kmart
- McDonald's
- KFC

**Walk-in आवेदन**
उपयुक्त:
- Cafe
- Restaurant
- साना पसल
- Local business

**समुदाय स्रोत**
- Facebook groups
- Nepali pages
- WhatsApp groups
- University job board

**सुझाव**
Walk-in गर्न सबैभन्दा राम्रो समय: **२–४ बजे**।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — INTERVIEW PREPARATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Interview Preparation",
      nepaliTitle: "इन्टरभ्यू तयारी",
      content: """
**Before the Interview**
- Research the company.
- Practice introducing yourself.
- Prepare 2–3 examples of teamwork.
- Wear clean, simple clothes.

**Common Interview Questions**
- Tell me about yourself.
- Why do you want to work here?
- What are your strengths?
- How do you handle pressure?
- Do you have experience?

**How to Answer Without Experience**
Use the STAR method:
- Situation  
- Task  
- Action  
- Result  

Example:
“I worked in a group project where I helped organise tasks and meet deadlines.”

**Body Language Tips**
- Smile
- Maintain eye contact
- Sit straight
- Speak slowly and clearly
""",
      nepaliContent: """
**इन्टरभ्यू अघि**
- कम्पनीबारे जानकारी लिनुहोस्।
- आफैलाई कसरी introduce गर्ने अभ्यास गर्नुहोस्।
- Teamwork का २–३ उदाहरण तयार राख्नुहोस्।
- सफा र सरल लुगा लगाउनुहोस्।

**सामान्य प्रश्नहरू**
- आफ्नो बारेमा भन्नुहोस्।
- यहाँ किन काम गर्न चाहनुहुन्छ?
- तपाईंका strengths के हुन्?
- Pressure कसरी handle गर्नुहुन्छ?
- अनुभव छ?

**अनुभव नभए कसरी उत्तर दिने?**
STAR method प्रयोग गर्नुहोस्:
- Situation  
- Task  
- Action  
- Result  

**Body language टिप्स**
- मुस्कान
- Eye contact
- Straight बस्ने
- बिस्तारै र स्पष्ट बोल्ने
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — WORKPLACE EXPECTATIONS
    // ------------------------------------------------------------
    GuideSection(
      title: "Workplace Expectations & Rights",
      nepaliTitle: "कार्यस्थल अपेक्षा र अधिकार",
      content: """
**Employer Expectations**
- Arrive 5–10 minutes early.
- Follow instructions carefully.
- Ask questions if unsure.
- Keep phone away during work.
- Maintain hygiene and grooming.

**Your Rights**
- Minimum wage applies to everyone.
- You must receive payslips.
- You cannot be forced to work unpaid.
- Unsafe work can be refused.
- You can report exploitation.

**Red Flags**
- Cash jobs below minimum wage
- No payslips
- No breaks
- Threats or pressure
- Asking for passport/visa copy

**Tip**
If something feels wrong → it probably is.
""",
      nepaliContent: """
**नियोक्ताको अपेक्षा**
- ५–१० मिनेट अगाडि पुग्ने।
- निर्देशन ध्यानपूर्वक सुन्ने।
- नबुझे सोध्ने।
- काममा फोन नचलाउने।
- सफा र व्यवस्थित रहने।

**तपाईंका अधिकार**
- न्यूनतम तलब सबैलाई लागू।
- Payslip अनिवार्य।
- Unpaid काम गर्न बाध्य पार्न पाइँदैन।
- Unsafe काम अस्वीकार गर्न सकिन्छ।
- Exploitation रिपोर्ट गर्न सकिन्छ।

**Red flags**
- न्यूनतम तलबभन्दा कम cash job
- Payslip नदिने
- Break नदिने
- धम्की
- Passport/visa माग्ने

**सुझाव**
गलत लागे → सोध्नुहोस् वा अस्वीकार गर्नुहोस्।
""",
    ),
  ],
),

Guide(
  emoji: "🏠",
  title: "Accommodation & Renting",
  nepaliTitle: "बसोबास र भाडा",
  subtitle: "Inspections, lease, bond, rights, avoiding scams",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — TYPES OF ACCOMMODATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Types of Accommodation in Australia",
      nepaliTitle: "अष्ट्रेलियामा बसोबासका प्रकार",
      content: """
**1. Shared Rooms**
- Cheapest option
- 2–4 people in one room
- Common among students

**2. Private Rooms**
- More privacy
- Higher cost
- Suitable for couples or workers

**3. Studio Apartments**
- Fully private
- Kitchen + bathroom included
- Expensive but comfortable

**4. Homestay**
- Live with an Australian family
- Meals sometimes included
- Good for improving English

**5. Student Accommodation**
- On-campus or near campus
- Safe but expensive
""",
      nepaliContent: """
**१. Shared room**
- सबैभन्दा सस्तो
- २–४ जना एकै कोठामा
- विद्यार्थीमा लोकप्रिय

**२. Private room**
- गोपनीयता
- महँगो
- Couple वा कामदारका लागि उपयुक्त

**३. Studio apartment**
- पूर्ण निजी
- Kitchen + bathroom
- महँगो तर आरामदायी

**४. Homestay**
- अष्ट्रेलियाली परिवारसँग बस्ने
- कहिलेकाहीँ खाना समावेश
- अंग्रेजी सुधारका लागि राम्रो

**५. Student accommodation**
- क्याम्पसमा वा नजिक
- सुरक्षित तर महँगो
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — INSPECTIONS
    // ------------------------------------------------------------
    GuideSection(
      title: "Room/House Inspection Checklist",
      nepaliTitle: "कोठा/घर निरीक्षण चेकलिस्ट",
      content: """
**What to Check During Inspection**
- Cleanliness of room
- Condition of bed/mattress
- Windows and ventilation
- Heating/cooling availability
- Kitchen cleanliness
- Bathroom hygiene
- Internet speed
- Noise level
- Safety locks on doors

**Questions to Ask**
- Are bills included?
- How many people live here?
- Is bond required?
- Minimum stay period?
- Any house rules?

**Red Flags**
- No written agreement
- Overcrowded rooms
- Dirty kitchen/bathroom
- Landlord avoiding questions
""",
      nepaliContent: """
**निरीक्षणमा के हेर्ने?**
- कोठाको सफाइ
- बेड/म्याट्रेसको अवस्था
- झ्याल र हावा
- Heater/cooler छ कि छैन
- Kitchen सफा छ कि छैन
- Bathroom सफा छ कि छैन
- Internet speed
- आवाजको स्तर
- ढोकामा सुरक्षित lock

**सोध्नुपर्ने प्रश्न**
- Bills समावेश छन्?
- कति जना बस्छन्?
- Bond चाहिन्छ?
- Minimum stay कति?
- House rules के छन्?

**Red flags**
- Written agreement नदिने
- धेरै मानिस कोठामा
- फोहोर kitchen/bathroom
- प्रश्न टार्ने landlord
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — LEASE & BOND
    // ------------------------------------------------------------
    GuideSection(
      title: "Lease, Bond & Legal Requirements",
      nepaliTitle: "Lease, Bond र कानुनी आवश्यकताहरू",
      content: """
**Lease Agreement**
- A legal contract between tenant and landlord
- Read carefully before signing
- Check rent amount, notice period, and rules

**Bond**
- Usually 2–4 weeks rent
- Must be lodged with state authority (not kept by landlord)
- You get it back if no damage occurs

**Condition Report**
- Document describing the condition of the property
- Take photos of everything before moving in

**Notice Period**
- Usually 2–4 weeks depending on lease type
""",
      nepaliContent: """
**Lease सम्झौता**
- Tenant र landlord बीचको कानुनी सम्झौता
- हस्ताक्षर गर्नु अघि ध्यानपूर्वक पढ्नुहोस्
- Rent, notice period, rules जाँच्नुहोस्

**Bond**
- सामान्यतया २–४ हप्ता भाडा
- राज्य प्राधिकरणमा lodge गर्नुपर्छ
- क्षति नभए फिर्ता पाइन्छ

**Condition report**
- घरको अवस्था लेखिएको कागज
- भित्रिनु अघि फोटो खिच्नुहोस्

**Notice period**
- Lease अनुसार २–४ हप्ता
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — AVOIDING SCAMS
    // ------------------------------------------------------------
    GuideSection(
      title: "Avoiding Rental Scams",
      nepaliTitle: "भाडा स्क्यामबाट कसरी बच्ने?",
      content: """
**Common Rental Scams**
- Asking for bond before inspection
- Fake Facebook listings
- Landlord refusing video call
- Too cheap to be real

**How to Stay Safe**
- Never pay before inspection
- Always ask for written agreement
- Verify identity of landlord
- Use official rental websites

**If You Suspect a Scam**
- Stop communication
- Do not send money
- Report to platform (Facebook/Marketplace)
""",
      nepaliContent: """
**सामान्य स्क्यामहरू**
- Inspection अघि bond माग्ने
- Fake Facebook listing
- Video call गर्न नमान्ने
- अत्यन्तै सस्तो भाडा

**सुरक्षित रहने तरिका**
- Inspection अघि पैसा नदिनुहोस्
- Written agreement माग्नुहोस्
- Landlord को identity verify गर्नुहोस्
- Official वेबसाइट प्रयोग गर्नुहोस्

**स्क्याम शंका लागेमा**
- तुरुन्तै कुरा बन्द गर्नुहोस्
- पैसा नपठाउनुहोस्
- Platform मा report गर्नुहोस्
""",
    ),
  ],
),

Guide(
  emoji: "🚍",
  title: "Transport in Australia",
  nepaliTitle: "अष्ट्रेलियामा यातायात",
  subtitle: "Cards, buses, trains, rules, safety, saving money",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — TRANSPORT CARDS
    // ------------------------------------------------------------
    GuideSection(
      title: "Transport Cards & How They Work",
      nepaliTitle: "यातायात कार्ड र तिनीहरू कसरी काम गर्छन्",
      content: """
**Major Transport Cards**
- Sydney: Opal Card
- Melbourne: Myki Card
- Brisbane: Go Card
- Canberra: MyWay Card
- Perth: SmartRider

**How It Works**
- Tap on when entering
- Tap off when exiting
- Balance is deducted automatically

**Where to Buy**
- Convenience stores
- Train stations
- Online
- Airport kiosks

**Tip**
Always keep at least \$10 balance to avoid fines.
""",
      nepaliContent: """
**मुख्य कार्डहरू**
- Sydney: Opal
- Melbourne: Myki
- Brisbane: Go Card
- Canberra: MyWay
- Perth: SmartRider

**कसरी काम गर्छ?**
- चढ्दा tap on
- झर्दा tap off
- Balance बाट पैसा काटिन्छ

**कहाँ किन्न सकिन्छ?**
- Convenience store
- Train station
- Online
- Airport kiosk

**सुझाव**
कार्डमा कम्तिमा \$10 राख्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — USING PUBLIC TRANSPORT
    // ------------------------------------------------------------
    GuideSection(
      title: "Using Buses, Trains & Light Rail",
      nepaliTitle: "बस, ट्रेन र लाइट रेल प्रयोग गर्ने",
      content: """
**Buses**
- Stops are clearly marked.
- Press the stop button before your stop.
- Enter from the front door unless otherwise indicated.

**Trains**
- Platforms are numbered.
- Digital boards show arrival times and delays.
- Stand behind the yellow safety line.
- Allow passengers to exit before entering.

**Light Rail / Tram**
- Runs frequently in major cities.
- Tap on/off at platforms (varies by city).
- Doors open automatically or via button.

**Apps to Check Timetables**
- Google Maps
- Moovit
- Local transport apps (Opal, PTV, Transport Canberra)
""",
      nepaliContent: """
**बस**
- Stop स्पष्ट देखिन्छ।
- झर्नु अघि stop बटन थिच्नुहोस्।
- अगाडिको ढोकाबाट प्रवेश गर्नुहोस्।

**ट्रेन**
- Platform नम्बर हुन्छ।
- Digital board मा समय देखिन्छ।
- Yellow line पछाडि उभिनुहोस्।
- पहिले झर्नेहरूलाई बाटो दिनुहोस्।

**लाइट रेल / ट्राम**
- ठूला शहरमा चल्छ।
- Platform मा tap on/off गर्नुपर्छ (शहर अनुसार फरक पर्छ)।
- ढोका आफै खुल्छ वा बटन थिच्नुपर्छ।

**समय हेर्ने एपहरू**
- Google Maps
- Moovit
- स्थानीय transport apps
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — SAVING MONEY
    // ------------------------------------------------------------
    GuideSection(
      title: "Saving Money on Transport",
      nepaliTitle: "यातायातमा पैसा बचत गर्ने तरिका",
      content: """
**Ways to Save**
- Off-peak fares are cheaper.
- Weekly caps limit maximum spending.
- Student concessions available in some states.
- Use multi-trip passes if available.
- Avoid peak-hour travel when possible.

**Example**
Sydney Opal weekly cap ensures you never pay more than a fixed amount per week, no matter how much you travel.
""",
      nepaliContent: """
**पैसा बचत गर्ने तरिका**
- Off-peak भाडा सस्तो हुन्छ।
- Weekly cap ले खर्च सीमित गर्छ।
- केही राज्यमा विद्यार्थी छुट उपलब्ध।
- Multi-trip pass उपलब्ध भए प्रयोग गर्नुहोस्।
- Peak-hour मा यात्रा कम गर्नुहोस्।

**उदाहरण**
Sydney Opal weekly cap: हप्तामा निश्चित रकमभन्दा बढी तिर्नु पर्दैन।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — OTHER TRANSPORT OPTIONS
    // ------------------------------------------------------------
    GuideSection(
      title: "Other Transport Options",
      nepaliTitle: "अन्य यातायात विकल्प",
      content: """
**Ride-Sharing Services**
- Uber
- Ola
- Didi
- Bolt (in some cities)

**Taxis**
- More expensive than ride-share
- Available at taxi ranks or via phone booking

**E-Scooters**
- Available in Canberra, Brisbane, Adelaide, Perth
- Must follow road rules
- Helmet required

**Bicycles**
- Many cities have bike lanes
- Some offer bike-sharing services

**Car Share Services**
- GoGet
- Popcar
- Flexicar
- Great for occasional use without owning a car
""",
      nepaliContent: """
**Ride-sharing सेवा**
- Uber
- Ola
- Didi
- Bolt (केही शहरमा)

**ट्याक्सी**
- Ride-share भन्दा महँगो
- Taxi rank वा फोनबाट बोलाउन सकिन्छ

**E-scooter**
- Canberra, Brisbane, Adelaide, Perth मा उपलब्ध
- Road rule पालना गर्नुपर्छ
- Helmet अनिवार्य

**साइकल**
- धेरै शहरमा bike lane हुन्छ
- Bike-sharing सेवा पनि उपलब्ध

**Car share सेवा**
- GoGet
- Popcar
- Flexicar
- कहिलेकाहीँ कार चाहिनेहरूका लागि उपयुक्त
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — SAFETY & RULES
    // ------------------------------------------------------------
    GuideSection(
      title: "Transport Safety & Rules",
      nepaliTitle: "यातायात सुरक्षा र नियम",
      content: """
**General Safety Tips**
- Keep your belongings close.
- Avoid empty train carriages late at night.
- Sit near the driver on buses if alone.
- Follow platform safety markings.

**Legal Rules**
- No eating or drinking in some transport systems.
- Fines apply for:
  - Not tapping on/off
  - Traveling without a valid ticket
  - Misusing concession cards

**Emergency Situations**
- Press the emergency intercom button.
- Contact station staff.
- Call 000 if needed.
""",
      nepaliContent: """
**सुरक्षा सुझाव**
- सामान नजिक राख्नुहोस्।
- राति खाली coach मा नबस्नुहोस्।
- बसमा एक्लै भए driver नजिक बस्नुहोस्।
- Platform को safety marking पालना गर्नुहोस्।

**कानुनी नियम**
- केही यातायातमा खाना/पानी निषेध।
- Fine लाग्ने अवस्था:
  - Tap on/off नगरेमा
  - Valid ticket बिना यात्रा गर्दा
  - Concession card दुरुपयोग गर्दा

**आपतकालीन स्थिति**
- Emergency intercom थिच्नुहोस्।
- Station staff लाई खबर गर्नुहोस्।
- आवश्यक परे 000 मा फोन गर्नुहोस्।
""",
    ),
  ],
),

Guide(
  emoji: "📚",
  title: "Student Life & University Tips",
  nepaliTitle: "विद्यार्थी जीवन र विश्वविद्यालय टिप्स",
  subtitle: "Classes, assignments, attendance, academic success, support services",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — UNDERSTANDING THE AUSTRALIAN EDUCATION SYSTEM
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding the Australian Education System",
      nepaliTitle: "अष्ट्रेलियाको शिक्षा प्रणाली बुझ्ने",
      content: """
**Types of Classes**
- **Lectures:** Large classes where the main theory is taught.
- **Tutorials:** Small group discussions where you apply concepts.
- **Workshops:** Hands-on learning for practical subjects.
- **Labs:** Required for IT, engineering, and science courses.

**Attendance Rules**
- Some universities track attendance.
- Missing too many tutorials may affect grades.
- International students must maintain satisfactory progress.

**Learning Style in Australia**
- Independent learning is expected.
- Students must read materials before class.
- Asking questions is encouraged.
""",
      nepaliContent: """
**क्लासका प्रकार**
- **Lecture:** ठूलो कक्षा, सिद्धान्त पढाइ।
- **Tutorial:** सानो समूह, अभ्यास र छलफल।
- **Workshop:** Practical सिकाइ।
- **Lab:** IT, engineering, science मा अनिवार्य।

**Attendance नियम**
- केही विश्वविद्यालयले attendance ट्र्याक गर्छन्।
- धेरै tutorial छुटे ग्रेडमा असर पर्छ।
- International विद्यार्थीले satisfactory progress राख्नुपर्छ।

**अष्ट्रेलियाको पढाइ शैली**
- Self-study अपेक्षित।
- कक्षा अघि सामग्री पढ्नुपर्छ।
- प्रश्न सोध्न प्रोत्साहन गरिन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — ASSIGNMENTS & DEADLINES
    // ------------------------------------------------------------
    GuideSection(
      title: "Assignments, Deadlines & Academic Integrity",
      nepaliTitle: "असाइनमेन्ट, समयसीमा र Academic Integrity",
      content: """
**Types of Assignments**
- Essays
- Reports
- Case studies
- Presentations
- Group projects
- Quizzes and exams

**Submission Platforms**
- Canvas
- Moodle
- Blackboard
- Turnitin

**Late Submission Penalties**
- 5–10% deduction per day
- Zero marks after a certain number of days

**Academic Integrity**
- No plagiarism
- No copying from friends
- No using AI without permission
- Always cite sources

**Extensions**
You can request an extension if:
- You are sick
- You have personal emergencies
- You provide evidence (medical certificate)
""",
      nepaliContent: """
**असाइनमेन्टका प्रकार**
- Essay
- Report
- Case study
- Presentation
- Group project
- Quiz/Exam

**बुझाउने प्लेटफर्म**
- Canvas
- Moodle
- Blackboard
- Turnitin

**ढिलो बुझाउँदा जरिवाना**
- प्रति दिन 5–10% कटौती
- धेरै ढिलो भए Zero marks

**Academic Integrity**
- Plagiarism कडा रूपमा निषेध
- साथीको assignment नक्कल गर्न नपाइने
- अनुमति बिना AI प्रयोग नगर्नु
- Source cite गर्नैपर्छ

**Extension**
Extension पाउन सकिन्छ यदि:
- बिरामी परे
- आपतकालीन अवस्था भयो
- Medical प्रमाण छ
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — STUDENT SUPPORT SERVICES
    // ------------------------------------------------------------
    GuideSection(
      title: "Student Support Services You Should Use",
      nepaliTitle: "विद्यार्थी सहायता सेवाहरू",
      content: """
**Academic Support**
- Writing workshops
- Assignment feedback
- Study skills coaching

**Wellbeing Support**
- Free counselling
- Mental health support
- Stress management workshops

**Career Support**
- Resume building
- Interview practice
- Job search guidance

**International Student Support**
- Visa advice
- Orientation programs
- Cultural adjustment support
""",
      nepaliContent: """
**Academic Support**
- Writing workshop
- Assignment feedback
- Study skills coaching

**Wellbeing Support**
- निःशुल्क counselling
- Mental health support
- Stress management workshop

**Career Support**
- Resume बनाउने सहयोग
- Interview practice
- Job search guidance

**International Student Support**
- Visa सम्बन्धी सहयोग
- Orientation कार्यक्रम
- सांस्कृतिक अनुकूलन सहयोग
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — MAKING FRIENDS & NETWORKING
    // ------------------------------------------------------------
    GuideSection(
      title: "Making Friends, Networking & Campus Life",
      nepaliTitle: "साथी बनाउने, नेटवर्किङ र क्याम्पस जीवन",
      content: """
**How to Make Friends**
- Join clubs and societies.
- Attend university events.
- Participate in group projects.
- Volunteer on campus.

**Networking Tips**
- Talk to classmates.
- Attend career fairs.
- Connect with lecturers.
- Join LinkedIn groups.

**Campus Life Activities**
- Sports clubs
- Cultural clubs
- Music & arts groups
- Student leadership programs
""",
      nepaliContent: """
**साथी कसरी बनाउने?**
- क्लब र समाजमा सहभागी हुनुहोस्।
- विश्वविद्यालयका कार्यक्रमहरूमा जानुहोस्।
- Group project मा सक्रिय हुनुहोस्।
- क्याम्पसमा volunteer गर्नुहोस्।

**नेटवर्किङ टिप्स**
- Classmates सँग कुरा गर्नुहोस्।
- Career fair मा जानुहोस्।
- Lecturer सँग सम्बन्ध बनाउनुहोस्।
- LinkedIn group मा join गर्नुहोस्।

**क्याम्पस गतिविधि**
- Sports club
- Cultural club
- Music/Arts group
- Leadership program
""",
    ),
  
    // ------------------------------------------------------------
    // SECTION 1 — OPENING A BANK ACCOUNT
    // ------------------------------------------------------------
    GuideSection(
      title: "Opening a Bank Account in Australia",
      nepaliTitle: "अष्ट्रेलियामा बैंक खाता खोल्ने",
      content: """
**Major Banks**
- Commonwealth Bank (CBA)
- ANZ
- NAB
- Westpac

**Documents Required**
- Passport
- Visa grant letter
- Australian address
- Phone number

**Types of Accounts**
- Everyday account (daily use)
- Savings account (interest earning)

**How to Open**
- Visit a branch
- Apply online
- Use mobile app (some banks allow full digital onboarding)

**Tips**
- Students often get fee-free accounts.
- Keep your bank app secure with biometrics.
""",
      nepaliContent: """
**मुख्य बैंकहरू**
- Commonwealth Bank
- ANZ
- NAB
- Westpac

**आवश्यक कागजात**
- राहदानी
- Visa grant letter
- अष्ट्रेलियाको ठेगाना
- फोन नम्बर

**खाताका प्रकार**
- Everyday account (दैनिक खर्च)
- Savings account (बचत)

**कसरी खोल्ने?**
- Branch मा गएर
- Online
- Mobile app बाट

**सुझाव**
- विद्यार्थीलाई प्रायः शुल्क‑मुक्त खाता।
- Bank app लाई biometric ले सुरक्षित राख्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — TAX FILE NUMBER (TFN)
    // ------------------------------------------------------------
    GuideSection(
      title: "Tax File Number (TFN): Why You Need It",
      nepaliTitle: "TFN: किन आवश्यक छ?",
      content: """
**What Is TFN?**
A unique number issued by the Australian Taxation Office (ATO).

**Why You Need TFN**
- Required for any job
- Prevents higher tax deductions
- Needed for bank interest reporting
- Required for superannuation

**How to Apply**
- Apply online on ATO website
- Takes 10–28 days to arrive
- Delivered to your postal address

**Common Mistakes**
- Giving wrong address → TFN lost
- Not applying early → delayed job start
""",
      nepaliContent: """
**TFN के हो?**
ATO ले दिने एक unique नम्बर।

**किन आवश्यक?**
- काम गर्न अनिवार्य
- TFN नभए उच्च कर काटिन्छ
- बैंक interest रिपोर्ट गर्न
- Superannuation का लागि

**कसरी आवेदन दिने?**
- ATO वेबसाइटबाट अनलाइन
- 10–28 दिन लाग्न सक्छ
- Postal address मा पठाइन्छ

**सामान्य गल्ती**
- गलत ठेगाना → TFN हराउने
- ढिलो आवेदन → काम सुरु ढिलो
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — SUPERANNUATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding Superannuation (Retirement Savings)",
      nepaliTitle: "सुपरएनुएशन बुझ्ने",
      content: """
**What Is Superannuation?**
A compulsory retirement savings fund paid by employers.

**When Do You Get Super?**
- If you earn above a certain threshold
- Paid into your super fund every pay cycle

**Choosing a Super Fund**
- AustralianSuper
- HostPlus
- REST
- Aware Super

**What You Should Check**
- Fees
- Investment options
- Insurance included

**Claiming Super When Leaving Australia**
- Apply for DASP (Departing Australia Superannuation Payment)
- Tax applies depending on visa type
""",
      nepaliContent: """
**Superannuation के हो?**
नियोक्ताले तिर्ने retirement बचत।

**कहिले पाउने?**
- निश्चित कमाइ भए
- प्रत्येक pay cycle मा super जम्मा हुन्छ

**Super fund छान्ने**
- AustralianSuper
- HostPlus
- REST
- Aware Super

**के जाँच्ने?**
- Fees
- Investment विकल्प
- Insurance

**अष्ट्रेलिया छोड्दा Super फिर्ता**
- DASP मार्फत आवेदन
- Visa अनुसार कर लाग्छ
""",
    ),
  ],
),

Guide(
  emoji: "⚖️",
  title: "Workplace Rights",
  nepaliTitle: "कार्यस्थल अधिकार",
  subtitle: "Minimum wage, safety, payslips, unfair treatment, legal protections",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — MINIMUM WAGE
    // ------------------------------------------------------------
    GuideSection(
      title: "Minimum Wage & Fair Pay",
      nepaliTitle: "न्यूनतम तलब र Fair Pay",
      content: """
**Minimum Wage**
Australia has a national minimum wage set by Fair Work.

**Industry Awards**
Different industries have different pay rates:
- Hospitality Award
- Retail Award
- Cleaning Award
- Fast Food Award

**Penalty Rates**
Higher pay applies on:
- Weekends
- Public holidays
- Late-night shifts

**Cash Jobs**
Cash jobs must still follow minimum wage laws.
""",
      nepaliContent: """
**न्यूनतम तलब**
अष्ट्रेलियामा Fair Work ले तय गर्छ।

**Industry Award**
उद्योग अनुसार तलब फरक:
- Hospitality
- Retail
- Cleaning
- Fast Food

**Penalty Rate**
यी समयमा तलब बढी:
- Weekend
- Public holiday
- राति

**Cash Job**
Cash job मा पनि न्यूनतम तलब लागू हुन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — PAYSLIPS & RECORDS
    // ------------------------------------------------------------
    GuideSection(
      title: "Payslips, Records & Your Legal Rights",
      nepaliTitle: "Payslip, रेकर्ड र कानुनी अधिकार",
      content: """
**Payslips Must Include**
- Hours worked
- Hourly rate
- Tax deducted
- Superannuation
- Employer ABN

**When You Receive Payslips**
- Weekly or fortnightly
- Must be provided electronically or on paper

**Why Payslips Matter**
- Proof of income
- Required for visa extensions
- Helps track underpayment
""",
      nepaliContent: """
**Payslip मा के हुन्छ?**
- काम गरेको घण्टा
- प्रति घण्टा दर
- काटिएको कर
- Superannuation
- Employer ABN

**कहिले पाउने?**
- हप्तामा वा पन्ध्र दिनमा
- Email वा कागजमा

**किन महत्वपूर्ण?**
- आयको प्रमाण
- Visa extension का लागि
- Underpayment पत्ता लगाउन
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — SAFETY & HARASSMENT
    // ------------------------------------------------------------
    GuideSection(
      title: "Workplace Safety, Bullying & Harassment",
      nepaliTitle: "कार्यस्थल सुरक्षा, धम्की र उत्पीडन",
      content: """
**Safety Rights**
- You must receive safety training.
- You can refuse unsafe work.
- Employers must provide safety equipment.

**Bullying & Harassment**
Illegal behaviours include:
- Verbal abuse
- Threats
- Unwanted touching
- Discrimination

**Reporting**
- Report to supervisor
- Contact Fair Work Ombudsman
- Keep written evidence
""",
      nepaliContent: """
**सुरक्षा अधिकार**
- Safety training पाउनुपर्छ।
- Unsafe काम अस्वीकार गर्न सकिन्छ।
- Safety equipment दिनुपर्छ।

**धम्की र उत्पीडन**
अवैध व्यवहार:
- गालीगलौज
- धम्की
- अवाञ्छित छोइछोइ
- भेदभाव

**रिपोर्ट गर्ने**
- Supervisor लाई भन्नुहोस्
- Fair Work Ombudsman
- Evidence सुरक्षित राख्नुहोस्
""",
    ),
  ],
),

Guide(
  emoji: "🍲",
  title: "Food, Groceries & Nepali Stores",
  nepaliTitle: "खाना, किराना र नेपाली स्टोर",
  subtitle: "Where to shop, saving money, Nepali ingredients, meal planning",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — WHERE TO SHOP
    // ------------------------------------------------------------
    GuideSection(
      title: "Where to Buy Groceries",
      nepaliTitle: "किराना कहाँ किन्ने",
      content: """
**Major Supermarkets**
- Coles
- Woolworths
- Aldi (cheapest)

**Asian Grocery Stores**
- Fresh vegetables
- Spices
- Rice and lentils
- Nepali ingredients

**Nepali Stores (in major cities)**
- Momo wrappers
- Achar
- Beaten rice (chiura)
- Ghee
""",
      nepaliContent: """
**मुख्य सुपरमार्केट**
- Coles
- Woolworths
- Aldi (सबैभन्दा सस्तो)

**Asian Grocery Store**
- ताजा तरकारी
- मसला
- चामल, दाल
- नेपाली सामग्री

**नेपाली स्टोर (ठूला शहरमा)**
- Momo wrapper
- अचार
- चिउरा
- घ्यू
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — SAVING MONEY
    // ------------------------------------------------------------
    GuideSection(
      title: "Saving Money on Food",
      nepaliTitle: "खानामा पैसा बचत गर्ने तरिका",
      content: """
**Tips to Save**
- Buy in bulk during sales.
- Compare prices using apps.
- Cook at home instead of eating out.
- Freeze leftover meals.
- Buy seasonal vegetables.

**Meal Planning**
- Plan weekly meals.
- Make a shopping list.
- Avoid impulse buying.
""",
      nepaliContent: """
**पैसा बचत गर्ने तरिका**
- Sale हुँदा धेरै किन्नुहोस्।
- एप प्रयोग गरेर मूल्य तुलना गर्नुहोस्।
- बाहिर खानुभन्दा घरमै पकाउनुहोस्।
- बाँकी खाना freeze गर्नुहोस्।
- Seasonal तरकारी किन्नुहोस्।

**Meal Planning**
- हप्ताको खाना योजना बनाउनुहोस्।
- Shopping list बनाउनुहोस्।
- अनावश्यक सामान नकिन्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — NEPALI INGREDIENTS
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Nepali Ingredients & Where to Find Them",
      nepaliTitle: "नेपाली सामग्री र कहाँ पाइन्छ",
      content: """
**Common Ingredients**
- Basmati rice
- Lentils (masoor, moong, chana)
- Spices (jeera, dhaniya, turmeric)
- Ghee
- Momo wrappers
- Achar

**Where to Find**
- Asian stores
- Nepali stores
- Indian stores
""",
      nepaliContent: """
**नेपाली सामग्री**
- बास्मती चामल
- दाल (मसुरो, मूँग, चना)
- मसला (जिरा, धनियाँ, बेसार)
- घ्यू
- Momo wrapper
- अचार

**कहाँ पाइन्छ?**
- Asian store
- Nepali store
- Indian store
""",
    ),
  ],
),

Guide(
  emoji: "🇦🇺",
  title: "Australian Culture & Etiquette",
  nepaliTitle: "अष्ट्रेलियाली संस्कृति र व्यवहार",
  subtitle: "Social norms, communication style, workplace culture, daily etiquette",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — SOCIAL BEHAVIOUR
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding Australian Social Behaviour",
      nepaliTitle: "अष्ट्रेलियाली सामाजिक व्यवहार बुझ्ने",
      content: """
**General Social Norms**
- Australians value politeness and respect.
- People are friendly but prefer personal space.
- Smiling and saying “Hi” is common even to strangers.
- Queueing (standing in line) is taken seriously.

**Personal Space**
- Avoid standing too close.
- Do not touch people casually.
- Ask before hugging or shaking hands if unsure.

**Punctuality**
- Being on time is considered respectful.
- Arriving late without notice is seen as rude.

**Equality**
- Australia is an egalitarian society.
- People address each other by first names, even bosses.
""",
      nepaliContent: """
**सामान्य सामाजिक व्यवहार**
- अष्ट्रेलियालीहरू विनम्रता र सम्मानलाई महत्व दिन्छन्।
- मैत्रीपूर्ण तर व्यक्तिगत space चाहन्छन्।
- अपरिचितलाई पनि “Hi” भन्नु सामान्य हो।
- Line (queue) मा बस्ने कडा नियम छ।

**Personal Space**
- धेरै नजिक नबस्नुहोस्।
- अनावश्यक छोइछोइ नगर्नुहोस्।
- Hug वा handshake अघि अनुमति लिनुहोस्।

**समयपालन**
- समयमै पुग्नु सम्मानजनक मानिन्छ।
- बिना जानकारी ढिलो हुनु असभ्य मानिन्छ।

**Equality**
- सबैलाई बराबरी व्यवहार।
- Boss लाई पनि first name ले बोलाइन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — COMMUNICATION STYLE
    // ------------------------------------------------------------
    GuideSection(
      title: "Communication Style in Australia",
      nepaliTitle: "अष्ट्रेलियाको संचार शैली",
      content: """
**Direct but Polite**
- Australians speak clearly and directly.
- They avoid overly formal language.
- Honesty is appreciated.

**Humour**
- Jokes and sarcasm are common.
- Not meant to offend — part of friendly culture.

**Small Talk Topics**
Safe topics include:
- Weather
- Sports
- Weekend plans
- Travel

Avoid:
- Religion
- Politics
- Money
""",
      nepaliContent: """
**सिधा तर विनम्र बोल्ने शैली**
- स्पष्ट र सिधा कुरा गर्छन्।
- धेरै formal भाषा प्रयोग हुँदैन।
- इमान्दार उत्तर मन पर्छ।

**Humour**
- मजाक र sarcasm सामान्य।
- अपमान होइन, मैत्रीपूर्ण शैली हो।

**Small Talk विषय**
- मौसम
- खेलकुद
- Weekend योजना
- यात्रा

बच्नुपर्ने विषय:
- धर्म
- राजनीति
- पैसा
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — WORKPLACE CULTURE
    // ------------------------------------------------------------
    GuideSection(
      title: "Workplace Culture & Professional Behaviour",
      nepaliTitle: "कार्यस्थल संस्कृति र पेशागत व्यवहार",
      content: """
**Workplace Expectations**
- Arrive on time.
- Communicate clearly.
- Respect everyone equally.
- Follow safety rules.

**Teamwork**
- Collaboration is highly valued.
- Everyone’s opinion matters.

**Work-Life Balance**
- Australians separate work and personal life.
- Overtime is not encouraged unless necessary.

**Dress Code**
- Varies by workplace.
- Hospitality: black pants + black shoes.
- Office: smart casual.
""",
      nepaliContent: """
**कार्यस्थल अपेक्षा**
- समयमै पुग्नुहोस्।
- स्पष्ट रूपमा कुरा गर्नुहोस्।
- सबैलाई बराबरी सम्मान।
- Safety नियम पालना।

**Teamwork**
- समूहमा कामलाई महत्व।
- सबैको विचार सुन्ने।

**Work-Life Balance**
- काम र व्यक्तिगत जीवन अलग राखिन्छ।
- अनावश्यक overtime प्रोत्साहित हुँदैन।

**Dress Code**
- Workplace अनुसार फरक।
- Hospitality: कालो पाइन्ट + कालो जुत्ता।
- Office: Smart casual।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — DAILY ETIQUETTE
    // ------------------------------------------------------------
    GuideSection(
      title: "Daily Etiquette & Good Manners",
      nepaliTitle: "दैनिक व्यवहार र शिष्टाचार",
      content: """
**Public Behaviour**
- Keep noise low in public transport.
- Do not litter.
- Give priority seats to elderly or disabled.

**Dining Etiquette**
- Pay separately unless someone offers.
- Tipping is optional but appreciated.
- Say “Thank you” to staff.

**Respecting Rules**
- Follow signs and instructions.
- Do not cross roads without pedestrian lights.
""",
      nepaliContent: """
**सार्वजनिक व्यवहार**
- Public transport मा आवाज कम राख्नुहोस्।
- फोहोर नफाल्नुहोस्।
- Elderly वा disabled लाई सीट दिनुहोस्।

**Dining Etiquette**
- Bill प्रायः अलग-अलग तिर्ने।
- Tipping अनिवार्य होइन तर राम्रो मानिन्छ।
- Staff लाई “Thank you” भन्नुहोस्।

**नियमको सम्मान**
- Signboard र निर्देश पालना।
- Pedestrian light बिना बाटो नकटाउनुहोस्।
""",
    ),
  ],
),

Guide(
  emoji: "🧭",
  title: "Survival Tips for Newcomers",
  nepaliTitle: "नयाँ आउनेहरूका लागि जीवनरक्षक टिप्स",
  subtitle: "Money, safety, transport, communication, daily life",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — MONEY MANAGEMENT
    // ------------------------------------------------------------
    GuideSection(
      title: "Money Management & Budgeting",
      nepaliTitle: "पैसा व्यवस्थापन र बजेट",
      content: """
**Why Budgeting Matters**
Australia is expensive.  
Budgeting helps you survive the first few months.

**Essential Monthly Expenses**
- Rent
- Groceries
- Transport
- Phone plan
- Utilities
- Emergency savings

**Tips**
- Track expenses using apps.
- Avoid unnecessary subscriptions.
- Cook at home.
""",
      nepaliContent: """
**किन बजेट आवश्यक?**
अष्ट्रेलिया महँगो देश हो।  
बजेटले पहिलो महिना सजिलै बिताउन मद्दत गर्छ।

**महिनाको मुख्य खर्च**
- भाडा
- किराना
- यातायात
- फोन प्लान
- Utilities
- Emergency बचत

**सुझाव**
- App बाट खर्च ट्र्याक गर्नुहोस्।
- अनावश्यक subscription हटाउनुहोस्।
- घरमै पकाउनुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — SAFETY
    // ------------------------------------------------------------
    GuideSection(
      title: "Personal Safety & Emergency Awareness",
      nepaliTitle: "व्यक्तिगत सुरक्षा र आपतकालीन जानकारी",
      content: """
**Emergency Numbers**
- 000 → Police, Fire, Ambulance
- 131 444 → Non-emergency police

**Safety Tips**
- Avoid walking alone late at night.
- Stay in well-lit areas.
- Keep your phone charged.
- Do not share personal details with strangers.

**Scam Awareness**
- Do not trust random job offers.
- Never pay bond without inspection.
- Do not share bank details.
""",
      nepaliContent: """
**आपतकालीन नम्बर**
- 000 → Police, Fire, Ambulance
- 131 444 → Non-emergency police

**सुरक्षा सुझाव**
- राति एक्लै नहिँड्नुहोस्।
- उज्यालो ठाउँमा बस्नुहोस्।
- फोन चार्ज राख्नुहोस्।
- अपरिचितलाई व्यक्तिगत जानकारी नदिनुहोस्।

**Scam बाट बच्ने**
- Random job offer नमान्नुहोस्।
- Inspection बिना bond नतिर्नुहोस्।
- Bank विवरण नदिनुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — DAILY LIFE
    // ------------------------------------------------------------
    GuideSection(
      title: "Daily Life Tips for Newcomers",
      nepaliTitle: "दैनिक जीवनका सुझाव",
      content: """
**Weather**
- Australia has strong sun.
- Use sunscreen.
- Carry water.

**Shopping**
- Compare prices.
- Buy in bulk.
- Use discount apps.

**Health**
- Register with a GP.
- Keep OSHC card with you.
""",
      nepaliContent: """
**मौसम**
- अष्ट्रेलियामा घाम कडा हुन्छ।
- Sunscreen प्रयोग गर्नुहोस्।
- पानी बोकेर हिँड्नुहोस्।

**किनमेल**
- मूल्य तुलना गर्नुहोस्।
- Bulk मा किन्नुहोस्।
- Discount app प्रयोग गर्नुहोस्।

**स्वास्थ्य**
- GP सँग दर्ता गर्नुहोस्।
- OSHC कार्ड साथमा राख्नुहोस्।
""",
    ),
  ],
),

Guide(
  emoji: "🚨",
  title: "Scams & Safety",
  nepaliTitle: "Scams र सुरक्षा",
  subtitle: "Common scams, how to avoid them, emergency actions",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — COMMON SCAMS
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Scams Targeting Newcomers",
      nepaliTitle: "नयाँ आउनेहरूलाई हुने सामान्य Scams",
      content: """
**Job Scams**
- Fake job offers on social media
- Asking for upfront payment
- No interview required

**Room Scams**
- Asking bond before inspection
- Fake photos
- No rental agreement

**Phone Scams**
- Fake ATO calls
- Threatening visa cancellation
- Asking for gift cards
""",
      nepaliContent: """
**Job Scam**
- Social media मा fake job
- पहिले पैसा माग्ने
- Interview बिना job दिने

**Room Scam**
- Inspection अघि bond माग्ने
- Fake फोटो
- Rental agreement नदिने

**Phone Scam**
- Fake ATO call
- Visa cancel गर्ने धम्की
- Gift card माग्ने
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — HOW TO AVOID SCAMS
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Avoid Scams",
      nepaliTitle: "Scam बाट कसरी बच्ने",
      content: """
**Tips**
- Never pay before inspection.
- Do not share passport details.
- Verify job offers on official websites.
- Do not trust unknown phone numbers.

**Red Flags**
- Too good to be true offers
- Urgent payment requests
- Threatening language
""",
      nepaliContent: """
**सुझाव**
- Inspection अघि पैसा नतिर्नुहोस्।
- Passport विवरण नदिनुहोस्।
- Job offer official वेबसाइटमा verify गर्नुहोस्।
- Unknown नम्बर नमान्नुहोस्।

**Red Flag**
- धेरै नै राम्रो देखिने offer
- तुरुन्तै पैसा माग्ने
- धम्की दिने भाषा
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — WHAT TO DO IF SCAMMED
    // ------------------------------------------------------------
    GuideSection(
      title: "What To Do If You Get Scammed",
      nepaliTitle: "Scam परे के गर्ने?",
      content: """
**Steps**
1. Stop communication immediately.
2. Take screenshots of messages.
3. Report to:
   - Scamwatch
   - Police (if money lost)
4. Inform your bank.
5. Warn others.

**Do Not**
- Do not negotiate with scammers.
- Do not send more money.
""",
      nepaliContent: """
**के गर्ने?**
1. तुरुन्तै सम्पर्क बन्द गर्नुहोस्।
2. Screenshot राख्नुहोस्।
3. Report गर्नुहोस्:
   - Scamwatch
   - Police (पैसा हराएमा)
4. बैंकलाई खबर गर्नुहोस्।
5. अरूलाई चेतावनी दिनुहोस्।

**नगर्नु पर्ने**
- Scammer सँग कुरा नगर्नुहोस्।
- थप पैसा नपठाउनुहोस्।
""",
    ),
  ],
),

Guide(
  emoji: "📱",
  title: "Essential Apps in Australia",
  nepaliTitle: "अष्ट्रेलियामा आवश्यक एपहरू",
  subtitle: "Transport, banking, jobs, safety, communication",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — TRANSPORT APPS
    // ------------------------------------------------------------
    GuideSection(
      title: "Transport Apps You Must Have",
      nepaliTitle: "यातायातका आवश्यक एपहरू",
      content: """
**General**
- Google Maps
- Moovit

**City-Specific**
- Sydney: Opal Travel
- Melbourne: PTV
- Canberra: Transport Canberra
- Brisbane: Translink

**Ride-Share**
- Uber
- Ola
- Didi
""",
      nepaliContent: """
**सामान्य**
- Google Maps
- Moovit

**शहर अनुसार**
- Sydney: Opal Travel
- Melbourne: PTV
- Canberra: Transport Canberra
- Brisbane: Translink

**Ride-share**
- Uber
- Ola
- Didi
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — JOB & WORK APPS
    // ------------------------------------------------------------
    GuideSection(
      title: "Job Search & Work Apps",
      nepaliTitle: "काम खोज्ने र कामका एपहरू",
      content: """
**Job Search**
- Seek
- Indeed
- Jora
- LinkedIn

**Work Management**
- Deputy
- WorkJam
- Xero Me
""",
      nepaliContent: """
**काम खोज्ने**
- Seek
- Indeed
- Jora
- LinkedIn

**काम व्यवस्थापन**
- Deputy
- WorkJam
- Xero Me
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — BANKING & MONEY
    // ------------------------------------------------------------
    GuideSection(
      title: "Banking & Money Apps",
      nepaliTitle: "बैंकिङ र पैसा सम्बन्धी एपहरू",
      content: """
**Bank Apps**
- Commonwealth
- ANZ
- NAB
- Westpac

**Money Transfer**
- Remitly
- WorldRemit
- Wise

**Budgeting**
- Frollo
- Pocketbook
""",
      nepaliContent: """
**बैंक एपहरू**
- Commonwealth
- ANZ
- NAB
- Westpac

**पैसा पठाउने**
- Remitly
- WorldRemit
- Wise

**बजेट एप**
- Frollo
- Pocketbook
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — SAFETY & HEALTH
    // ------------------------------------------------------------
    GuideSection(
      title: "Safety & Health Apps",
      nepaliTitle: "सुरक्षा र स्वास्थ्य एपहरू",
      content: """
**Safety**
- Emergency Plus
- SES apps (state-specific)

**Health**
- HotDoc (doctor booking)
- Healthdirect
""",
      nepaliContent: """
**सुरक्षा**
- Emergency Plus
- SES apps

**स्वास्थ्य**
- HotDoc (doctor booking)
- Healthdirect
""",
    ),
  ],
),

Guide(
  emoji: "🏥",
  title: "Health, OSHC & Emergencies",
  nepaliTitle: "स्वास्थ्य, OSHC र आपतकालीन सेवा",
  subtitle: "How to access healthcare, insurance, emergencies",
  sections: [
    // ------------------------------------------------------------
    // SECTION 1 — OSHC
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding OSHC (Overseas Student Health Cover)",
      nepaliTitle: "OSHC बुझ्ने",
      content: """
**What OSHC Covers**
- GP visits (partially)
- Hospital treatment
- Emergency services
- Prescription medicines (limited)

**What It Does NOT Cover**
- Dental
- Optical
- Physiotherapy (mostly)

**How to Use OSHC**
- Show your OSHC card at clinics.
- Claim refunds through the app.
- Keep your OSHC policy number saved on your phone.

**Choosing an OSHC Provider**
Common providers:
- Bupa
- Medibank
- Allianz
- nib

Compare:
- Waiting periods
- Claim process
- Coverage limits
""",
      nepaliContent: """
**OSHC ले के कभर गर्छ?**
- GP भेट (आंशिक)
- Hospital उपचार
- Emergency सेवा
- Prescription औषधि (सीमित)

**के कभर गर्दैन?**
- Dental
- Optical
- Physiotherapy

**कसरी प्रयोग गर्ने?**
- Clinic मा OSHC कार्ड देखाउनुहोस्।
- App बाट refund claim गर्नुहोस्।
- Policy नम्बर फोनमा सुरक्षित राख्नुहोस्।

**OSHC Provider छान्ने**
- Bupa
- Medibank
- Allianz
- nib

हेर्नुपर्ने कुरा:
- Waiting period
- Claim प्रक्रिया
- Coverage सीमा
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — GP & HOSPITAL
    // ------------------------------------------------------------
    GuideSection(
      title: "GP, Hospitals & How Healthcare Works",
      nepaliTitle: "GP, Hospital र स्वास्थ्य प्रणाली",
      content: """
**GP (General Practitioner)**
- First point of contact for health issues.
- Book appointments through HotDoc or clinic websites.
- GP will refer you to specialists if needed.

**Hospitals**
- Emergency departments handle serious issues.
- Long waiting times for non-life-threatening cases.
- Bring your OSHC card and ID.

**Bulk Billing**
Some clinics offer free GP visits if:
- They bulk bill OSHC
- Your OSHC provider has a partnership

**Pharmacies (Chemists)**
- Open long hours
- Provide over-the-counter medicines
- Pharmacists can give basic health advice
""",
      nepaliContent: """
**GP**
- स्वास्थ्य समस्याको पहिलो सम्पर्क।
- HotDoc वा clinic वेबसाइटबाट appointment लिन सकिन्छ।
- GP ले आवश्यक परे specialist मा refer गर्छ।

**Hospital**
- Emergency को लागि।
- Non-emergency मा लामो प्रतीक्षा हुन सक्छ।
- OSHC कार्ड र ID साथमा राख्नुहोस्।

**Bulk Billing**
कुनै GP ले निःशुल्क सेवा दिन सक्छ यदि:
- Bulk bill गर्छ
- OSHC provider सँग partnership छ

**Pharmacy**
- लामो समय खुला हुन्छ
- सामान्य औषधि पाइन्छ
- Pharmacist ले आधारभूत स्वास्थ्य सल्लाह दिन्छ
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — EMERGENCIES
    // ------------------------------------------------------------
    GuideSection(
      title: "Emergency Services & What To Do",
      nepaliTitle: "आपतकालीन सेवा र के गर्ने?",
      content: """
**Emergency Number**
- 000 → Police, Fire, Ambulance

**When To Call 000**
- Serious injury
- Difficulty breathing
- Fire or smoke
- Crime in progress
- Someone unconscious
- Severe allergic reaction

**Non-Emergency Police**
- 131 444 → For reporting incidents that are not life-threatening

**If You Are Unsure**
Call 000 — operators will guide you.

**Emergency Tips**
- Stay calm.
- Speak clearly.
- Give exact location (street + nearby landmark).
- Follow operator instructions.
- Do not hang up until told.

**Ambulance Costs**
- OSHC covers emergency ambulance in most cases.
- Check your policy for details.
""",
      nepaliContent: """
**आपतकालीन नम्बर**
- 000 → Police, Fire, Ambulance

**कहिले 000 फोन गर्ने?**
- गम्भीर चोट
- सास फेर्न गाह्रो
- आगलागी
- अपराध भइरहेको
- बेहोस भएको
- Allergy को गम्भीर प्रतिक्रिया

**Non-Emergency Police**
- 131 444 → जीवन-खतरा नभएको घटनाका लागि

**निश्चित नभएमा**
000 फोन गर्नुहोस् — operator ले मार्गदर्शन गर्छ।

**आपतकालीन सुझाव**
- शान्त रहनुहोस्।
- स्पष्ट बोल्नुहोस्।
- ठ्याक्कै location दिनुहोस्।
- Operator को निर्देशन पालना गर्नुहोस्।
- भन्नु नपाएसम्म फोन नकटाउनुहोस्।

**Ambulance खर्च**
- धेरैजसो अवस्थामा OSHC ले कभर गर्छ।
- आफ्नो policy हेर्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — MENTAL HEALTH
    // ------------------------------------------------------------
    GuideSection(
      title: "Mental Health & Wellbeing Support",
      nepaliTitle: "मानसिक स्वास्थ्य र सहयोग",
      content: """
**Why Mental Health Matters**
Moving to a new country is stressful.  
It is normal to feel:
- Lonely
- Homesick
- Overwhelmed
- Anxious

**Where to Get Help**
- University counselling (free)
- Headspace (youth mental health)
- Lifeline (crisis support)
- GP referral to psychologist

**Signs You Need Support**
- Trouble sleeping
- Loss of appetite
- Feeling hopeless
- Difficulty focusing
- Avoiding social contact

**Self-Care Tips**
- Maintain routine
- Exercise regularly
- Talk to friends/family
- Take breaks from work/study
""",
      nepaliContent: """
**किन मानसिक स्वास्थ्य महत्वपूर्ण?**
नयाँ देशमा आउँदा तनाव हुन्छ।  
यी भावना सामान्य हुन्:
- एक्लोपन
- घरको याद
- तनाव
- चिन्ता

**सहयोग कहाँ पाउने?**
- विश्वविद्यालय counselling (निःशुल्क)
- Headspace
- Lifeline
- GP बाट psychologist referral

**सहयोग आवश्यक संकेत**
- निद्रा नआउनु
- भोक नलाग्नु
- निराश महसुस
- ध्यान केन्द्रित गर्न गाह्रो
- मानिसबाट टाढा बस्ने

**Self-care सुझाव**
- Routine बनाउनुहोस्
- Exercise गर्नुहोस्
- साथी/परिवारसँग कुरा गर्नुहोस्
- काम/पढाइबाट break लिनुहोस्
""",
    ),

   
  ],
),

  // ============================================================
  // GUIDE 1 — Opening a Bank Account
  // ============================================================
  Guide(
  emoji: "🏦",
  title: "Opening a Bank Account in Australia",
  nepaliTitle: "अस्ट्रेलियामा बैंक खाता खोल्ने प्रक्रिया",
  subtitle: "Documents, verification, debit card, online banking, safety tips",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHY YOU NEED A BANK ACCOUNT
    // ------------------------------------------------------------
    GuideSection(
      title: "Why a Bank Account is Essential",
      nepaliTitle: "बैंक खाता किन आवश्यक छ?",
      content: """
**Why You Need It**
A bank account is required for:
- Receiving salary
- Paying rent and bills
- Online shopping
- Tax refunds
- Emergency savings
- Sending/receiving money internationally

**Benefits**
- Safe and regulated banking system
- Easy online banking
- Debit card for daily use
- No need to carry cash
""",
      nepaliContent: """
**किन आवश्यक छ?**
बैंक खाता आवश्यक हुन्छ:
- तलब लिन
- भाडा र बिल तिर्न
- अनलाइन किनमेल गर्न
- कर फिर्ता पाउन
- आपतकालीन बचत राख्न
- अन्तर्राष्ट्रिय पैसा पठाउन/पाउन

**फाइदा**
- सुरक्षित र नियमन गरिएको बैंक प्रणाली
- सजिलो अनलाइन बैंकिङ
- दैनिक प्रयोगका लागि डेबिट कार्ड
- नगद बोक्न नपर्ने
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — REQUIRED DOCUMENTS
    // ------------------------------------------------------------
    GuideSection(
      title: "Documents You Need",
      nepaliTitle: "आवश्यक कागजातहरू",
      content: """
**Essential Documents**
- Passport
- Australian visa
- Australian address (temporary is fine)
- Phone number
- Email address

**Optional (but helpful)**
- Student ID
- Enrollment letter
- Employment contract (if working)

**Tip**
Temporary address is acceptable — you can update it later.
""",
      nepaliContent: """
**आवश्यक कागजात**
- पासपोर्ट
- अस्ट्रेलियाली भिसा
- अस्ट्रेलियाको ठेगाना (अस्थायी भए पनि चल्छ)
- फोन नम्बर
- इमेल ठेगाना

**ऐच्छिक (तर उपयोगी)**
- विद्यार्थी परिचयपत्र
- भर्ना पत्र
- रोजगार सम्झौता (काम गर्दै भए)

**सुझाव**
अस्थायी ठेगाना राखे पनि हुन्छ — पछि सजिलै अपडेट गर्न सकिन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — CHOOSING A BANK
    // ------------------------------------------------------------
    GuideSection(
      title: "Choosing the Right Bank",
      nepaliTitle: "उचित बैंक कसरी छान्ने?",
      content: """
**Popular Banks**
- Commonwealth Bank (CBA)
- ANZ
- NAB
- Westpac
- Bank Australia

**What to Compare**
- Monthly account fees
- ATM access
- Mobile app quality
- International transfer fees
- Student-friendly options

**Tip**
Most banks offer “no monthly fee” accounts for students.
""",
      nepaliContent: """
**लोकप्रिय बैंकहरू**
- Commonwealth Bank (CBA)
- ANZ
- NAB
- Westpac
- Bank Australia

**के तुलना गर्ने?**
- मासिक शुल्क
- ATM पहुँच
- मोबाइल एपको गुणस्तर
- अन्तर्राष्ट्रिय ट्रान्सफर शुल्क
- विद्यार्थीमैत्री योजना

**सुझाव**
धेरै बैंकले विद्यार्थीका लागि “मासिक शुल्क नलाग्ने” खाता दिन्छन्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — HOW TO OPEN THE ACCOUNT
    // ------------------------------------------------------------
    GuideSection(
      title: "Step-by-Step: Opening Your Account",
      nepaliTitle: "चरणबद्ध प्रक्रिया: खाता खोल्ने",
      content: """
**1. Apply Online**
Most banks allow you to open an account before arriving in Australia.

**2. Enter Your Details**
- Passport information
- Visa details
- Address
- Contact number

**3. Visit a Branch (If Required)**
Some banks need in-person identity verification.

**4. Receive Your Debit Card**
Delivery options:
- Home address
- Branch pickup

**5. Activate Online Banking**
- Download the bank’s app
- Set up login
- Enable notifications
""",
      nepaliContent: """
**१. अनलाइन आवेदन दिनुहोस्**
धेरै बैंकले अस्ट्रेलिया आउनु अघि नै अनलाइन खाता खोल्न दिन्छन्।

**२. विवरण भर्नुहोस्**
- पासपोर्ट विवरण
- भिसा विवरण
- ठेगाना
- सम्पर्क नम्बर

**३. शाखामा जानुहोस् (यदि आवश्यक)**
केही बैंकले प्रत्यक्ष पहिचान जाँच माग्न सक्छन्।

**४. डेबिट कार्ड प्राप्त गर्नुहोस्**
कार्ड प्राप्त गर्ने तरिका:
- घरमा डेलिभरी
- शाखाबाट लिनुहोस्

**५. अनलाइन बैंकिङ सक्रिय गर्नुहोस्**
- बैंकको एप डाउनलोड गर्नुहोस्
- लगइन सेट गर्नुहोस्
- नोटिफिकेशन अन गर्नुहोस्
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — USING YOUR ACCOUNT
    // ------------------------------------------------------------
    GuideSection(
      title: "Using Your Bank Account",
      nepaliTitle: "खाता कसरी प्रयोग गर्ने?",
      content: """
**Important Details**
- BSB Number
- Account Number
- Customer ID

**Daily Uses**
- Paying rent
- Receiving salary
- Transferring money
- Online shopping
- ATM withdrawals

**Tip**
Save your BSB and account number safely — you’ll need it for salary.
""",
      nepaliContent: """
**महत्वपूर्ण विवरण**
- BSB नम्बर
- खाता नम्बर
- ग्राहक ID

**दैनिक प्रयोग**
- भाडा तिर्न
- तलब लिन
- पैसा ट्रान्सफर गर्न
- अनलाइन किनमेल
- ATM बाट पैसा निकाल्न

**सुझाव**
BSB र खाता नम्बर सुरक्षित राख्नुहोस् — तलबका लागि आवश्यक हुन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 6 — SAFETY & COMMON MISTAKES
    // ------------------------------------------------------------
    GuideSection(
      title: "Safety Tips & Common Mistakes",
      nepaliTitle: "सुरक्षा सुझाव र सामान्य गल्तीहरू",
      content: """
**Safety Tips**
- Never share your PIN.
- Lock your card if lost.
- Enable transaction alerts.
- Use official bank apps only.

**Common Mistakes**
- Using a foreign SIM for OTP.
- Giving wrong address → card lost.
- Ignoring suspicious transactions.
- Not updating visa details.

**Tip**
If something feels wrong, contact your bank immediately.
""",
      nepaliContent: """
**सुरक्षा सुझाव**
- PIN कसैलाई नदिनुहोस्।
- कार्ड हराएमा तुरुन्त लक गर्नुहोस्।
- ट्रान्जेक्सन अलर्ट अन गर्नुहोस्।
- केवल आधिकारिक बैंक एप प्रयोग गर्नुहोस्।

**सामान्य गल्तीहरू**
- विदेशी सिमबाट OTP चलाउन खोज्नु।
- गलत ठेगाना राख्दा कार्ड हराउनु।
- शंकास्पद ट्रान्जेक्सन बेवास्ता गर्नु।
- भिसा विवरण अपडेट नगर्नु।

**सुझाव**
कुनै समस्या देखिएमा तुरुन्त बैंकलाई सम्पर्क गर्नुहोस्।
""",
    ),
  ],
),


  // ============================================================
  // GUIDE 2 — Understanding Payslip
  // ============================================================
Guide(
  emoji: "💼",
  title: "Understanding Your Payslip",
  nepaliTitle: "तपाईंको पे–स्लिप बुझ्ने तरिका",
  subtitle: "Earnings, tax, superannuation, hours, deductions, leave balance",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHY PAYSLIP MATTERS
    // ------------------------------------------------------------
    GuideSection(
      title: "Why Your Payslip is Important",
      nepaliTitle: "पे–स्लिप किन महत्वपूर्ण छ?",
      content: """
**What a Payslip Shows**
A payslip is an official record of:
- Hours worked
- Hourly rate
- Total earnings
- Tax deducted
- Superannuation paid
- Leave balances

**Why It Matters**
- Helps you check if you are paid correctly
- Required for visa applications
- Useful for rental applications
- Proof of employment
""",
      nepaliContent: """
**पे–स्लिपले के देखाउँछ?**
पे–स्लिपले निम्न विवरण देखाउँछ:
- काम गरेको घण्टा
- प्रति घण्टा दर
- कुल कमाइ
- काटिएको कर
- सुपरएनुएसन
- बिदा विवरण

**किन महत्वपूर्ण?**
- सही तलब पाएको छ कि छैन जाँच गर्न
- भिसा आवेदनका लागि आवश्यक
- घर भाडामा लिन उपयोगी
- रोजगार प्रमाणका रूपमा प्रयोग हुन्छ
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — KEY TERMS
    // ------------------------------------------------------------
    GuideSection(
      title: "Key Terms You Must Know",
      nepaliTitle: "जान्नैपर्ने मुख्य शब्दहरू",
      content: """
**Gross Pay**
Total earnings before tax and deductions.

**Net Pay**
Amount you actually receive in your bank account.

**Tax Withheld**
Tax your employer sends to the ATO on your behalf.

**Superannuation**
Retirement savings paid by your employer (usually 11%).

**Penalty Rates**
Higher pay for weekends, public holidays, or late-night shifts.

**TFN (Tax File Number)**
Your unique tax identity in Australia.
""",
      nepaliContent: """
**Gross Pay**
कर र कटौती अघि कमाएको कुल रकम।

**Net Pay**
तपाईंको बैंक खातामा आउने वास्तविक रकम।

**Tax Withheld**
तपाईंको तलबबाट काटेर ATO लाई पठाइने कर।

**Superannuation**
निवृत्ति बचत, जुन सामान्यतया ११% नियोक्ताले तिर्छ।

**Penalty Rates**
सप्ताहन्त, सार्वजनिक बिदा वा राति काम गर्दा पाउने बढी दर।

**TFN (Tax File Number)**
अस्ट्रेलियामा करका लागि तपाईंको पहिचान नम्बर।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — HOW TO READ YOUR PAYSLIP
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Read Your Payslip",
      nepaliTitle: "पे–स्लिप कसरी पढ्ने?",
      content: """
**1. Personal Details**
- Your name
- Employer name
- ABN (Australian Business Number)
- Pay period dates

**2. Earnings Section**
Shows:
- Hours worked
- Hourly rate
- Overtime
- Penalty rates
- Total earnings

**3. Deductions**
Includes:
- Tax withheld
- Union fees (if any)
- Other deductions

**4. Superannuation**
Shows:
- Employer contribution
- Super fund name

**5. Leave Balances**
- Annual leave
- Sick leave
""",
      nepaliContent: """
**१. व्यक्तिगत विवरण**
- तपाईंको नाम
- नियोक्ताको नाम
- ABN नम्बर
- तलब अवधि

**२. कमाइ (Earnings)**
देखाउँछ:
- काम गरेको घण्टा
- प्रति घण्टा दर
- ओभरटाइम
- अतिरिक्त दर (Penalty)
- कुल कमाइ

**३. कटौती (Deductions)**
समावेश:
- काटिएको कर
- यूनियन शुल्क (यदि छ भने)
- अन्य कटौती

**४. सुपरएनुएसन**
देखाउँछ:
- नियोक्ताले तिरेको सुपर
- सुपर फन्डको नाम

**५. बिदा विवरण**
- वार्षिक बिदा
- बिरामी बिदा
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — COMMON ISSUES & UNDERPAYMENT
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Issues & Underpayment Signs",
      nepaliTitle: "सामान्य समस्या र कम तलबका संकेत",
      content: """
**Signs of Underpayment**
- Hours on payslip do not match your roster
- Penalty rates missing
- Superannuation not paid
- Incorrect hourly rate
- No payslip provided

**What You Can Do**
- Talk to your employer politely
- Keep screenshots of rosters
- Track your hours
- Check your super fund regularly
""",
      nepaliContent: """
**कम तलब पाएको संकेत**
- पे–स्लिपमा देखिएको घण्टा र रोस्टर नमेल्नु
- Penalty दर नदेखिनु
- सुपरएनुएसन नतिर्नु
- गलत प्रति घण्टा दर
- पे–स्लिप नै नदिइनु

**के गर्न सकिन्छ?**
- नियोक्तासँग विनम्र रूपमा कुरा गर्नुहोस्
- रोस्टरको screenshot राख्नुहोस्
- आफ्नो घण्टा ट्र्याक गर्नुहोस्
- सुपर फन्ड नियमित जाँच गर्नुहोस्
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — SAFETY & RECORD KEEPING
    // ------------------------------------------------------------
    GuideSection(
      title: "Record Keeping & Safety Tips",
      nepaliTitle: "रेकर्ड राख्ने तरिका र सुरक्षा सुझाव",
      content: """
**Keep These Safe**
- All payslips (PDF or screenshots)
- Employment contract
- TFN details
- Superannuation account details

**Why Keep Records?**
- Needed for visa applications
- Helps resolve disputes
- Useful for tax return
- Proof of income for rentals

**Tip**
Create a folder in Google Drive or OneDrive and store everything.
""",
      nepaliContent: """
**यी कुरा सुरक्षित राख्नुहोस्**
- सबै पे–स्लिप (PDF वा screenshot)
- रोजगार सम्झौता
- TFN विवरण
- सुपरएनुएसन खाता विवरण

**किन आवश्यक?**
- भिसा आवेदनका लागि
- विवाद समाधानका लागि
- कर फिर्ता भर्नका लागि
- घर भाडामा लिन आय प्रमाणका रूपमा

**सुझाव**
Google Drive वा OneDrive मा एउटा फोल्डर बनाएर सबै राख्नुहोस्।
""",
    ),
  ],
),


  // ============================================================
  // GUIDE 3 — TR Visa
  // ============================================================
  Guide(
  emoji: "🎓",
  title: "Applying for TR (Temporary Graduate) Visa",
  nepaliTitle: "टीआर (अस्थायी स्नातक) भिसा आवेदन",
  subtitle: "Eligibility, documents, ImmiAccount, AFP, health check, insurance",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT TR VISA IS
    // ------------------------------------------------------------
    GuideSection(
      title: "What is the TR Visa?",
      nepaliTitle: "टीआर भिसा भनेको के हो?",
      content: """
**Purpose of TR Visa**
The Temporary Graduate Visa (Subclass 485) allows international students to:
- Stay in Australia after completing studies
- Work full-time
- Gain local experience
- Prepare for PR pathways

**Who Can Apply**
Students who completed an eligible Australian qualification.
""",
      nepaliContent: """
**टीआर भिसाको उद्देश्य**
Temporary Graduate Visa (Subclass 485) ले अन्तर्राष्ट्रिय विद्यार्थीलाई:
- पढाइ सकेपछि अस्ट्रेलियामा बस्न
- पूर्ण समय काम गर्न
- स्थानीय अनुभव कमाउन
- पीआरको तयारी गर्न

**कसले आवेदन दिन सक्छ?**
अस्ट्रेलियामा योग्य अध्ययन पूरा गरेका विद्यार्थीले।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — STREAMS & ELIGIBILITY
    // ------------------------------------------------------------
    GuideSection(
      title: "Streams & Eligibility",
      nepaliTitle: "स्ट्रिम र योग्यता",
      content: """
**Two Main Streams**
1. Graduate Work Stream  
   - For occupations on the skilled list  
   - Usually for diploma or trade qualifications

2. Post-Study Work Stream  
   - For higher education graduates (Bachelor, Master, PhD)

**General Eligibility**
- Completed a CRICOS-registered course
- Course duration meets requirements
- Valid student visa at time of application
- Age under 50
""",
      nepaliContent: """
**दुई मुख्य स्ट्रिम**
१. Graduate Work Stream  
   - Skilled occupation listमा पर्ने पेशाका लागि  
   - Diploma वा trade योग्यता भएका विद्यार्थी

२. Post-Study Work Stream  
   - Bachelor, Master, PhD पूरा गरेका विद्यार्थी

**सामान्य योग्यता**
- CRICOS दर्ता गरिएको कोर्स पूरा गरेको
- कोर्स अवधि आवश्यकताअनुसार भएको
- आवेदन दिने बेला मान्य विद्यार्थी भिसा
- उमेर ५० वर्षभन्दा कम
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — REQUIRED DOCUMENTS
    // ------------------------------------------------------------
    GuideSection(
      title: "Documents You Need",
      nepaliTitle: "आवश्यक कागजातहरू",
      content: """
**Essential Documents**
- Passport
- Australian visa details
- Academic transcript
- Completion letter
- Passport-size photo
- English test (if required)
- AFP (Australian Federal Police) check
- Health insurance (OVHC)

**Optional (but helpful)**
- Resume
- Previous work evidence
""",
      nepaliContent: """
**आवश्यक कागजात**
- पासपोर्ट
- अस्ट्रेलियाली भिसा विवरण
- शैक्षिक ट्रान्सक्रिप्ट
- Completion letter
- पासपोर्ट साइज फोटो
- अंग्रेजी परीक्षा (यदि आवश्यक)
- AFP (Australian Federal Police) चेक
- स्वास्थ्य बीमा (OVHC)

**ऐच्छिक (तर उपयोगी)**
- रिजुमे
- कामको प्रमाण
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — AFP CHECK & HEALTH CHECK
    // ------------------------------------------------------------
    GuideSection(
      title: "AFP Check & Health Requirements",
      nepaliTitle: "एएफपी चेक र स्वास्थ्य आवश्यकताहरू",
      content: """
**AFP Check**
- Must be applied under Code 33 (Immigration)
- Can be done online
- Required before visa decision

**Health Check**
- You may receive a HAP ID after applying
- Must visit an approved panel clinic
- Includes medical exam, chest X-ray, blood tests
""",
      nepaliContent: """
**एएफपी चेक**
- Code 33 (Immigration) अन्तर्गत आवेदन दिनुपर्छ
- अनलाइन गर्न सकिन्छ
- भिसा निर्णय अघि आवश्यक

**स्वास्थ्य परीक्षण**
- आवेदनपछि HAP ID आउन सक्छ
- मान्य प्यानल क्लिनिकमा जानुपर्छ
- मेडिकल जाँच, एक्स-रे, रगत परीक्षण समावेश
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — HOW TO APPLY (IMMIACCOUNT)
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Apply via ImmiAccount",
      nepaliTitle: "इम्मी–अकाउन्टबाट कसरी आवेदन दिने?",
      content: """
**1. Create or Log In to ImmiAccount**
Use the official Home Affairs website.

**2. Select Visa Subclass 485**
Choose the correct stream.

**3. Fill in Your Details**
- Personal information
- Education history
- Address
- Health & character questions

**4. Upload Documents**
Ensure all scans are clear and readable.

**5. Pay the Visa Fee**
Payment is done online.

**6. Receive Bridging Visa**
If your student visa expires, the bridging visa keeps you lawful.

**7. Wait for Outcome**
Processing times vary.
""",
      nepaliContent: """
**१. इम्मी–अकाउन्ट बनाउनुहोस् वा लगइन गर्नुहोस्**
Home Affairs को आधिकारिक वेबसाइट प्रयोग गर्नुहोस्।

**२. Subclass 485 छान्नुहोस्**
उचित स्ट्रिम चयन गर्नुहोस्।

**३. विवरण भर्नुहोस्**
- व्यक्तिगत जानकारी
- शैक्षिक विवरण
- ठेगाना
- स्वास्थ्य र चरित्र सम्बन्धी प्रश्न

**४. कागजात अपलोड गर्नुहोस्**
सबै स्क्यान स्पष्ट र पढ्न मिल्ने हुनुपर्छ।

**५. भिसा शुल्क तिर्नुहोस्**
अनलाइन भुक्तानी गर्न सकिन्छ।

**६. Bridging Visa प्राप्त गर्नुहोस्**
विद्यार्थी भिसा सकिएपछि कानुनी रूपमा बस्न मद्दत गर्छ।

**७. नतिजा पर्खनुहोस्**
प्रोसेसिङ समय फरक–फरक हुन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 6 — COMMON MISTAKES & TIPS
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Mistakes & Helpful Tips",
      nepaliTitle: "सामान्य गल्तीहरू र उपयोगी सुझाव",
      content: """
**Common Mistakes**
- Applying before receiving completion letter
- Uploading unclear documents
- Forgetting AFP check
- Not maintaining health insurance
- Using expired passport

**Helpful Tips**
- Apply early (before student visa expires)
- Keep all documents in one folder
- Double-check your English test validity
- Maintain OVHC throughout the visa period
""",
      nepaliContent: """
**सामान्य गल्तीहरू**
- Completion letter नआउँदै आवेदन दिनु
- अस्पष्ट कागजात अपलोड गर्नु
- AFP चेक बिर्सनु
- स्वास्थ्य बीमा निरन्तर नराख्नु
- पासपोर्ट म्याद सकिएको हुनु

**उपयोगी सुझाव**
- विद्यार्थी भिसा सकिनुअघि नै आवेदन दिनुहोस्
- सबै कागजात एउटै फोल्डरमा राख्नुहोस्
- अंग्रेजी परीक्षाको म्याद जाँच गर्नुहोस्
- OVHC निरन्तर सक्रिय राख्नुहोस्
""",
    ),
  ],
),

  // ============================================================
  // GUIDE 4 — PR Application
  // ============================================================
  Guide(
  emoji: "🏡",
  title: "Applying for Permanent Residency (PR)",
  nepaliTitle: "स्थायी बसोबास (पीआर) को लागि आवेदन",
  subtitle: "Points, skills assessment, EOI, state nomination, documents",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT PR MEANS
    // ------------------------------------------------------------
    GuideSection(
      title: "What PR Means in Australia",
      nepaliTitle: "अस्ट्रेलियामा पीआर भनेको के हो?",
      content: """
**Benefits of PR**
- Live in Australia permanently
- Work and study without restrictions
- Access to Medicare
- Sponsor family members
- Pathway to citizenship

**Why It Matters**
PR gives long-term stability and opens more career opportunities.
""",
      nepaliContent: """
**पीआरका फाइदा**
- अस्ट्रेलियामा स्थायी रूपमा बस्न पाउने
- काम र पढाइमा कुनै प्रतिबन्ध नहुने
- मेडिकेयर सुविधा
- परिवारलाई स्पोन्सर गर्न सकिने
- नागरिकता पाउने बाटो खुल्ने

**किन महत्वपूर्ण?**
पीआरले दीर्घकालीन स्थिरता र राम्रो करियर अवसर दिन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — POINTS SYSTEM
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding the Points System",
      nepaliTitle: "अंक प्रणाली बुझ्ने",
      content: """
**Key Factors**
- Age
- English test score
- Education level
- Skilled work experience
- Australian study requirement
- State nomination (extra points)
- Partner skills

**Minimum Requirement**
You generally need **65 points** to lodge an EOI.
""",
      nepaliContent: """
**मुख्य आधारहरू**
- उमेर
- अंग्रेजी परीक्षाको स्कोर
- शैक्षिक योग्यता
- सीपयुक्त काम अनुभव
- अस्ट्रेलियामा अध्ययन
- राज्य नामांकन (थप अंक)
- पार्टनरको सीप

**न्यूनतम आवश्यकता**
सामान्यतया **६५ अंक** आवश्यक हुन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — SKILLS ASSESSMENT
    // ------------------------------------------------------------
    GuideSection(
      title: "Skills Assessment",
      nepaliTitle: "सीप मूल्यांकन",
      content: """
**What It Is**
A formal assessment of your qualification and work experience.

**Common Assessing Bodies**
- ACS (IT)
- Engineers Australia
- VETASSESS
- AHPRA (Health)

**Why It Matters**
You cannot lodge an EOI without a positive skills assessment.
""",
      nepaliContent: """
**के हो?**
तपाईंको योग्यता र काम अनुभवको औपचारिक मूल्यांकन।

**सामान्य मूल्यांकन संस्था**
- ACS (आईटी)
- Engineers Australia
- VETASSESS
- AHPRA (स्वास्थ्य)

**किन आवश्यक?**
सकारात्मक सीप मूल्यांकन बिना EOI दर्ता गर्न सकिँदैन।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — EOI & STATE NOMINATION
    // ------------------------------------------------------------
    GuideSection(
      title: "EOI & State Nomination",
      nepaliTitle: "ईओआई र राज्य नामांकन",
      content: """
**EOI (Expression of Interest)**
- Submitted through SkillSelect
- Shows your points and eligibility

**State Nomination**
- Some states offer extra points
- Each state has its own criteria

**Tip**
Check state occupation lists regularly.
""",
      nepaliContent: """
**ईओआई (Expression of Interest)**
- SkillSelect मार्फत दर्ता गरिन्छ
- तपाईंको अंक र योग्यता देखाउँछ

**राज्य नामांकन**
- केही राज्यले अतिरिक्त अंक दिन्छन्
- प्रत्येक राज्यका आफ्नै मापदण्ड हुन्छन्

**सुझाव**
राज्यको occupation सूची नियमित जाँच गर्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — PR APPLICATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Lodging the PR Application",
      nepaliTitle: "पीआर आवेदन दिने प्रक्रिया",
      content: """
**Steps**
1. Receive invitation
2. Gather documents
3. Upload evidence
4. Complete health check
5. Provide police clearance
6. Wait for decision

**Documents Needed**
- Passport
- Skills assessment
- English test
- Work evidence
- Education certificates
""",
      nepaliContent: """
**चरणहरू**
१. निमन्त्रणा प्राप्त गर्नुहोस्  
२. कागजात संकलन गर्नुहोस्  
३. प्रमाण अपलोड गर्नुहोस्  
४. स्वास्थ्य परीक्षण गर्नुहोस्  
५. प्रहरी प्रमाणपत्र दिनुहोस्  
६. नतिजा पर्खनुहोस्  

**आवश्यक कागजात**
- पासपोर्ट
- सीप मूल्यांकन
- अंग्रेजी परीक्षा
- कामको प्रमाण
- शैक्षिक प्रमाणपत्र
""",
    ),
  ],
),

  // ============================================================
  // GUIDE 5 — Rent System
  // ============================================================
  Guide(
  emoji: "🏘️",
  title: "Understanding How Rent Works in Australia",
  nepaliTitle: "अस्ट्रेलियामा भाडा प्रणाली बुझ्ने",
  subtitle: "Inspection, application, lease, rent payments, tenant rights",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — RENT BASICS
    // ------------------------------------------------------------
    GuideSection(
      title: "How Renting Works",
      nepaliTitle: "भाडा प्रणाली कसरी चल्छ?",
      content: """
**Key Points**
- Rent is usually weekly
- Bond is usually 4 weeks of rent
- Lease agreement is legally binding
- Real estate agents manage most properties

**Why It Matters**
Understanding the system helps avoid scams and disputes.
""",
      nepaliContent: """
**मुख्य कुरा**
- भाडा प्रायः साप्ताहिक हुन्छ
- बन्ड सामान्यतया ४ हप्ता बराबर
- लिज कानुनी सम्झौता हो
- धेरै घर एजेन्टमार्फत चल्छ

**किन महत्वपूर्ण?**
प्रणाली बुझ्दा ठगी र विवादबाट बच्न सकिन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — INSPECTION
    // ------------------------------------------------------------
    GuideSection(
      title: "Property Inspection",
      nepaliTitle: "घर निरीक्षण",
      content: """
**What to Check**
- Water pressure
- Heating/cooling
- Mould or dampness
- Windows and locks
- Noise levels
- Public transport access

**Tip**
Take photos and videos during inspection.
""",
      nepaliContent: """
**के जाँच गर्ने?**
- पानीको दबाब
- हीटर/कूलर
- फफूंदी वा चिस्यान
- झ्याल र लक
- आवाजको स्तर
- सार्वजनिक यातायात

**सुझाव**
निरीक्षण गर्दा फोटो र भिडियो लिनुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — APPLICATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Rental Application",
      nepaliTitle: "भाडा आवेदन",
      content: """
**Documents Needed**
- Passport
- Visa
- Payslips or bank statements
- References
- Employment letter (if any)

**Tips**
- Apply quickly after inspection
- Write a short introduction message
""",
      nepaliContent: """
**आवश्यक कागजात**
- पासपोर्ट
- भिसा
- पे–स्लिप वा बैंक स्टेटमेन्ट
- सिफारिस पत्र
- रोजगार पत्र (यदि छ भने)

**सुझाव**
- निरीक्षणपछि छिट्टै आवेदन दिनुहोस्
- छोटो परिचय लेख्नुहोस्
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — LEASE & MOVE-IN
    // ------------------------------------------------------------
    GuideSection(
      title: "Lease & Moving In",
      nepaliTitle: "लिज र घरमा बस्ने प्रक्रिया",
      content: """
**Lease Includes**
- Rent amount
- Duration (6 or 12 months)
- Rules (pets, smoking, noise)
- Bond amount

**Move-In Steps**
1. Pay bond
2. Pay initial rent
3. Complete condition report
""",
      nepaliContent: """
**लिजमा हुने कुरा**
- भाडा रकम
- अवधि (६ वा १२ महिना)
- नियम (पाल्तु जनावर, धूम्रपान, आवाज)
- बन्ड रकम

**घरमा बस्ने चरण**
१. बन्ड तिर्नुहोस्  
२. प्रारम्भिक भाडा तिर्नुहोस्  
३. Condition report पूरा गर्नुहोस्  
""",
    ),
  ],
),

  // ============================================================
  // GUIDE 6 — Bond & Lease
  // ============================================================
  Guide(
  emoji: "📄",
  title: "Understanding Bond & Lease",
  nepaliTitle: "बन्ड र लिज बुझ्ने",
  subtitle: "Bond payment, lease rules, condition report, refund process",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT IS BOND?
    // ------------------------------------------------------------
    GuideSection(
      title: "What is Bond?",
      nepaliTitle: "बन्ड भनेको के हो?",
      content: """
**Bond**
- A security deposit
- Usually 4 weeks of rent
- Held by the government, not the landlord

**When You Get It Back**
- When you move out
- If there is no damage or unpaid rent
""",
      nepaliContent: """
**बन्ड**
- सुरक्षा रकम
- सामान्यतया ४ हप्ता बराबर
- सरकारको निकायले राख्छ, घरधनीले होइन

**कहिले फिर्ता पाइन्छ?**
- घर छोड्दा
- कुनै क्षति वा बक्यौता नभएमा
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — LEASE AGREEMENT
    // ------------------------------------------------------------
    GuideSection(
      title: "Lease Agreement",
      nepaliTitle: "लिज सम्झौता",
      content: """
**Lease Includes**
- Rent amount
- Duration
- Rules and restrictions
- Break lease fees

**Why It Matters**
It is a legal contract — read it carefully.
""",
      nepaliContent: """
**लिजमा हुने कुरा**
- भाडा रकम
- अवधि
- नियम र प्रतिबन्ध
- Break lease शुल्क

**किन महत्वपूर्ण?**
यो कानुनी सम्झौता हो — ध्यानपूर्वक पढ्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — CONDITION REPORT
    // ------------------------------------------------------------
    GuideSection(
      title: "Condition Report",
      nepaliTitle: "अवस्था प्रतिवेदन",
      content: """
**Purpose**
Records the condition of the property before you move in.

**Tips**
- Take photos of every room
- Note any scratches, stains, or damage
""",
      nepaliContent: """
**उद्देश्य**
घरमा बस्नु अघि घरको अवस्था प्रमाणित गर्न।

**सुझाव**
- प्रत्येक कोठाको फोटो लिनुहोस्
- दाग, स्क्र्याच वा क्षति नोट गर्नुहोस्
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — BOND REFUND
    // ------------------------------------------------------------
    GuideSection(
      title: "Bond Refund Process",
      nepaliTitle: "बन्ड फिर्ता प्रक्रिया",
      content: """
**Steps**
1. Move out
2. Final inspection
3. Submit bond claim
4. Receive refund

**Common Deductions**
- Cleaning fees
- Damage repair
- Unpaid rent
""",
      nepaliContent: """
**चरणहरू**
१. घर छोड्नुहोस्  
२. अन्तिम निरीक्षण  
३. बन्ड दाबी गर्नुहोस्  
४. फिर्ता प्राप्त गर्नुहोस्  

**सामान्य कटौती**
- सरसफाइ शुल्क
- क्षति मर्मत
- बक्यौता भाडा
""",
    ),
  ],
),

  // ============================================================
  // GUIDE 7 — Parent Visa
  // ============================================================
  Guide(
  emoji: "👨‍👩‍👧",
  title: "Applying for Parent’s Visa",
  nepaliTitle: "अभिभावक भिसा आवेदन",
  subtitle: "Visitor visa, documents, invitation letter, biometrics",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — VISA OPTIONS
    // ------------------------------------------------------------
    GuideSection(
      title: "Parent Visa Options",
      nepaliTitle: "अभिभावक भिसाका विकल्प",
      content: """
**Common Option**
- Visitor Visa (Subclass 600)

**Streams**
- Tourist stream
- Sponsored family stream

**Stay Duration**
Usually 3, 6, or 12 months.
""",
      nepaliContent: """
**सामान्य विकल्प**
- Visitor Visa (Subclass 600)

**स्ट्रिमहरू**
- पर्यटक स्ट्रिम
- परिवार स्पोन्सर स्ट्रिम

**बसाइ अवधि**
सामान्यतया ३, ६ वा १२ महिना।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — DOCUMENTS
    // ------------------------------------------------------------
    GuideSection(
      title: "Documents Required",
      nepaliTitle: "आवश्यक कागजात",
      content: """
**For Parents**
- Passport
- Bank statements
- Property or family ties
- Travel history

**From You**
- Invitation letter
- Passport copy
- Visa copy
- Address proof
""",
      nepaliContent: """
**अभिभावकका लागि**
- पासपोर्ट
- बैंक स्टेटमेन्ट
- सम्पत्ति वा परिवारको प्रमाण
- यात्रा इतिहास

**तपाईंबाट**
- निमन्त्रणा पत्र
- पासपोर्ट प्रतिलिपि
- भिसा प्रतिलिपि
- ठेगाना प्रमाण
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — APPLICATION PROCESS
    // ------------------------------------------------------------
    GuideSection(
      title: "Application Process",
      nepaliTitle: "आवेदन प्रक्रिया",
      content: """
**Steps**
1. Create ImmiAccount
2. Fill application
3. Upload documents
4. Pay visa fee
5. Biometrics
6. Wait for outcome
""",
      nepaliContent: """
**चरणहरू**
१. इम्मी–अकाउन्ट बनाउनुहोस्  
२. आवेदन भर्नुहोस्  
३. कागजात अपलोड गर्नुहोस्  
४. शुल्क तिर्नुहोस्  
५. बायोमेट्रिक्स  
६. नतिजा पर्खनुहोस्  
""",
    ),
  ],
),

  // ============================================================
  // GUIDE 8 — Spouse Visa
  // ============================================================
  Guide(
  emoji: "❤️",
  title: "Applying for Spouse / Partner Visa",
  nepaliTitle: "पति/पत्नी (पार्टनर) भिसा आवेदन",
  subtitle: "Relationship evidence, sponsor, documents, stages",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — VISA OVERVIEW
    // ------------------------------------------------------------
    GuideSection(
      title: "Understanding Partner Visa",
      nepaliTitle: "पार्टनर भिसा बुझ्ने",
      content: """
**Two Stages**
- Temporary visa (820/309)
- Permanent visa (801/100)

**Who Can Apply**
Partners of:
- Australian citizens
- Permanent residents
- Eligible NZ citizens
""",
      nepaliContent: """
**दुई चरण**
- अस्थायी भिसा (820/309)
- स्थायी भिसा (801/100)

**कसले आवेदन दिन सक्छ?**
यीका पार्टनर:
- अस्ट्रेलियाली नागरिक
- स्थायी बासिन्दा
- योग्य न्युजिल्यान्ड नागरिक
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — RELATIONSHIP EVIDENCE
    // ------------------------------------------------------------
    GuideSection(
      title: "Relationship Evidence",
      nepaliTitle: "सम्बन्ध प्रमाण",
      content: """
**Types of Evidence**
- Photos together
- Chat/call history
- Joint lease or bills
- Joint bank account
- Statutory declarations

**Tip**
Provide evidence from different time periods.
""",
      nepaliContent: """
**प्रमाणका प्रकार**
- सँगै खिचेका फोटो
- च्याट/कल इतिहास
- संयुक्त लिज वा बिल
- संयुक्त बैंक खाता
- स्ट्याटुटरी डिक्लेरेशन

**सुझाव**
विभिन्न समयका प्रमाण दिनुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — SPONSOR & APPLICATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Sponsor & Application Steps",
      nepaliTitle: "स्पोन्सर र आवेदन चरण",
      content: """
**Steps**
1. Partner submits visa application
2. Sponsor submits sponsorship form
3. Upload relationship evidence
4. Health check
5. Police clearance
6. Wait for temporary visa
7. Later assessed for permanent visa
""",
      nepaliContent: """
**चरणहरू**
१. पार्टनरले भिसा आवेदन दिन्छ  
२. स्पोन्सरले sponsorship फारम भर्छ  
३. सम्बन्ध प्रमाण अपलोड  
४. स्वास्थ्य परीक्षण  
५. प्रहरी प्रमाणपत्र  
६. अस्थायी भिसा पर्खनु  
७. पछि स्थायी भिसा मूल्यांकन  
""",
    ),
  ],
),


  // ============================================================
  // GUIDE 9 — Giving Birth in Australia
  // ============================================================
  Guide(
  emoji: "👶",
  title: "Giving Birth in Australia",
  nepaliTitle: "अस्ट्रेलियामा बच्चा जन्माउने प्रक्रिया",
  subtitle: "GP, hospital booking, antenatal care, delivery, documents",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — PREGNANCY BASICS
    // ------------------------------------------------------------
    GuideSection(
      title: "Pregnancy & Healthcare System",
      nepaliTitle: "गर्भावस्था र स्वास्थ्य प्रणाली",
      content: """
**How It Works**
- Visit a GP to confirm pregnancy
- GP provides referral to a hospital or midwife program
- Antenatal appointments scheduled throughout pregnancy

**Public vs Private**
- Public hospitals are free for Medicare holders
- Private hospitals cost more but offer private rooms
""",
      nepaliContent: """
**कसरी चल्छ?**
- गर्भ पुष्टि गर्न GP भेट्नुहोस्
- GP ले अस्पताल वा मिडवाइफ कार्यक्रमको रेफरल दिन्छ
- गर्भपूर्व भेटघाटहरू नियमित रूपमा हुन्छन्

**सार्वजनिक बनाम निजी**
- मेडिकेयर भएका अभिभावकका लागि सार्वजनिक अस्पताल निःशुल्क हुन्छ
- निजी अस्पताल महँगो हुन्छ तर निजी कोठा जस्ता सुविधा दिन्छ
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — HOSPITAL BOOKING
    // ------------------------------------------------------------
    GuideSection(
      title: "Hospital Booking Process",
      nepaliTitle: "अस्पताल बुकिङ प्रक्रिया",
      content: """
**Steps**
1. GP confirms pregnancy
2. GP sends referral to your chosen hospital
3. Hospital contacts you for booking
4. You receive antenatal schedule

**What Hospitals Check**
- Your medical history
- Pregnancy risk level
- Due date
""",
      nepaliContent: """
**चरणहरू**
१. GP ले गर्भ पुष्टि गर्छ  
२. GP ले तपाईंले रोजेको अस्पतालमा रेफरल पठाउँछ  
३. अस्पतालले बुकिङका लागि सम्पर्क गर्छ  
४. तपाईंलाई गर्भपूर्व भेटघाटको तालिका दिइन्छ  

**अस्पतालले के जाँच्छ?**
- स्वास्थ्य इतिहास  
- गर्भको जोखिम स्तर  
- अनुमानित जन्म मिति  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — ANTENATAL CARE
    // ------------------------------------------------------------
    GuideSection(
      title: "Antenatal Appointments",
      nepaliTitle: "गर्भपूर्व भेटघाट",
      content: """
**What Happens During Visits**
- Blood pressure check
- Baby growth monitoring
- Ultrasound scans
- Blood tests
- Health advice

**Education Sessions**
Many hospitals offer:
- Birth preparation classes
- Breastfeeding classes
- Parenting workshops
""",
      nepaliContent: """
**भेटघाटमा के हुन्छ?**
- रक्तचाप जाँच
- बच्चाको विकास जाँच
- अल्ट्रासाउन्ड
- रगत परीक्षण
- स्वास्थ्य सल्लाह

**शिक्षा कक्षा**
धेरै अस्पतालले प्रदान गर्छन्:
- प्रसूति तयारी कक्षा
- स्तनपान कक्षा
- अभिभावक प्रशिक्षण
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — LABOUR & DELIVERY
    // ------------------------------------------------------------
    GuideSection(
      title: "Labour & Delivery",
      nepaliTitle: "प्रसूति र बच्चा जन्म",
      content: """
**When to Go to Hospital**
- Strong contractions
- Water breaking
- Heavy bleeding
- Reduced baby movement

**Pain Relief Options**
- Gas
- Epidural
- Warm shower
- Breathing techniques

**Delivery Types**
- Natural birth
- Assisted birth
- C-section (if required)
""",
      nepaliContent: """
**अस्पताल कहिले जाने?**
- कडा contractions सुरु हुँदा
- पानी फुट्दा
- धेरै रक्तस्राव हुँदा
- बच्चाको movement कम हुँदा

**दुखाइ कम गर्ने विकल्प**
- ग्यास
- Epidural
- न्यानो पानीको स्नान
- सास फेर्ने अभ्यास

**जन्मका प्रकार**
- सामान्य प्रसूति
- सहायतापूर्ण प्रसूति
- C-section (आवश्यक परेमा)
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — AFTER BIRTH
    // ------------------------------------------------------------
    GuideSection(
      title: "After Birth Care",
      nepaliTitle: "बच्चा जन्मिएपछि हेरचाह",
      content: """
**Baby Care**
- First health check
- Vitamin K injection
- Newborn screening test
- Vaccination schedule begins

**Mother’s Care**
- Recovery monitoring
- Breastfeeding support
- Pain management

**Home Visits**
A midwife or child health nurse may visit your home.
""",
      nepaliContent: """
**बच्चाको हेरचाह**
- पहिलो स्वास्थ्य जाँच
- भिटामिन K इंजेक्शन
- नवजात परीक्षण
- खोप कार्यक्रम सुरु

**आमाको हेरचाह**
- स्वास्थ्य निगरानी
- स्तनपान सहयोग
- दुखाइ व्यवस्थापन

**घर भ्रमण**
मिडवाइफ वा नर्सले घरमै आएर जाँच गर्न सक्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 6 — DOCUMENTS & REGISTRATION
    // ------------------------------------------------------------
    GuideSection(
      title: "Birth Registration & Documents",
      nepaliTitle: "जन्म दर्ता र कागजात",
      content: """
**Birth Registration**
- Must be completed within 60 days
- Done through your state’s Birth Registry

**Documents You Receive**
- Birth certificate
- Immunisation record

**Passport Application**
- Apply through your embassy or consulate
- Birth certificate required
""",
      nepaliContent: """
**जन्म दर्ता**
- ६० दिनभित्र दर्ता गर्नुपर्छ
- राज्यको Birth Registry मार्फत गरिन्छ

**पाइने कागजात**
- जन्म प्रमाणपत्र
- खोप अभिलेख

**पासपोर्ट आवेदन**
- आफ्नो दूतावास/कन्सुलेटमार्फत आवेदन दिनुहोस्
- जन्म प्रमाणपत्र आवश्यक हुन्छ
""",
    ),
  ],
),

Guide(
  emoji: "🧾",
  title: "How to Get an ABN",
  nepaliTitle: "ABN कसरी प्राप्त गर्ने?",
  subtitle: "Uber, delivery, cleaning, freelancing, self-employment",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT IS AN ABN?
    // ------------------------------------------------------------
    GuideSection(
      title: "What is an ABN?",
      nepaliTitle: "ABN भनेको के हो?",
      content: """
**ABN (Australian Business Number)**
A unique 11-digit number used for:
- Uber, Uber Eats, DoorDash, Menulog
- Cleaning work
- Freelancing
- Contract jobs
- Small businesses

**Why You Need It**
- To work as an independent contractor
- To invoice clients
- To get paid legally
""",
      nepaliContent: """
**ABN (Australian Business Number)**
११ अङ्कको विशेष नम्बर, प्रयोग हुन्छ:
- Uber, Uber Eats, DoorDash, Menulog
- सफाइ काम
- Freelancing
- Contract jobs
- साना व्यवसाय

**किन आवश्यक?**
- Independent contractor रूपमा काम गर्न
- ग्राहकलाई invoice दिन
- कानुनी रूपमा भुक्तानी पाउन
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — ELIGIBILITY
    // ------------------------------------------------------------
    GuideSection(
      title: "Eligibility",
      nepaliTitle: "योग्यता",
      content: """
You can apply for an ABN if:
- You are starting a business activity
- You are working as a contractor
- You are doing gig work (Uber, delivery)
- You have a valid visa that allows work

**Note**
Student visa holders *can* apply for an ABN.
""",
      nepaliContent: """
तपाईं ABN लिन सक्नुहुन्छ यदि:
- व्यवसाय गतिविधि सुरु गर्दै हुनुहुन्छ
- Contractor रूपमा काम गर्दै हुनुहुन्छ
- Gig work (Uber, delivery) गर्दै हुनुहुन्छ
- काम गर्न अनुमति दिने भिसा छ

**नोट**
विद्यार्थी भिसा भएका व्यक्तिले पनि ABN लिन सक्छन्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — HOW TO APPLY
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Apply for an ABN",
      nepaliTitle: "ABN कसरी आवेदन गर्ने?",
      content: """
**Steps**
1. Go to the Australian Business Register (ABR) website  
2. Select “Apply for an ABN”  
3. Choose “Sole Trader”  
4. Enter personal details  
5. Enter TFN  
6. Describe your business activity  
7. Submit application  

**Processing Time**
Usually instant, sometimes up to 24–48 hours.
""",
      nepaliContent: """
**चरणहरू**
१. Australian Business Register (ABR) वेबसाइटमा जानुहोस्  
२. “Apply for an ABN” छान्नुहोस्  
३. “Sole Trader” चयन गर्नुहोस्  
४. व्यक्तिगत विवरण भर्नुहोस्  
५. TFN प्रविष्ट गर्नुहोस्  
६. आफ्नो काम/व्यवसायको विवरण लेख्नुहोस्  
७. आवेदन पठाउनुहोस्  

**समय**
धेरैजसो तुरुन्तै आउँछ, कहिलेकाहीँ २४–४८ घण्टा लाग्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — COMMON MISTAKES
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Mistakes",
      nepaliTitle: "सामान्य गल्तीहरू",
      content: """
- Selecting the wrong business type  
- Writing unclear business activity  
- Entering incorrect TFN  
- Not updating ABN details when moving  

**Tip**
Use “Delivery services”, “Cleaning services”, or “Freelance digital services” as activity descriptions.
""",
      nepaliContent: """
- गलत व्यवसाय प्रकार छान्नु  
- अस्पष्ट व्यवसाय विवरण लेख्नु  
- गलत TFN प्रविष्ट गर्नु  
- ठेगाना परिवर्तन हुँदा ABN अपडेट नगर्नु  

**सुझाव**
Activity विवरणमा “Delivery services”, “Cleaning services”, वा “Freelance digital services” लेख्न सकिन्छ।
""",
    ),
  ],
),

Guide(
  emoji: "🖥️",
  title: "How to Open a MyGov Account",
  nepaliTitle: "MyGov खाता कसरी खोल्ने?",
  subtitle: "Medicare, ATO, Centrelink, tax return, government services",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT IS MYGOV?
    // ------------------------------------------------------------
    GuideSection(
      title: "What is MyGov?",
      nepaliTitle: "MyGov भनेको के हो?",
      content: """
MyGov is a secure portal that connects you to:
- Medicare
- ATO (Tax Office)
- Centrelink
- Child support
- My Health Record

**Why You Need It**
- To file tax returns
- To access Medicare
- To receive government letters
""",
      nepaliContent: """
MyGov एक सुरक्षित पोर्टल हो जसले तपाईंलाई जोड्छ:
- Medicare
- ATO (Tax Office)
- Centrelink
- Child support
- My Health Record

**किन आवश्यक?**
- कर फिर्ता भर्न
- Medicare प्रयोग गर्न
- सरकारी पत्रहरू पाउन
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — HOW TO CREATE ACCOUNT
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Create a MyGov Account",
      nepaliTitle: "MyGov खाता कसरी बनाउने?",
      content: """
**Steps**
1. Go to my.gov.au  
2. Click “Create account”  
3. Enter your email  
4. Create a password  
5. Set up security questions  
6. Verify your email  

**Tip**
Use an email you will always have access to.
""",
      nepaliContent: """
**चरणहरू**
१. my.gov.au मा जानुहोस्  
२. “Create account” क्लिक गर्नुहोस्  
३. इमेल प्रविष्ट गर्नुहोस्  
४. पासवर्ड बनाउनुहोस्  
५. सुरक्षा प्रश्न सेट गर्नुहोस्  
६. इमेल प्रमाणित गर्नुहोस्  

**सुझाव**
सधैं पहुँच हुने इमेल प्रयोग गर्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — LINKING SERVICES
    // ------------------------------------------------------------
    GuideSection(
      title: "Linking Government Services",
      nepaliTitle: "सरकारी सेवाहरू कसरी लिंक गर्ने?",
      content: """
**Common Services**
- Medicare  
- ATO  
- Centrelink  

**To Link ATO**
You need:
- TFN  
- Bank account  
- Super account  

**To Link Medicare**
You need:
- Passport  
- Visa  
- Medicare card (if already issued)
""",
      nepaliContent: """
**सामान्य सेवाहरू**
- Medicare  
- ATO  
- Centrelink  

**ATO लिंक गर्न**
आवश्यक:
- TFN  
- बैंक खाता  
- सुपर खाता  

**Medicare लिंक गर्न**
आवश्यक:
- पासपोर्ट  
- भिसा  
- Medicare कार्ड (यदि जारी भएको छ भने)
""",
    ),
  ],
),

Guide(
  emoji: "🏥",
  title: "How to Use Medicare",
  nepaliTitle: "Medicare कसरी प्रयोग गर्ने?",
  subtitle: "Eligibility, GP visits, bulk billing, claims, emergencies",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — WHAT IS MEDICARE?
    // ------------------------------------------------------------
    GuideSection(
      title: "What is Medicare?",
      nepaliTitle: "Medicare भनेको के हो?",
      content: """
Medicare is Australia’s public healthcare system.

It covers:
- GP visits
- Specialist visits (partially)
- Hospital treatment
- Tests & scans (partially)
- Emergency care

**Not Covered**
- Dental
- Glasses
- Most medicines (unless subsidised)
""",
      nepaliContent: """
Medicare अस्ट्रेलियाको सार्वजनिक स्वास्थ्य प्रणाली हो।

यसले कभर गर्छ:
- GP भेटघाट
- विशेषज्ञ भेटघाट (आंशिक)
- अस्पताल उपचार
- परीक्षण र स्क्यान (आंशिक)
- आपतकालीन उपचार

**कभर नहुने सेवा**
- दन्त उपचार
- चस्मा
- धेरैजसो औषधि (सब्सिडी नभएमा)
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — ELIGIBILITY
    // ------------------------------------------------------------
    GuideSection(
      title: "Eligibility",
      nepaliTitle: "पात्रता",
      content: """
You may be eligible if you are:
- Australian citizen
- Permanent resident
- Some temporary visa holders (e.g., NZ citizens)
- Partner of eligible residents

**International students**
Usually **not** eligible (use OSHC instead).
""",
      nepaliContent: """
तपाईं पात्र हुन सक्नुहुन्छ यदि:
- अस्ट्रेलियाली नागरिक
- स्थायी बासिन्दा
- केही अस्थायी भिसा (जस्तै NZ नागरिक)
- पात्र पार्टनरका परिवार

**अन्तर्राष्ट्रिय विद्यार्थी**
सामान्यतया पात्र हुँदैनन् (OSHC प्रयोग गर्नुपर्छ)।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — HOW TO USE MEDICARE
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Use Medicare",
      nepaliTitle: "Medicare कसरी प्रयोग गर्ने?",
      content: """
**1. Visit a GP**
Show your Medicare card.

**2. Bulk Billing**
If the clinic offers bulk billing:
- You pay 0 dollars
- Medicare pays the clinic directly

**3. Specialist Visits**
You need a GP referral.

**4. Hospital Care**
Public hospitals are free for Medicare holders.
""",
      nepaliContent: """
**१. GP भेट्नुहोस्**
Medicare कार्ड देखाउनुहोस्।

**२. Bulk Billing**
यदि क्लिनिकले bulk billing गर्छ भने:
- तपाईंले 0 तिर्नुहुन्छ
- Medicare ले क्लिनिकलाई भुक्तानी गर्छ

**३. विशेषज्ञ भेटघाट**
GP ले रेफरल दिनुपर्छ।

**४. अस्पताल उपचार**
Medicare भएका व्यक्तिका लागि सार्वजनिक अस्पताल निःशुल्क हुन्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — CLAIMING MONEY BACK
    // ------------------------------------------------------------
    GuideSection(
      title: "Claiming Medicare Refunds",
      nepaliTitle: "Medicare फिर्ता कसरी पाउने?",
      content: """
If you pay upfront:
- Ask for an invoice
- Submit claim through MyGov
- Refund goes to your bank account

**Processing Time**
Usually 1–3 business days.
""",
      nepaliContent: """
यदि तपाईंले पहिले भुक्तानी गर्नुभयो भने:
- Invoice लिनुहोस्
- MyGov मार्फत दाबी गर्नुहोस्
- फिर्ता रकम बैंक खातामा आउँछ

**समय**
सामान्यतया १–३ कार्यदिन।
""",
    ),
  ],
),

Guide(
  emoji: "🚗",
  title: "Driving in Australia: Complete Guide for Newcomers",
  nepaliTitle: "अस्ट्रेलियामा ड्राइभिङ: नयाँ आउनेहरूका लागि पूर्ण मार्गदर्शन",
  subtitle: "License conversion, tests, car buying, PPSR, insurance, scams, maintenance",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — LICENSE CONVERSION
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Convert Nepali License to an Australian License",
      nepaliTitle: "नेपाली लाइसेन्स अस्ट्रेलियाली लाइसेन्समा रूपान्तरण",
      content: """
**Important Note**
Nepal is NOT a recognised country for direct license transfer.

This means:
- You cannot directly convert your Nepali license
- You must follow the full process:
  - Knowledge test
  - Learner license
  - Driving test (P1)
  - Hazard perception test (state dependent)

**Documents Needed**
- Passport
- Visa
- Proof of address
- Nepali license
- NAATI/embassy translation
- Medicare/bank card (ID)

**Steps**
1. Translate your Nepali license  
2. Book knowledge test  
3. Get learner license  
4. Practice driving  
5. Book driving test  
6. Pass → Get P1 license  
""",
      nepaliContent: """
**महत्वपूर्ण जानकारी**
नेपाल प्रत्यक्ष लाइसेन्स रूपान्तरणका लागि मान्यता प्राप्त देश होइन।

यसको अर्थ:
- नेपाली लाइसेन्स सिधै रूपान्तरण हुँदैन
- पूरा प्रक्रिया गर्नुपर्छ:
  - ज्ञान परीक्षा
  - Learner लाइसेन्स
  - ड्राइभिङ टेस्ट (P1)
  - Hazard perception test (राज्य अनुसार)

**आवश्यक कागजात**
- पासपोर्ट
- भिसा
- ठेगाना प्रमाण
- नेपाली लाइसेन्स
- NAATI/दूतावास अनुवाद
- Medicare/बैंक कार्ड

**चरणहरू**
१. लाइसेन्स अनुवाद  
२. ज्ञान परीक्षा  
३. Learner लाइसेन्स  
४. ड्राइभिङ अभ्यास  
५. ड्राइभिङ टेस्ट  
६. पास → P1 लाइसेन्स  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — BOOKING A DRIVING TEST
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Book a Driving Test",
      nepaliTitle: "ड्राइभिङ टेस्ट कसरी बुक गर्ने?",
      content: """
**Steps**
1. Visit your state’s road authority website  
2. Create an account  
3. Choose test type (hazard or driving test)  
4. Select date, time, location  
5. Pay the fee  

**What You Need on Test Day**
- Learner license  
- ID documents  
- Safe, registered car  
- Supervising driver (if required)

**Common Reasons for Failure**
- Not checking blind spots  
- Speeding  
- Rolling stops  
- Poor lane discipline  
""",
      nepaliContent: """
**चरणहरू**
१. राज्यको रोड अथोरिटी वेबसाइटमा जानुहोस्  
२. खाता बनाउनुहोस्  
३. टेस्ट प्रकार छान्नुहोस्  
४. मिति, समय, स्थान छान्नुहोस्  
५. शुल्क तिर्नुहोस्  

**टेस्ट दिन के चाहिन्छ?**
- Learner लाइसेन्स  
- पहिचान कागजात  
- सुरक्षित, दर्ता भएको कार  
- Supervising driver (यदि आवश्यक)

**असफल हुने कारण**
- Blind spot नहेर्नु  
- गति सीमा नमान्नु  
- पूर्ण रोक नलगाउनु  
- लेन अनुशासन कमजोर  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — BUYING A SECOND-HAND CAR
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Buy a Second‑Hand Car Safely",
      nepaliTitle: "सेकेन्ड–ह्यान्ड कार सुरक्षित रूपमा कसरी किन्नु?",
      content: """
**Where to Buy**
- Facebook Marketplace  
- Dealerships  
- Gumtree  
- Carsales  

**What to Check**
- Service history  
- Odometer  
- Engine noise  
- Oil leaks  
- Tyres  
- AC  
- Registration expiry  

**Test Drive Checklist**
- Smooth acceleration  
- No shaking  
- Brakes responsive  
- Steering straight  
- No warning lights  
""",
      nepaliContent: """
**कहाँबाट किन्नु?**
- Facebook Marketplace  
- Dealerships  
- Gumtree  
- Carsales  

**के जाँच गर्ने?**
- Service इतिहास  
- Odometer  
- इन्जिन आवाज  
- तेल चुहावट  
- टायर  
- एसी  
- Registration  

**टेस्ट ड्राइभ चेकलिस्ट**
- सहज acceleration  
- कार नडुल्नु  
- ब्रेक राम्रो काम गर्नु  
- Steering सीधा  
- Warning light नदेखिनु  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — PPSR CHECK
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Check Car History (PPSR)",
      nepaliTitle: "PPSR मार्फत कार इतिहास कसरी जाँच गर्ने?",
      content: """
**PPSR Shows**
- If car has unpaid loan  
- If car is stolen  
- If car is written off  
- VIN & engine details  

**How to Check**
1. Get VIN  
2. Go to ppsr.gov.au  
3. Enter VIN  
4. Pay 2 dollars 
5. Download report  

**Tip:**  
Always do PPSR before paying any money.
""",
      nepaliContent: """
**PPSR ले देखाउँछ**
- कारमा loan बाँकी छ कि छैन  
- कार चोरी भएको हो कि होइन  
- कार write‑off भएको हो कि होइन  
- VIN र इन्जिन विवरण  

**कसरी चेक गर्ने?**
१. VIN नम्बर लिनुहोस्  
२. ppsr.gov.au मा जानुहोस्  
३. VIN प्रविष्ट गर्नुहोस्  
४. 2 तिर्नुहोस्  
५. रिपोर्ट डाउनलोड  

**सुझाव:**  
पैसा तिर्नु अघि PPSR अनिवार्य गर्नुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — CAR INSURANCE
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Get Car Insurance",
      nepaliTitle: "कार बीमा कसरी गर्ने?",
      content: """
**Types of Insurance**
1. CTP (mandatory)  
2. Third‑party property  
3. Comprehensive (best coverage)

**What to Compare**
- Price  
- Excess  
- Coverage  
- Reviews  
- Roadside assistance  

**Popular Providers**
- NRMA  
- AAMI  
- Budget Direct  
- Allianz  
""",
      nepaliContent: """
**बीमाका प्रकार**
१. CTP (अनिवार्य)  
२. Third‑party property  
३. Comprehensive (सबैभन्दा राम्रो)  

**के तुलना गर्ने?**
- मूल्य  
- Excess  
- Coverage  
- समीक्षा  
- Roadside assistance  

**लोकप्रिय प्रदायक**
- NRMA  
- AAMI  
- Budget Direct  
- Allianz  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 6 — AVOIDING CAR SCAMS
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Avoid Car Scams",
      nepaliTitle: "कार ठगीबाट कसरी बच्ने?",
      content: """
**Common Scams**
- Fake sellers  
- Stolen photos  
- Odometer tampering  
- Hidden damage  
- Asking for deposit before inspection  

**How to Stay Safe**
- Inspect car in person  
- Do PPSR check  
- Never pay deposit online  
- Meet in public places  
- Bring a friend or mechanic  
""",
      nepaliContent: """
**सामान्य ठगी**
- नक्कली विक्रेता  
- चोरीका फोटो  
- Odometer मिलाइएको  
- लुकाइएको क्षति  
- Inspection अघि पैसा माग्ने  

**सुरक्षित रहने तरिका**
- कार प्रत्यक्ष हेर्नुहोस्  
- PPSR चेक गर्नुहोस्  
- अनलाइन अग्रिम पैसा नदिनुहोस्  
- सार्वजनिक स्थानमा भेट्नुहोस्  
- साथी वा मिस्त्री लिएर जानुहोस्  
""",
    ),

    // ------------------------------------------------------------
    // SECTION 7 — CHEAP CAR MAINTENANCE
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Maintain a Car Cheaply",
      nepaliTitle: "कार सस्तोमा कसरी मर्मत गर्ने?",
      content: """
**Basic Maintenance**
- Regular oil change  
- Check tyre pressure  
- Replace air filter yearly  
- Keep coolant topped up  
- Wash car to prevent rust  

**How to Save Money**
- Use independent mechanics  
- Compare service quotes  
- Buy parts online  
- Avoid unnecessary add-ons  
- Drive smoothly to save fuel  
""",
      nepaliContent: """
**मूलभूत मर्मत**
- नियमित तेल बदल्नु  
- टायरको हावा जाँच  
- वर्षमा एकपटक एयर फिल्टर बदल्नु  
- Coolant जाँच  
- कार धुने — जंग रोक्न  

**पैसा बचत गर्ने तरिका**
- Independent मिस्त्री प्रयोग  
- Service quote तुलना  
- Spare parts अनलाइन किन्नु  
- अनावश्यक add-on नलिनु  
- नरम ड्राइभ गरेर इन्धन बचत  
""",
    ),
  ],
),

Guide(
  emoji: "🛂",
  title: "Renewing Your Nepalese Passport in Australia",
  nepaliTitle: "अस्ट्रेलियामा नेपाली पासपोर्ट नवीकरण",
  subtitle: "Eligibility, documents, embassy process, fees, timelines",
  sections: [

    // ------------------------------------------------------------
    // SECTION 1 — OVERVIEW
    // ------------------------------------------------------------
    GuideSection(
      title: "Overview",
      nepaliTitle: "सारांश",
      content: """
Nepalese citizens living in Australia can renew their passport through:
- Embassy of Nepal (Canberra)
- Consulate Offices (Sydney, Melbourne, Perth) — for form submission only

**Important**
All passports are printed in Nepal.  
Processing time can take several weeks.
""",
      nepaliContent: """
अस्ट्रेलियामा बस्ने नेपाली नागरिकले पासपोर्ट नवीकरण गर्न सक्छन्:
- नेपाली दूतावास (Canberra)
- कन्सुलेट कार्यालय (Sydney, Melbourne, Perth) — फारम बुझाउन मात्र

**महत्वपूर्ण**
पासपोर्ट नेपालमै छापिन्छ।  
प्रक्रिया पूरा हुन केही हप्ता लाग्न सक्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 2 — DOCUMENTS REQUIRED
    // ------------------------------------------------------------
    GuideSection(
      title: "Documents You Need",
      nepaliTitle: "आवश्यक कागजात",
      content: """
**Required Documents**
- Old Nepalese passport
- Completed passport application form
- 2 passport-size photos (white background)
- Australian visa copy
- Proof of address (bank statement, utility bill)
- Birth certificate (if details need correction)

**For Minors**
- Parents' passports
- Birth certificate
- Consent letter
""",
      nepaliContent: """
**आवश्यक कागजात**
- पुरानो नेपाली पासपोर्ट
- भरेको आवेदन फारम
- २ पासपोर्ट साइज फोटो (सेतो पृष्ठभूमि)
- अस्ट्रेलियाली भिसा प्रतिलिपि
- ठेगाना प्रमाण (बैंक स्टेटमेन्ट, बिल)
- जन्म प्रमाणपत्र (विवरण परिवर्तन भएमा)

**नाबालकका लागि**
- आमाबाबुको पासपोर्ट
- जन्म प्रमाणपत्र
- सहमति पत्र
""",
    ),

    // ------------------------------------------------------------
    // SECTION 3 — HOW TO APPLY
    // ------------------------------------------------------------
    GuideSection(
      title: "How to Apply",
      nepaliTitle: "कसरी आवेदन गर्ने?",
      content: """
**Steps**
1. Download the passport renewal form from the embassy website  
2. Fill the form clearly  
3. Attach photos and required documents  
4. Visit the Embassy or nearest Consulate  
5. Submit biometrics (fingerprints & signature)  
6. Pay the passport fee  
7. Wait for processing  

**Biometrics**
Must be done in person — cannot be done online.
""",
      nepaliContent: """
**चरणहरू**
१. दूतावासको वेबसाइटबाट फारम डाउनलोड गर्नुहोस्  
२. फारम स्पष्ट रूपमा भर्नुहोस्  
३. फोटो र कागजात संलग्न गर्नुहोस्  
४. दूतावास वा नजिकको कन्सुलेटमा जानुहोस्  
५. बायोमेट्रिक्स (औँठाछाप र हस्ताक्षर) दिनुहोस्  
६. शुल्क तिर्नुहोस्  
७. प्रक्रिया पूरा हुने पर्खनुहोस्  

**बायोमेट्रिक्स**
अनिवार्य रूपमा प्रत्यक्ष उपस्थित हुनुपर्छ — अनलाइन सम्भव छैन।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 4 — FEES & PROCESSING TIME
    // ------------------------------------------------------------
    GuideSection(
      title: "Fees & Processing Time",
      nepaliTitle: "शुल्क र प्रक्रिया समय",
      content: """
**Fees (Approximate)**
- Normal passport: AUD 150–200  
- Lost passport: Higher fee applies  
- Minor passport: Slightly lower fee  

**Processing Time**
- Usually 4–8 weeks  
- Can be longer during peak periods  

**Tip**
Apply early — do not wait until your passport expires.
""",
      nepaliContent: """
**शुल्क (अनुमानित)**
- सामान्य पासपोर्ट: AUD 150–200  
- हराएको पासपोर्ट: बढी शुल्क  
- नाबालकको पासपोर्ट: अलि कम शुल्क  

**प्रक्रिया समय**
- सामान्यतया ४–८ हप्ता  
- व्यस्त समयमा अझै ढिलो हुन सक्छ  

**सुझाव**
पासपोर्ट सकिनु अघि नै आवेदन दिनुहोस्।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 5 — COLLECTION & TRACKING
    // ------------------------------------------------------------
    GuideSection(
      title: "Passport Collection & Tracking",
      nepaliTitle: "पासपोर्ट प्राप्ति र ट्र्याकिङ",
      content: """
**How You Receive Your Passport**
- Embassy will notify you by email or phone  
- You can collect in person  
- Or request postal delivery (extra fee may apply)

**Tracking**
You can contact the Embassy for status updates.

**Tip**
Keep your receipt safe — you may need it for collection.
""",
      nepaliContent: """
**पासपोर्ट कसरी प्राप्त गर्ने?**
- दूतावासले इमेल वा फोनमार्फत जानकारी दिन्छ  
- प्रत्यक्ष गएर लिन सकिन्छ  
- वा पोस्टमार्फत माग्न सकिन्छ (अतिरिक्त शुल्क लाग्न सक्छ)

**ट्र्याकिङ**
स्थिति जान्न दूतावासलाई सम्पर्क गर्न सकिन्छ।

**सुझाव**
रसीद सुरक्षित राख्नुहोस् — पासपोर्ट लिन आवश्यक पर्न सक्छ।
""",
    ),

    // ------------------------------------------------------------
    // SECTION 6 — COMMON ISSUES & TIPS
    // ------------------------------------------------------------
    GuideSection(
      title: "Common Issues & Helpful Tips",
      nepaliTitle: "सामान्य समस्या र उपयोगी सुझाव",
      content: """
**Common Issues**
- Incorrect form details  
- Low-quality photos  
- Missing documents  
- Delays from Nepal  

**Helpful Tips**
- Fill the form in BLOCK letters  
- Use recent photos  
- Double-check your name, DOB, and passport number  
- Keep a scanned copy of your old passport  
""",
      nepaliContent: """
**सामान्य समस्या**
- फारममा गलत विवरण  
- फोटोको गुणस्तर कमजोर  
- कागजात अपूर्ण  
- नेपालबाट ढिलाइ  

**उपयोगी सुझाव**
- फारम BLOCK अक्षरमा भर्नुहोस्  
- नयाँ फोटो प्रयोग गर्नुहोस्  
- नाम, जन्म मिति, पासपोर्ट नम्बर जाँच गर्नुहोस्  
- पुरानो पासपोर्टको स्क्यान सुरक्षित राख्नुहोस्  
""",
    ),
  ],
),

];
