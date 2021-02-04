package mjf.design.adpter;

import com.google.common.collect.Lists;

/**
 * @author mjf
 * @since: 2021/02/04 17:21
 */
public class Master {

	public static void main(String[] args) {
		Adapter adapter = new ChinaAdapter();
		JapanAdapter japanAdapter = new JapanAdapter();

		CompositeAdapter compositeAdapter = new CompositeAdapter(Lists.newArrayList(adapter, japanAdapter));
		int output = compositeAdapter.output(new ChinaPower());
		System.out.println(output);
	}

}
