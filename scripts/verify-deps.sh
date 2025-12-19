#!/bin/bash
# 验证依赖脚本 - 在推送前运行此脚本可以发现缺失的依赖

set -e

echo "🧹 清理旧构建..."
rm -rf node_modules .astro .vercel dist

echo "📦 全新安装依赖..."
pnpm install --frozen-lockfile

echo "✅ 运行类型检查..."
pnpm astro check

echo "🏗️  构建项目..."
pnpm build

echo ""
echo "✅ 验证成功！所有依赖都已正确声明。"
echo "现在可以安全推送到 Vercel 了。"
