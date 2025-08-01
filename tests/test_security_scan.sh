#!/bin/bash

# Terraform Security Scanning Tests
# Testing library: Shell-based security validation
# Framework: Custom security testing framework for Terraform

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "${YELLOW}[SECURITY TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test for hardcoded credentials
test_hardcoded_credentials() {
    log_test "Scanning for hardcoded credentials"
    
    # Check for potential hardcoded access keys
    if grep -qi "AKIA\|aws_access_key\|aws_secret" main.tf; then
        log_fail "Potential hardcoded AWS credentials found"
        return 1
    else
        log_pass "No hardcoded AWS credentials detected"
    fi
    
    # Check for hardcoded passwords
    if grep -qi "password.*=.*[\"'][^\"']*[\"']" main.tf; then
        log_fail "Potential hardcoded passwords found"
        return 1
    else
        log_pass "No hardcoded passwords detected"
    fi
}

# Test for overly permissive security groups (intentional for testing)
test_security_group_permissions() {
    log_test "Analyzing security group permissions"
    
    # Check for 0.0.0.0/0 CIDR blocks (expected in test scenario)
    SG_OPEN_COUNT=$(grep -c "0.0.0.0/0" main.tf || echo "0")
    
    if [ "$SG_OPEN_COUNT" -gt 0 ]; then
        log_warning "Found $SG_OPEN_COUNT instances of 0.0.0.0/0 CIDR blocks (expected for test scenario)"
        log_pass "Security group open access validated for test environment"
    else
        log_fail "Expected open security group access not found in test configuration"
        return 1
    fi
    
    # Check for SSH access on port 22
    if grep -A5 'from_port.*=.*22' main.tf | grep -q "0.0.0.0/0"; then
        log_warning "SSH access (port 22) is open to the world (expected for test scenario)"
        log_pass "SSH access configuration validated for test environment"
    else
        log_fail "Expected SSH access configuration not found"
        return 1
    fi
}

# Test for overly permissive IAM policies (intentional for testing)
test_iam_permissions() {
    log_test "Analyzing IAM policy permissions"
    
    # Check for wildcard permissions
    WILDCARD_COUNT=$(grep -c "\*" main.tf | grep -v "Principal" || echo "0")
    
    if [ "$WILDCARD_COUNT" -gt 0 ]; then
        log_warning "Found wildcard permissions in IAM policies (expected for test scenario)"
        log_pass "IAM wildcard permissions validated for test environment"
    else
        log_fail "Expected wildcard IAM permissions not found in test configuration"
        return 1
    fi
    
    # Check for overly broad resource permissions
    if grep -q '"Resource": "\*"' main.tf; then
        log_warning "IAM policies with wildcard resources found (expected for test scenario)"
        log_pass "IAM resource wildcards validated for test environment"
    else
        log_fail "Expected IAM resource wildcards not found"
        return 1
    fi
}

# Test for public S3 bucket configuration (intentional for testing)
test_s3_security() {
    log_test "Analyzing S3 bucket security configuration"
    
    # Check for public access block settings
    if grep -A5 'aws_s3_bucket_public_access_block' main.tf | grep -q 'false'; then
        log_warning "S3 bucket has public access enabled (expected for test scenario)"
        log_pass "S3 public access configuration validated for test environment"
    else
        log_fail "Expected S3 public access configuration not found"
        return 1
    fi
    
    # Check for public bucket policy
    if grep -A10 'aws_s3_bucket_policy' main.tf | grep -q '"Principal": "\*"'; then
        log_warning "S3 bucket policy allows public access (expected for test scenario)"
        log_pass "S3 bucket policy public access validated for test environment"
    else
        log_fail "Expected S3 bucket policy public access not found"
        return 1
    fi
}

# Test for encryption settings
test_encryption_settings() {
    log_test "Checking encryption configurations"
    
    # Check if EKS cluster has encryption enabled (not explicitly configured in test)
    if grep -A10 'aws_eks_cluster' main.tf | grep -q 'encryption_config'; then
        log_pass "EKS cluster encryption configuration found"
    else
        log_warning "EKS cluster encryption not explicitly configured"
    fi
    
    # Check S3 bucket encryption (not configured in test scenario)
    if grep -A5 'aws_s3_bucket' main.tf | grep -q 'server_side_encryption'; then
        log_pass "S3 bucket encryption configuration found"
    else
        log_warning "S3 bucket encryption not configured (typical for test scenario)"
    fi
}

# Test for outdated AMI usage (intentional for testing)
test_ami_security() {
    log_test "Analyzing AMI security"
    
    # Check for specific outdated AMI (expected in test scenario)
    if grep -q 'ami-0c02fb55956c7d316' main.tf; then
        log_warning "Outdated AMI detected (expected for test scenario)"
        log_pass "Outdated AMI usage validated for test environment"
    else
        log_fail "Expected outdated AMI not found in test configuration"
        return 1
    fi
}

# Test for missing security features
test_missing_security_features() {
    log_test "Checking for missing security features"
    
    # Check for CloudTrail (not configured in test)
    if grep -q 'aws_cloudtrail' main.tf; then
        log_pass "CloudTrail configuration found"
    else
        log_warning "CloudTrail not configured (acceptable for test scenario)"
    fi
    
    # Check for Config (not configured in test)
    if grep -q 'aws_config' main.tf; then
        log_pass "AWS Config configuration found"
    else
        log_warning "AWS Config not configured (acceptable for test scenario)"
    fi
    
    # Check for Security Hub (should be present)
    if grep -q 'aws_securityhub_account' main.tf; then
        log_pass "AWS Security Hub is configured"
    else
        log_fail "AWS Security Hub configuration missing"
        return 1
    fi
    
    # Check for GuardDuty (should be present)
    if grep -q 'aws_guardduty_detector' main.tf; then
        log_pass "AWS GuardDuty is configured"
    else
        log_fail "AWS GuardDuty configuration missing"
        return 1
    fi
}

main() {
    echo -e "${BLUE}Starting Terraform Security Scanning Tests${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    
    test_hardcoded_credentials || true
    test_security_group_permissions || true
    test_iam_permissions || true
    test_s3_security || true
    test_encryption_settings || true
    test_ami_security || true
    test_missing_security_features || true
    
    echo ""
    echo -e "${BLUE}Security Test Results:${NC}"
    echo -e "${BLUE}======================${NC}"
    echo "Tests Run: $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    echo ""
    echo -e "${YELLOW}Note: This configuration intentionally contains security vulnerabilities for testing purposes.${NC}"
    echo -e "${YELLOW}Many 'warnings' above are expected and validate the test scenario.${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}Security scanning completed successfully!${NC}"
        exit 0
    else
        echo -e "${RED}Some security tests failed!${NC}"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi