# AbstractApplication与BeanFactory的关系

AbstractApplication继承了BeanFactory，同时又进行了扩展。

![image-20210302213442753](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210302213442753.png)

# ApplicationContext

## AnnotationConfigApplicationContext

```java
@Test
public void testComponentScan() {
    // 会将ComponentScanBean添加到spring的容器中，然后由ConfigurationClassPostProcessor类去处理ComponentScanBean上的所有的注解
    AnnotationConfigApplicationContext ctx =  new AnnotationConfigApplicationContext(ComponentScanBean.class);

    System.out.println(ctx.getBean(OrderService.class));
}
```

专门用来处理利用注解配置的bean

```java
/**
 * Create a new AnnotationConfigApplicationContext that needs to be populated
 * through {@link #register} calls and then manually {@linkplain #refresh refreshed}.
 */
public AnnotationConfigApplicationContext() {
    // 注解读取器
   this.reader = new AnnotatedBeanDefinitionReader(this);
    // 用来扫描包的
   this.scanner = new ClassPathBeanDefinitionScanner(this);
}
```

## 注册注解的processors

ConfigurationClassPostProcessor非常重要，用来处理众多注解的。例如：ComponentSacn，@Configuration，@Bean，@Import等等

![image-20210501165235374](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210501165235374.png)

```java
public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
      BeanDefinitionRegistry registry, @Nullable Object source) {

   DefaultListableBeanFactory beanFactory = unwrapDefaultListableBeanFactory(registry);
   if (beanFactory != null) {
      if (!(beanFactory.getDependencyComparator() instanceof AnnotationAwareOrderComparator)) {
         beanFactory.setDependencyComparator(AnnotationAwareOrderComparator.INSTANCE);
      }
      if (!(beanFactory.getAutowireCandidateResolver() instanceof ContextAnnotationAutowireCandidateResolver)) {
         beanFactory.setAutowireCandidateResolver(new ContextAnnotationAutowireCandidateResolver());
      }
   }

   Set<BeanDefinitionHolder> beanDefs = new LinkedHashSet<>(8);

   if (!registry.containsBeanDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME)) {
       // ConfigurationClassPostProcessor非常重要
      RootBeanDefinition def = new RootBeanDefinition(ConfigurationClassPostProcessor.class);
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME));
   }

   if (!registry.containsBeanDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME)) {
      RootBeanDefinition def = new RootBeanDefinition(AutowiredAnnotationBeanPostProcessor.class);
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME));
   }

   // Check for JSR-250 support, and if present add the CommonAnnotationBeanPostProcessor.
   if (jsr250Present && !registry.containsBeanDefinition(COMMON_ANNOTATION_PROCESSOR_BEAN_NAME)) {
      RootBeanDefinition def = new RootBeanDefinition(CommonAnnotationBeanPostProcessor.class);
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, COMMON_ANNOTATION_PROCESSOR_BEAN_NAME));
   }

   // Check for JPA support, and if present add the PersistenceAnnotationBeanPostProcessor.
   if (jpaPresent && !registry.containsBeanDefinition(PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME)) {
      RootBeanDefinition def = new RootBeanDefinition();
      try {
         def.setBeanClass(ClassUtils.forName(PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME,
               AnnotationConfigUtils.class.getClassLoader()));
      }
      catch (ClassNotFoundException ex) {
         throw new IllegalStateException(
               "Cannot load optional framework class: " + PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME, ex);
      }
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME));
   }

   if (!registry.containsBeanDefinition(EVENT_LISTENER_PROCESSOR_BEAN_NAME)) {
      RootBeanDefinition def = new RootBeanDefinition(EventListenerMethodProcessor.class);
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_PROCESSOR_BEAN_NAME));
   }

   if (!registry.containsBeanDefinition(EVENT_LISTENER_FACTORY_BEAN_NAME)) {
      RootBeanDefinition def = new RootBeanDefinition(DefaultEventListenerFactory.class);
      def.setSource(source);
      beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_FACTORY_BEAN_NAME));
   }

   return beanDefs;
}
```

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

# BeanFactoryPostProcessor

## ConfigurationClassPostProcessor

