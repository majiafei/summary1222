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