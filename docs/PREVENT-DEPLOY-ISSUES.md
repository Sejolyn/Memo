# 如何预防 Vercel 部署依赖问题

## 📋 问题说明

当你的代码在本地能构建成功，但在 Vercel 上失败时，通常是因为：
- 本地 `node_modules` 包含了间接依赖（其他包带来的）
- 你的代码直接使用了这些间接依赖，但没有在 `package.json` 中声明
- Vercel 全新安装时找不到这些依赖

## 🛡️ 预防方法

### 方法 1：推送前本地验证（推荐）

每次推送到 Vercel 前运行：

```bash
pnpm verify
```

这个脚本会：
1. 删除 `node_modules`（清理缓存）
2. 全新安装依赖
3. 运行类型检查
4. 执行构建

如果本地验证通过，Vercel 上也会成功。

### 方法 2：使用 GitHub Actions 自动检查

我们已经添加了 `.github/workflows/verify-build.yml`，它会在每次推送时自动运行验证构建。

如果 GitHub Actions 构建失败，**不要推送到生产环境**。

## 🔍 如何发现缺失的依赖

如果构建失败，错误信息通常会显示：
```
Cannot find module 'xxx' imported from 'yyy'
```

解决方法：
```bash
pnpm add xxx -D  # 如果是开发依赖
pnpm add xxx     # 如果是生产依赖
```

## 📝 最佳实践

1. **直接导入的包必须声明**：如果你的代码里有 `import xxx from 'yyy'`，那么 `yyy` 必须在 `package.json` 中
2. **定期运行 `pnpm verify`**：特别是添加新插件或工具后
3. **关注 GitHub Actions 构建状态**：如果失败，说明有依赖问题
4. **不要依赖间接依赖**：即使本地能用，也可能随时失效

## 🚨 应急处理

如果 Vercel 部署已经失败：

1. 查看 Vercel 错误日志，找到缺失的包名
2. 本地添加依赖：`pnpm add <包名> -D`
3. 运行 `pnpm verify` 验证
4. 提交并推送
