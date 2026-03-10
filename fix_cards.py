#!/usr/bin/env python3
import re
import os

# Process all guide files except guide_helpers.dart
guide_files = [
    'lib/guides/tfn_guide_page.dart',
    'lib/guides/tfn_guide_nepali_page.dart',
    'lib/guides/immigration_guide_page.dart',
    'lib/guides/immigration_guide_nepali_page.dart',
    'lib/guides/accommodation_guide_page.dart',
    'lib/guides/accommodation_guide_nepali_page.dart',
    'lib/guides/bank_guide_page.dart',
    'lib/guides/bank_guide_nepali_page.dart',
    'lib/guides/transport_guide_page.dart',
    'lib/guides/transport_guide_nepali_page.dart',
    'lib/guides/transport_navigation_guide_page.dart',
    'lib/guides/transport_navigation_guide_nepali_page.dart',
]

for filepath in guide_files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Remove elevation: 2, from Card widgets
    content = re.sub(r'\n\s*elevation:\s*2,\s*\n', '\n', content)
    
    # Remove shape: RoundedRectangleBorder(...), from Card widgets
    # This handles both single-line and multi-line shape definitions
    content = re.sub(
        r'\n\s*shape:\s*RoundedRectangleBorder\([^)]*\),\s*\n',
        '\n',
        content,
        flags=re.MULTILINE
    )
    
    # Also handle the case where borderRadius is on next line
    content = re.sub(
        r'\n\s*shape:\s*RoundedRectangleBorder\(\s*\n\s*borderRadius:[^)]*\),\s*\n',
        '\n',
        content,
        flags=re.MULTILINE | re.DOTALL
    )
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'✓ Updated {filepath}')
    else:
        print(f'- No changes needed for {filepath}')

print('\nDone! All cards will now use consistent styling from CardTheme.')
