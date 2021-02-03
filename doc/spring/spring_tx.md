# 在context项目导入jar包

spring-context.gradle文件中添加一下代码：

```
// 依赖jar包
compile("mysql:mysql-connector-java:8.0.21")
compile("com.alibaba:druid:1.1.23")
```

# JDBC以及Mybatis配置xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	   xmlns:aop="http://www.springframework.org/schema/aop"
	   xmlns:tx="http://www.springframework.org/schema/tx"
	   xmlns:context="http://www.springframework.org/schema/context"
	   xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
	    http://www.springframework.org/schema/aop https://www.springframework.org/schema/aop/spring-aop.xsd
       http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
       http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd">

	<tx:annotation-driven transaction-manager="transactionManager"/>

	<context:property-placeholder location="properties/dataSource.properties"></context:property-placeholder>

   <!--	数据源-->
	<bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
		<property name="url" value="${url}"/>
		<property name="username" value="root"/>
		<property name="password" value="1111"/>
		<property name="driverClassName" value="com.mysql.cj.jdbc.Driver"/>
	</bean>


    <!--	事务管理器 -->
	<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
		<property name="dataSource" ref="dataSource"/>
	</bean>

<!--	sql session-->
	<bean class="org.mybatis.spring.SqlSessionFactoryBean">
		<property name="dataSource" ref="dataSource"/>
		<property name="mapperLocations" value="classpath*:mappers/*Mapper.xml"/>
	</bean>

<!--	mapper扫描配置-->
	<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
		<property name="basePackage" value="test.mjf.mapper"/>
	</bean>

</beans>
```

# tx命名空间处理器

## AnnotationDrivenBeanDefinitionParser

```java
public BeanDefinition parse(Element element, ParserContext parserContext) {
   registerTransactionalEventListenerFactory(parserContext);
   String mode = element.getAttribute("mode");
   if ("aspectj".equals(mode)) {
      // mode="aspectj"
      registerTransactionAspect(element, parserContext);
      if (ClassUtils.isPresent("javax.transaction.Transactional", getClass().getClassLoader())) {
         registerJtaTransactionAspect(element, parserContext);
      }
   }
   else {
      // mode="proxy"
      AopAutoProxyConfigurer.configureAutoProxyCreator(element, parserContext);
   }
   return null;
}

	private static class AopAutoProxyConfigurer {

		public static void configureAutoProxyCreator(Element element, ParserContext parserContext) {
			AopNamespaceUtils.registerAutoProxyCreatorIfNecessary(parserContext, element);

			String txAdvisorBeanName = TransactionManagementConfigUtils.TRANSACTION_ADVISOR_BEAN_NAME;
			if (!parserContext.getRegistry().containsBeanDefinition(txAdvisorBeanName)) {
				Object eleSource = parserContext.extractSource(element);

				// 创建 TransactionAttributeSource bean.
				RootBeanDefinition sourceDef = new RootBeanDefinition(
						"org.springframework.transaction.annotation.AnnotationTransactionAttributeSource");
				sourceDef.setSource(eleSource);
				sourceDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				String sourceName = parserContext.getReaderContext().registerWithGeneratedName(sourceDef);

				//创建 TransactionInterceptor definition.
				RootBeanDefinition interceptorDef = new RootBeanDefinition(TransactionInterceptor.class);
				interceptorDef.setSource(eleSource);
				interceptorDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				registerTransactionManager(element, interceptorDef);
				// 添加属性
				interceptorDef.getPropertyValues().add("transactionAttributeSource", new RuntimeBeanReference(sourceName));
				String interceptorName = parserContext.getReaderContext().registerWithGeneratedName(interceptorDef);

				// 创建 BeanFactoryTransactionAttributeSourceAdvisor definition.
				RootBeanDefinition advisorDef = new RootBeanDefinition(BeanFactoryTransactionAttributeSourceAdvisor.class);
				advisorDef.setSource(eleSource);
				advisorDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				// 添加属性:transactionAttributeSource
				advisorDef.getPropertyValues().add("transactionAttributeSource", new RuntimeBeanReference(sourceName));
				// 添加属性:adviceBeanName
				advisorDef.getPropertyValues().add("adviceBeanName", interceptorName);
				if (element.hasAttribute("order")) {
					advisorDef.getPropertyValues().add("order", element.getAttribute("order"));
				}
				parserContext.getRegistry().registerBeanDefinition(txAdvisorBeanName, advisorDef);

				CompositeComponentDefinition compositeDef = new CompositeComponentDefinition(element.getTagName(), eleSource);
				compositeDef.addNestedComponent(new BeanComponentDefinition(sourceDef, sourceName));
				compositeDef.addNestedComponent(new BeanComponentDefinition(interceptorDef, interceptorName));
				compositeDef.addNestedComponent(new BeanComponentDefinition(advisorDef, txAdvisorBeanName));
				parserContext.registerComponent(compositeDef);
			}
		}
	}
