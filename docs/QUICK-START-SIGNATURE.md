# 🚀 5 分钟创建你的签名动画

## 第一步：打开在线编辑器

访问：**https://yqnn.github.io/svg-path-editor/**

## 第二步：绘制签名

1. 点击 **"Clear"** 清空画布
2. 用鼠标手写你的名字（比如 "Sejolyn"）
3. 尽量一笔完成

![示例图](https://i.imgur.com/example.png)

## 第三步：获取代码

1. 点击 **"Export"** 按钮
2. 你会看到类似这样的代码：
```xml
<svg>
  <path d="M50,90 Q100,50 150,90 T250,90" />
</svg>
```
3. **复制** `d="..."` 里面的内容（就是那串 M50,90 Q100... 的部分）

## 第四步：替换到组件

1. 打开文件：`src/components/signature/MySignature.astro`

2. 找到这一行：
```html
<path
  d="M50,90 Q100,50 150,90 T250,90"
     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     把这里替换成你复制的内容
```

3. 粘贴你的路径，保存文件

## 第五步：计算路径长度

1. 运行 `pnpm dev` 启动开发服务器
2. 打开浏览器访问你的网站
3. 按 **F12** 打开开发者工具
4. 切换到 **Console** 标签
5. 输入并回车：
```javascript
document.querySelector('.my-signature-path').getTotalLength()
```
6. 你会得到一个数字，比如 `345.6789`，记住它（取整数 346）

## 第六步：更新 CSS

在同一个文件中找到这部分：

```css
.my-signature-path {
  stroke-dasharray: 300;  /* ← 改成 346 */
  stroke-dashoffset: 300; /* ← 改成 346 */
}
```

改成：
```css
.my-signature-path {
  stroke-dasharray: 346;
  stroke-dashoffset: 346;
}
```

保存文件！

## 第七步：使用你的签名

在任何页面中导入并使用：

```astro
---
import MySignature from '@/components/signature/MySignature.astro'
---

<MySignature />
```

## 完成！🎉

刷新浏览器，你应该能看到你的签名动画了！

---

## 📝 常见问题

### Q: 签名不显示？
A: 检查路径是否正确复制，确保 `d="..."` 中有内容

### Q: 动画太快/太慢？
A: 修改 CSS 中的 `0.8s`：
```css
animation: draw-signature 0.8s ease-in-out forwards;
                        /* ↑ 改这里 */
```

### Q: 签名太小/太大？
A: 调整 SVG 的 viewBox：
```html
<svg viewBox="0 0 320 180">
           <!-- ↑ 增大/减小这些数字 -->
```

### Q: 笔画太粗/太细？
A: 调整 stroke-width：
```html
<path stroke-width="3" ... />
              <!-- ↑ 改这个数字 -->
```

### Q: 想要多种颜色？
A: 改变 stroke 属性：
```html
<path stroke="#448bff" ... />
      <!-- ↑ 任意颜色 -->
```

---

## 🎨 进阶：多笔画签名

如果你的签名需要分多笔：

1. 在编辑器中分别画每一笔
2. 每一笔会生成一个 `<path>`
3. 给每个路径不同的 class 名
4. 用 CSS 设置延迟让它们依次绘制

```html
<!-- 第一笔 -->
<path d="..." class="signature-path path-1" />
<!-- 第二笔 -->
<path d="..." class="signature-path path-2" />
```

```css
.path-1 {
  animation: draw 0.8s ease-in-out forwards;
}

.path-2 {
  animation: draw 0.6s ease-in-out 0.8s forwards;
  /*                            ↑ 延迟 0.8s，等第一笔完成 */
}
```

---

需要更详细的教程？查看 `docs/HOW-TO-CREATE-SIGNATURE.md`！