```java
/**
 * Build and validate a configuration model based on the registry of
 * {@link Configuration} classes.
 */
public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
   List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
   String[] candidateNames = registry.getBeanDefinitionNames();

   for (String beanName : candidateNames) {
      BeanDefinition beanDef = registry.getBeanDefinition(beanName);
      if (beanDef.getAttribute(ConfigurationClassUtils.CONFIGURATION_CLASS_ATTRIBUTE) != null) {
         if (logger.isDebugEnabled()) {
            logger.debug("Bean definition has already been processed as a configuration class: " + beanDef);
         }
      }
      else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
         configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
      }
   }

   // Return immediately if no @Configuration classes were found
   if (configCandidates.isEmpty()) {
      return;
   }

   // Sort by previously determined @Order value, if applicable
    // 排序
   configCandidates.sort((bd1, bd2) -> {
      int i1 = ConfigurationClassUtils.getOrder(bd1.getBeanDefinition());
      int i2 = ConfigurationClassUtils.getOrder(bd2.getBeanDefinition());
      return Integer.compare(i1, i2);
   });

   // Detect any custom bean name generation strategy supplied through the enclosing application context
   SingletonBeanRegistry sbr = null;
   if (registry instanceof SingletonBeanRegistry) {
      sbr = (SingletonBeanRegistry) registry;
      if (!this.localBeanNameGeneratorSet) {
         BeanNameGenerator generator = (BeanNameGenerator) sbr.getSingleton(
               AnnotationConfigUtils.CONFIGURATION_BEAN_NAME_GENERATOR);
         if (generator != null) {
            this.componentScanBeanNameGenerator = generator;
            this.importBeanNameGenerator = generator;
         }
      }
   }

   if (this.environment == null) {
      this.environment = new StandardEnvironment();
   }

   // Parse each @Configuration class
   ConfigurationClassParser parser = new ConfigurationClassParser(
         this.metadataReaderFactory, this.problemReporter, this.environment,
         this.resourceLoader, this.componentScanBeanNameGenerator, registry);

   Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
   Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
   do {
       // 解析
      parser.parse(candidates);
      parser.validate();

      Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
      configClasses.removeAll(alreadyParsed);

      // Read the model and create bean definitions based on its content
      if (this.reader == null) {
         this.reader = new ConfigurationClassBeanDefinitionReader(
               registry, this.sourceExtractor, this.resourceLoader, this.environment,
               this.importBeanNameGenerator, parser.getImportRegistry());
      }
      this.reader.loadBeanDefinitions(configClasses);
      alreadyParsed.addAll(configClasses);

      candidates.clear();
      if (registry.getBeanDefinitionCount() > candidateNames.length) {
         String[] newCandidateNames = registry.getBeanDefinitionNames();
         Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
         Set<String> alreadyParsedClasses = new HashSet<>();
         for (ConfigurationClass configurationClass : alreadyParsed) {
            alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
         }
         for (String candidateName : newCandidateNames) {
            if (!oldCandidateNames.contains(candidateName)) {
               BeanDefinition bd = registry.getBeanDefinition(candidateName);
               if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
                     !alreadyParsedClasses.contains(bd.getBeanClassName())) {
                  candidates.add(new BeanDefinitionHolder(bd, candidateName));
               }
            }
         }
         candidateNames = newCandidateNames;
      }
   }
   while (!candidates.isEmpty());

   // Register the ImportRegistry as a bean in order to support ImportAware @Configuration classes
   if (sbr != null && !sbr.containsSingleton(IMPORT_REGISTRY_BEAN_NAME)) {
      sbr.registerSingleton(IMPORT_REGISTRY_BEAN_NAME, parser.getImportRegistry());
   }

   if (this.metadataReaderFactory instanceof CachingMetadataReaderFactory) {
      // Clear cache in externally provided MetadataReaderFactory; this is a no-op
      // for a shared cache since it'll be cleared by the ApplicationContext.
      ((CachingMetadataReaderFactory) this.metadataReaderFactory).clearCache();
   }
}
```

# 注解

注解注入属性：

1、收集注解：

```java
// Allow post-processors to modify the merged bean definition.
synchronized (mbd.postProcessingLock) {
   if (!mbd.postProcessed) {
      try {
         // 收集添加注解的方法或者字段，以便实现依赖注入
         // @Autowired、@PostConstruct、@PreDestroy注解
         applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
      }
      catch (Throwable ex) {
         throw new BeanCreationException(mbd.getResourceDescription(), beanName,
               "Post-processing of merged bean definition failed", ex);
      }
      mbd.postProcessed = true;
   }
}
```

2、通过反射注入属性

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

## @Import

ConfigurationClassPostProcessor

引入需要引入的类，比如我们可能依赖一些jar包，但是jar包的类一般是不去扫描的，但是又需要引入该jar包的类，就可以使用import注解。

可以写个类实现ImportBeanDefinitionRegistrar接口，引入需要引入的类。

## @ComponentScan

ConfigurationClassPostProcessor

## @Bean

ConfigurationClassPostProcessor



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

# 如何解决循环依赖

共有三级缓存。

```java
// 一级 缓存
/** Cache of singleton objects: bean name to bean instance. */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

// 三级缓存
/** Cache of singleton factories: bean name to ObjectFactory. */
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);

// 二级缓存
/** Cache of early singleton objects: bean name to bean instance. */
private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);
```



## 获取实例

