$(function () {
    $("#pbDetailTable").datagrid({
        url: "/features/wish/pb/list.do?campaignId="+getUrlParam("campaignId") ,
        title: '活动详情',
        iconCls: 'icon-search',
        toolbar: '#qryCondition',
        width: 1200,
        height: 150,
        left: 300,
        columns: [[
            {field: 'wishCampaignId', title: 'wishCampaignId', width: 100, hidden: true},
            {field: 'campaignState', title: '状态', width: 100, align: 'center'},
            {field: 'totalCampaignSpend', title: '费用', width: 80, align: 'center'},
            {field: 'sales', title: '订单数', width: 100, align: 'center'},
            {field: 'gmv', title: '成交总额', width: 100}, // gmv
            {field: 'costToTradeRatioStr', title: '花费成交比', width: 100},// 费用/成交总额
            {field: 'costToTradeRatio', title: '花费成交比', width: 100, hidden: true},
            {field: 'startTime', title: '开始日期', width: 100, align: 'center'},
            {field: 'endTime', title: '截止日期', width: 100, align: 'center'}
        ]],
        onLoadSuccess: function () {
            var rows = $('#pbDetailTable').datagrid('getRows');
            var merges = [];
            var index = 0;
            var spans = 0;
            merges.push({index:0,rowspan:rows.length});
            for(var i=0; i < merges.length; i++){
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'wishCampaignId',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'campaignState',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'totalCampaignSpend',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'sales',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'gmv',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'costToTradeRatioStr',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'startTime',
                    rowspan: merges[i].rowspan
                });
                $(this).datagrid('mergeCells',{
                    index: merges[i].index,
                    field: 'endTime',
                    rowspan: merges[i].rowspan
                });
            }
        }
    });

    /**
     * 产品详情
     */
    $("#productDetail").datagrid({
        url: '/features/wish/pb/statistics/list.do?campaignId=' + getUrlParam("campaignId"),
        title: '产品详情',
        iconCls: 'icon-search',
        rownumbers: true,
        width: 1200,
        height: 200,
        left: 300,
        columns: [[
            {field: 'wishCampaignId', title: 'wishCampaignId', width: 100, hidden: true},
            {field: 'productId', title: '广告id', width: 200, align: 'center', formatter: function (value,row,index) {
                    return "<a  style='color: #0a56c8'  href='https://www.wish.com/c/"+(value)+"' target='_blank'  >"+value+"</a>";
                }},
            {field: 'productName', title: '广告标题', width: 400, align: 'center'},
            {field: 'sku', title: 'Sku', width: 200, align: 'center'},
            {field: 'skuState', title: 'sku状态', width: 100}, // gmv
            {field: 'spend', title: '总费用', width: 100},// 费用/成交总额
            {field: 'sales', title: '订单数', width: 100, },
            {field: 'gmv', title: '成交总额', width: 100, align: 'center'},
            {field: 'costToTradeRatioStr', title: '花费成交比', width: 100, align: 'center'}
        ]]
    });

    $("#dailyStatisticsTable").datagrid({
        url: '/features/wish/daily/listByCampaign.do?campaignId=' + getUrlParam("campaignId"),
        title: '日统计',
        iconCls: 'icon-search',
        rownumbers: true,
        width: 1200,
        height: 600,
        left: 300,
        columns: [[
            {field: 'id', title: 'id', width: 100, hidden: true},
            {field: 'dateStr', title: '日期', width: 200, align: 'center'},
            {field: 'totalImpressions', title: '产品浏览数', width: 300, align: 'center'},
            {field: 'spend', title: '总费用', width: 100, align: 'center', formatter:function(value,row, index) {
                return value.toFixed(2)
                }},
            {field: 'sales', title: '订单', width: 100}, // gmv
            {field: 'gmv', title: '成交总额', width: 100, formatter:function(value,row, index){
                return "$" + value;
                }},// 费用/成交总额
            {field: 'spendGmvRate', title: '花费与成交总额之比', width: 130, formatter:function(value,row, index) {
                    var  rate = ((row.spend / row.gmv) * 100).toFixed(2)
                return rate + "%";
                }},
            {field: 'thousandImpressionsOrders', title: '每一千流览量的订单', width: 100, align: 'center', formatter:function(value,row, index) {
                return (row.sales / row.totalImpressions * 1000).toFixed(2);
                }},
            {field: 'thousandImpressionsGmv', title: '每一千流量的成交总额', width: 100, align: 'center',formatter:function(value,row, index) {
                    return '$' + (row.gmv / row.totalImpressions * 1000).toFixed(2);
                }},
            {field: 'type', title: 'type', width: 100, align: 'center', hidden: true, formatter:function(value,row, index) {
                }}
        ]],
        rowStyler: function(index,row){
            if (row.type == 2) {
                return 'background-color:green;color:#fff;font-weight:bold;';
            }
        }
    });

    var myChart = echarts.init(document.getElementById('main'));;
    option = {
        title: {
            text: '每日表现'
        },
        tooltip: {
            trigger: 'axis'
        },
        legend: {
            data:[]
        },
        toolbox: {
            feature: {
                saveAsImage: {}
            }
        },
        xAxis: {
            type: 'category',
            boundaryGap: false,
            data: [],
            splitLine: {
                show: true
            }
        },
        yAxis: [
            {
                name: '产品浏览总数',
                type: 'value',
                min: 0,
                nameTextStyle:{
                    verticalAlign:'bottom',
                    fontWeight: 'bold',
                    align: 'center',
                    fontSize: 15
                },
                nameLocation: 'center',
                nameRotate: 90,
                nameGap: 50,
                splitNumber: 10,
                splitLine:{show: true}//去除网格线
            },
            {
                name: '订单数及GMV',
                splitLine:{show: true},//去除网格线
                type: 'value',
                min: 0,
                splitNumber: 10,
                nameTextStyle:{
                    verticalAlign:'bottom',
                    fontWeight: 'bold',
                    align: 'center',
                    fontSize: 15
                },
                nameRotate: 270,
                nameGap: 50,
                nameLocation: 'center',
                splitNumber: 10,
                // max: 100
            }
    ],
        series: []
    };



    myChart.setOption(option);

    $.ajax({
        url: '/features/wish/daily/statisticsByCampaignId.do',
        data: {campaignId: getUrlParam("campaignId")},
        success: function (result) {
            var responseJsonObj = eval("(" + result + ")");
            myChart.setOption({
                yAxis: [
                    {
                        interval: responseJsonObj.leftInterval,
                        splitNumber: 10,
                        max: responseJsonObj.leftInterval * 10
                    },
                    {
                        interval: responseJsonObj.rightInterval,
                        splitNumber: 10,
                        max: responseJsonObj.rightInterval*10
                    }],
                xAxis: {
                    splitArea: {
                        areaStyle: {
                            color: '#D1EEEE',
                        },
                        show: true,
                        interval: function (index, value) {
                            if (responseJsonObj.runningDate != null) {
                               if (responseJsonObj.runningDate.indexOf(value) != -1) {
                                   return true;
                               }
                            } else {
                                return false;
                            }
                        }
                    },
                    data: responseJsonObj.xAxis,
                          axisLabel:{
                               interval:0,
                               rotate: 30, // 旋转30度
                               margin: 10
                           }
                },
                color:['#00DDDD','red','green'],
                legend: {
                    data:[{
                        name: '产品浏览总数',
                        // 强制设置图形为圆。
                        icon: 'rect'
                    },{
                        name: '订单总量',
                        // 强制设置图形为圆。
                        icon: 'rect'
                    },
                        {
                            name: '成交总额',
                            // 强制设置图形为圆。
                            icon: 'rect'
                        }]
                },
                series: responseJsonObj.series
            });
        }
    });
});