--Mysql优化（抄袭网文第一天，抄完之后发原文地址^_^）
知识点1：
Mysql优化
优化成本：硬件>系统配置>数据库表结构>SQL及索引。
优化效果：硬件<系统配置<数据库表结构<SQL及索引。

知识点2：
对于MySQL层优化一般遵从五个原则：
减少数据访问： 设置合理的字段类型，启用压缩，通过索引访问等减少磁盘IO
返回更少的数据： 只返回需要的字段和数据分页处理 减少磁盘io及网络io
减少交互次数： 批量DML操作，函数存储等减少数据连接次数
减少服务器CPU开销： 尽量减少数据库排序操作以及全表查询，减少cpu 内存占用
利用更多资源： 使用表分区，可以增加并行操作，更大限度利用cpu资源

知识点3：
总结到SQL优化中，就三点:
最大化利用索引；
尽可能避免全表扫描；
减少无效数据的查询；

知识点4：
SELECT语句 - 语法顺序：
语句顺序								执行顺序
1. SELECT 								7			
2. DISTINCT <select_list>				8		
3. FROM <left_table>					1
4. <join_type> JOIN <right_table>		3
5. ON <join_condition>					2
6. WHERE <where_condition>				4
7. GROUP BY <group_by_list>				5
8. HAVING <having_condition>			6		
9. ORDER BY <order_by_condition>		9
10.LIMIT <limit_number>					10

SELECT语句 - 执行顺序：
FROM
<表名> # 选取表，将多个表数据通过笛卡尔积变成一个表。

ON
<筛选条件> # 对笛卡尔积的虚表进行筛选

JOIN<join, left join, right join...>
<join表> # 指定join，用于添加数据到on之后的虚表中，例如left join会将左表的剩余数据添加到虚表中

WHERE
<where条件> # 对上述虚表进行筛选

GROUP BY
<分组条件> # 分组
<SUM()等聚合函数> # 用于having子句进行判断，在书写上这类聚合函数是写在having判断里面的

HAVING
<分组筛选> # 对分组后的结果进行聚合筛选

SELECT
<返回数据列表> # 返回的单列必须在group by子句中，聚合函数除外

DISTINCT
# 数据除重

ORDER BY
<排序条件> # 排序

LIMIT
<行数限制>