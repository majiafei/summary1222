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
            // -1不需要交换位置，1需要交换位置
            return Integer.compare(i1, i2);
        });
        System.out.println(integerList);
    }

    // 从大到小排序
    public void testCompare() {
        List<Integer> integerList = Lists.newArrayList(3, 4, 1);
        integerList.sort((i1, i2) -> {
            if (i1 > i2) {
                return -1;
            } else if (i1 == i2) {
                return 0;
            } else {
                return 1;
            }
        });
        System.out.println(integerList);
    }
}
