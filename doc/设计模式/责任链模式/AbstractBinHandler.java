package com.richart.warehouse.handler;

import com.richart.warehouse.domain.Bin;
import com.richart.warehouse.service.BinService;

/**
 * @ClassName: BinHandler
 * @Auther: admin
 * @Date: 2019/11/21 17:17
 * @Description:
 */
public abstract class AbstractBinHandler {

    private AbstractBinHandler binHandler;

    private BinService binService;

    public AbstractBinHandler() {
    }

    public AbstractBinHandler(BinService binService) {
       this.binService = binService;
    }

    public Bin getBin(String volume) {
        Bin bin = doGetBin(volume);
        if (bin != null) {
            return bin;
        }

        if (binHandler != null) {
            return binHandler.getBin(volume);
        } else {
            return null;
        }
    }

    protected abstract Bin doGetBin(String volume);

    public AbstractBinHandler getBinHandler() {
        return binHandler;
    }

    public void setBinHandler(AbstractBinHandler binHandler) {
        this.binHandler = binHandler;
    }

    public BinService getBinService() {
        return binService;
    }

    public void setBinService(BinService binService) {
        this.binService = binService;
    }
}
