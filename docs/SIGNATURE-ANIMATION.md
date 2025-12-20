# 签名动画使用指南

## 📝 简介

SVG 签名动画组件，使用 CSS stroke-dasharray 实现手写效果。

## 🎯 使用方法

### 在页面中使用

```astro
---
import Signature from '@/components/signature/Signature.astro'
---

<Signature />
```

### 自定义样式

```astro
<Signature class="my-custom-class" />
```

## 🎨 如何制作自己的签名

### 方法 1：使用在线工具

1. 访问 [SVG Path Editor](https://yqnn.github.io/svg-path-editor/)
2. 手写或绘制你的签名
3. 导出 SVG 代码
4. 替换组件中的 `<path d="...">` 部分

### 方法 2：使用设计软件

1. **Figma/Sketch/Illustrator** 中绘制签名
2. 导出为 SVG
3. 打开 SVG 文件，复制 `<path>` 标签
4. 粘贴到组件中

### 方法 3：使用手写板

1. 使用 [MyScript](https://webdemo.myscript.com/) 手写签名
2. 导出为 SVG
3. 提取路径数据

## 🔧 计算路径长度

需要知道路径的总长度来设置 `stroke-dasharray`：

```javascript
// 在浏览器控制台运行
const path = document.querySelector('.signature-path')
const length = path.getTotalLength()
console.log('Path length:', length)
```

然后更新 CSS：
```css
.path-1 {
  stroke-dasharray: 404; /* 使用计算出的长度 */
  stroke-dashoffset: 404;
}
```

## ⚙️ 动画配置

### 调整动画时长

```css
.path-1 {
  animation: draw-path-1 0.6s ease-in-out forwards;
  /* 0.6s 改为你想要的时长 */
}
```

### 调整延迟

```css
.path-2 {
  animation: draw-path-2 1s ease-in-out 0.4s forwards;
  /* 0.4s 是延迟时间 */
}
```

### 循环播放

```css
.signature-path {
  animation-iteration-count: infinite; /* 无限循环 */
}
```

## 🎭 触发方式

### 1. 鼠标悬停触发（默认）
```astro
<Signature /> <!-- 悬停时播放 -->
```

### 2. 页面加载自动播放
已内置，延迟 500ms 后自动播放

### 3. 滚动到视图时播放
已内置 IntersectionObserver，滚动到可见时播放

### 4. 点击触发
```astro
<Signature class="click-trigger" />

<script>
  document.querySelector('.click-trigger').addEventListener('click', () => {
    // 重置并重新播放
    const paths = document.querySelectorAll('.signature-path')
    paths.forEach(path => {
      path.style.animation = 'none'
      setTimeout(() => {
        path.style.animation = ''
      }, 10)
    })
  })
</script>
```

## 💡 进阶技巧

### 添加颜色渐变

```css
.signature-path {
  stroke: url(#gradient);
}
```

```html
<defs>
  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" style="stop-color:#448bff;stop-opacity:1" />
    <stop offset="100%" style="stop-color:#44e9ff;stop-opacity:1" />
  </linearGradient>
</defs>
```

### 添加阴影效果

```css
.signature-svg {
  filter: drop-shadow(2px 2px 4px rgba(0, 0, 0, 0.2));
}
```

### 响应式大小

```css
.signature-svg {
  width: 100%;
  max-width: 320px;
}

@media (max-width: 640px) {
  .signature-svg {
    max-width: 240px;
  }
}
```

## 🌟 使用场景

- 关于页面的个性签名
- 博客底部的签名档
- 首页的欢迎签名
- 文章结尾的作者签名

## 📚 参考资源

- [SVG Path Tutorial](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths)
- [CSS stroke-dasharray](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/stroke-dasharray)
- [SVG Animation Guide](https://css-tricks.com/svg-line-animation-works/)
