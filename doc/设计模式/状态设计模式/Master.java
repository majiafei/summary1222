package cn.e3mall.demo_1214.design.state;

/**
 * @ClassName: Master
 * @Auther: admin
 * @Date: 2020/3/19 10:52
 * @Description:
 */
public class Master {

    public static void main(String[] args) {
        FinPayState payApplyState = new PayApplyState();
        FinPayState accountingRemarkState = new AccountingRemarkState();

        Context context = new Context();
        context.setFinPayState(payApplyState);
        context.request();

        context.setFinPayState(accountingRemarkState);
        context.request();
    }

}
