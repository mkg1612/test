#!/bin/bash

# Terraform Configuration Unit Tests
# Testing library: Shell-based testing with terraform validate, fmt, and plan
# Framework: Custom shell testing framework for Terraform configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
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

# Setup test environment
setup_test_env() {
    log_test "Setting up test environment"
    
    # Create temporary directory for testing
    TEST_DIR=$(mktemp -d)
    cp -r . "$TEST_DIR/"
    cd "$TEST_DIR"
    
    # Create test variables file
    cat << 'TFVARS' > terraform.tfvars.test
aws_region = "us-east-1"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7S6EXAMPLE test@example.com"
TFVARS
    
    log_pass "Test environment setup complete"
}

# Cleanup test environment
cleanup_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}

# Test 1: Terraform syntax validation
test_terraform_syntax() {
    log_test "Validating Terraform syntax"
    
    if terraform fmt -check=true -recursive .; then
        log_pass "Terraform formatting is correct"
    else
        log_fail "Terraform formatting issues found"
        return 1
    fi
    
    if terraform init -backend=false >/dev/null 2>&1; then
        log_pass "Terraform initialization successful"
    else
        log_fail "Terraform initialization failed"
        return 1
    fi
    
    if terraform validate; then
        log_pass "Terraform configuration is valid"
    else
        log_fail "Terraform validation failed"
        return 1
    fi
}

# Test 2: Required providers validation
test_required_providers() {
    log_test "Validating required providers"
    
    # Check AWS provider version constraint
    if grep -q 'version = "~> 5.0"' main.tf; then
        log_pass "AWS provider version constraint is properly set"
    else
        log_fail "AWS provider version constraint missing or incorrect"
        return 1
    fi
    
    # Check random provider version constraint
    if grep -q 'version = "~> 3.1"' main.tf; then
        log_pass "Random provider version constraint is properly set"
    else
        log_fail "Random provider version constraint missing or incorrect"
        return 1
    fi
    
    # Check minimum Terraform version
    if grep -q 'required_version = ">= 1.0"' main.tf; then
        log_pass "Minimum Terraform version requirement is set"
    else
        log_fail "Minimum Terraform version requirement missing"
        return 1
    fi
}

# Test 3: Network configuration validation
test_network_configuration() {
    log_test "Validating network configuration"
    
    # Test VPC CIDR block
    if grep -q 'cidr_block.*=.*"10.0.0.0/16"' main.tf; then
        log_pass "VPC CIDR block is correctly configured"
    else
        log_fail "VPC CIDR block configuration issue"
        return 1
    fi
    
    # Test public subnet CIDR
    if grep -q 'cidr_block.*=.*"10.0.1.0/24"' main.tf; then
        log_pass "Public subnet CIDR is correctly configured"
    else
        log_fail "Public subnet CIDR configuration issue"
        return 1
    fi
    
    # Test private subnet CIDR
    if grep -q 'cidr_block.*=.*"10.0.2.0/24"' main.tf; then
        log_pass "Private subnet CIDR is correctly configured"
    else
        log_fail "Private subnet CIDR configuration issue"
        return 1
    fi
    
    # Test DNS settings
    if grep -A2 -B2 'enable_dns_hostnames.*=.*true' main.tf | grep -q 'enable_dns_support.*=.*true'; then
        log_pass "VPC DNS settings are properly configured"
    else
        log_fail "VPC DNS settings configuration issue"
        return 1
    fi
}

# Test 4: Security group validation
test_security_groups() {
    log_test "Validating security group configurations"
    
    # Test MongoDB security group SSH access
    if grep -A10 'resource "aws_security_group" "mongodb_sg"' main.tf | grep -q 'from_port.*=.*22'; then
        log_pass "MongoDB security group SSH access is configured"
    else
        log_fail "MongoDB security group SSH access missing"
        return 1
    fi
    
    # Test MongoDB port access
    if grep -A20 'resource "aws_security_group" "mongodb_sg"' main.tf | grep -q 'from_port.*=.*27017'; then
        log_pass "MongoDB security group database access is configured"
    else
        log_fail "MongoDB security group database access missing"
        return 1
    fi
    
    # Test EKS cluster security group HTTPS access
    if grep -A10 'resource "aws_security_group" "eks_cluster"' main.tf | grep -q 'from_port.*=.*443'; then
        log_pass "EKS cluster security group HTTPS access is configured"
    else
        log_fail "EKS cluster security group HTTPS access missing"
        return 1
    fi
}

