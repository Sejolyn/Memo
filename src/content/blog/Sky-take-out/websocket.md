---
title: 「苍穹外卖」复盘：WebSocket
description: '「苍穹外卖」中WebSocket的介绍与使用。'
publishDate: 2025-12-19 22:50:10
tags:
  - backend
---



## HTTP 缺陷



在 WebSocket 出现之前，Web 世界主要靠 HTTP 协议。HTTP 有一个致命的性格缺陷：**“被动”**。

- **HTTP 的规则**：请求 -> 响应。
    - 前端：如果不问，后端就不说。
    - 后端：我有新数据（新订单），但我联系不上前端，我只能干着急。



> 假如没有 WebSocket，怎么实现“新订单提醒”？



只能使用笨办法——**轮询 (Polling)**：

1. **短轮询 (Short Polling)**：
    - 商家后台每隔 2 秒发一个 HTTP 请求问后端：“有新订单吗？”
    - 后端：“没有。”
    - 2秒后：“有新订单吗？”
    - 后端：“没有。”
    - _缺点_：99% 的请求都是废话，浪费流量，浪费服务器资源，而且有延迟（运气不好要等2秒）。
    
2. **长轮询 (Long Polling)**：
    - 商家后台问：“有新订单吗？”
    - 后端**不立即回复**，而是把请求“挂起”（hold住）。哪怕等 20 秒，一旦有新订单，立刻返回；或者超时了再返回“没有”。
    - _缺点_：虽然比短轮询好，但依然建立在 HTTP 之上，连接频繁断开重连，Header 头部信息冗余大。



而 WebSocket 实现了 **全双工通信** ——服务端可以 **主动** 给客户端发消息。



## WebSocket 工作机制



WebSocket 并不是完全脱离 HTTP 的，它更像是 HTTP 的一种“升级”。



### 握手



WebSocket 的连接建立，必须依靠 HTTP 来开路。

1. **客户端发起请求**：看起来像普通的 HTTP GET 请求，但 Header 里带了特殊的暗号：
```http
GET /ws/clientId HTTP/1.1
Connection: Upgrade
Upgrade: websocket
```

- **翻译**：“大哥（服务器），我想把协议升级一下，咱们别用 HTTP 了，改用 WebSocket 吧？”




2. **服务器响应**：如果服务器支持，会返回状态码 **101**：

```http
HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Upgrade: websocket
```

- **翻译**：“准了！以后这条连接就是 WebSocket 的天下了。”



### 全双工通信



一旦握手成功，HTTP 协议就退场了。这条 TCP 连接**不会断开**，双方可以通过这条“专线”自由地互相发送数据帧。

- 后端有新订单 -> 直接推给前端。
- 前端有操作 -> 直接推给后端。
- **低开销**：不需要像 HTTP 那样每次都带一大堆 Header（Cookie, User-Agent等），数据包很轻量。



### 心跳保活



网络环境是很复杂的（中间有 Nginx、防火墙、路由器）。如果一条连接很久没数据传输，这些中间设备可能会以为连接“死”了，强行切断它。

- **Ping/Pong**：客户端或服务端会定时发一个很小的数据包（Ping），另一方回复（Pong），以此证明“我还活着，别断我网”。



## 现实应用



> 如果部署了多台后端服务器（集群），WebSocket 会出什么问题？



在苍穹外卖单体版里没问题，但如果部署了两台 Tomcat：

- 商家 A 连上了 **Tomcat 1**。
- 用户 B 的下单请求打到了 **Tomcat 2**。
- Tomcat 2 支付成功，调用 `sendToAllClient`。**但是 Tomcat 2 的内存 Map 里没有商家 A 的 Session**
- **结果**：商家 A 收不到提醒。
- **解决方案**：引入 **Redis 发布订阅 (Pub/Sub)** 或 **消息队列 (RabbitMQ)**。Tomcat 2 收到订单 -> 发消息给 Redis -> 所有 Tomcat 监听 Redis -> Tomcat 1 收到消息 -> 推送给商家 A。
