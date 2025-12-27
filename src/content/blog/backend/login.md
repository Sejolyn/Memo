---
title: 短信登陆
description: '使用Redis实现用户短信登陆。'
publishDate: 2025-12-22 22:55:58
tags:
  - backend
---



![短信登陆流程图](images/login.png)




---



## 1 技术选型



> 为什么使用 Redis 来代替 Session？



1. **集群挑战**

  - Session 数据存储在 **JVM 的堆内存**中，在单机环境下没问题。但是在生产环境的**集群部署**（多台服务器跑同一个项目）下，负载均衡器（比如 Nginx）会将请求分发到不同的服务器。
  - 如果用户在服务器 A 登陆，Session 存在 A 的内存里。该用户的下一次请求被分发到了服务器 B，B 内存中没有其 Session，那么就会认证失败
  - Redis 是**分布式缓存系统**，所有的服务器可以去同一个 Redis 集群读写数据

2. **数据可靠性**

  - Session 的生命周期**依赖于进程**，一旦后端程序崩溃或重启，那么所有用户的登录状态都会消失，那么用户的体验感极差
  - Redis 虽然也是基于内存，但是其运行在独立的进程中

  

> 为什么使用 Hash 存储用户信息，而不是 String？



1. **内存效率**：Redis 的 Hash 结构在字段较少时使用 `ziplist` 存储，内存占用极其紧凑。
2. **操作粒度**：可以利用 `HSET` 或 `HGET` 针对单个属性（如更新昵称）进行操作，而 String 则需要进行全序列化和反序列化

---

## 2 系统设计与架构

### 2.1 Redis 数据模型设计

- **验证码**:    
    - **结构**: `String`
    - **Key**: `login:code:{phone}`
    - **TTL**: 2 分钟 
- **用户信息**:
    - **结构**: `Hash`
    - **Key**: `login:token:{token}` (Token 采用随机 UUID)
    - **TTL**: 30 分钟 

### 2.2 核心业务流程

1. **发送验证码**：校验手机号 -> 生成验证码 -> 存入 Redis -> 发送短信。
2. **登录/注册**：校验验证码 -> 数据库查/增用户 -> **生成随机 Token** -> 脱敏处理 (UserDTO) -> 存入 Redis 并返回 Token。

---

## 3 核心代码实现



实现时要注意 `StringRedisTemplate`对值类型的要求。

```java
// 核心逻辑：用户信息序列化与存储
public String login(LoginFormDTO loginForm) {
    // ... 校验逻辑 ...
    
    // 1. 生成唯一凭证（Token）
    String token = UUID.randomUUID().toString(true);
    
    // 2. 对象脱敏与类型转换
    UserDTO userDTO = BeanUtil.copyProperties(user, UserDTO.class);
    
    // 3. 将 Bean 转为 Map，并强制将所有字段转为 String
    Map<String, Object> userMap = BeanUtil.beanToMap(userDTO, new HashMap<>(),
        CopyOptions.create()
            .setIgnoreNullValue(true)
            .setFieldValueEditor((fieldName, fieldValue) -> {
                if (fieldValue == null) return null;
                return fieldValue.toString();
            }));
            
    // 4. 写入 Redis 并设置有效期
    String tokenKey = LOGIN_USER_KEY + token;
    stringRedisTemplate.opsForHash().putAll(tokenKey, userMap);
    stringRedisTemplate.expire(tokenKey, LOGIN_USER_TTL, TimeUnit.MINUTES);
    
    return token;
}
```

---

## 4 滚动过期

为了提升用户体验，需要实现 **“滚动过期”** 机制：用户在活跃期间，Token 有效期应自动续期，只有长时间无操作才会过期。



### 4.1 单拦截器方案的缺陷



如果仅在 `LoginInterceptor`（登录拦截器）中重置有效期，会存在一个**严重漏洞**：
- 拦截器通常配置为排除**公开路径**（如首页、商铺详情页）。
- 若用户登录后，长时间**只浏览公开页面**，拦截器不会执行，Token 将在 30 分钟后过期，导致用户在进行需要登录的操作时被意外踢出。



### 4.2 解决方案：双拦截器架构



引入两个拦截器，职责分离，解决上述问题：

| **拦截器**                  | **拦截范围**         | **核心职责**                                                 | **执行顺序** |
| :-------------------------- | :------------------- | :----------------------------------------------------------- | :----------- |
| **RefreshTokenInterceptor** | **所有请求** (`/**`) | 1. 尝试获取请求头中的 Token。  <br>2. 若 Token 有效，则**刷新其在 Redis 中的有效期**。  <br>3. 将用户信息存入 `ThreadLocal`，供后续流程使用。  <br>4. 无论是否成功，**均放行**。 | 第一         |
| **LoginInterceptor**        | **需要登录的路径**   | 1. 检查 `ThreadLocal` 中是否存在用户信息。  <br>2. 若存在，说明已登录，放行。  <br>3. 若不存在，则拦截并返回“未登录”状态码（401）。 | 第二         |



拦截器流程：

![拦截器流程图](images/interceptor.png)



`RefreshTokenInterceptor` 核心逻辑：

```java
public boolean preHandle(HttpServletRequest request, ...) {
    // 1. 获取请求头中的 token
    String token = request.getHeader("authorization");
    if (StrUtil.isBlank(token)) {
        // 无 token，直接放行，由 LoginInterceptor 决定是否拦截
        return true;
    }
    
    // 2. 基于 token 从 Redis 获取用户信息
    String tokenKey = getTokenCacheKey(token);
    Map<Object, Object> userMap = redisTemplate.opsForHash().entries(tokenKey);
    if (userMap.isEmpty()) {
        // token 无效，直接放行
        return true;
    }
    
    // 3. 将 Hash 数据转换回 UserDTO 对象
    UserDTO userDTO = BeanUtil.fillBeanWithMap(userMap, new UserDTO(), false);
    // 4. 保存用户信息到 ThreadLocal
    UserHolder.saveUser(userDTO);
    // 5. 刷新 token 有效期（实现滚动过期）
    redisTemplate.expire(tokenKey, LOGIN_USER_TTL, TimeUnit.MINUTES);
    return true;
}
```






> [!CAUTION]
>
> 在拦截器的 `afterCompletion`方法中，必须调用 `UserHolder.removeUser()`。这是因为 Tomcat 线程池会复用线程，如果不手动清理，会导致 ThreadLocal 中的数据被错误带入下一个请求，并造成内存泄漏。
