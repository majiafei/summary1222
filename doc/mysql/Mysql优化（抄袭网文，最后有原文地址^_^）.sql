--Mysql优化（抄袭网文第四天，抄完之后发原文地址^_^）
四、查询条件优化
1. 对于复杂的查询，可以使用中间临时表 暂存数据；

2. 优化group by语句
默认情况下，MySQL 会对GROUP BY分组的所有值进行排序，如 “GROUP BY col1，col2，....;” 查询的方法如同在查询中指定 “ORDER BY col1，col2，...;” 
如果显式包括一个包含相同的列的 ORDER BY子句，MySQL 可以毫不减速地对它进行优化，尽管仍然进行排序。
因此，如果查询包括 GROUP BY 但你并不想对分组的值进行排序，你可以指定 ORDER BY NULL禁止排序。

3. 优化join语句
MySQL中可以通过子查询来使用 SELECT 语句来创建一个单列的查询结果，然后把这个结果作为过滤条件用在另一个查询中。使用子查询可以一次性的完成很多逻辑上需要多个步骤才能完成的 SQL 操作，同时也可以避免事务或者表锁死，并且写起来也很容易。但是，有些情况下，子查询可以被更有效率的连接(JOIN)..替代。
例子：假设要将所有没有订单记录的用户取出来，可以用下面这个查询完成：
SELECT col1 FROM customerinfo WHERE CustomerID NOT in (SELECT CustomerID FROM salesinfo )
如果使用连接(JOIN).. 来完成这个查询工作，速度将会有所提升。尤其是当 salesinfo表中对 CustomerID 建有索引的话，性能将会更好，查询如下：
SELECT col1 FROM customerinfo 
LEFT JOIN salesinfoON customerinfo.CustomerID=salesinfo.CustomerID 
WHERE salesinfo.CustomerID IS NULL 
连接(JOIN).. 之所以更有效率一些，是因为 MySQL 不需要在内存中创建临时表来完成这个逻辑上的需要两个步骤的查询工作。

4. 优化union查询
MySQL通过创建并填充临时表的方式来执行union查询。除非确实要消除重复的行，否则建议使用union all。原因在于如果没有all这个关键词，MySQL会给临时表加上distinct选项，这会导致对整个临时表的数据做唯一性校验，这样做的消耗相当高。
高效：
SELECT COL1, COL2, COL3 FROM TABLE WHERE COL1 = 10 
UNION ALL 
SELECT COL1, COL2, COL3 FROM TABLE WHERE COL3= 'TEST'; 

低效：
SELECT COL1, COL2, COL3 FROM TABLE WHERE COL1 = 10 
UNION 
SELECT COL1, COL2, COL3 FROM TABLE WHERE COL3= 'TEST';

5.拆分复杂SQL为多个小SQL，避免大事务
简单的SQL容易使用到MySQL的QUERY CACHE；
减少锁表时间特别是使用MyISAM存储引擎的表；
可以使用多核CPU。

6. 使用truncate代替delete（注意--truncate记录不可恢复）
当删除全表中记录时，使用delete语句的操作会被记录到undo块中，删除记录也记录binlog，当确认需要删除全表时，会产生很大量的binlog并占用大量的undo数据块，此时既没有很好的效率也占用了大量的资源。
使用truncate替代，不会记录可恢复的信息，数据不能被恢复。也因此使用truncate操作有其极少的资源占用与极快的时间。另外，使用truncate可以回收表的水位，使自增字段值归零。

7. 使用合理的分页方式以提高分页效率
使用合理的分页方式以提高分页效率 针对展现等分页需求，合适的分页方式能够提高分页的效率。
案例1：
select * from t where thread_id = 10000 and deleted = 0 
order by gmt_create asc limit 0, 15;
上述例子通过一次性根据过滤条件取出所有字段进行排序返回。数据访问开销=索引IO+索引全部记录结果对应的表数据IO。因此，该种写法越翻到后面执行效率越差，时间越长，尤其表数据量很大的时候。
适用场景：当中间结果集很小（10000行以下）或者查询条件复杂（指涉及多个不同查询字段或者多表连接）时适用。

案例2：
select t.* from (select id from t where thread_id = 10000 and deleted = 0
order by gmt_create asc limit 0, 15) a, t 
where a.id = t.id;
上述例子必须满足t表主键是id列，且有覆盖索引secondary key:(thread_id, deleted, gmt_create)。通过先根据过滤条件利用覆盖索引取出主键id进行排序，再进行join操作取出其他字段。数据访问开销=索引IO+索引分页后结果（例子中是15行）对应的表数据IO。因此，该写法每次翻页消耗的资源和时间都基本相同，就像翻第一页一样。
适用场景：当查询和排序字段（即where子句和order by子句涉及的字段）有对应覆盖索引时，且中间结果集很大的情况时适用。

五、建表优化
1. 在表中建立索引，优先考虑where、order by使用到的字段。

2. 尽量使用数字型字段（如性别，男：1 女：2），若只含数值信息的字段尽量不要设计为字符型，这会降低查询和连接的性能，并会增加存储开销。
这是因为引擎在处理查询和连接时会 逐个比较字符串中每一个字符，而对于数字型而言只需要比较一次就够了。

3. 查询数据量大的表 会造成查询缓慢。主要的原因是扫描行数过多。这个时候可以通过程序，分段分页进行查询，循环遍历，将结果合并处理进行展示。要查询100000到100050的数据，如下：
SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY ID ASC) AS rowid,* 
FROM infoTab)t WHERE t.rowid > 100000 AND t.rowid <= 100050

4. 用varchar/nvarchar 代替 char/nchar
尽可能的使用 varchar/nvarchar 代替 char/nchar ，因为首先变长字段存储空间小，可以节省存储空间，其次对于查询来说，在一个相对较小的字段内搜索效率显然要高些。
不要以为 NULL 不需要空间，比如：char(100) 型，在字段建立时，空间就固定了， 不管是否插入值（NULL也包含在内），都是占用 100个字符的空间的，如果是varchar这样的变长字段， null 不占用空间。

抄完了！
当当当当--原文链接  https://zhuanlan.zhihu.com/p/265852739