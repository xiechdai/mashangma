# 马上码项目GitHub Pages生产部署指南

## 前提条件
- 已安装Flutter 3.19+
- 已配置Git环境
- 已将代码推送到GitHub仓库 `git@github.com:xiechdai/mashangma.git`

## 部署步骤

### 1. 构建生产版本的Web应用

在项目根目录执行：
```bash
# 构建生产版本
flutter build web --release

# 如果需要自定义基础路径（如使用GitHub Pages子目录）
# flutter build web --release --base-href="/mashangma/"
```

构建完成后，所有静态文件将生成在 `build/web` 目录。

### 2. 配置GitHub Pages

#### 方法1：自动部署（推荐）

使用GitHub Actions自动构建和部署：

1. 在项目根目录创建 `.github/workflows/deploy.yml` 文件：
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ master ]
  
permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './build/web'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

2. 提交并推送这个文件：
```bash
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Pages deployment workflow"
git push origin master
```

3. 启用GitHub Pages：
   - 登录GitHub，进入仓库设置
   - 点击 "Pages"（在左侧菜单）
   - 在 "Build and deployment" 部分，选择 "Source" 为 "GitHub Actions"
   - 保存设置

4. 等待部署完成：
   - 进入 "Actions" 标签页查看部署进度
   - 部署完成后，访问：`https://xiechdai.github.io/mashangma/`

#### 方法2：手动部署

1. 切换到 `build/web` 目录：
```bash
cd build/web
```

2. 初始化Git仓库并提交：
```bash
git init
git remote add origin git@github.com:xiechdai/mashangma.git
git checkout -b gh-pages
git add .
git commit -m "Deploy web version"
git push -f origin gh-pages
```

3. 启用GitHub Pages：
   - 登录GitHub，进入仓库设置
   - 点击 "Pages"
   - 在 "Build and deployment" 部分，选择 "Source" 为 "Deploy from a branch"
   - 选择 "Branch" 为 "gh-pages"，"Folder" 为 "/ (root)"
   - 点击 "Save"

4. 访问网站：
   - 部署完成后，访问：`https://xiechdai.github.io/mashangma/`

## 3. 配置自定义域名（可选）

1. 在GitHub Pages设置中，添加自定义域名
2. 在域名注册商处，添加CNAME记录指向：`xiechdai.github.io`
3. 在 `build/web` 目录中创建CNAME文件：
   ```bash
echo "yourdomain.com" > CNAME
git add CNAME
git commit -m "Add custom domain"
git push origin gh-pages
```

## 4. 验证部署

1. 访问：`https://xiechdai.github.io/mashangma/`
2. 检查网站功能是否正常
3. 测试响应式设计在不同设备上的表现

## 5. 自动化更新

每次推送代码到master分支时：
- 方法1（GitHub Actions）：自动重新构建和部署
- 方法2（手动）：需要重新执行构建和部署步骤

## 常见问题解决

### 1. 页面空白或资源加载失败
- 检查 `--base-href` 参数是否正确
- 确保所有资源文件都已上传
- 查看浏览器控制台的错误信息

### 2. 路由问题（刷新页面404）
- GitHub Pages默认不支持单页应用路由
- 解决方案：使用hash路由或配置404页面重定向

### 3. 部署延迟
- GitHub Pages部署可能需要几分钟时间
- 清除浏览器缓存后重试

### 4. HTTPS问题
- GitHub Pages默认提供HTTPS
- 自定义域名需要单独配置SSL

## 下一步

- 定期更新依赖包
- 监控网站访问情况
- 根据用户反馈优化功能
- 考虑使用CDN加速静态资源
