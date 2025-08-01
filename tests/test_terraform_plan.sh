#!/bin/bash

# Terraform Plan Validation Tests
# Testing library: Shell-based testing with terraform plan
# Framework: Custom shell testing framework for Terraform plan validation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "${YELLOW}[PLAN TEST]${NC} $1"
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

# Setup test environment with mock AWS credentials
setup_plan_test_env() {
    log_test "Setting up plan test environment"
    
    TEST_DIR=$(mktemp -d)
    cp -r . "$TEST_DIR/"
    cd "$TEST_DIR"
    
    # Set mock AWS credentials for plan testing
    export AWS_ACCESS_KEY_ID="mock-access-key"
    export AWS_SECRET_ACCESS_KEY="mock-secret-key"
    export AWS_DEFAULT_REGION="us-east-1"
    
    # Create test variables file
    cat << 'TFVARS' > terraform.tfvars.test
aws_region = "us-east-1"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7S6EXAMPLE test@example.com"
TFVARS
    
    # Create mock MongoDB userdata script
    cat << 'USERDATA' > mongodb_userdata.sh
#!/bin/bash
echo "Mock userdata script for MongoDB"
echo "S3 Bucket: ${s3_bucket}"
USERDATA
    
    log_pass "Plan test environment setup complete"
}

cleanup_plan_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
    
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_DEFAULT_REGION
}

# Test Terraform plan generation
test_terraform_plan_generation() {
    log_test "Testing Terraform plan generation"
    
    # Initialize Terraform
    if terraform init -backend=false >/dev/null 2>&1; then
        log_pass "Terraform initialization for plan test successful"
    else
        log_fail "Terraform initialization for plan test failed"
        return 1
    fi
    
    # Generate plan (will fail with mock credentials but should validate syntax)
    PLAN_OUTPUT=$(terraform plan -var-file=terraform.tfvars.test -no-color 2>&1 || true)
    
    # Check if plan contains expected resources
    if echo "$PLAN_OUTPUT" | grep -q "aws_vpc.main"; then
        log_pass "Plan includes VPC resource"
    else
        log_fail "Plan missing VPC resource"
        return 1
    fi
    
    if echo "$PLAN_OUTPUT" | grep -q "aws_eks_cluster.main"; then
        log_pass "Plan includes EKS cluster resource"
    else
        log_fail "Plan missing EKS cluster resource"
        return 1
    fi
    
    if echo "$PLAN_OUTPUT" | grep -q "aws_s3_bucket.db_backups"; then
        log_pass "Plan includes S3 bucket resource"
    else
        log_fail "Plan missing S3 bucket resource"
        return 1
    fi
}

# Test resource count in plan
test_resource_count() {
    log_test "Testing expected resource count in plan"
    
    # Count expected resources in the configuration
    EXPECTED_RESOURCES=$(grep -c '^resource ' main.tf)
    
    if [ "$EXPECTED_RESOURCES" -ge 20 ]; then
        log_pass "Configuration contains adequate number of resources ($EXPECTED_RESOURCES)"
    else
        log_fail "Configuration has fewer resources than expected ($EXPECTED_RESOURCES)"
        return 1
    fi
}

# Test variable validation
test_variable_validation() {
    log_test "Testing variable validation in plan"
    
    # Test with missing required variable
    PLAN_OUTPUT_NO_VARS=$(terraform plan -no-color 2>&1 || true)
    
    if echo "$PLAN_OUTPUT_NO_VARS" | grep -qi "variable.*not.*defined\|no value for required variable"; then
        log_pass "Plan correctly identifies missing required variables"
    else
        log_fail "Plan should identify missing required variables"
        return 1
    fi
}

main() {
    echo "Starting Terraform Plan Validation Tests"
    echo "========================================"
    
    setup_plan_test_env
    
    test_terraform_plan_generation || true
    test_resource_count || true
    test_variable_validation || true
    
    cleanup_plan_test_env
    
    echo ""
    echo "Plan Test Results:"
    echo "=================="
    echo "Tests Run: $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All plan tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some plan tests failed!${NC}"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi