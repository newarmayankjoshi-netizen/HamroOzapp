#!/usr/bin/env python3
import re

file_path = 'lib/guides_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Remove duplicate nepaliTitle lines
cleaned_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    # Check if this is a nepaliTitle line
    if 'nepaliTitle:' in line:
        # Look ahead to see if the next line is also nepaliTitle
        if i + 1 < len(lines) and 'nepaliTitle:' in lines[i + 1]:
            # Skip this duplicate
            print(f"Removing duplicate at line {i+1}: {line.strip()[:50]}...")
            i += 1
            continue
    cleaned_lines.append(line)
    i += 1

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(cleaned_lines)

print(f"\nDone! Cleaned {len(lines) - len(cleaned_lines)} duplicate lines")
