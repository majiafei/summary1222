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

# 事务传播特性

# 几个有关事务的实体类

## TransactionStatus

## TransactionDefinition

# 注意

1、如果定义了多个切面，一定要注意，是否有的通知把异常给捕获了，但是并没有抛出，那么这时候事务就不会生效

2、如果要使事务生效，捕获异常之后，一定要抛出，事务回滚是根据异常来回滚的，spring事务捕获到异常之后才会回滚。

