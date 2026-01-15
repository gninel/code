#!/bin/bash

# Voice Autobiography Flutter - 自动化测试执行脚本
# 用途: 运行不同类型的测试并生成覆盖率报告
# 用法:
#   ./scripts/run_tests.sh all           # 运行所有测试
#   ./scripts/run_tests.sh unit          # 只运行单元测试
#   ./scripts/run_tests.sh widget        # 只运行Widget测试
#   ./scripts/run_tests.sh integration   # 运行集成测试(Mock)
#   ./scripts/run_tests.sh coverage      # 生成覆盖率报告

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 覆盖率目标
COVERAGE_TARGET=90

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Voice Autobiography - 自动化测试执行脚本                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 运行单元测试
run_unit_tests() {
    print_info "运行单元测试..."
    flutter test test/unit/ --coverage

    if [ $? -eq 0 ]; then
        print_success "单元测试通过"
        return 0
    else
        print_error "单元测试失败"
        return 1
    fi
}

# 运行Widget测试
run_widget_tests() {
    print_info "运行Widget测试..."
    flutter test test/widget/ --coverage

    if [ $? -eq 0 ]; then
        print_success "Widget测试通过"
        return 0
    else
        print_error "Widget测试失败"
        return 1
    fi
}

# 运行集成测试
run_integration_tests() {
    print_info "运行集成测试..."
    flutter test test/integration/ --coverage

    if [ $? -eq 0 ]; then
        print_success "集成测试通过"
        return 0
    else
        print_error "集成测试失败"
        return 1
    fi
}

# 运行所有测试
run_all_tests() {
    print_info "运行所有测试..."
    flutter test --coverage

    if [ $? -eq 0 ]; then
        print_success "所有测试通过"
        return 0
    else
        print_error "部分测试失败"
        return 1
    fi
}

# 生成覆盖率报告
generate_coverage_report() {
    print_info "生成覆盖率报告..."

    if [ ! -f coverage/lcov.info ]; then
        print_error "覆盖率文件不存在,请先运行测试"
        return 1
    fi

    # 检查是否安装了lcov
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html --no-function-coverage
        print_success "HTML覆盖率报告已生成: coverage/html/index.html"
    else
        print_warning "未安装genhtml,跳过HTML报告生成"
        print_info "可以使用以下命令安装: brew install lcov"
    fi

    # 计算覆盖率
    if command -v lcov &> /dev/null; then
        echo ""
        print_info "覆盖率统计:"
        lcov --summary coverage/lcov.info 2>&1 | grep -E "(lines|functions)" || true

        # 提取覆盖率百分比
        coverage_percent=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')

        if [ ! -z "$coverage_percent" ]; then
            if (( $(echo "$coverage_percent >= $COVERAGE_TARGET" | bc -l) )); then
                print_success "覆盖率 ${coverage_percent}% ≥ 目标 ${COVERAGE_TARGET}%"
            else
                print_warning "覆盖率 ${coverage_percent}% < 目标 ${COVERAGE_TARGET}%"
            fi
        fi
    fi
}

# 清理旧的覆盖率报告
clean_coverage() {
    print_info "清理旧的覆盖率报告..."
    rm -rf coverage/
    print_success "清理完成"
}

# 主函数
main() {
    print_header

    case "${1:-all}" in
        unit)
            run_unit_tests
            ;;
        widget)
            run_widget_tests
            ;;
        integration)
            run_integration_tests
            ;;
        all)
            run_all_tests
            ;;
        coverage)
            generate_coverage_report
            ;;
        clean)
            clean_coverage
            ;;
        *)
            echo "用法: $0 {all|unit|widget|integration|coverage|clean}"
            echo ""
            echo "命令说明:"
            echo "  all          - 运行所有测试 (默认)"
            echo "  unit         - 只运行单元测试"
            echo "  widget       - 只运行Widget测试"
            echo "  integration  - 只运行集成测试"
            echo "  coverage     - 生成覆盖率报告"
            echo "  clean        - 清理覆盖率报告"
            exit 1
            ;;
    esac
}

main "$@"
