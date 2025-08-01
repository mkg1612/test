# Terraform Configuration Test Suite

This directory contains comprehensive unit tests for the Terraform configuration in `main.tf`.

## Testing Framework

- **Testing Library**: Shell-based testing framework
- **Framework**: Custom shell testing framework specifically designed for Terraform configurations
- **Tools Used**: terraform validate, terraform fmt, terraform plan, bash scripting

## Test Files

### 1. `test_main_tf.sh`

Comprehensive unit tests covering:

- Terraform syntax validation
- Required providers validation
- Network configuration validation
- Security group configurations
- EKS cluster configuration
- IAM roles and policies
- S3 bucket configuration
- EC2 instance configuration
- Random resource validation
- ECR repository configuration
- Security services validation
- Resource dependencies
- Resource tagging
- Variable usage
- Security practices (including intentional vulnerabilities for testing)

### 2. `test_terraform_plan.sh`

Plan validation tests covering:

- Terraform plan generation
- Resource count validation
- Variable validation

### 3. `run_all_tests.sh`

Comprehensive test runner that:

- Checks prerequisites
- Runs all test suites
- Generates summary report

## Running Tests

### Run All Tests

```bash
./tests/run_all_tests.sh
```

### Run Individual Test Suites

```bash
# Main configuration tests
./tests/test_main_tf.sh

# Plan validation tests
./tests/test_terraform_plan.sh
```

## Test Coverage

The test suite covers:

- ✅ Syntax validation
- ✅ Provider configuration
- ✅ Network resources (VPC, subnets, routing)
- ✅ Security groups
- ✅ EKS cluster and node groups
- ✅ IAM roles and policies
- ✅ S3 bucket configuration
- ✅ EC2 instances
- ✅ Random resources
- ✅ ECR repositories
- ✅ Security services (Security Hub, GuardDuty)
- ✅ Resource dependencies
- ✅ Resource tagging
- ✅ Variable usage
- ✅ Security configurations (including intentional test vulnerabilities)

## Expected Behavior

Note that this Terraform configuration contains intentional security vulnerabilities for testing purposes:

- Overly permissive security groups (0.0.0.0/0 CIDR blocks)
- Overly permissive IAM policies (wildcard permissions)
- Public S3 bucket access
- Outdated AMI references

The tests validate that these configurations are present as expected for the testing scenario.

## Prerequisites

- Terraform >= 1.0
- Bash shell
- Basic Unix utilities (grep, sed, awk)

## Test Environment

Tests run in isolated temporary directories and use mock AWS credentials for plan validation to avoid requiring actual AWS access.