```



# BeanFactoryTransactionAttributeSourceAdvisor什么时候被获取到的

```java
AnnotationAwareAspectJAutoProxyCreator.class

@Override
protected List<Advisor> findCandidateAdvisors() {
   // 从spring容器中获取bean class为advisor的bean，就会获取到BeanFactoryTransactionAttributeSourceAdvisor
   List<Advisor> advisors = super.findCandidateAdvisors();
   // 从spring容器中筛选带有@Aspect的bean
   if (this.aspectJAdvisorsBuilder != null) {
      advisors.addAll(this.aspectJAdvisorsBuilder.buildAspectJAdvisors());
   }
   return advisors;
}
```





# 几个有关事务的实体类

## TransactionAttribute

@Transactional注解的各个属性的封装

![image-20210203151829803](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203151829803.png)

## TransactionStatus

## TransactionDefinition

## TransactionInfo

封装了transactionManager，transactionAttribute，joinpointIdentification，transactionStatus

## DataSourceTransactionObject



# 事务管理器

## 抽象类AbstractPlatformTransactionManager

实现了PlatformTransactionManager接口

![image-20210203114600898](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203114600898.png)

### commit方法

```java
	/**
	 * 提交事务。如果标记为已回滚,请执行回滚。
	 *
	 * 如果不是新的事务，则忽略提交。如果前一个事务已经被挂起以便创建一个新的事务，则在提交新的事务后
	 * 恢复上一个事务。
	 *
	 * 不论是正常情况还是抛出异常，都必须完成事务并且进行清理，在这种情况下，不应该进行回滚。
	 *
	 * 如果此方法引发了TransactionException以外的其他异常，则某些提交前错误将导致提交尝试失败。
	 * 例如，一个O / R映射工具可能已经尝试在提交之前立即刷新对数据库的更改，结果DataAccessException导致事务失败
	 * 在这种情况下，原始异常将传播到此commit方法的调用方。
	 */
