#!/usr/bin/env python3
import os

# Read the original file
with open('lib/guides_page.dart', 'r') as f:
    lines = f.readlines()

# Define extractions
extractions = {
    'tfn_guide_page.dart': (406, 778),
    'tfn_guide_nepali_page.dart': (779, 1195),
    'immigration_guide_page.dart': (1196, 1696),
    'immigration_guide_nepali_page.dart': (1697, 2044),
    'accommodation_guide_page.dart': (2045, 2266),
    'accommodation_guide_nepali_page.dart': (2267, 2482),
    'bank_guide_page.dart': (2483, 3028),
    'bank_guide_nepali_page.dart': (3029, 3237),
    'transport_guide_page.dart': (3238, 3673),
    'transport_guide_nepali_page.dart': (3674, 4105),
    'transport_navigation_guide_page.dart': (4106, 4510),
    'transport_navigation_guide_nepali_page.dart': (4511, 4898),
}

# Extract each class
for name, (start, end) in extractions.items():
    content = ''.join(lines[start:end+1])
    content = content.replace('_buildGuideAppBar', 'buildGuideAppBar')
    content = content.replace('_wrapGuideBody', 'wrapGuideBody')
    content = content.replace('_buildStep', 'buildStep')
    content = content.replace('_buildStepNepali', 'buildStepNepali')
    content = content.replace('_bankLinkRow', 'bankLinkRow')
    with open(f'lib/guides/{name}', 'w') as f:
        f.write(content)
    print(f'Created {name}')

print('Done extracting!')
