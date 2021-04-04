# AbstractApplication与BeanFactory的关系

AbstractApplication继承了BeanFactory，同时又进行了扩展。

![image-20210302213442753](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210302213442753.png)

# Bean标签

## 属性

### id

### name

### scope

### autowire

### abstract

### lazy-init

### autowire-candidate

如果不希望被注入到其他的类中，就设置false

### init-method

### factory-bean和factory-method

factory-bean是一个工厂bean，用来创建对象的，调用factory-method来创建对象。

```java
/**
 * @author mjf
 * @date 2021-03-03-21:14:00
 */
public class FactoryBean {

    public Object createBean() {
        return new User();
    }

}
```

```xml
<bean class="com.spring.mjf.factorybean.FactoryBean" id="factoryBean"></bean>
<bean id="user2" factory-bean="factoryBean" factory-method="createBean"></bean>
```

### primary

优先被注入的，如果一个接口有多个实现类，那么在其中一个bean的配置上加上这个属性，并且设置为true，在另一个类中注入这个类中的时候，会优先装配加primary为true的。

## 内部标签

### lookup-method

一个抽象类定义了个抽象方法，在xml配置的class就是这个抽象类，接下来，又配置了lookup-method属性，名称就为抽象方法，为这个抽象方法找一个 bean实例。

```java
public abstract class ShowSex {

    public void showSex() {
        getPeople().sex();
    }

    public abstract People getPeople();

}


////////////////////////////////
public abstract class People {

    abstract void sex();

}
public class Women extends People {

    void sex() {
        System.out.println("I'm a female");
    }

}
```

```xml
<bean class="com.spring.mjf.lookup.Women" id="women"></bean>
<bean class="com.spring.mjf.lookup.ShowSex">
    <!--	getPeople返回的就是women这个实例-->
   <lookup-method bean="women" name="getPeople" ></lookup-method>
</bean>
```

### replace-method

用于项目已经封版了，不允许进行修改，可以利用这个标签去替换某要需要修改的方法。

```java
public class Original {

    public void method() {
        System.out.println("hello, 我是小明");
    }

}

public class Replacer implements MethodReplacer {
    public Object reimplement(Object obj, Method method, Object[] args) throws Throwable {
        System.out.println("我对你进行了增强");
        return null;
    }
}
```

```xml
<bean class="com.spring.mjf.replace.Original" id="original">
   <replaced-method replacer="replacer" name="method"/>
</bean>
<bean class="com.spring.mjf.replace.Replacer" id="replacer"></bean>
```

### property

用PropertyValue类来封装property标签的数据。

### constructor-arg

ConstructorArgumentValues来封装。

# 装饰bean

![image-20210316213626397](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210316213626397.png)

```java
bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
```

```xml
<!--    装饰bean-->
   <bean id="user3" class="com.spring.mjf.entity.User" c:name="xiaoming" p:id="1"/>
```

# 别名注册

# SPI

```java
/**
 * @author mjf
 * @date 2021-03-16-21:45:00
 */
public interface SpiService {

    void save();

}

/**
 * @author mjf
 * @date 2021-03-16-21:45:00
 */
public class SpiServiceImpl implements SpiService {

    public void save() {
        System.out.println("save...........");
    }
}

    @Test
    public void testSpi() {
        ServiceLoader<SpiService> load = ServiceLoader.load(SpiService.class);
        for (SpiService spiService : load) {
            spiService.save();
        }
    }

```

## 好处

扩展容易

## 缺点

粒度不够细。获取实现类的时候获取了很多个。

# Spring自定义标签

## context

### 解析器

#### 注册

```java
public class ContextNamespaceHandler extends NamespaceHandlerSupport {

   @Override
   public void init() {
      registerBeanDefinitionParser("property-placeholder", new PropertyPlaceholderBeanDefinitionParser());
      registerBeanDefinitionParser("property-override", new PropertyOverrideBeanDefinitionParser());
      registerBeanDefinitionParser("annotation-config", new AnnotationConfigBeanDefinitionParser());
      registerBeanDefinitionParser("component-scan", new ComponentScanBeanDefinitionParser());
      registerBeanDefinitionParser("load-time-weaver", new LoadTimeWeaverBeanDefinitionParser());
      registerBeanDefinitionParser("spring-configured", new SpringConfiguredBeanDefinitionParser());
      registerBeanDefinitionParser("mbean-export", new MBeanExportBeanDefinitionParser());
      registerBeanDefinitionParser("mbean-server", new MBeanServerBeanDefinitionParser());
   }

}
```



## aop

# 包扫描

ClassPathBeanDefinitionScanner用来扫描指定包下带有注解的类。

## 注册默认的过滤器

过滤器用来对扫描到的类进行过滤，不符合条件的不会添加到BeanFactory。

```java
protected void registerDefaultFilters() {
    // 对Component注解进行包装
   this.includeFilters.add(new AnnotationTypeFilter(Component.class));
}
```

## 扫描

