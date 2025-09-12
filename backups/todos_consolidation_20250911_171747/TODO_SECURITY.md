# TODO: Security Audit and Cleanup

## Critical Issues
- [ ] **IMMEDIATE**: Remove real private key from `certs/dask_key.pem` - This contains a live private key that should not be in the repository
- [ ] Regenerate Dask TLS certificates if needed for secure communication
- [ ] Update `.gitignore` to exclude sensitive files (*.pem, *.key, certs/, keys/, secrets/)

## Security Improvements
- [ ] Run gitleaks scan on repository: `gitleaks detect --config .gitleaks.toml --verbose`
- [ ] Implement environment variables for sensitive configuration (API keys, passwords, tokens)
- [ ] Move sensitive configuration to `.env` files (excluded from git)
- [ ] Review and update password policies in configuration files
- [ ] Implement secrets management (e.g., HashiCorp Vault, AWS Secrets Manager, or similar)

## Documentation Updates
- [ ] Update guides to use environment variables instead of hardcoded values
- [ ] Add security best practices section to README
- [ ] Document proper key management procedures

## Monitoring
- [ ] Set up pre-commit hooks to run gitleaks before commits
- [ ] Add CI/CD pipeline security scanning
- [ ] Regular security audits of the codebase

## Verification
- [ ] Confirm no sensitive data remains in repository
- [ ] Test that removed key doesn't break functionality (regenerate if needed)
- [ ] Verify .gitignore properly excludes sensitive files
