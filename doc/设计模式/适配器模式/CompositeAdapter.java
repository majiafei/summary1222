package mjf.design.adpter;

import java.util.List;

/**
 * @author mjf
 * @since: 2021/02/04 17:22
 */
public class CompositeAdapter {

	private List<Adapter> adapterList;

	public CompositeAdapter(List<Adapter> adapterList) {
		this.adapterList = adapterList;
	}

	public int output(Power power) {
		for (Adapter adapter : adapterList) {
			if (adapter.support(power)) {
				return adapter.output(power);
			}
		}
		return -1;
	}

}
