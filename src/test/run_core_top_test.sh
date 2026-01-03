#!/bin/bash
# 快速运行 test_core_top.v 测试脚本

set -e

echo "========================================="
echo "Core Top Test - Quick Run Script"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在正确的目录
if [ ! -f "test_core_top.v" ]; then
    echo -e "${RED}错误：请在 src/test 目录下运行此脚本${NC}"
    exit 1
fi

# 检查核心模块文件
echo -e "\n${YELLOW}[1/4]${NC} 检查核心模块文件..."

required_files=(
    "../core/core_defs.v"
    "../core/core_alu.v"
    "../core/core_regfile.v"
    "../core/core_fetch.v"
    "../core/core_decode.v"
    "../core/core_exec.v"
    "../core/core_lsu.v"
    "../core/core_pipeline_ctrl.v"
    "../core/core_top.v"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} 缺失: $file"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo -e "\n${RED}错误：缺少 $missing_files 个核心模块文件${NC}"
    exit 1
fi

# 选择仿真器
echo -e "\n${YELLOW}[2/4]${NC} 选择仿真器..."

if command -v iverilog &> /dev/null; then
    SIMULATOR="iverilog"
    echo -e "  ${GREEN}✓${NC} 使用 iverilog"
elif command -v xvlog &> /dev/null; then
    SIMULATOR="xsim"
    echo -e "  ${GREEN}✓${NC} 使用 Vivado XSim"
else
    echo -e "  ${RED}✗${NC} 未找到仿真器（iverilog 或 Vivado XSim）"
    echo "  请安装其中之一："
    echo "    - iverilog: sudo apt-get install iverilog"
    echo "    - Vivado: source /path/to/Vivado/settings64.sh"
    exit 1
fi

# 编译
echo -e "\n${YELLOW}[3/4]${NC} 编译测试..."

if [ "$SIMULATOR" = "iverilog" ]; then
    # 使用iverilog编译
    iverilog -g2012 -o test_core_top \
        -I../core \
        ../core/core_defs.v \
        ../core/core_alu.v \
        ../core/core_regfile.v \
        ../core/core_fetch.v \
        ../core/core_decode.v \
        ../core/core_exec.v \
        ../core/core_lsu.v \
        ../core/core_pipeline_ctrl.v \
        ../core/core_top.v \
        test_core_top.v
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} 编译成功"
    else
        echo -e "  ${RED}✗${NC} 编译失败"
        exit 1
    fi
else
    # 使用XSim编译
    xvlog --incr --relax -i ../core \
        ../core/core_defs.v \
        ../core/core_alu.v \
        ../core/core_regfile.v \
        ../core/core_fetch.v \
        ../core/core_decode.v \
        ../core/core_exec.v \
        ../core/core_lsu.v \
        ../core/core_pipeline_ctrl.v \
        ../core/core_top.v \
        test_core_top.v > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} 编译成功 (xvlog)"
        
        xelab -debug typical test_core_top -s test_core_top_snapshot > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} 链接成功 (xelab)"
        else
            echo -e "  ${RED}✗${NC} 链接失败"
            exit 1
        fi
    else
        echo -e "  ${RED}✗${NC} 编译失败"
        exit 1
    fi
fi

# 运行仿真
echo -e "\n${YELLOW}[4/4]${NC} 运行仿真..."
echo ""

if [ "$SIMULATOR" = "iverilog" ]; then
    # 运行iverilog仿真
    ./test_core_top | tee test_core_top.log
    sim_result=${PIPESTATUS[0]}
else
    # 运行XSim仿真
    xsim test_core_top_snapshot -runall | tee test_core_top.log
    sim_result=${PIPESTATUS[0]}
fi

# 检查测试结果
echo ""
echo "========================================="
echo "检查测试结果..."
echo "========================================="

if grep -q "ALL TESTS PASSED" test_core_top.log; then
    echo -e "${GREEN}✓✓✓ 所有测试通过！✓✓✓${NC}"
    
    # 显示测试摘要
    echo ""
    echo "测试摘要："
    grep -E "Test Summary:" test_core_top.log
    
    echo ""
    echo -e "${GREEN}测试成功完成！${NC}"
    exit_code=0
else
    echo -e "${RED}✗ 测试失败${NC}"
    
    # 显示失败信息
    echo ""
    echo "失败的测试："
    grep -E "\[FAIL\]" test_core_top.log || echo "  (无明确失败信息)"
    
    echo ""
    echo -e "${RED}测试未通过，请检查日志。${NC}"
    exit_code=1
fi

# 清理信息
echo ""
echo "========================================="
echo "文件信息"
echo "========================================="
echo "日志文件: test_core_top.log"
echo "波形文件: test_core_top.vcd"
echo ""
echo "查看波形："
if command -v gtkwave &> /dev/null; then
    echo "  gtkwave test_core_top.vcd"
else
    echo "  (需要安装 gtkwave)"
fi

echo ""
echo "重新运行测试："
echo "  ./run_core_top_test.sh"
echo ""

exit $exit_code
