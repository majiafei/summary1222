# 处理@RequestMapping注解

RequestMappingHandlerMapping专门处理RequestMapping注解的。

## RequestMappingHandlerMapping

### 类图

![image-20210205115029853](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210205115029853.png)



### afterPropertiesSet

在实例化之后会调用这个方法。

```java
@Override
@SuppressWarnings("deprecation")
public void afterPropertiesSet() {
   this.config = new RequestMappingInfo.BuilderConfiguration();
   this.config.setUrlPathHelper(getUrlPathHelper());
   this.config.setPathMatcher(getPathMatcher());
   this.config.setSuffixPatternMatch(useSuffixPatternMatch());
   this.config.setTrailingSlashMatch(useTrailingSlashMatch());
   this.config.setRegisteredSuffixPatternMatch(useRegisteredSuffixPatternMatch());
   this.config.setContentNegotiationManager(getContentNegotiationManager());

   super.afterPropertiesSet();
}
```

### 初始化HandlerMethod

```java
/**
 * Scan beans in the ApplicationContext, detect and register handler methods.
 * @see #getCandidateBeanNames()
 * @see #processCandidateBean
 * @see #handlerMethodsInitialized
 */
protected void initHandlerMethods() {
   for (String beanName : getCandidateBeanNames()) {
      if (!beanName.startsWith(SCOPED_TARGET_NAME_PREFIX)) {
          // 处理没有bean中的方法,带有RequestMapping注解的，将其属性值封装到RequestMappingInfo中。
         processCandidateBean(beanName);
      }
   }
   handlerMethodsInitialized(getHandlerMethods());
}
```

### MappingRegistry

AbstractHandlerMethodMapping的内部类，用来注册url到方法的映射信息的。

# 处理@ResponseBody注解

# 寻找handler

# 查找HandlerAdapter

# DispatcheServlet

## 处理流程

# 参数解析

# 返回值处理

