# 数值累加的例子

## 单线程环境

```java
public class SysnchronizedTest {

    private static int num = 0;

    private static int sum() {
        return num++;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 10; i++) {
            sum();
        }

        System.out.println(num);
    }

}
```

结果：

![image-20201208211907394](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201208211907394.png)

## 多线程环境

```java
public class SysnchronizedTest {

    private static int num = 0;

    private static int sum() {
        return num++;
    }

    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 3; i++) {
            new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    sum();
                }
            }).start();
        }

        Thread.sleep(1000);

        System.out.println(num);
    }

}
```

第一次运行的结果：

![image-20201208212305273](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201208212305273.png)

第二次运行的结果：

![image-20201208212412667](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201208212412667.png)

第三次运行的结果：

![image-20201208212435208](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201208212435208.png)

由以上结果看出：每一次运行的结果都不一样。

## 使用Synchronized

```java
public class SysnchronizedTest {

    private static int num = 0;

    private static int sum() {
        synchronized (object) {
            num++;
        }
        return num;
    }

    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 3; i++) {
            new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    sum();
                }
            }).start();
        }

        Thread.sleep(1000);

        System.out.println(num);
    }

}
```

**每一次运行的结果都是3000；**

# 对象头

http://openjdk.java.net/groups/hotspot/docs/HotSpotGlossary.html

## 组成

![image-20201209221311259](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201209221311259.png)

![image-20201209221501985](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201209221501985.png)

mark word 占64位，在jvm源码的注释上写的。

![image-20201209222602239](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201209222602239.png)

剩下的是kclass pointer占32位，4个字节；在jvm启动的时候，class文件加载到元空间中的地址的首地址。

## 打印对象头信息

```xml
<!-- https://mvnrepository.com/artifact/org.xerial.snappy/snappy-java -->
<dependency>
    <groupId>org.xerial.snappy</groupId>
    <artifactId>snappy-java</artifactId>
    <version>1.1.7.6</version>
</dependency>

<!-- https://mvnrepository.com/artifact/org.openjdk.jol/jol-core -->
<dependency>
    <groupId>org.openjdk.jol</groupId>
    <artifactId>jol-core</artifactId>
    <version>0.13</version>
    <scope>provided</scope>
</dependency>
```

```java
public class User {

    private int age;

}

public static void main(String[] args) {
    User user = new User();
    System.out.println(ClassLayout.parseInstance(object).toPrintable());
}
```



**打印结果：**

cn.e3mall.demo_1214.syn.User object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           43 c1 00 f8 (01000011 11000001 00000000 11111000) (-134168253)
     12     4    int User.age                                  0
Instance size: 16 bytes
Space losses: 0 bytes internal + 0 bytes external = 0 bytes total

## mark word

![image-20201210222818964](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201210222818964.png)

## 关闭偏向延迟

-XX:BiasedLockingStartupDelay=0

![image-20201210223333435](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201210223333435.png)

## 大端存储和小端存储

1).大端存储：大端模式，是指数据的高字节保存在内存的低地址中，而数据的低字节保存在内存的高地址中，这样的存储模式有点儿类似于把数据当作字符串顺序处理：地址由小向大增加，而数据从高位往低位放。

2).小端存储：小端模式，是指数据的高字节保存在内存的高地址中，而数据的低字节保存在内存的低地址中，这种存储模式将地址的高低和数据位权有效地结合起来，高地址部分权值高，低地址部分权值低，和我们的逻辑方法一致。



![image-20201209230829925](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201209230829925.png)



# 锁状态转换

## 没有打印hashcode

没有打印hashcode，是可以偏向的

```java
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) {
        System.out.println(ClassLayout.parseInstance(object).toPrintable());
    }

}
```

![image-20201214204846986](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214204846986.png)

## 打印hashcode

是不可偏向的，因为有对象头有31位存储了hashcode，那么就没有位置去存线程id(如果可偏向，那么当为偏向锁的时候，有56位存储的是线程id，现在已经有31位存储了hashcode，那么线程id就存不下了)，所以不可偏向的。

```java
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) {
        // 打印hashcode
        System.out.println(Integer.toHexString(object.hashCode()));
        // 打印对象头
        System.out.println(ClassLayout.parseInstance(object).toPrintable());
    }

}
```

![image-20201214205517772](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214205517772.png)

## 不打印HashCode，但是加锁

加锁之后，当前锁为偏向锁，对象头中的前56位存储的是线程id

```java
/**
 * @author majiafei
 * @date 2020/10/18 20:40
 */
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) {
//        System.out.println(Integer.toHexString(object.hashCode()));
        System.out.println(ClassLayout.parseInstance(object).toPrintable());

        synchronized (object){
            System.out.println(ClassLayout.parseInstance(object).toPrintable());
        }
    }

}
```

![image-20201214210308374](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214210308374.png)

## 打印HashCode，并且加锁

```java
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) {
        System.out.println(Integer.toHexString(object.hashCode()));
        System.out.println(ClassLayout.parseInstance(object).toPrintable());

        synchronized (object){
            System.out.println(ClassLayout.parseInstance(object).toPrintable());
        }

        System.out.println(Long.toHexString(Thread.currentThread().getId()));
    }

}
```

![image-20201214211340078](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214211340078.png)

## 不打印HashCode，两个线程交替执行

```java
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) throws InterruptedException {
//        System.out.println(Integer.toHexString(object.hashCode()));
        System.out.println(ClassLayout.parseInstance(object).toPrintable());


        Thread t1 = new Thread(() -> {
            add();
        });
        t1.start();
        t1.join();


        Thread t2 = new Thread(() -> {
            add();
        });
        t2.start();

    }

    public static void add() {
        synchronized (object){
            System.out.println(ClassLayout.parseInstance(object).toPrintable());
        }
    }

}
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

![image-20201214212531444](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214212531444.png)

## 不打印HashCode，两个线程存在资源竞争，基本同时去抢锁，Synchronized会直接升级为重量级锁

```java
public class SynTest2 {

    private static Object object = new Object();

    static int i = 0;

    public static void main(String[] args) throws InterruptedException {
//        System.out.println(Integer.toHexString(object.hashCode()));
        System.out.println(ClassLayout.parseInstance(object).toPrintable());


        for (int i = 0; i < 2; i++) {
            new Thread(() -> {
                add();
            }).start();
        }

    }

    public static void add() {
        synchronized (object){
            System.out.println(ClassLayout.parseInstance(object).toPrintable());
        }
    }

}
```

![image-20201214213017063](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20201214213017063.png)

## 重入加锁

第一次加锁之后，将线程id存到对象头中，同一个线程第二次、第三次、第n次获取锁时，将线程id拿出来比较一下，如果相等，就直接进入方法，不跟操作系统有交互，提高效率。

```java
    private static int num = 0;

    private static Object object = new Object();

    private static int sum() {
        synchronized (object) {
            num++;
        }
        return num;
    }

/*    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 3; i++) {
            new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    sum();
                }
            }).start();
        }

        Thread.sleep(1000);

        System.out.println(num);
    }*/

    public static void main(String[] args) {
        User user = new User();
        System.out.println(ClassLayout.parseInstance(user).toPrintable());
    }
```

java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total





加锁之后。。。。。。。。。。。。。。。。。

java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 d8 e2 1f (00000101 11011000 11100010 00011111) (534960133)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 d8 e2 1f (00000101 11011000 11100010 00011111) (534960133)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 d8 e2 1f (00000101 11011000 11100010 00011111) (534960133)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 d8 e2 1f (00000101 11011000 11100010 00011111) (534960133)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

# 虚拟地址