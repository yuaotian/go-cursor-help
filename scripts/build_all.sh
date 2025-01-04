#!/bin/bash

# 设置颜色代码 / Set color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color / 无颜色

# Build optimization flags
OPTIMIZATION_FLAGS="-trimpath -ldflags=\"-s -w\""
PARALLEL_JOBS=$(nproc || echo "4")  # Get number of CPU cores or default to 4

# Messages / 消息
EN_MESSAGES=(
    "Starting build process for version"
    "Cleaning old builds..."
    "Creating bin directory..."
    "Failed to create bin directory"
    "Building for"
    "Successfully built:"
    "Failed to build for"
    "Build Summary:"
    "Successful builds:"
    "Failed builds:"
    "Generated files:"
)

CN_MESSAGES=(
    "开始构建版本"
    "正在清理旧的构建文件..."
    "正在创建bin目录..."
    "创建bin目录失败"
    "正在构建"
    "构建成功："
    "构建失败："
    "构建摘要："
    "成功构建数："
    "失败构建数："
    "生成的文件："
    "构建过程被中断"
    "错误："
)

# 版本信息 / Version info
VERSION="1.0.0"

# Detect system language / 检测系统语言
detect_language() {
    if [[ $(locale | grep "LANG=zh_CN") ]]; then
        echo "cn"
    else
        echo "en"
    fi
}

# Get message based on language / 根据语言获取消息
get_message() {
    local index=$1
    local lang=$(detect_language)
    
    if [[ "$lang" == "cn" ]]; then
        echo "${CN_MESSAGES[$index]}"
    else
        echo "${EN_MESSAGES[$index]}"
    fi
}

# 错误处理函数 / Error handling function
handle_error() {
    echo -e "${RED}$(get_message 12) $1${NC}"
    exit 1
}

# 清理函数 / Cleanup function
cleanup() {
    if [ -d "../bin" ]; then
        rm -rf ../bin
        echo -e "${GREEN}$(get_message 1)${NC}"
    fi
}

# Build function with optimizations
build() {
    local os=$1
    local arch=$2
    local ext=""
    [ "$os" = "windows" ] && ext=".exe"
    
    echo -e "${GREEN}$(get_message 4) $os/$arch${NC}"
    
    GOOS=$os GOARCH=$arch CGO_ENABLED=0 go build \
        -trimpath \
        -ldflags="-s -w" \
        -o "../bin/$os/$arch/cursor-id-modifier$ext" \
        -a -installsuffix cgo \
        -mod=readonly \
        ../cmd/cursor-id-modifier &
}

# Parallel build execution
build_all() {
    local builds=0
    local max_parallel=$PARALLEL_JOBS
    
    # Define build targets
    declare -A targets=(
        ["linux/amd64"]=1
        ["linux/386"]=1
        ["linux/arm64"]=1
        ["windows/amd64"]=1
        ["windows/386"]=1
        ["darwin/amd64"]=1
        ["darwin/arm64"]=1
    )
    
    for target in "${!targets[@]}"; do
        IFS='/' read -r os arch <<< "$target"
        build "$os" "$arch"
        
        ((builds++))
        
        if ((builds >= max_parallel)); then
            wait
            builds=0
        fi
    done
    
    # Wait for remaining builds
    wait
}

# Main execution
main() {
    cleanup
    mkdir -p ../bin || { echo -e "${RED}$(get_message 3)${NC}"; exit 1; }
    build_all
    echo -e "${GREEN}Build completed successfully${NC}"
}

# 捕获错误信号 / Catch error signals
trap 'echo -e "\n${RED}$(get_message 11)${NC}"; exit 1' INT TERM

# 执行主函数 / Execute main function
main