```java
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
   Assert.notEmpty(basePackages, "At least one base package must be specified");
   Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
   for (String basePackage : basePackages) {
      // 寻找符合条件的类(添加某种注解的类)
      Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
      for (BeanDefinition candidate : candidates) {
         // 包装了Bean的元数据信息
         ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
         candidate.setScope(scopeMetadata.getScopeName());
         String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
         if (candidate instanceof AbstractBeanDefinition) {
            postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
         }
         if (candidate instanceof AnnotatedBeanDefinition) {
            AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
         }
         if (checkCandidate(beanName, candidate)) {
            BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
            definitionHolder =
                  AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
            beanDefinitions.add(definitionHolder);
            // 注册到BeanFactory中
            registerBeanDefinition(definitionHolder, this.registry);
         }
      }
   }
   return beanDefinitions;
}
```

## GetBean

![](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210319213550407.png)

# BeanPostProcessor

非常重要的接口。

## ConfigurationClassPostProcessor

在springboot中完成了bean的加载与注册。

## CommonAnnotationBeanPostProcessor

注解的处理

# 注解

## Autowired

AutowiredAnnotationBeanPostProcessor。

1、实例化：registerBeanPostProcessors(beanFactory);

2、注册：AnnotationConfigUtils.registerAnnotationConfigProcessors

3、inject

```java
PropertyValues pvsToUse = ibp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
```

## Resource

CommonAnnotationBeanPostProcessor类来处理该注解的。

```java
@Override
public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
   super.postProcessMergedBeanDefinition(beanDefinition, beanType, beanName);
   // 将在方法有@Resource包装成InjectionMetadata
   InjectionMetadata metadata = findResourceMetadata(beanName, beanType, null);
   metadata.checkConfigMembers(beanDefinition);
}
```

## PostConstruct

CommonAnnotationBeanPostProcessor类来处理该注解的。

```java
public CommonAnnotationBeanPostProcessor() {
   setOrder(Ordered.LOWEST_PRECEDENCE - 3);
    // 设置注解的类型为PostConstruct
   setInitAnnotationType(PostConstruct.class);
   setDestroyAnnotationType(PreDestroy.class);
   ignoreResourceType("javax.xml.ws.WebServiceContext");
}
```

## PreDestroy

CommonAnnotationBeanPostProcessor类来处理该注解的。

# 自定义标签

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	   xmlns:dubbo="http://www.ttxs.org/schema/dubbo"
	   xsi:schemaLocation="
	   http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.ttxs.org/schema/dubbo
		http://www.ttxs.org/schema/dubbo/dubbo.xsd">

    <!--	自定义标签-->
	<dubbo:service ip="127.0.0.1"/>

</beans>
```

1、在META-INF下面定义spring.handlers文件，主要是用来指定命名空间的处理类的。

```handler
http\://www.ttxs.org/schema/dubbo=com.spring.mjf.custom.DubboNamespaceHandler
```

2、在META-INF下面定义spring.schemas文件，指定xds文件的位置

```
http\://www.ttxs.org/schema/dubbo=com.spring.mjf.custom.DubboNamespaceHandler
```

3、定义dubbo.xsd。

```xml
<?xml version="1.0" encoding="UTF-8"?>

<xsd:schema xmlns="http://www.ttxs.org/schema/dubbo"
            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            targetNamespace="http://www.ttxs.org/schema/dubbo"
            elementFormDefault="qualified">

    <xsd:element name="service">
        <xsd:complexType>
            <xsd:attribute name="id" type="xsd:string"></xsd:attribute>
            <xsd:attribute name="ip" type="xsd:string"></xsd:attribute>
        </xsd:complexType>
    </xsd:element>

</xsd:schema>
```

4、定义命名空间的处理类和解析类。

```java
public class DubboNamespaceHandler extends NamespaceHandlerSupport {

    @Override
    public void init() {
        registerBeanDefinitionParser("service", new DubboServiceParser());
    }
}

public class DubboServiceParser implements BeanDefinitionParser {

    @Override
    public BeanDefinition parse(Element element, ParserContext parserContext) {
        String ip = element.getAttribute("ip");
        GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
        beanDefinition.getPropertyValues().add("ip", ip);
        beanDefinition.setBeanClass(DubboService.class);
        parserContext.getRegistry().registerBeanDefinition("dubboService", beanDefinition);

        return beanDefinition;
    }

/*    @Override
    protected Class<?> getBeanClass(Element element) {
        return DubboService.class;
    }

    @Override
    protected void doParse(Element element, BeanDefinitionBuilder builder) {
        String ip = element.getAttribute("ip");
        builder.getBeanDefinition().getPropertyValues().add("ip", ip);
    }*/


}


@Data
public class DubboService {

    private String ip;

}
```

## 设置xsd文件可以通过域名来访问

将xsd文件放到nginx的目录下，可以通过nginx来访问。

nginx需要设置才能浏览xds文件，不设置直接访问的话，就会将xsd文件下载下来。

### 如果设置呢？

只需要去修改mime.types，添加类型即可，拿xsd为例子，我们访问以xsd结尾的文件，实际上想要返回一个xml文件，只要在mime.types文件中添加一行：

```
 text/xml                                         xsd;
```

### 让目录中的文件以列表的形式展现

只需要在nginx.conf添加一行即可

```
autoindex on;
```

![image-20210321115021528](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210321115021528.png)

