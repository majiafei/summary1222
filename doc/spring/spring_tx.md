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

事务的所有的状态信息

### DefaultTransactionStatus(实现类一)

```java
/**
 * 事务对象
 */
@Nullable
private final Object transaction;

/**
 * 是否是新的事务(connection是新获取的)
 */
private final boolean newTransaction;

private final boolean newSynchronization;

private final boolean readOnly;

private final boolean debug;

/**
 * 挂起资源
 */
@Nullable
private final Object suspendedResources;
```

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

### 处理已经存在的事务

```java
/**
 * Create a TransactionStatus for an existing transaction.
 */
private TransactionStatus handleExistingTransaction(
      TransactionDefinition definition, Object transaction, boolean debugEnabled)
      throws TransactionException {

   // 从不使用事务
   if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NEVER) {
      throw new IllegalTransactionStateException(
            "Existing transaction found for transaction marked with propagation 'never'");
   }

   // 当前方法不支持事务，将上一个事务挂起
   if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NOT_SUPPORTED) {
      if (debugEnabled) {
         logger.debug("Suspending current transaction");
      }
      // connection对象，从当前线程获取的
      Object suspendedResources = suspend(transaction);
      boolean newSynchronization = (getTransactionSynchronization() == SYNCHRONIZATION_ALWAYS);
      return prepareTransactionStatus(
            definition, null, false, newSynchronization, debugEnabled, suspendedResources);
   }

   // 新建一个事务，挂起当前的事务
   if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRES_NEW) {
      if (debugEnabled) {
         logger.debug("Suspending current transaction, creating new transaction with name [" +
               definition.getName() + "]");
      }
      // 挂起事务
      SuspendedResourcesHolder suspendedResources = suspend(transaction);
      try {
         return startTransaction(definition, transaction, debugEnabled, suspendedResources);
      }
      catch (RuntimeException | Error beginEx) {
         resumeAfterBeginException(transaction, suspendedResources, beginEx);
         throw beginEx;
      }
   }

   // 嵌套事务，设置保存点
   if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NESTED) {
      if (!isNestedTransactionAllowed()) {
         throw new NestedTransactionNotSupportedException(
               "Transaction manager does not allow nested transactions by default - " +
               "specify 'nestedTransactionAllowed' property with value 'true'");
      }
      if (debugEnabled) {
         logger.debug("Creating nested transaction with name [" + definition.getName() + "]");
      }
      if (useSavepointForNestedTransaction()) {
         // Create savepoint within existing Spring-managed transaction,
         // through the SavepointManager API implemented by TransactionStatus.
         // Usually uses JDBC 3.0 savepoints. Never activates Spring synchronization.
         DefaultTransactionStatus status =
               prepareTransactionStatus(definition, transaction, false, false, debugEnabled, null);
         status.createAndHoldSavepoint();
         return status;
      }
      else {
         // Nested transaction through nested begin and commit/rollback calls.
         // Usually only for JTA: Spring synchronization might get activated here
         // in case of a pre-existing JTA transaction.
         return startTransaction(definition, transaction, debugEnabled, null);
      }
   }

   // Assumably PROPAGATION_SUPPORTS or PROPAGATION_REQUIRED.
   if (debugEnabled) {
      logger.debug("Participating in existing transaction");
   }
   if (isValidateExistingTransaction()) {
      if (definition.getIsolationLevel() != TransactionDefinition.ISOLATION_DEFAULT) {
         Integer currentIsolationLevel = TransactionSynchronizationManager.getCurrentTransactionIsolationLevel();
         if (currentIsolationLevel == null || currentIsolationLevel != definition.getIsolationLevel()) {
            Constants isoConstants = DefaultTransactionDefinition.constants;
            throw new IllegalTransactionStateException("Participating transaction with definition [" +
                  definition + "] specifies isolation level which is incompatible with existing transaction: " +
                  (currentIsolationLevel != null ?
                        isoConstants.toCode(currentIsolationLevel, DefaultTransactionDefinition.PREFIX_ISOLATION) :
                        "(unknown)"));
         }
      }
      if (!definition.isReadOnly()) {
         if (TransactionSynchronizationManager.isCurrentTransactionReadOnly()) {
            throw new IllegalTransactionStateException("Participating transaction with definition [" +
                  definition + "] is not marked as read-only but existing transaction is");
         }
      }
   }
   boolean newSynchronization = (getTransactionSynchronization() != SYNCHRONIZATION_NEVER);
   // required类型的传播特性，和之前存在的事务是同一个事务，即使用的是同一个connection
   return prepareTransactionStatus(definition, transaction, false, newSynchronization, debugEnabled, null);
}
```

