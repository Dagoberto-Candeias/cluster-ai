#!/bin/bash

# HIPAA Compliance Check Script for Cluster AI

set -e

echo "Starting HIPAA compliance checks..."

# Check for HIPAA related keywords in code and documentation
echo "Checking for HIPAA keywords in source files..."
if grep -r -iE "hipaa|phi|protected health information|ehi|electronic health information" --include="*.py" --include="*.js" --include="*.md" .; then
  echo "✅ HIPAA related keywords found in source files."
else
  echo "ℹ️  No HIPAA related keywords found (may be appropriate if not handling health data)."
fi

# Check for BAA (Business Associate Agreement) mentions
echo "Checking for BAA mentions..."
if grep -r -i "baa|business associate agreement" --include="*.md" docs/; then
  echo "✅ BAA mentions found in documentation."
else
  echo "ℹ️  No BAA mentions found (may be appropriate if not a business associate)."
fi

# Check for encryption at rest and in transit
echo "Checking for encryption configurations..."
if grep -r -i "tls|ssl|encryption" --include="*.yml" --include="*.yaml" deployments/; then
  echo "✅ Encryption configurations found."
else
  echo "⚠️  No encryption configurations found."
fi

# Check for audit logging
echo "Checking for audit logging configurations..."
if grep -r -i "audit|logging" --include="*.yml" --include="*.yaml" monitoring/; then
  echo "✅ Audit logging configurations found."
else
  echo "⚠️  Audit logging configurations not found."
fi

echo "HIPAA compliance checks completed."