public final void commit(TransactionStatus status) throws TransactionException {
   if (status.isCompleted()) {
      throw new IllegalTransactionStateException(
            "Transaction is already completed - do not call commit or rollback more than once per transaction");
   }

   DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
   if (defStatus.isLocalRollbackOnly()) {
      if (defStatus.isDebug()) {
         logger.debug("Transactional code has requested rollback");
      }
      processRollback(defStatus, false);
      return;
   }

   if (!shouldCommitOnGlobalRollbackOnly() && defStatus.isGlobalRollbackOnly()) {
      if (defStatus.isDebug()) {
         logger.debug("Global transaction is marked as rollback-only but transactional code requested commit");
      }
      processRollback(defStatus, true);
      return;
   }

   processCommit(defStatus);
}
```

### 获取事务

```java
public final TransactionStatus getTransaction(@Nullable TransactionDefinition definition)
      throws TransactionException {

   // Use defaults if no transaction definition given.
   TransactionDefinition def = (definition != null ? definition : TransactionDefinition.withDefaults());

   // 调用子类的方法
   Object transaction = doGetTransaction();
   boolean debugEnabled = logger.isDebugEnabled();

   // 如果存在事务(transaction中已经存在connection对象并且事务是激活状态)
   if (isExistingTransaction(transaction)) {
      // Existing transaction found -> check propagation behavior to find out how to behave.
      return handleExistingTransaction(def, transaction, debugEnabled);
   }

   // Check definition settings for new transaction.
   if (def.getTimeout() < TransactionDefinition.TIMEOUT_DEFAULT) {
      throw new InvalidTimeoutException("Invalid transaction timeout", def.getTimeout());
   }

   // No existing transaction found -> check propagation behavior to find out how to proceed.
   if (def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_MANDATORY) {
      throw new IllegalTransactionStateException(
            "No existing transaction found for transaction marked with propagation 'mandatory'");
   }
   // 传播特性为REQUIRED，REQUIRES_NEW，NESTED
   else if (def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRED ||
         def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRES_NEW ||
         def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NESTED) {
      // 挂起事务，因为当前并不存在事务，所以传的参数为null
      SuspendedResourcesHolder suspendedResources = suspend(null);
      if (debugEnabled) {
         logger.debug("Creating new transaction with name [" + def.getName() + "]: " + def);
      }
      try {
         // 开启事务
         return startTransaction(def, transaction, debugEnabled, suspendedResources);
      }
      catch (RuntimeException | Error ex) {
         resume(null, suspendedResources);
         throw ex;
      }
   }
   else {
      // Create "empty" transaction: no actual transaction, but potentially synchronization.
      if (def.getIsolationLevel() != TransactionDefinition.ISOLATION_DEFAULT && logger.isWarnEnabled()) {
         logger.warn("Custom isolation level specified but no actual transaction initiated; " +
               "isolation level will effectively be ignored: " + def);
      }
      boolean newSynchronization = (getTransactionSynchronization() == SYNCHRONIZATION_ALWAYS);
      return prepareTransactionStatus(def, null, true, newSynchronization, debugEnabled, null);
   }
}
```

### 开启事务

```java
private TransactionStatus startTransaction(TransactionDefinition definition, Object transaction,
      boolean debugEnabled, @Nullable SuspendedResourcesHolder suspendedResources) {

   boolean newSynchronization = (getTransactionSynchronization() != SYNCHRONIZATION_NEVER);
   DefaultTransactionStatus status = newTransactionStatus(
         definition, transaction, true, newSynchronization, debugEnabled, suspendedResources);
    // 调用子类的方法
   doBegin(transaction, definition);
   prepareSynchronization(status, definition);
   return status;
}
```

## DataSourceTransactionManager

### 获取事务

```java
@Override
protected Object doGetTransaction() {
   DataSourceTransactionObject txObject = new DataSourceTransactionObject();
   txObject.setSavepointAllowed(isNestedTransactionAllowed());
   ConnectionHolder conHolder =
         (ConnectionHolder) TransactionSynchronizationManager.getResource(obtainDataSource());
   txObject.setConnectionHolder(conHolder, false);
   return txObject;
}
```

### 是否存在事务

```java
@Override
protected boolean isExistingTransaction(Object transaction) {
   DataSourceTransactionObject txObject = (DataSourceTransactionObject) transaction;
   return (txObject.hasConnectionHolder() && txObject.getConnectionHolder().isTransactionActive());
}
```



# 事务切面

## TransactionInterceptor

事务的拦截器，在执行目标方法的时候会对其进行拦截。

### 类图

![image-20210203114147042](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203114147042.png)

## createTransactionIfNecessary



# 事务传播特性

## PROPAGATION_SUPPORTS

## PROPAGATION_REQUIRED

## PROPAGATION_REQUIRES_NEW

## PROPAGATION_NESTED

## PROPAGATION_MANDATORY

# 隔离级别

## Read Uncommitted

## Read Committed

## Repeatable Read（可重读）

## Serializable（可串行化



# 注意

1、如果定义了多个切面，一定要注意，是否有的通知把异常给捕获了，但是并没有抛出，那么这时候事务就不会生效

2、如果要使事务生效，捕获异常之后，一定要抛出，事务回滚是根据异常来回滚的，spring事务捕获到异常之后才会回滚。

