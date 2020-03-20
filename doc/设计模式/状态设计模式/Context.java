package cn.e3mall.demo_1214.design.state;

/**
 * @ClassName: Context
 * @Auther: admin
 * @Date: 2020/3/19 10:37
 * @Description:
 */
public class Context {

    private FinPayState finPayState;

    public void request() {
        finPayState.handel(this);
    }

    public FinPayState getFinPayState() {
        return finPayState;
    }

    public void setFinPayState(FinPayState finPayState) {
        this.finPayState = finPayState;
    }
}