### 回滚

```java
/**
 * This implementation of rollback handles participating in existing
 * transactions. Delegates to {@code doRollback} and
 * {@code doSetRollbackOnly}.
 * @see #doRollback
 * @see #doSetRollbackOnly
 */
@Override
public final void rollback(TransactionStatus status) throws TransactionException {
    // 事务之后，不允许再次回滚
   if (status.isCompleted()) {
      throw new IllegalTransactionStateException(
            "Transaction is already completed - do not call commit or rollback more than once per transaction");
   }

   DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
   processRollback(defStatus, false);
}

/**
 * Process an actual rollback.
 * The completed flag has already been checked.
 * @param status object representing the transaction
 * @throws TransactionException in case of rollback failure
 */
private void processRollback(DefaultTransactionStatus status, boolean unexpected) {
   try {
      boolean unexpectedRollback = unexpected;

      try {
         triggerBeforeCompletion(status);

         if (status.hasSavepoint()) {
            if (status.isDebug()) {
               logger.debug("Rolling back transaction to savepoint");
            }
            // 回滚到保存点的位置
            status.rollbackToHeldSavepoint();
         }
         else if (status.isNewTransaction()) {
            if (status.isDebug()) {
               logger.debug("Initiating transaction rollback");
            }
            // 直接回滚
            doRollback(status);
         }
         else {
            // Participating in larger transaction
            if (status.hasTransaction()) {
               if (status.isLocalRollbackOnly() || isGlobalRollbackOnParticipationFailure()) {
                  if (status.isDebug()) {
                     logger.debug("Participating transaction failed - marking existing transaction as rollback-only");
                  }
                  doSetRollbackOnly(status);
               }
               else {
                   // 没有事务
                  if (status.isDebug()) {
                     logger.debug("Participating transaction failed - letting transaction originator decide on rollback");
                  }
               }
            }
            else {
               logger.debug("Should roll back transaction but cannot - no transaction available");
            }
            // Unexpected rollback only matters here if we're asked to fail early
            if (!isFailEarlyOnGlobalRollbackOnly()) {
               unexpectedRollback = false;
            }
         }
      }
      catch (RuntimeException | Error ex) {
         triggerAfterCompletion(status, TransactionSynchronization.STATUS_UNKNOWN);
         throw ex;
      }

      triggerAfterCompletion(status, TransactionSynchronization.STATUS_ROLLED_BACK);

      // Raise UnexpectedRollbackException if we had a global rollback-only marker
      if (unexpectedRollback) {
         throw new UnexpectedRollbackException(
               "Transaction rolled back because it has been marked as rollback-only");
      }
   }
   finally {
      cleanupAfterCompletion(status);
   }
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

### 开启事务

```java
protected void doBegin(Object transaction, TransactionDefinition definition) {
   DataSourceTransactionObject txObject = (DataSourceTransactionObject) transaction;
   Connection con = null;

   try {
      // 没有connection对象或者事务没有被激活
      if (!txObject.hasConnectionHolder() ||
            txObject.getConnectionHolder().isSynchronizedWithTransaction()) {
         // 获取connection从数据源中
         Connection newCon = obtainDataSource().getConnection();
         if (logger.isDebugEnabled()) {
            logger.debug("Acquired Connection [" + newCon + "] for JDBC transaction");
         }
         // ConnectionHolder封装Connection
         txObject.setConnectionHolder(new ConnectionHolder(newCon), true);
      }

      txObject.getConnectionHolder().setSynchronizedWithTransaction(true);
      con = txObject.getConnectionHolder().getConnection();

      // 隔离级别
      Integer previousIsolationLevel = DataSourceUtils.prepareConnectionForTransaction(con, definition);
      txObject.setPreviousIsolationLevel(previousIsolationLevel);
      txObject.setReadOnly(definition.isReadOnly());

      // Switch to manual commit if necessary. This is very expensive in some JDBC drivers,
      // so we don't want to do it unnecessarily (for example if we've explicitly
      // configured the connection pool to set it already).
      if (con.getAutoCommit()) {
         txObject.setMustRestoreAutoCommit(true);
         if (logger.isDebugEnabled()) {
            logger.debug("Switching JDBC Connection [" + con + "] to manual commit");
         }
          
          
          
          
         // 将事务设置为非自动提交****************
         con.setAutoCommit(false);
      }

      prepareTransactionalConnection(con, definition);
      // 将事务激活
      txObject.getConnectionHolder().setTransactionActive(true);

      // 超时时间
      int timeout = determineTimeout(definition);
      if (timeout != TransactionDefinition.TIMEOUT_DEFAULT) {
         txObject.getConnectionHolder().setTimeoutInSeconds(timeout);
      }

      // Bind the connection holder to the thread.
      // 将connection绑定到当前线程，ThreadLocal的value是一个map，key为数据源，value为connection
      // 因为一个项目中可能存在多个数据源
      if (txObject.isNewConnectionHolder()) {
         TransactionSynchronizationManager.bindResource(obtainDataSource(), txObject.getConnectionHolder());
      }
   }

   catch (Throwable ex) {
      if (txObject.isNewConnectionHolder()) {
         DataSourceUtils.releaseConnection(con, obtainDataSource());
         txObject.setConnectionHolder(null, false);
      }
      throw new CannotCreateTransactionException("Could not open JDBC Connection for transaction", ex);
   }
}
```

### 提交事务

```java
@Override
protected void doCommit(DefaultTransactionStatus status) {
   DataSourceTransactionObject txObject = (DataSourceTransactionObject) status.getTransaction();
   Connection con = txObject.getConnectionHolder().getConnection();
   if (status.isDebug()) {
      logger.debug("Committing JDBC transaction on Connection [" + con + "]");
   }
   try {
      con.commit();
   }
   catch (SQLException ex) {
      throw new TransactionSystemException("Could not commit JDBC transaction", ex);
   }
}
```

### 清除事务信息

```java
	@Override
	protected void doCleanupAfterCompletion(Object transaction) {
		DataSourceTransactionObject txObject = (DataSourceTransactionObject) transaction;

		// Remove the connection holder from the thread, if exposed.
		if (txObject.isNewConnectionHolder()) {
			// 将事务与当前事务解绑
			TransactionSynchronizationManager.unbindResource(obtainDataSource());
		}

		// Reset connection.
		Connection con = txObject.getConnectionHolder().getConnection();
		try {
			if (txObject.isMustRestoreAutoCommit()) {
				// 设置为自动提交，在开启事务的事务设置为false，事务完成之后恢复
				con.setAutoCommit(true);
			}
			DataSourceUtils.resetConnectionAfterTransaction(
					con, txObject.getPreviousIsolationLevel(), txObject.isReadOnly());
		}
		catch (Throwable ex) {
			logger.debug("Could not reset JDBC Connection after transaction", ex);
		}

		if (txObject.isNewConnectionHolder()) {
			if (logger.isDebugEnabled()) {
				logger.debug("Releasing JDBC Connection [" + con + "] after transaction");
			}
			// 释放连接
			DataSourceUtils.releaseConnection(con, this.dataSource);
		}

		txObject.getConnectionHolder().clear();
	}
