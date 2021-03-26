--Mysql优化（抄袭网文第三天，抄完之后发原文地址^_^）
二、SELECT语句其他优化
1. 避免出现select *
使用select * 取出全部列，会让优化器无法完成索引覆盖扫描这类优化，会影响优化器对执行计划的选择，也会增加网络带宽消耗，更会带来额外的I/O,内存和CPU消耗。
建议提出业务实际需要的列数，将指定列名以取代select *。

2. 避免出现不确定结果的函数
特定针对主从复制这类业务场景。由于原理上从库复制的是主库执行的语句，使用如now()、rand()、sysdate()、current_user()等不确定结果的函数很容易导致主库与从库相应的数据不一致。
另外不确定值的函数,产生的SQL语句无法利用query cache。

3.多表关联查询时，小表在前，大表在后。
在MySQL中，执行 from 后的表关联查询是从左往右执行的（Oracle相反），第一张表会涉及到全表扫描，所以将小表放在前面，先扫小表，扫描快效率较高，在扫描后面的大表，或许只扫描大表的前100行就符合返回条件并return了。

4. 使用表的别名
当在SQL语句中连接多个表时，请使用表的别名并把别名前缀于每个列名上。这样就可以减少解析的时间并减少哪些友列名歧义引起的语法错误。

5. 用where字句替换HAVING字句
避免使用HAVING字句，因为HAVING只会在检索出所有记录之后才对结果集进行过滤，而where则是在聚合前刷选记录，如果能通过where字句限制记录的数目，那就能减少这方面的开销。HAVING中的条件一般用于聚合函数的过滤，除此之外，应该将条件写在where字句中。
where和having的区别：where后面不能使用组函数

6.调整Where字句中的连接顺序
MySQL采用从左往右，自上而下的顺序解析where子句。根据这个原理，应将过滤数据多的条件往前放，最快速度缩小结果集。

三、增删改 DML 语句优化
1. 大批量插入数据
如果同时执行大量的插入，建议使用多个值的INSERT语句。这比使用分开INSERT语句快，一般情况下批量插入效率有几倍的差别。
Insert into T values(1,2),(1,3),(1,4); 
原因有三：
减少SQL语句解析的操作，MySQL没有类似Oracle的share pool，采用此方法，只需要解析一次就能进行数据的插入操作；
在特定场景可以减少对DB连接次数
SQL语句较短，可以减少网络传输的IO。

2. 适当使用commit
适当使用commit可以释放事务占用的资源而减少消耗，commit后能释放的资源如下：
事务占用的undo数据块；
事务在redo log中记录的数据块；
释放事务施加的，减少锁争用影响性能。特别是在需要使用delete删除大量数据的时候，必须分解删除量并定期commit。

3. 避免重复查询更新的数据
针对业务中经常出现的更新行同时又希望获得改行信息的需求，MySQL并不支持PostgreSQL那样的UPDATE RETURNING语法，在MySQL中可以通过变量实现。
使用变量，可以重写为以下方式：
Update t1 set time=now () where col1=1 and @now: = now (); 
Select @now; 
前后二者都需要两次网络来回，但使用变量避免了再次访问数据表，特别是当t1表数据量较大时，后者比前者快很多。

4.查询优先还是更新（insert、update、delete）优先
MySQL 还允许改变语句调度的优先级，它可以使来自多个客户端的查询更好地协作，这样单个客户端就不会由于锁定而等待很长时间。改变调度策略的方法主要是针对只存在表锁的存储引擎，比如 MyISAM 、MEMROY、MERGE，对于Innodb 存储引擎，语句的执行是由获得行锁的顺序决定的。
