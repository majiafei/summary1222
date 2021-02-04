package mjf.design.adpter;

import org.python.antlr.op.Pow;

/**
 * @author mjf
 * @since: 2021/02/04 17:19
 */
public class JapanAdapter implements Adapter{

	@Override
	public int output(Power power) {
		return power.output() / 2;
	}

	@Override
	public boolean support(Power power) {
		return power.output() == 110;
	}
}
