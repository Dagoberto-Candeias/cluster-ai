#!/bin/bash

# GDPR Compliance Check Script for Cluster AI

set -e

echo "Starting GDPR compliance checks..."

# Check for GDPR related keywords in code and documentation
echo "Checking for GDPR keywords in source files..."
if grep -r -iE "gdpr|privacy|data protection|consent" --include="*.py" --include="*.js" --include="*.md" .; then
  echo "✅ GDPR related keywords found in source files."
else
  echo "⚠️  No GDPR related keywords found. Please review."
fi

# Check for privacy policy file
if [ -f "docs/privacy_policy.md" ] || [ -f "docs/PRIVACY_POLICY.md" ]; then
  echo "✅ Privacy policy document found."
else
  echo "⚠️  Privacy policy document not found."
fi

# Check for data retention policy mentions
echo "Checking for data retention policy mentions..."
if grep -r -i "data retention" --include="*.md" docs/; then
  echo "✅ Data retention policy mentioned in documentation."
else
  echo "⚠️  Data retention policy not mentioned."
fi

echo "GDPR compliance checks completed."
