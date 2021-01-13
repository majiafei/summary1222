# aop生效的位置

在initializeBean方法中调用applyBeanPostProcessorsBeforeInitialization，aop便从这里开始处理aop了。

# 启用aop注解

```xml
<aop:aspectj-autoproxy/>
```