# Test 5: EKS cluster configuration validation
test_eks_configuration() {
    log_test "Validating EKS cluster configuration"
    
    # Test EKS cluster name
    if grep -q 'name.*=.*"cbdc-app-cluster"' main.tf; then
        log_pass "EKS cluster name is properly set"
    else
        log_fail "EKS cluster name configuration issue"
        return 1
    fi
    
    # Test EKS version
    if grep -q 'version.*=.*"1.27"' main.tf; then
        log_pass "EKS cluster version is specified"
    else
        log_fail "EKS cluster version not specified or incorrect"
        return 1
    fi
    
    # Test node group instance types
    if grep -q 'instance_types.*=.*\["t3.medium"\]' main.tf; then
        log_pass "EKS node group instance types are configured"
    else
        log_fail "EKS node group instance types configuration issue"
        return 1
    fi
    
    # Test scaling configuration
    if grep -A5 'scaling_config' main.tf | grep -q 'desired_size.*=.*2'; then
        log_pass "EKS node group scaling configuration is set"
    else
        log_fail "EKS node group scaling configuration issue"
        return 1
    fi
}

# Test 6: IAM roles and policies validation
test_iam_configuration() {
    log_test "Validating IAM roles and policies"
    
    # Test EKS cluster role
    if grep -q 'name = "cbdc-app-eks-cluster-role"' main.tf; then
        log_pass "EKS cluster IAM role is properly named"
    else
        log_fail "EKS cluster IAM role naming issue"
        return 1
    fi
    
    # Test EKS node group role
    if grep -q 'name = "cbdc-app-eks-node-group-role"' main.tf; then
        log_pass "EKS node group IAM role is properly named"
    else
        log_fail "EKS node group IAM role naming issue"
        return 1
    fi
    
    # Test policy attachments
    if grep -q 'policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"' main.tf; then
        log_pass "EKS cluster policy attachment is configured"
    else
        log_fail "EKS cluster policy attachment missing"
        return 1
    fi
    
    # Test MongoDB role permissions (intentionally overpermissive for testing)
    if grep -A10 'resource "aws_iam_role_policy" "mongodb_policy"' main.tf | grep -q '"s3:\*"'; then
        log_pass "MongoDB IAM policy includes S3 permissions (as expected for test scenario)"
    else
        log_fail "MongoDB IAM policy S3 permissions missing"
        return 1
    fi
}

# Test 7: S3 bucket configuration validation
test_s3_configuration() {
    log_test "Validating S3 bucket configuration"
    
    # Test bucket naming with random suffix
    if grep -q "bucket = \"cbdc-app-db-backups-\${random_string.bucket_suffix.result}\"" main.tf; then
        log_pass "S3 bucket uses random suffix for uniqueness"
    else
        log_fail "S3 bucket naming configuration issue"
        return 1
    fi
    
    # Test public access block settings (intentionally permissive for testing)
    if grep -A5 'resource "aws_s3_bucket_public_access_block"' main.tf | grep -q 'block_public_acls.*=.*false'; then
        log_pass "S3 bucket public access settings are configured (intentionally permissive for testing)"
    else
        log_fail "S3 bucket public access settings configuration issue"
        return 1
    fi
    
    # Test bucket policy
    if grep -A10 'resource "aws_s3_bucket_policy"' main.tf | grep -q '"s3:GetObject"'; then
        log_pass "S3 bucket policy includes GetObject permission"
    else
        log_fail "S3 bucket policy GetObject permission missing"
        return 1
    fi
}