```

# 事务切面

## TransactionInterceptor

事务的拦截器，在执行目标方法的时候会对其进行拦截。

### 类图

![image-20210203114147042](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203114147042.png)

## createTransactionIfNecessary

```java
/**
 * General delegate for around-advice-based subclasses, delegating to several other template
 * methods on this class. Able to handle {@link CallbackPreferringPlatformTransactionManager}
 * as well as regular {@link PlatformTransactionManager} implementations and
 * {@link ReactiveTransactionManager} implementations for reactive return types.
 * @param method the Method being invoked
 * @param targetClass the target class that we're invoking the method on
 * @param invocation the callback to use for proceeding with the target invocation
 * @return the return value of the method, if any
 * @throws Throwable propagated from the target invocation
 */
@Nullable
protected Object invokeWithinTransaction(Method method, @Nullable Class<?> targetClass,
      final InvocationCallback invocation) throws Throwable {

   // If the transaction attribute is null, the method is non-transactional.
   TransactionAttributeSource tas = getTransactionAttributeSource();
   final TransactionAttribute txAttr = (tas != null ? tas.getTransactionAttribute(method, targetClass) : null);
   // 获取事务管理器
   final TransactionManager tm = determineTransactionManager(txAttr);

   if (this.reactiveAdapterRegistry != null && tm instanceof ReactiveTransactionManager) {
      ReactiveTransactionSupport txSupport = this.transactionSupportCache.computeIfAbsent(method, key -> {
         if (KotlinDetector.isKotlinType(method.getDeclaringClass()) && KotlinDelegate.isSuspend(method)) {
            throw new TransactionUsageException(
                  "Unsupported annotated transaction on suspending function detected: " + method +
                  ". Use TransactionalOperator.transactional extensions instead.");
         }
         ReactiveAdapter adapter = this.reactiveAdapterRegistry.getAdapter(method.getReturnType());
         if (adapter == null) {
            throw new IllegalStateException("Cannot apply reactive transaction to non-reactive return type: " +
                  method.getReturnType());
         }
         return new ReactiveTransactionSupport(adapter);
      });
      return txSupport.invokeWithinTransaction(
            method, targetClass, invocation, txAttr, (ReactiveTransactionManager) tm);
   }

   PlatformTransactionManager ptm = asPlatformTransactionManager(tm);
   final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);

   if (txAttr == null || !(ptm instanceof CallbackPreferringPlatformTransactionManager)) {
      // Standard transaction demarcation with getTransaction and commit/rollback calls.
      TransactionInfo txInfo = createTransactionIfNecessary(ptm, txAttr, joinpointIdentification);

      Object retVal;
      try {
         // This is an around advice: Invoke the next interceptor in the chain.
         // This will normally result in a target object being invoked.
         // 这是一个环绕通知:接下来去调用下一个intercept
         retVal = invocation.proceedWithInvocation();
      }
      catch (Throwable ex) {
         // 抛出异常后完成事务(可能回滚或者提交)
         completeTransactionAfterThrowing(txInfo, ex);
         throw ex;
      }
      finally {
         // 清除事务
         cleanupTransactionInfo(txInfo);
      }

      if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
         // Set rollback-only in case of Vavr failure matching our rollback rules...
         TransactionStatus status = txInfo.getTransactionStatus();
         if (status != null && txAttr != null) {
            retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
         }
      }

      // 提交事务
      commitTransactionAfterReturning(txInfo);
      return retVal;
   }

   else {
      Object result;
      final ThrowableHolder throwableHolder = new ThrowableHolder();

      // It's a CallbackPreferringPlatformTransactionManager: pass a TransactionCallback in.
      try {
         result = ((CallbackPreferringPlatformTransactionManager) ptm).execute(txAttr, status -> {
            TransactionInfo txInfo = prepareTransactionInfo(ptm, txAttr, joinpointIdentification, status);
            try {
               Object retVal = invocation.proceedWithInvocation();
               if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
                  // Set rollback-only in case of Vavr failure matching our rollback rules...
                  retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
               }
               return retVal;
            }
            catch (Throwable ex) {
               if (txAttr.rollbackOn(ex)) {
                  // A RuntimeException: will lead to a rollback.
                  if (ex instanceof RuntimeException) {
                     throw (RuntimeException) ex;
                  }
                  else {
                     throw new ThrowableHolderException(ex);
                  }
               }
               else {
                  // A normal return value: will lead to a commit.
                  throwableHolder.throwable = ex;
                  return null;
               }
            }
            finally {
               cleanupTransactionInfo(txInfo);
            }
         });
      }
      catch (ThrowableHolderException ex) {
         throw ex.getCause();
      }
      catch (TransactionSystemException ex2) {
         if (throwableHolder.throwable != null) {
            logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
            ex2.initApplicationException(throwableHolder.throwable);
         }
         throw ex2;
      }
      catch (Throwable ex2) {
         if (throwableHolder.throwable != null) {
            logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
         }
         throw ex2;
      }

      // Check result state: It might indicate a Throwable to rethrow.
      if (throwableHolder.throwable != null) {
         throw throwableHolder.throwable;
      }
      return result;
   }
}
```

## 抛出异常后完成事务

```java
/**
 * Handle a throwable, completing the transaction.
 * We may commit or roll back, depending on the configuration.
 * @param txInfo information about the current transaction
 * @param ex throwable encountered
 */
