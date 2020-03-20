package cn.e3mall.demo_1214.design.state;

/**
 * @ClassName: AccountingRemarkState
 * @Auther: admin
 * @Date: 2020/3/19 10:51
 * @Description:
 */
public class AccountingRemarkState implements FinPayState {

    @Override
    public void handel(Context context) {
        System.out.println("往来会计审核状态");
    }
}
