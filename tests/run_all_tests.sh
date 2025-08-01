#!/bin/bash

# Comprehensive Test Runner for Terraform Configuration
# Testing library: Shell-based testing framework
# Framework: Custom comprehensive testing suite

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Terraform Configuration Test Suite   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check for required tools
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: terraform is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ terraform found: $(terraform version | head -1)${NC}"
    echo ""
}

# Run main configuration tests
run_main_tests() {
    echo -e "${BLUE}Running main configuration tests...${NC}"
    if ./tests/test_main_tf.sh; then
        echo -e "${GREEN}✓ Main configuration tests passed${NC}"
        MAIN_TESTS_PASSED=1
    else
        echo -e "${RED}✗ Main configuration tests failed${NC}"
        MAIN_TESTS_PASSED=0
    fi
    echo ""
}

# Run plan validation tests
run_plan_tests() {
    echo -e "${BLUE}Running plan validation tests...${NC}"
    if ./tests/test_terraform_plan.sh; then
        echo -e "${GREEN}✓ Plan validation tests passed${NC}"
        PLAN_TESTS_PASSED=1
    else
        echo -e "${RED}✗ Plan validation tests failed${NC}"
        PLAN_TESTS_PASSED=0
    fi
    echo ""
}

# Run security scanning tests
run_security_tests() {
    echo -e "${BLUE}Running security scanning tests...${NC}"
    if ./tests/test_security_scan.sh; then
        echo -e "${GREEN}✓ Security scanning tests passed${NC}"
        SECURITY_TESTS_PASSED=1
    else
        echo -e "${RED}✗ Security scanning tests failed${NC}"
        SECURITY_TESTS_PASSED=0
    fi
    echo ""
}

# Generate test report
generate_report() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}           Test Summary Report          ${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    TOTAL_SUITES=3
    PASSED_SUITES=0
    
    if [ "$MAIN_TESTS_PASSED" -eq 1 ]; then
        echo -e "${GREEN}✓ Main Configuration Tests: PASSED${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "${RED}✗ Main Configuration Tests: FAILED${NC}"
    fi
    
    if [ "$PLAN_TESTS_PASSED" -eq 1 ]; then
        echo -e "${GREEN}✓ Plan Validation Tests: PASSED${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "${RED}✗ Plan Validation Tests: FAILED${NC}"
    fi

    if [ "$SECURITY_TESTS_PASSED" -eq 1 ]; then
        echo -e "${GREEN}✓ Security Scanning Tests: PASSED${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "${RED}✗ Security Scanning Tests: FAILED${NC}"
    fi
    
    echo ""
    echo "Test Suites: $PASSED_SUITES/$TOTAL_SUITES passed"
    
    if [ "$PASSED_SUITES" -eq "$TOTAL_SUITES" ]; then
        echo -e "${GREEN}🎉 All test suites passed successfully!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some test suites failed${NC}"
        exit 1
    fi
}

# Main execution
main() {
    check_prerequisites
    run_main_tests
    run_plan_tests
    run_security_tests
    generate_report
}

main "$@"