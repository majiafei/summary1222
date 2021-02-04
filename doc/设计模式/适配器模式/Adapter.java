package mjf.design.adpter;

/**
 * @author mjf
 * @since: 2021/02/04 17:13
 */
public interface Adapter {

	boolean support(Power power);

	int output(Power power);

}
