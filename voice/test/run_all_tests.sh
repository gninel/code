#!/bin/bash

# 测试脚本 - 运行所有测试并生成报告

set -e

echo "=========================================="
echo "Voice Autobiography Flutter - 测试套件"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "📁 项目目录: $PROJECT_ROOT"
echo ""

# 函数：运行测试并记录结果
run_test() {
    local test_name=$1
    local test_command=$2

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 运行: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ $test_name 失败${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    echo ""
}

# 1. 单元测试 - Entity
echo "📋 1. 单元测试 - Entity 层"
echo "================================"

run_test "VoiceRecord Entity 测试" \
    "flutter test test/unit/entities/voice_record_entity_test.dart"

run_test "Autobiography Entity 测试" \
    "flutter test test/unit/entities/autobiography_entity_test.dart"

# 2. 单元测试 - Repository
echo ""
echo "📋 2. 单元测试 - Repository 层"
echo "================================"

run_test "VoiceRecord Repository 测试" \
    "flutter test test/unit/repositories/voice_record_repository_test.dart"

run_test "Recording Bloc 测试" \
    "flutter test test/unit/features/recording/recording_bloc_test.dart"

run_test "AI Generation Bloc 测试" \
    "flutter test test/unit/features/ai_generation/ai_generation_bloc_test.dart"

# 3. Widget 测试
echo ""
echo "📋 3. Widget 测试"
echo "================="

run_test "Recording Widget 测试" \
    "flutter test test/unit/widgets/recording_widget_test.dart"

# 4. 服务测试
echo ""
echo "📋 4. 服务层测试"
echo "================"

run_test "Xunfei ASR Service 测试" \
    "flutter test test/unit/services/xunfei_asr_service_test.dart"

run_test "Doubao AI Service 测试" \
    "flutter test test/unit/services/doubao_ai_service_test.dart"

# 5. API 测试
echo ""
echo "📋 5. API 测试"
echo "============"

run_test "API 签名测试" \
    "flutter test test/api_signature_test.dart"

run_test "综合 API 测试" \
    "flutter test test/comprehensive_test.dart"

# 6. 生成覆盖率报告
echo ""
echo "📊 6. 生成覆盖率报告"
echo "=================="

echo "正在生成覆盖率报告..."
flutter test --coverage || true

if [ -f "coverage/lcov.info" ]; then
    echo -e "${GREEN}✅ 覆盖率报告已生成: coverage/lcov.info${NC}"

    # 尝试生成 HTML 报告
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html || true
        echo -e "${GREEN}📄 HTML 覆盖率报告: coverage/html/index.html${NC}"
    else
        echo -e "${YELLOW}⚠️  genhtml 未安装，跳过 HTML 报告生成${NC}"
        echo "   安装: brew install lcov"
    fi
else
    echo -e "${YELLOW}⚠️  覆盖率报告生成失败${NC}"
fi

# 测试总结
echo ""
echo "=========================================="
echo "📈 测试总结"
echo "=========================================="
echo "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}⚠️  有 $FAILED_TESTS 个测试失败${NC}"
    exit 1
fi