protected void completeTransactionAfterThrowing(@Nullable TransactionInfo txInfo, Throwable ex) {
   if (txInfo != null && txInfo.getTransactionStatus() != null) {
      if (logger.isTraceEnabled()) {
         logger.trace("Completing transaction for [" + txInfo.getJoinpointIdentification() +
               "] after exception: " + ex);
      }
      // ex必须属于事务注解中设置的回滚异常类型或者是error异常
      if (txInfo.transactionAttribute != null && txInfo.transactionAttribute.rollbackOn(ex)) {
         try {
            // 调用事务管理器的回滚
            txInfo.getTransactionManager().rollback(txInfo.getTransactionStatus());
         }
         catch (TransactionSystemException ex2) {
            logger.error("Application exception overridden by rollback exception", ex);
            ex2.initApplicationException(ex);
            throw ex2;
         }
         catch (RuntimeException | Error ex2) {
            logger.error("Application exception overridden by rollback exception", ex);
            throw ex2;
         }
      }
      else {
         // We don't roll back on this exception.
         // Will still roll back if TransactionStatus.isRollbackOnly() is true.
         // 不满足条件的异常就要提交提交事务
         try {
            txInfo.getTransactionManager().commit(txInfo.getTransactionStatus());
         }
         catch (TransactionSystemException ex2) {
            logger.error("Application exception overridden by commit exception", ex);
            ex2.initApplicationException(ex);
            throw ex2;
         }
         catch (RuntimeException | Error ex2) {
            logger.error("Application exception overridden by commit exception", ex);
            throw ex2;
         }
      }
   }
}
```

# 事务传播特性

## PROPAGATION_SUPPORTS

## PROPAGATION_REQUIRED

## PROPAGATION_REQUIRES_NEW

## PROPAGATION_NESTED

## PROPAGATION_MANDATORY

## PROPAGATION_NEVER

## PROPAGATION_NOT_SUPPORTED

# 隔离级别

## Read Uncommitted

## Read Committed

## Repeatable Read（可重读）

## Serializable（可串行化)

# 方法嵌套

## 方法A的传播特性为required，方法B的传播特性为never

```java
@Transactional(rollbackFor = Exception.class)
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);

    // 事务的传播特性为never
   storeService.decrease(order.getCommodityCode(), order.getCount());

   throw new InvalidDataAccessApiUsageException("xxx");
}


