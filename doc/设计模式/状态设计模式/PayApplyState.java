package cn.e3mall.demo_1214.design.state;

/**
 * <p>
 *     组长付款申请
 * </p>
 * @ClassName: PayApplyState
 * @Auther: admin
 * @Date: 2020/3/19 10:38
 * @Description:
 */
public class PayApplyState implements FinPayState {
    @Override
    public void handel(Context context) {
        System.out.println("当前状态为组长付款申请状态");
    }
}
