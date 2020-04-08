package com.mjf.coffee;

import org.assertj.core.util.Lists;
import org.junit.Test;

import java.util.List;

/**
 * @ClassName: IntegerTest
 * @Auther: admin
 * @Date: 2020/4/8 09:54
 * @Description:
 */
public class IntegerTest {
    @Test
    public void testCompare() {
        List<Integer> integerList = Lists.newArrayList(4, 3, 1);
        integerList.sort((i1, i2) -> {
            // 从小到大的顺序
//            public static int compare(int x, int y) {
//                return (x < y) ? -1 : ((x == y) ? 0 : 1);
//            }
            return Integer.compare(i1, i2);
        });
        System.out.println(integerList);
    }
}