方法B
@Transactional(propagation = Propagation.NEVER)
@Override
public void decrease(String commodityCode, Integer num) {
    storeMapper.decrease(commodityCode, num);
}
```

结果：

![image-20210203193512524](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203193512524.png)

## 方法A的传播特性为required，方法B的传播特性为required



执行之前数据库的记录：

![image-20210203193639830](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203193639830.png)

![image-20210203193652429](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203193652429.png)

方法成功执行之后数据库中的记录：

![image-20210203193824028](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203193824028.png)

![image-20210203193840623](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203193840623.png)

代码如下：

```java
@Transactional(rollbackFor = Exception.class)-------
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);

   storeService.decrease(order.getCommodityCode(), order.getCount());
}

	@Transactional(propagation = Propagation.REQUIRED)--------------------
	@Override
	public void decrease(String commodityCode, Integer num) {
		storeMapper.decrease(commodityCode, num);
	}
```





给addOrder方法抛出一个异常

![image-20210203194110921](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203194110921.png)



数据库中的记录：

![image-20210203194133900](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203194133900.png)

![image-20210203194147217](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210203194147217.png)

## 方法A的传播特性为required，方法B的传播特性为required_new

```java
@Transactional(rollbackFor = Exception.class)
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);

   storeService.decrease(order.getCommodityCode(), order.getCount());
   throw new InvalidDataAccessApiUsageException("xxx");
}


	@Transactional(propagation = Propagation.REQUIRES_NEW)
	@Override
	public void decrease(String commodityCode, Integer num) {
		storeMapper.decrease(commodityCode, num);
	}
