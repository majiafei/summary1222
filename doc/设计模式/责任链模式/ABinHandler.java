package com.richart.warehouse.handler;

import com.richart.warehouse.domain.Bin;
import com.richart.warehouse.service.BinService;
import org.springframework.util.CollectionUtils;

import java.util.List;

/**
 * @ClassName: ABinHandler
 * @Auther: admin
 * @Date: 2019/11/21 17:17
 * @Description:
 */
public class ABinHandler extends AbstractBinHandler{
    public ABinHandler() {
    }

    public ABinHandler(BinService binService) {
        super(binService);
    }

    public Bin doGetBin(String volume) {
        String sql = "from "+ Bin.class.getName() + " WHERE is_lock = 0 AND BinName NOT LIKE 'E44%' AND BinName NOT LIKE 'CM%' AND Inv_Material_ID is null AND" +
                " BinName LIKE 'A%' AND volume = '" + volume + "' ORDER BY binName";

        List<Bin> binList = getBinService().getBinBySql(sql);
        if (CollectionUtils.isEmpty(binList)) {
            return null;
        }

        return binList.get(0);
    }
}
