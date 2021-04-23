# 扫描mapper

## 流程图

![image-20210423220722136](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210423220722136.png)

## ClassPathMapperScanner

ClassPathMapperScanner扫描指定包下的mapper。



将BeanDefination的class设置为了MapperFactoryBean

```java
private void processBeanDefinitions(Set<BeanDefinitionHolder> beanDefinitions) {
  GenericBeanDefinition definition;
  for (BeanDefinitionHolder holder : beanDefinitions) {
    definition = (GenericBeanDefinition) holder.getBeanDefinition();
    String beanClassName = definition.getBeanClassName();
    LOGGER.debug(() -> "Creating MapperFactoryBean with name '" + holder.getBeanName() + "' and '" + beanClassName
        + "' mapperInterface");

    // the mapper interface is the original class of the bean
    // but, the actual class of the bean is MapperFactoryBean
      // 设置构造函数的参数为原来的BeanClass名称
    definition.getConstructorArgumentValues().addGenericArgumentValue(beanClassName); // issue #59
    definition.setBeanClass(this.mapperFactoryBeanClass);

    definition.getPropertyValues().add("addToConfig", this.addToConfig);

    boolean explicitFactoryUsed = false;
    if (StringUtils.hasText(this.sqlSessionFactoryBeanName)) {
      definition.getPropertyValues().add("sqlSessionFactory",
          new RuntimeBeanReference(this.sqlSessionFactoryBeanName));
      explicitFactoryUsed = true;
    } else if (this.sqlSessionFactory != null) {
      definition.getPropertyValues().add("sqlSessionFactory", this.sqlSessionFactory);
      explicitFactoryUsed = true;
    }

    if (StringUtils.hasText(this.sqlSessionTemplateBeanName)) {
      if (explicitFactoryUsed) {
        LOGGER.warn(
            () -> "Cannot use both: sqlSessionTemplate and sqlSessionFactory together. sqlSessionFactory is ignored.");
      }
      definition.getPropertyValues().add("sqlSessionTemplate",
          new RuntimeBeanReference(this.sqlSessionTemplateBeanName));
      explicitFactoryUsed = true;
    } else if (this.sqlSessionTemplate != null) {
      if (explicitFactoryUsed) {
        LOGGER.warn(
            () -> "Cannot use both: sqlSessionTemplate and sqlSessionFactory together. sqlSessionFactory is ignored.");
      }
      definition.getPropertyValues().add("sqlSessionTemplate", this.sqlSessionTemplate);
      explicitFactoryUsed = true;
    }

    if (!explicitFactoryUsed) {
      LOGGER.debug(() -> "Enabling autowire by type for MapperFactoryBean with name '" + holder.getBeanName() + "'.");
      definition.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
    }
    definition.setLazyInit(lazyInitialization);
  }
}
```

## MapperFactoryBean

实现了FactoryBean接口，那么实例化后的对象是从getObject方法获取的。

![image-20210422230010711](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210422230010711.png)

### 设置SqlSessionFactory和SqlSessionTemplate

spring在创建MapperFactoryBean对象之后，会设置SqlSessionFactory和SqlSessionTemplate属性

# SqlSessionFactory

是全局的对象。实例化的是DefaultSqlSessionFactory对象。

是由SqlSessionFactoryBean创建的。

## SqlSessionFactoryBean

实现了FactoryBean接口，spring创建的对象是由getObject返回的。

![image-20210423214125596](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210423214125596.png)

# MapperRegistry

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
  final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
  if (mapperProxyFactory == null) {
    throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
  }
  try {
      // 生成代理类
    return mapperProxyFactory.newInstance(sqlSession);
  } catch (Exception e) {
    throw new BindingException("Error getting mapper instance. Cause: " + e, e);
  }
}
```

# MapperProxyFactory

生成MapperProxy的工厂类。

```java
public T newInstance(SqlSession sqlSession) {
  final MapperProxy<T> mapperProxy = new MapperProxy<>(sqlSession, mapperInterface, methodCache);
    // 生成代理类
  return newInstance(mapperProxy);
}
```

# MapperProxy

实现了InvocationHandler，那么在执行mapper方法的时候，会执行到MapperProxy的invoke方法。

![image-20210423220436613](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210423220436613.png)