# Test 8: EC2 instance configuration validation
test_ec2_configuration() {
    log_test "Validating EC2 instance configuration"
    
    # Test AMI ID
    if grep -q 'ami.*=.*"ami-0c02fb55956c7d316"' main.tf; then
        log_pass "EC2 instance AMI is specified"
    else
        log_fail "EC2 instance AMI configuration issue"
        return 1
    fi
    
    # Test instance type
    if grep -q 'instance_type.*=.*"t3.medium"' main.tf; then
        log_pass "EC2 instance type is properly configured"
    else
        log_fail "EC2 instance type configuration issue"
        return 1
    fi
    
    # Test key pair configuration
    if grep -q 'key_name.*=.*aws_key_pair.mongodb_key.key_name' main.tf; then
        log_pass "EC2 instance key pair is properly referenced"
    else
        log_fail "EC2 instance key pair configuration issue"
        return 1
    fi
    
    # Test user data template
    if grep -q 'user_data.*=.*base64encode(templatefile(' main.tf; then
        log_pass "EC2 instance user data template is configured"
    else
        log_fail "EC2 instance user data template configuration issue"
        return 1
    fi
}

# Test 9: Random resource validation
test_random_resources() {
    log_test "Validating random resource configuration"
    
    # Test random string length
    if grep -A5 'resource "random_string" "bucket_suffix"' main.tf | grep -q 'length.*=.*8'; then
        log_pass "Random string length is properly configured"
    else
        log_fail "Random string length configuration issue"
        return 1
    fi
    
    # Test random string character settings
    if grep -A5 'resource "random_string" "bucket_suffix"' main.tf | grep -q 'special.*=.*false'; then
        log_pass "Random string special characters are disabled"
    else
        log_fail "Random string special characters configuration issue"
        return 1
    fi
    
    if grep -A5 'resource "random_string" "bucket_suffix"' main.tf | grep -q 'upper.*=.*false'; then
        log_pass "Random string uppercase characters are disabled"
    else
        log_fail "Random string uppercase configuration issue"
        return 1
    fi
}

# Test 10: ECR repository validation
test_ecr_configuration() {
    log_test "Validating ECR repository configuration"
    
    # Test repository name
    if grep -q 'name = "cbdc-app"' main.tf | head -1; then
        log_pass "ECR repository name is properly configured"
    else
        log_fail "ECR repository name configuration issue"
        return 1
    fi
    
    # Test image scanning
    if grep -A5 'image_scanning_configuration' main.tf | grep -q 'scan_on_push.*=.*true'; then
        log_pass "ECR repository image scanning is enabled"
    else
        log_fail "ECR repository image scanning configuration issue"
        return 1
    fi
}

# Test 11: Security services validation
test_security_services() {
    log_test "Validating security services configuration"
    
    # Test Security Hub
    if grep -q 'resource "aws_securityhub_account"' main.tf; then
        log_pass "AWS Security Hub is configured"
    else
        log_fail "AWS Security Hub configuration missing"
        return 1
    fi
    
    # Test GuardDuty
    if grep -q 'resource "aws_guardduty_detector"' main.tf; then
        log_pass "AWS GuardDuty detector is configured"
    else
        log_fail "AWS GuardDuty detector configuration missing"
        return 1
    fi
    
    # Test GuardDuty S3 logs
    if grep -A10 'datasources' main.tf | grep -A3 's3_logs' | grep -q 'enable.*=.*true'; then
        log_pass "GuardDuty S3 logs are enabled"
    else
        log_fail "GuardDuty S3 logs configuration issue"
        return 1
    fi
    
    # Test GuardDuty Kubernetes audit logs
    if grep -A15 'datasources' main.tf | grep -A5 'kubernetes' | grep -A3 'audit_logs' | grep -q 'enable.*=.*true'; then
        log_pass "GuardDuty Kubernetes audit logs are enabled"
    else
        log_fail "GuardDuty Kubernetes audit logs configuration issue"
        return 1
    fi
}

