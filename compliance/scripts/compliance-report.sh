#!/bin/bash

# Comprehensive Compliance Report Generator for Cluster AI

set -e

REPORT_DIR="compliance/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/compliance_report_$TIMESTAMP.md"

# Create reports directory if it doesn't exist
mkdir -p "$REPORT_DIR"

echo "# Cluster AI Compliance Report" > "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# GDPR Compliance Check
echo "## GDPR Compliance Check" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### GDPR Keywords in Source Files" >> "$REPORT_FILE"
if grep -r -iE "gdpr|privacy|data protection|consent" --include="*.py" --include="*.js" --include="*.md" . >> "$REPORT_FILE" 2>/dev/null; then
  echo "✅ GDPR related keywords found." >> "$REPORT_FILE"
else
  echo "⚠️  No GDPR related keywords found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "### Privacy Policy" >> "$REPORT_FILE"
if [ -f "docs/privacy_policy.md" ] || [ -f "docs/PRIVACY_POLICY.md" ]; then
  echo "✅ Privacy policy document found." >> "$REPORT_FILE"
else
  echo "⚠️  Privacy policy document not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# HIPAA Compliance Check
echo "## HIPAA Compliance Check" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### HIPAA Keywords in Source Files" >> "$REPORT_FILE"
if grep -r -iE "hipaa|phi|protected health information|ehi|electronic health information" --include="*.py" --include="*.js" --include="*.md" . >> "$REPORT_FILE" 2>/dev/null; then
  echo "✅ HIPAA related keywords found." >> "$REPORT_FILE"
else
  echo "ℹ️  No HIPAA related keywords found (may be appropriate if not handling health data)." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Security Configurations
echo "## Security Configurations" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### Encryption at Rest and Transit" >> "$REPORT_FILE"
if grep -r -i "tls\|ssl\|encryption" --include="*.yml" --include="*.yaml" deployments/ >> "$REPORT_FILE" 2>/dev/null; then
  echo "✅ Encryption configurations found." >> "$REPORT_FILE"
else
  echo "⚠️  No encryption configurations found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "### Network Policies" >> "$REPORT_FILE"
if grep -r "NetworkPolicy" --include="*.yml" --include="*.yaml" deployments/ >> "$REPORT_FILE" 2>/dev/null; then
  echo "✅ Network policies configured." >> "$REPORT_FILE"
else
  echo "⚠️  Network policies not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "### RBAC Configurations" >> "$REPORT_FILE"
if grep -r "Role\|RoleBinding\|ClusterRole" --include="*.yml" --include="*.yaml" deployments/ >> "$REPORT_FILE" 2>/dev/null; then
  echo "✅ RBAC configurations found." >> "$REPORT_FILE"
else
  echo "⚠️  RBAC configurations not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Data Retention
echo "## Data Retention Policies" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### Backup Configurations" >> "$REPORT_FILE"
if [ -d "backup/" ]; then
  echo "✅ Backup directory exists." >> "$REPORT_FILE"
  ls -la backup/ >> "$REPORT_FILE"
else
  echo "⚠️  Backup directory not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Recommendations
echo "## Recommendations" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **Privacy Policy**: Ensure a comprehensive privacy policy is documented and accessible." >> "$REPORT_FILE"
echo "2. **Data Processing Agreements**: Implement DPAs for GDPR compliance." >> "$REPORT_FILE"
echo "3. **Encryption**: Ensure all data is encrypted at rest and in transit." >> "$REPORT_FILE"
echo "4. **Access Controls**: Implement least privilege access controls." >> "$REPORT_FILE"
echo "5. **Audit Logging**: Enable comprehensive audit logging for compliance." >> "$REPORT_FILE"
echo "6. **Regular Reviews**: Conduct regular compliance reviews and updates." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Compliance report generated: $REPORT_FILE"
echo "Report saved to: $REPORT_FILE"