```java
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
   // 从一级缓存中获取(已经实例化且设置好属性的实例，是一个完整的实例)
   Object singletonObject = this.singletonObjects.get(beanName);
   if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
      synchronized (this.singletonObjects) {
         // 从二级缓存中获取，这个是提前实例化(是从ObjectFactory获取的)好的
         singletonObject = this.earlySingletonObjects.get(beanName);
         if (singletonObject == null && allowEarlyReference) {
            // 从ObjectFactory中获取，这个工厂是在刚刚实例化好bean时加入的
            ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
            if (singletonFactory != null) {
               singletonObject = singletonFactory.getObject();
               this.earlySingletonObjects.put(beanName, singletonObject);
               this.singletonFactories.remove(beanName);
            }
         }
      }
   }
   return singletonObject;
}
```

## 把刚刚实例化好的实例添加到singletonFactories

```java
// Eagerly cache singletons to be able to resolve circular references
// even when triggered by lifecycle interfaces like BeanFactoryAware.
boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
      isSingletonCurrentlyInCreation(beanName));
if (earlySingletonExposure) {
   if (logger.isTraceEnabled()) {
      logger.trace("Eagerly caching bean '" + beanName +
            "' to allow for resolving potential circular references");
   }
   // 添加到singletonFactories，lamda表达式是实现了ObjectFactory中getObject方法
   addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
}


protected Object getEarlyBeanReference(String beanName, RootBeanDefinition mbd, Object bean) {
    Object exposedObject = bean;
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof SmartInstantiationAwareBeanPostProcessor) {
                SmartInstantiationAwareBeanPostProcessor ibp = (SmartInstantiationAwareBeanPostProcessor) bp;
                exposedObject = ibp.getEarlyBeanReference(exposedObject, beanName);
            }
        }
    }
    return exposedObject;
}
```

## 注意

构造函数的循环依赖是不允许的。

属性的循环依赖是允许的。

# FactoryBean

## 作用

可以用来给没有实现类的接口生成代理类。比如Mybatis的mapper接口、Feign。

## 如何获取FactoryBean

在beanName中加上"&"

# Aop

aop是代理有实现类的接口，而getObject借口可以代理没有实现类的接口。

## AnnotationAwareAspectJAutoProxyCreator

基于注解的方式

### 类图

![image-20210502203015324](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210502203015324.png)

## aop的工具类

AopConfigUtils

## advice

### before

一个注解便是一个通知，spring会将其封装成为advice对象。

### after

### around

### afterreturning

### afterthrowing

## MethodIntercepter

也实现了Advice，相当于通知。

## Advisor

由Advice和PointCut组成。

## TargetSource

封装被代理对象（目标对象）

## 动态代理

### JDK动态代理

JdkDynamicAopProxy

### cglib代理

ObjenesisCglibAopProxy

## AOP的调用

链式调用。

```java
@Nullable
public Object proceed() throws Throwable {
   // currentInterceptorIndex是一个游标，一直往后执行
    // 为什么不用for循环呢？因为每次在调用advice之后又会调用到这个方法，如果用了for循环，那么每次都从头开始调用。for(int i = // 0; i < size; i++)
   if (this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1) {
      return invokeJoinpoint();
   }

    // 从数组中获取advice
   Object interceptorOrInterceptionAdvice =
         this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
   if (interceptorOrInterceptionAdvice instanceof InterceptorAndDynamicMethodMatcher) {
      // Evaluate dynamic method matcher here: static part will already have
      // been evaluated and found to match.
      InterceptorAndDynamicMethodMatcher dm =
            (InterceptorAndDynamicMethodMatcher) interceptorOrInterceptionAdvice;
      Class<?> targetClass = (this.targetClass != null ? this.targetClass : this.method.getDeclaringClass());
      if (dm.methodMatcher.matches(this.method, targetClass, this.arguments)) {
         return dm.interceptor.invoke(this);
      }
      else {
         // Dynamic matching failed.
         // Skip this interceptor and invoke the next in the chain.
         return proceed();
      }
   }
   else {
      // It's an interceptor, so we just invoke it: The pointcut will have
      // been evaluated statically before this object was constructed.
       // 调用advice
      return ((MethodInterceptor) interceptorOrInterceptionAdvice).invoke(this);
   }
}
```

# 实例的类型

## single

## prototype

## request

## session

## globlal request

# 事务

事务和Connection一一绑定的。连接对象要和用户挂钩（请求）

## 事务切面



### 事务通知

TransactionInterceptor是个事务通知，实现了MethodIntercepter方法，在aop调用链执行的时候，会执行invoke方法。

![image-20210515204238496](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210515204238496.png)

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
         retVal = invocation.proceedWithInvocation();
      }
      catch (Throwable ex) {
         // target invocation exception
         completeTransactionAfterThrowing(txInfo, ex);
         throw ex;
      }
      finally {
         cleanupTransactionInfo(txInfo);
      }

      if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
         // Set rollback-only in case of Vavr failure matching our rollback rules...
         TransactionStatus status = txInfo.getTransactionStatus();
         if (status != null && txAttr != null) {
            retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
         }
      }

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