# Test 12: Resource dependencies validation
test_resource_dependencies() {
    log_test "Validating resource dependencies"
    
    # Test EKS cluster dependencies
    if grep -A10 'resource "aws_eks_cluster"' main.tf | grep -A5 'depends_on' | grep -q 'aws_iam_role_policy_attachment.eks_cluster_policy'; then
        log_pass "EKS cluster dependencies are properly configured"
    else
        log_fail "EKS cluster dependencies configuration issue"
        return 1
    fi
    
    # Test EKS node group dependencies
    if grep -A20 'resource "aws_eks_node_group"' main.tf | grep -A10 'depends_on' | grep -q 'aws_iam_role_policy_attachment.eks_node_group_policy'; then
        log_pass "EKS node group dependencies are properly configured"
    else
        log_fail "EKS node group dependencies configuration issue"
        return 1
    fi
    
    # Test route table association
    if grep -q 'subnet_id.*=.*aws_subnet.public.id' main.tf; then
        log_pass "Route table association properly references subnet"
    else
        log_fail "Route table association configuration issue"
        return 1
    fi
}

# Test 13: Tagging validation
test_resource_tagging() {
    log_test "Validating resource tagging"
    
    # Count resources with tags
    TAG_RESOURCES=$(grep -c 'tags = {' main.tf)
    
    if [ "$TAG_RESOURCES" -ge 10 ]; then
        log_pass "Multiple resources have proper tagging ($TAG_RESOURCES resources tagged)"
    else
        log_fail "Insufficient resource tagging ($TAG_RESOURCES resources tagged)"
        return 1
    fi
    
    # Test specific tag values
    if grep -A3 'tags = {' main.tf | grep -q 'Name = "cbdc-app'; then
        log_pass "Resources use consistent naming convention in tags"
    else
        log_fail "Inconsistent resource naming in tags"
        return 1
    fi
}

# Test 14: Variable usage validation
test_variable_usage() {
    log_test "Validating variable usage"
    
    # Test aws_region variable usage
    if grep -q 'region = var.aws_region' main.tf; then
        log_pass "AWS region variable is properly used"
    else
        log_fail "AWS region variable usage issue"
        return 1
    fi
    
    # Test availability zone variable usage
    if grep -q "availability_zone.*=.*\"\${var.aws_region}" main.tf; then
        log_pass "Availability zone uses region variable"
    else
        log_fail "Availability zone variable usage issue"
        return 1
    fi
    
    # Test SSH public key variable usage
    if grep -q 'public_key = var.ssh_public_key' main.tf; then
        log_pass "SSH public key variable is properly used"
    else
        log_fail "SSH public key variable usage issue"
        return 1
    fi
}

# Test 15: Security best practices validation (intentional vulnerabilities for testing)
test_security_practices() {
    log_test "Validating security configurations (including intentional test vulnerabilities)"
    
    # Test for overly permissive security groups (expected for testing)
    if grep -A5 'ingress' main.tf | grep -q 'cidr_blocks = \["0.0.0.0/0"\]'; then
        log_pass "Security groups have wide-open access (as expected for test scenario)"
    else
        log_fail "Security group CIDR configuration unexpected"
        return 1
    fi
    
    # Test for overly permissive IAM policies (expected for testing)
    if grep -A10 'Action = \[' main.tf | grep -q '"s3:\*"'; then
        log_pass "IAM policies include wildcard permissions (as expected for test scenario)"
    else
        log_fail "IAM policy wildcard permissions missing"
        return 1
    fi
    
    # Test public S3 bucket configuration (expected for testing)
    if grep -A5 'block_public_acls' main.tf | grep -q 'false'; then
        log_pass "S3 bucket has public access enabled (as expected for test scenario)"
    else
        log_fail "S3 bucket public access configuration issue"
        return 1
    fi
}

# Main test execution
main() {
    echo "Starting Terraform Configuration Unit Tests"
    echo "=========================================="
    
    # Setup
    setup_test_env
    
    # Run all tests
    test_terraform_syntax || true
    test_required_providers || true
    test_network_configuration || true
    test_security_groups || true
    test_eks_configuration || true
    test_iam_configuration || true
    test_s3_configuration || true
    test_ec2_configuration || true
    test_random_resources || true
    test_ecr_configuration || true
    test_security_services || true
    test_resource_dependencies || true
    test_resource_tagging || true
    test_variable_usage || true
    test_security_practices || true
    
    # Cleanup
    cleanup_test_env
    
    # Results
    echo ""
    echo "Test Results:"
    echo "============="
    echo "Tests Run: $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi