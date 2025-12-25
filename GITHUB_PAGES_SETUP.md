# 🚀 GitHub Pages 部署指南

## 📋 已创建的配置文件

✅ `.nojekyll` - 禁用 Jekyll 处理
✅ `.github/workflows/deploy-pages.yml` - 自动部署工作流

---

## 🎯 启用 GitHub Pages（手动方式）

### 方法1：使用 GitHub Actions（推荐，自动部署）

1. **访问仓库设置**
   - 打开 https://github.com/gninel/code
   - 点击顶部的 **Settings（设置）**

2. **启用 GitHub Pages**
   - 在左侧菜单找到 **Pages**
   - 在 "Build and deployment" 部分：
     - **Source**: 选择 `GitHub Actions`

3. **推送代码**
   - 配置文件已创建，推送后自动触发部署
   - 等待几分钟让 GitHub Actions 完成部署

4. **访问游戏**
   - 部署成功后，访问：
   ```
   https://gninel.github.io/code/tetris/
   ```

---

### 方法2：使用分支部署（传统方式）

1. **访问仓库设置**
   - 打开 https://github.com/gninel/code/settings/pages

2. **配置部署源**
   - **Source**: 选择 `Deploy from a branch`
   - **Branch**: 选择 `claude/mobile-tetris-game-EbmgZ`
   - **Folder**: 选择 `/ (root)`

3. **保存并等待**
   - 点击 **Save**
   - 等待几分钟让 GitHub 构建站点

4. **访问游戏**
   ```
   https://gninel.github.io/code/tetris/
   ```

---

## 📱 在手机上访问

部署成功后，直接在手机浏览器输入：

```
https://gninel.github.io/code/tetris/
```

- ✅ 无需下载安装
- ✅ 无需本地服务器
- ✅ 随时随地访问
- ✅ 可以添加到主屏幕

---

## 🔧 故障排除

### 问题1：404 错误
**解决方案：**
- 确认 Pages 已启用
- 检查分支名称是否正确
- 等待5-10分钟让部署完成

### 问题2：样式丢失
**解决方案：**
- `.nojekyll` 文件已创建，应该不会有问题
- 检查浏览器控制台是否有错误

### 问题3：自动部署未触发
**解决方案：**
- 检查 Actions 权限：Settings → Actions → General
- 确保 "Workflow permissions" 设置为 "Read and write permissions"
- 启用 "Allow GitHub Actions to create and approve pull requests"

---

## 📊 部署状态检查

### 查看部署状态
1. 访问 https://github.com/gninel/code/actions
2. 查看 "Deploy Tetris Game to GitHub Pages" 工作流
3. 检查最新运行状态

### 查看已部署的站点
1. 访问 https://github.com/gninel/code/settings/pages
2. 在页面顶部会显示站点URL

---

## 🎮 分享游戏

部署成功后，您可以：

1. **直接分享链接**
   ```
   https://gninel.github.io/code/tetris/
   ```

2. **生成二维码**
   - 使用在线二维码生成器
   - 扫码即可在手机上玩

3. **添加到手机主屏幕**
   - iPhone: Safari → 分享 → 添加到主屏幕
   - Android: Chrome → 菜单 → 添加到主屏幕

---

## 🔄 更新游戏

当您修改游戏代码后：

1. 提交更改到 git
2. 推送到 GitHub
3. GitHub Actions 自动重新部署
4. 几分钟后访问新版本

---

## ✨ 优化建议

### 自定义域名（可选）
1. 在 Pages 设置中添加自定义域名
2. 配置 DNS CNAME 记录
3. 启用 HTTPS

### 性能优化
- 游戏已经是纯静态文件，加载速度很快
- GitHub Pages 自带 CDN 加速
- 支持 HTTPS 安全访问

---

## 📞 需要帮助？

如果部署遇到问题：
1. 检查 GitHub Actions 日志
2. 查看浏览器控制台错误
3. 确认文件路径正确

---

**祝您部署顺利！游戏马上就能在全球访问了！** 🎮🌍
