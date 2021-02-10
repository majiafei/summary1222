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

# synchronized实现原理

## 两个线程交替获取锁，一个线程获取完锁后，另一个线程再获取锁

```java
@Slf4j
public class SysnchronizedTest {
  
    private static Object lock = new Object();

    private static Thread t2;

    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(() -> {
            synchronized (lock) {
                log.info(ClassLayout.parseInstance(lock).toPrintable());
            }

            t2.start();
        });

        t2 = new Thread(() -> {
            synchronized (lock) {
                log.info(ClassLayout.parseInstance(lock).toPrintable());
            }
        });

        t1.start();
        t1.join();

        t2.join();

        log.info(ClassLayout.parseInstance(lock).toPrintable());
    }
}
```

打印结果如下：

```
22:14:43.669 [Thread-0] INFO com.alibaba.mjf.springboot.User - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           05 c8 9a 20 (00000101 11001000 10011010 00100000) (547014661)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

22:14:43.669 [Thread-1] INFO com.alibaba.mjf.springboot.User - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           08 f0 1d 21 (00001000 11110000 00011101 00100001) (555610120)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

22:14:43.669 [main] INFO com.alibaba.mjf.springboot.User - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

![image-20210203221904091](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210203221904091.png)

![image-20210203221940481](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210203221940481.png)

![image-20210203222019331](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210203222019331.png)

## 轻量级加锁

![image-20210203224426353](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210203224426353.png)

## 去掉偏向延迟的jvm参数，即打开偏向延迟，延迟时间大概为4s，睡眠超过4s，那么锁状态为可偏向的

```java
public static void main(String[] args) throws InterruptedException {
    Thread.sleep(6000);
    // 不能用static变量，因为static在类加载的时候就已经初始化好了,对象头已经创建好了，而且偏向状态为不可偏向状态，
    // 因为没有禁止偏向延迟
    Object o = new Object();

    new Thread(() -> {
        synchronized (o) {
            log.info(ClassLayout.parseInstance(o).toPrintable());
        }
    }).start();

}
```

![image-20210209225850053](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210209225850053.png)

## 重量级锁

hotspot源码在以下几个文件中：

### objectMonitor.cpp

![image-20210209231709023](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210209231709023.png)

```c++
void ObjectMonitor::enter(TRAPS) {
  // The following code is ordered to check the most common cases first
  // and to reduce RTS->RTO cache line upgrades on SPARC and IA32 processors.
  Thread * const Self = THREAD;

    // 当前锁的线程是否为null，将&_owner之前的值返回
  void * cur = Atomic::cmpxchg(Self, &_owner, (void*)NULL);
  if (cur == NULL) {
    // Either ASSERT _recursions == 0 or explicitly set _recursions = 0.
    assert(_recursions == 0, "invariant");
    assert(_owner == Self, "invariant");
    return;
  }

    // 重入
  if (cur == Self) {
    // TODO-FIXME: check for integer overflow!  BUGID 6557169.
      // 持有锁的次数加1
    _recursions++;
    return;
  }

  if (Self->is_lock_owned ((address)cur)) {
    assert(_recursions == 0, "internal state error");
    _recursions = 1;
    // Commute owner from a thread-specific on-stack BasicLockObject address to
    // a full-fledged "Thread *".
    _owner = Self;
    return;
  }

  // We've encountered genuine contention.
  assert(Self->_Stalled == 0, "invariant");
  Self->_Stalled = intptr_t(this);

  // Try one round of spinning *before* enqueueing Self
  // and before going through the awkward and expensive state
  // transitions.  The following spin is strictly optional ...
  // Note that if we acquire the monitor from an initial spin
  // we forgo posting JVMTI events and firing DTRACE probes.
  if (TrySpin(Self) > 0) {
    assert(_owner == Self, "invariant");
    assert(_recursions == 0, "invariant");
    assert(((oop)(object()))->mark() == markOopDesc::encode(this), "invariant");
    Self->_Stalled = 0;
    return;
  }

  assert(_owner != Self, "invariant");
  assert(_succ != Self, "invariant");
  assert(Self->is_Java_thread(), "invariant");
  JavaThread * jt = (JavaThread *) Self;
  assert(!SafepointSynchronize::is_at_safepoint(), "invariant");
  assert(jt->thread_state() != _thread_blocked, "invariant");
  assert(this->object() != NULL, "invariant");
  assert(_count >= 0, "invariant");

  // Prevent deflation at STW-time.  See deflate_idle_monitors() and is_busy().
  // Ensure the object-monitor relationship remains stable while there's contention.
  Atomic::inc(&_count);

  JFR_ONLY(JfrConditionalFlushWithStacktrace<EventJavaMonitorEnter> flush(jt);)
  EventJavaMonitorEnter event;
  if (event.should_commit()) {
    event.set_monitorClass(((oop)this->object())->klass());
    event.set_address((uintptr_t)(this->object_addr()));
  }

  { // Change java thread status to indicate blocked on monitor enter.
    JavaThreadBlockedOnMonitorEnterState jtbmes(jt, this);

    Self->set_current_pending_monitor(this);

    DTRACE_MONITOR_PROBE(contended__enter, this, object(), jt);
    if (JvmtiExport::should_post_monitor_contended_enter()) {
      JvmtiExport::post_monitor_contended_enter(jt, this);

      // The current thread does not yet own the monitor and does not
      // yet appear on any queues that would get it made the successor.
      // This means that the JVMTI_EVENT_MONITOR_CONTENDED_ENTER event
      // handler cannot accidentally consume an unpark() meant for the
      // ParkEvent associated with this ObjectMonitor.
    }

    OSThreadContendState osts(Self->osthread());
    ThreadBlockInVM tbivm(jt);

    // TODO-FIXME: change the following for(;;) loop to straight-line code.
      // 自旋
    for (;;) {
      jt->set_suspend_equivalent();
      // cleared by handle_special_suspend_equivalent_condition()
      // or java_suspend_self()

      EnterI(THREAD);

      if (!ExitSuspendEquivalent(jt)) break;

      // We have acquired the contended monitor, but while we were
      // waiting another thread suspended us. We don't want to enter
      // the monitor while suspended because that would surprise the
      // thread that suspended us.
      //
      _recursions = 0;
      _succ = NULL;
      exit(false, Self);

      jt->java_suspend_self();
    }
    Self->set_current_pending_monitor(NULL);

    // We cleared the pending monitor info since we've just gotten past
    // the enter-check-for-suspend dance and we now own the monitor free
    // and clear, i.e., it is no longer pending. The ThreadBlockInVM
    // destructor can go to a safepoint at the end of this block. If we
    // do a thread dump during that safepoint, then this thread will show
    // as having "-locked" the monitor, but the OS and java.lang.Thread
    // states will still report that the thread is blocked trying to
    // acquire it.
  }

  Atomic::dec(&_count);
  assert(_count >= 0, "invariant");
  Self->_Stalled = 0;

  // Must either set _recursions = 0 or ASSERT _recursions == 0.
  assert(_recursions == 0, "invariant");
  assert(_owner == Self, "invariant");
  assert(_succ != Self, "invariant");
  assert(((oop)(object()))->mark() == markOopDesc::encode(this), "invariant");

  // The thread -- now the owner -- is back in vm mode.
  // Report the glorious news via TI,DTrace and jvmstat.
  // The probe effect is non-trivial.  All the reportage occurs
  // while we hold the monitor, increasing the length of the critical
  // section.  Amdahl's parallel speedup law comes vividly into play.
  //
  // Another option might be to aggregate the events (thread local or
  // per-monitor aggregation) and defer reporting until a more opportune
  // time -- such as next time some thread encounters contention but has
  // yet to acquire the lock.  While spinning that thread could
  // spinning we could increment JVMStat counters, etc.

  DTRACE_MONITOR_PROBE(contended__entered, this, object(), jt);
  if (JvmtiExport::should_post_monitor_contended_entered()) {
    JvmtiExport::post_monitor_contended_entered(jt, this);

    // The current thread already owns the monitor and is not going to
    // call park() for the remainder of the monitor enter protocol. So
    // it doesn't matter if the JVMTI_EVENT_MONITOR_CONTENDED_ENTERED
    // event handler consumed an unpark() issued by the thread that
    // just exited the monitor.
  }
  if (event.should_commit()) {
    event.set_previousOwner((uintptr_t)_previous_owner_tid);
    event.commit();
  }
  OM_PERFDATA_OP(ContendedLockAttempts, inc());
}
```

### park方法

![image-20210209233651779](C:\Users\MI\AppData\Roaming\Typora\typora-user-images\image-20210209233651779.png)

将线程暂停

```c++
void os::PlatformEvent::park() {       // AKA "down()"
  // Transitions for _event:
  //   -1 => -1 : illegal
  //    1 =>  0 : pass - return immediately
  //    0 => -1 : block; then set _event to 0 before returning

  // Invariant: Only the thread associated with the PlatformEvent
  // may call park().
  assert(_nParked == 0, "invariant");

  int v;

  // atomically decrement _event
  for (;;) {
    v = _event;
    if (Atomic::cmpxchg(v - 1, &_event, v) == v) break;
  }
  guarantee(v >= 0, "invariant");

  if (v == 0) { // Do this the hard way by blocking ...
      // 操作系统的mutex
    int status = pthread_mutex_lock(_mutex);
    assert_status(status == 0, status, "mutex_lock");
    guarantee(_nParked == 0, "invariant");
    ++_nParked;
    while (_event < 0) {
      // OS-level "spurious wakeups" are ignored
      status = pthread_cond_wait(_cond, _mutex);
      assert_status(status == 0, status, "cond_wait");
    }
    --_nParked;

    _event = 0;
    status = pthread_mutex_unlock(_mutex);
    assert_status(status == 0, status, "mutex_unlock");
    // Paranoia to ensure our locked and lock-free paths interact
    // correctly with each other.
    OrderAccess::fence();
  }
  guarantee(_event >= 0, "invariant");
}
```



### synchronizer.cpp