#!/usr/bin/env python3
import os

# Define imports for each file
file_imports = {
    'tfn_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'package:url_launcher/url_launcher.dart';",
        "import 'guide_helpers.dart';",
        "import 'tfn_guide_nepali_page.dart';",
    ],
    'tfn_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'package:url_launcher/url_launcher.dart';",
        "import 'guide_helpers.dart';",
    ],
    'immigration_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
        "import 'immigration_guide_nepali_page.dart';",
    ],
    'immigration_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
    ],
    'accommodation_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
        "import 'accommodation_guide_nepali_page.dart';",
    ],
    'accommodation_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
    ],
    'bank_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
        "import 'bank_guide_nepali_page.dart';",
    ],
    'bank_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
    ],
    'transport_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
        "import 'transport_guide_nepali_page.dart';",
    ],
    'transport_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
    ],
    'transport_navigation_guide_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
        "import 'transport_navigation_guide_nepali_page.dart';",
    ],
    'transport_navigation_guide_nepali_page.dart': [
        "import 'package:flutter/material.dart';",
        "import 'guide_helpers.dart';",
    ],
}

# Add imports to each file
for filename, imports in file_imports.items():
    filepath = f'lib/guides/{filename}'
    with open(filepath, 'r') as f:
        content = f.read()
    
    with open(filepath, 'w') as f:
        for imp in imports:
            f.write(imp + '\n')
        f.write('\n')
        f.write(content)
    
    print(f'Added imports to {filename}')

print('Done!')