```

addOrder方法和decrease方法属于不同的事务，当addOrder方法抛出异常的时候，decrease方法是不会回滚的，decrease方法执行完之后，事务就已经提交了，所以只会回滚addOrder方法，decrease不会回滚，这就导致没有生成订单数据，但是库存却减少了。



执行之前：

![image-20210204100810494](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204100810494.png)



![image-20210204101939424](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204101939424.png)





执行后：

![image-20210204102012817](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204102012817.png)

![image-20210204102023586](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204102023586.png)

## 方法A的传播特性为required，方法B的传播特性为NOT_SUPPORTED

```java
@Transactional(rollbackFor = Exception.class)
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);

   storeService.decrease(order.getCommodityCode(), order.getCount());
}

	@Transactional(propagation = Propagation.NOT_SUPPORTED)
	@Override
	public void decrease(String commodityCode, Integer num) {
		storeMapper.decrease(commodityCode, num);
		throw new RuntimeException();
	}
```

addOrder方法有事务，decrease方法没有事务，事务是自动提交的，库存已经修改完事务就提交了，即便后面出现了异常也不会回滚。

在decrease会将异常抛到addOrder方法，所以addOrder会回滚事务。

执行完之后数据库记录如下：

![image-20210204103346144](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204103346144.png)

![image-20210204103408286](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204103408286.png)



## 方法A的传播特性为required，方法B的传播特性为NESTED

```java
@Transactional(rollbackFor = Exception.class)
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);
   try {
      storeService.decrease(order.getCommodityCode(), order.getCount());
   } catch (Exception e) {
      e.printStackTrace();
   }
}

	@Transactional(propagation = Propagation.NESTED)
	@Override
	public void decrease(String commodityCode, Integer num) {
		storeMapper.decrease(commodityCode, num);
		throw new RuntimeException("store is empty");
	}
```

addOrder和decrease属于同一个事务，只不过decrease属于子事务，主事务提交子事务才能提交，当子事务出现异常时会回滚到保存点，主事务提交的时候会将保存点以前的操作进行提交。注意：要将子事务cache一下，否则，主事务也会全部回滚。

![image-20210204105353986](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204105353986.png)

![image-20210204105410532](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204105410532.png)

## 方法A的传播特性传播特性为MANDATORY

```java
@Transactional(propagation = Propagation.MANDATORY)
@Override
public void addOrder(Order order) {
   orderMapper.addOrder(order);
   storeService.decrease(order.getCommodityCode(), order.getCount());
}
```

MANDATORY表示当前必须存在事务，如果没有事务就报错。

![image-20210204111320137](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204111320137.png)

# 注意

1、如果定义了多个切面，一定要注意，是否有的通知把异常给捕获了，但是并没有抛出，那么这时候事务就不会生效

2、如果要使事务生效，捕获异常之后，一定要抛出，事务回滚是根据异常来回滚的，spring事务捕获到异常之后才会回滚。

3、一个方法调用同类的其它方法，被调用的其它方法的事务注解不起作用。

4、注意抛出的异常，默认RuntimeException的异常会回滚。

![image-20210204100137045](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210204100137045.png)

