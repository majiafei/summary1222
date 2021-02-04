package mjf.design.adpter;

/**
 * @author mjf
 * @since: 2021/02/04 17:13
 */
public class ChinaAdapter implements Adapter{

	@Override
	public boolean support(Power power) {
		return power.output() == 220;
	}

	@Override
	public int output(Power power) {
		System.out.println(power.output() + "转换成了" + power.output() / 5);
		return power.output() / 4;
	}
}
