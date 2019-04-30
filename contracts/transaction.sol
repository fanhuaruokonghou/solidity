pragma solidity ^0.5.0;

import "./MyAdvancedToken.sol";

contract transaction is MyAdvancedToken {
    
    //时间定义
    uint256 constant DAY_IN_SECONDS = 86400; //一天有多少秒
    uint256 constant MONTH_IN_SECONDS = 2592000; //一月有多少秒
    uint256 private currTimeInSeconds; //当前时间（以秒为单位）
    uint256 private lastbuytimeInSeconds; //最近一次交易的时间（以秒为单位）
    uint256 private timeinterval; //当前交易与上一次交易的时间间隔（以秒为单位）
    
    uint256 private totalbuyerpayment; //买家购买情报总金额
    uint256 private buycontributionvalue; //买家贡献值
    uint256 private sellcontributionvalue; //卖家贡献值
    uint256 private totalsellercollection; //卖家卖出情报总金
    uint256 private buyrebate; //买家返利
    uint256 private sellrebate; //卖家返利
    uint256 private fee; //交易手续费（买家支付）
    uint256 private buyerpayment; //买家付款（交易手续费+情报总价）
    uint256 private sellercollection; //卖家收款（情报总价-交易手续费）
    uint256 private commission; //交易提成（卖家支付）
    uint256 private feeProportion = 1000; //买家手续费收取比例，初始时设为千分之一
    uint256 private commissionProportion = 100; //卖家提成收取比例，初始时为百分之一
    uint256 private totalvalue; //定制情报总价
    uint8 private needSubsellercredit; //卖家待减信用值
    uint8 private realSubsellercredit; //卖家实际减去的信用值
    uint8 private needAddsellercredit; //卖家待加信用值
    uint8 private realAddsellercredit; //卖家实际增加的信用值
    uint8 private _buyerTotalScore; //买家总分
    uint8 private _sellerTotalScore; //卖家总分
    uint8 private sellercreditScore; //卖家信用分
    
    event SuccessFunds(address target, bool success);//定义一个事件，用来通知前端交易发生
    
    // 用mapping保存每个地址对应的买家贡献值(记录超过一定交易金额的交易次数)
    mapping (address => uint256) private _buycontributionvalue;
    // 用mapping保存每个地址对应的卖家贡献值
    mapping (address => uint256) private _sellcontributionvalue;
    // 用mapping保存每个地址对应的最近一次购买情报的时间
    mapping (address => uint256) private _lastbuytime;
    // 用mapping保存每个地址对应的卖家信用值、退款次数(累计10次，信用值-1，满10次后清0重新累计)、成功交易次数(累计50次，信用值+1)
    mapping (address => uint8[3]) private _sellercredit;
    // 用mapping保存每个地址对应的买家购买情报总金额
    mapping (address => uint256) private _totalbuyerpayment;
    // 用mapping保存每个地址对应的卖家卖出情报总金额
    mapping (address => uint256) private _totalsellercollection;

//求两个数中的较小者，用来比较卖家当前信用值与待减信用值的大小
    /**
     * a,b:比较大小的两个整数
     */ 
    function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a < b ? a : b;
    }
    
//买家手续费及卖家提成的收取比例设置
    /**
     * newfeeProportion:新的买家手续费收取比例，初始时设为千分之一（1000）,newcommissionProportion:新的卖家提成收取比例，初始时为百分之一（100）
     */ 
    function setProportion(uint256 newfeeProportion, uint256 newcommissionProportion) onlyOwner public whenNotPaused{
        feeProportion = newfeeProportion;
        commissionProportion = newcommissionProportion; 
    } 
   
//计算买家付款（交易手续费+情报总价）
    /**
     * totalprice:情报总价
     */ 
    function _Buyerpayment(uint256 totalprice) internal whenNotPaused returns (uint256){
        fee = totalprice / feeProportion;       //收取0.1%的手续费
        //交易费的最小值为1
        if(fee!=0){        
            buyerpayment = fee + totalprice; //计算买家付款
        }
        else{
            buyerpayment = 1 + totalprice;
        }
        return buyerpayment;
  }
  
//计算卖家收款（情报总价-交易手续费）
    /**
     * totalprice:情报总价
     */ 
    function _Sellercollection(uint256 totalprice) internal whenNotPaused returns (uint256){
        commission = totalprice / commissionProportion;       //收取1%的交易提成
        //交易费的最小值为1
        if(commission!=0){        
            sellercollection = totalprice - commission;  //计算卖家收款
        }
        else{
            sellercollection = totalprice - 1;
        }
        return sellercollection;
  }
  
//查询最近一次购买情报的时间
    /**
     * who:待查询最近一次购买情报的时间的账户地址
     */
    function Lastbuytime(address who) external view returns (uint256) {
        return _lastbuytime[who];    //返回最近一次购买情报的时间
    }

//更新最近一次购买情报的时间
    /**
     * buyer:买家地址
     */
    function _UpdateLastbuytime(address buyer)  internal whenNotPaused{
        _lastbuytime[buyer] = now;  //将账户最近一次购买情报的时间更新为当前时间
    }

//查询买家贡献值
    /**
     * who:待查询买家贡献值的账户地址
     */
    function Buycontributionvalue(address who) external view returns (uint256) {
        return _buycontributionvalue[who];
    }

//查询卖家贡献值
    /**
     * who:待查询卖家贡献值的账户地址
     */
    function Sellcontributionvalue(address who) external view returns (uint256) {
        return _sellcontributionvalue[who];
    }
    
//更新买家贡献值
    /**
     * target:买家地址,totalprice:情报总价
     */
    function _UpdateBuycontributionvalue(address target, uint256 totalprice)  internal whenNotPaused{
        if(totalprice >= 2000){
            _buycontributionvalue[target] += 1;  //当情报总价>=2000时,将账户买家贡献值加1
        }
    }

//更新卖家贡献值
    /**
     * target:卖家地址,totalprice:情报总价
     */
    function _UpdateSellcontributionvalue(address target, uint256 totalprice)  internal whenNotPaused{
        if(totalprice >= 2000){
            _sellcontributionvalue[target] += 1;  //当情报总价>=2000时,将账户卖家贡献值加1
        }
    }

//查询买家购买情报总金额
    /**
     * who:待查询买家购买情报总金额的账户地址
     */
    function Totalbuyerpayment(address who) external view returns (uint256) {
        return _totalbuyerpayment[who];
    }

//查询卖家卖出情报总金额
    /**
     * who:待查询卖家卖出情报总金额的账户地址
     */
    function Totalsellercollection(address who) external view returns (uint256) {
        return _totalsellercollection[who];
    }

//更新买家购买情报总金额
    /**
     * target:买家地址,totalprice:情报总价
     */
    function _UpdateTotalbuyerpayment(address target, uint256 totalprice)  internal whenNotPaused{
            _totalbuyerpayment[target] += totalprice;  //将买家购买情报总金额加将账户卖家贡献值加本次交易情报总价
    }

//更新卖家卖出情报总金额
    /**
     * target:卖家地址,totalprice:情报总价
     */
    function _UpdateTotalsellercollection(address target, uint256 totalprice)  internal whenNotPaused{
            _totalsellercollection[target] += totalprice;  //将卖家卖出情报总金额加将账户卖家贡献值加本次交易情报总价
    }

//查询卖家信用值/退款次数/成功交易次数，其中信用值等价于信用值维度对应评价的分数（30分），卖家评价分数总分为100分
    /**
     * who:待查询卖家信用值/退款次数/成功交易次数的账户地址,i:表示选取想要查询的值,i可为0(卖家信用值),1(退款次数),2(成功交易次数)
     */
    function Sellercredit(address who, uint256 i) external view returns (uint256) {
        return _sellercredit[who][i];//i可为0(卖家信用值)，1(退款次数)，2(成功交易次数)
    }

//更新卖家退款次数/成功交易次数
    /**
     * target:卖家地址,i:表示选取想要更新的值,i可为1(修改退款次数),2(修改成功交易次数)
     */
    function _UpdateRelatedSellercredit(address target, uint256 i)  internal whenNotPaused{
        if(i == 1){
            _sellercredit[target][1] += 1;  //将卖家退款次数加1 
        }
        if(i == 2){
            _sellercredit[target][2] += 1;  //将卖家成功交易次数加1
        }        
    }

//更新信用值
//减少卖家信用值
    /**
     * target:卖家地址
     */
    function _DecreaseSellercredit(address target)  internal whenNotPaused{
        if(_sellercredit[target][1] == 10){   //当退款次数累计至10次
            if(_sellercredit[target][0] > 0){ //如果卖家当前的信用值大于0
                _sellercredit[target][0] -= 1;  //将卖家信用值减1 
                _sellercredit[target][1] = 0;   //将退款次数累加器清0
            }
            if(_sellercredit[target][0] == 0){   //如果卖家当前的信用值等于0
                _sellercredit[target][0] = 0;   //卖家信用值不变仍为0，即卖家信用值的最小值为0
            }
        }
        if(_sellercredit[target][1] > 10){   //当退款次数大于10时（由于此前信用值为0导致信用值无法继续减小）
            needSubsellercredit = _sellercredit[target][1] / 10;  //求出需要减掉信用值
            realSubsellercredit = min(needSubsellercredit, _sellercredit[target][0]);  //用来比较卖家当前信用值与待减信用值的大小，求出真正可以减掉的信用值
            _sellercredit[target][0] -= realSubsellercredit;     //更新卖家信用值
            _sellercredit[target][1] -= realSubsellercredit * 10;  //减去真正可以减掉的信用值对应的退款次数
        }
    }

//增加卖家信用值
    /**
     * target:卖家地址
     */
    function _IncreaseSellercredit(address target)  internal whenNotPaused{
        if(_sellercredit[target][2] == 50){ //当成功交易次数累计至50次
            if(_sellercredit[target][0] < 30){ //如果卖家当前的信用值小于30
                _sellercredit[target][0] += 1;  //将卖家信用值加1
                _sellercredit[target][2] = 0;  //将成功次数累加器清0         
            }
            if(_sellercredit[target][0] == 30){   //如果卖家当前的信用值等于30
                _sellercredit[target][0] = 30;   //卖家信用值不变仍为30，即卖家信用值的最大值为30
            }
        } 
        if(_sellercredit[target][2] > 50){   //当成功交易次数大于50时（由于此前信用值为30导致信用值无法继续增加）
            needAddsellercredit = _sellercredit[target][2] / 50;  //求出需要增加的信用值
            realAddsellercredit = min(needAddsellercredit, 30 - _sellercredit[target][0]);  //用来比较卖家当前可增加信用值与待加信用值的大小，求出真正可以增加的信用值
            _sellercredit[target][0] += realAddsellercredit;     //更新卖家信用值
            _sellercredit[target][2] -= realAddsellercredit * 50;  //减去真正可以增加的信用值对应的成功交易次数
        }
    }

//对买家和卖家进行评分(总分100分)
//对买家的活跃度进行评分，其中活跃度可通过最近一次交易的时间(30分)和交易次数(20分)进行评价
//买家交易时间得分(30分)
    /**
     * who:买家账户地址
     */
    function LastbuytimeScore(address who) internal whenNotPaused returns (uint8) {
        lastbuytimeInSeconds = _lastbuytime[who]; //查询最近一次购买情报的时间
        currTimeInSeconds = now; //获取当前时间
        timeinterval = currTimeInSeconds - lastbuytimeInSeconds; //当前交易与上一次交易的时间间隔（以秒为单位）
        if(timeinterval >= MONTH_IN_SECONDS * 3){  //当交易时间间隔大于或等于3个月时，得分为0
            return 0;
        }
        if(timeinterval < MONTH_IN_SECONDS * 3){  
            if(timeinterval >= MONTH_IN_SECONDS) {//当交易时间间隔小于3个月，大于或等于1个月时，得分为10
                return 10;
            }
            if(timeinterval < MONTH_IN_SECONDS){  
                if(timeinterval >= DAY_IN_SECONDS * 3){ //当交易时间间隔小于1个月，大于或等于3天时，得分为20
                    return 20;
                }
                if(timeinterval < DAY_IN_SECONDS * 3){  
                    if(timeinterval >= 0){ //当交易时间间隔小于3天时，得分为30
                        return 30;
                    }
                }
            }
        }
    }
    
//买家交易次数得分(20分)
    /**
     * who:买家账户地址
     */
    function BuycontributionvalueScore(address who) internal whenNotPaused returns (uint8) {
        buycontributionvalue = _buycontributionvalue[who]; //查询买家贡献值
        if(buycontributionvalue >= 10000){  //当买家交易贡献值大于或等于10000时，得分为20
            return 20;
        }
        if(buycontributionvalue < 10000){  
            if(buycontributionvalue >= 1000) {//当买家交易贡献值小于10000，大于或等于1000时，得分为15
                return 15;
            }
            if(buycontributionvalue < 1000){  
                if(buycontributionvalue >= 100){ //当买家交易贡献值小于1000，大于或等于100时，得分为10
                    return 10;
                }
                if(buycontributionvalue < 100){  
                    if(buycontributionvalue >= 10){ //当买家交易贡献值小于100，大于等于10时，得分为5
                        return 5;
                    }
                    if(buycontributionvalue < 10){ 
                        if(buycontributionvalue >= 0){ //当买家交易贡献值小于10，大于等于0时，得分为0
                        return 0;
                        }
                    }
                }
            }
        }
    }

//对买家的交易总金额进行评分(20分)
    /**
     * who:买家账户地址
     */
    function TotalbuyerpaymentScore(address who) internal whenNotPaused returns (uint8) {
        totalbuyerpayment = _totalbuyerpayment[who]; //获取买家购买情报总金额
        if(totalbuyerpayment >= 20000000){  //当买家购买情报总金额大于或等于20000000时，得分为20（与交易次数的评分标准对应每次超过2000代币的交易可使买家交易贡献值加1，而贡献值=10000次时，可得满分，因此2000*10000）
            return 20;
        }
        if(totalbuyerpayment < 20000000){  
            if(totalbuyerpayment >= 2000000) {//当买家购买情报总金额小于20000000，大于或等于2000000时，得分为15
                return 15;
            }
            if(totalbuyerpayment < 2000000){  
                if(totalbuyerpayment >= 200000){ //当买家购买情报总金额小于2000000，大于或等于200000时，得分为10
                    return 10;
                }
                if(totalbuyerpayment < 200000){  
                    if(totalbuyerpayment >= 20000){ //当买家购买情报总金额小于200000，大于等于20000时，得分为5
                        return 5;
                    }
                    if(totalbuyerpayment < 20000){ 
                        if(totalbuyerpayment >= 0){ //当买家购买情报总金额小于20000，大于等于0时，得分为0
                        return 0;
                        }
                    }
                }
            }
        }
    }

//对买家的用户等级进行评分(30分)   
    /**
     * buyergrade:买家用户等级(个人：0，企业：1，国家：2)
     */
    function BuyergradeScore(uint8 buyergrade) internal view whenNotPaused returns (uint8) { 
        if(buyergrade == 0){ //当买家为个人时，得分为10
            return 10;       
        }
        if(buyergrade == 1){ //当买家为企业时，得分为20
            return 20;       
        }
        if(buyergrade == 2){ //当买家为国家时，得分为30
            return 30;       
        }
    }

//对买家进行整体打分
    /**
     *who:买家账户地址,buyergrade:买家用户等级(个人：0，企业：1，国家：2)
     */
    function BuyerTotalScore(address who, uint8 buyergrade) internal whenNotPaused returns (uint8) { 
        _buyerTotalScore = LastbuytimeScore(who) + BuycontributionvalueScore(who) + TotalbuyerpaymentScore(who) + BuyergradeScore(buyergrade); //计算买家最后得分
        return _buyerTotalScore;
    }

//对卖家的交易次数进行评分(40分)
    /**
     * who:卖家账户地址
     */
    function SellcontributionvalueScore(address who) internal whenNotPaused returns (uint8) {
        sellcontributionvalue = _sellcontributionvalue[who]; //查询卖家贡献值
        if(sellcontributionvalue >= 10000){  //当买家交易贡献值大于或等于10000时，得分为40
            return 40;
        }
        if(sellcontributionvalue < 10000){  
            if(sellcontributionvalue >= 1000) {//当买家交易贡献值小于10000，大于或等于1000时，得分为30
                return 30;
            }
            if(sellcontributionvalue < 1000){  
                if(sellcontributionvalue >= 100){ //当买家交易贡献值小于1000，大于或等于100时，得分为20
                    return 20;
                }
                if(sellcontributionvalue < 100){  
                    if(sellcontributionvalue >= 10){ //当买家交易贡献值小于100，大于等于10时，得分为10
                        return 10;
                    }
                    if(sellcontributionvalue < 10){ 
                        if(sellcontributionvalue >= 0){ //当买家交易贡献值小于10，大于等于0时，得分为0
                        return 0;
                        }
                    }
                }
            }
        }
    }
    
//对卖家的交易总金额进行评分(30分)
    /**
     * who:卖家账户地址
     */
    function TotalsellercollectionScore(address who) internal whenNotPaused returns (uint8) {
        totalsellercollection = _totalsellercollection[who]; //获取买家购买情报总金额
        if(totalsellercollection >= 20000000){  //当买家购买情报总金额大于或等于20000000时，得分为20（与交易次数的评分标准对应每次超过2000代币的交易可使买家交易贡献值加1，而贡献值=10000次时，可得满分，因此2000*10000）
            return 20;
        }
        if(totalsellercollection < 20000000){  
            if(totalsellercollection >= 2000000) {//当买家购买情报总金额小于20000000，大于或等于2000000时，得分为15
                return 15;
            }
            if(totalsellercollection < 2000000){  
                if(totalsellercollection >= 200000){ //当买家购买情报总金额小于2000000，大于或等于200000时，得分为10
                    return 10;
                }
                if(totalsellercollection < 200000){  
                    if(totalsellercollection >= 20000){ //当买家购买情报总金额小于200000，大于等于20000时，得分为5
                        return 5;
                    }
                    if(totalsellercollection < 20000){ 
                        if(totalsellercollection >= 0){ //当买家购买情报总金额小于20000，大于等于0时，得分为0
                        return 0;
                        }
                    }
                }
            }
        }
    }

//对卖家进行整体打分
    /**
     *who:卖家账户地址
     */
    function SellerTotalScore(address who) internal whenNotPaused returns (uint8) { 
        sellercreditScore = _sellercredit[who][0]; //获取卖家信用分
        _sellerTotalScore = SellcontributionvalueScore(who) + TotalsellercollectionScore(who) + sellercreditScore; //计算卖家最后得分
        return _sellerTotalScore;
    }

//计算买家和卖家返利
//计算买家返利(交易手续费*返利比例)
    /**
     *totalprice:情报总价,who:买家账户地址,buyergrade:买家用户等级(个人：0，企业：1，国家：2)
     */
    function BuyRebate(uint256 totalprice, address who, uint8 buyergrade) internal whenNotPaused returns (uint256) { 
        
        fee = totalprice / feeProportion;       //收取0.1%的手续费
        _buyerTotalScore = BuyerTotalScore(who, buyergrade);     //获取买家最后得分
        if(_buyerTotalScore <= 100){  
            if(_buyerTotalScore >= 90) {//当买家最后得分小于100，大于或等于90时，返利比例为90%
                buyrebate = fee * 9 / 10;
            }
            if(_buyerTotalScore < 90){  
                if(_buyerTotalScore >= 80){ //当买家最后得分小于90，大于或等于80时，返利比例为80%
                    buyrebate = fee * 8 / 10;
                }
                if(_buyerTotalScore < 80){  
                    if(_buyerTotalScore >= 70){ //当买家最后得分小于80，大于等于70时，返利比例为70%
                        buyrebate = fee * 7 / 10;
                    }
                    if(_buyerTotalScore < 70){ 
                        if(_buyerTotalScore >= 60){ //当买家最后得分小于70，大于等于60时，返利比例为60%
                            buyrebate = fee * 6 / 10;
                        }
                        if(_buyerTotalScore < 60){ 
                            if(_buyerTotalScore >= 50){ //当买家最后得分小于60，大于等于50时，返利比例为50%
                                buyrebate = fee * 5 / 10;
                            }
                            if(_buyerTotalScore < 50){ 
                                if(_buyerTotalScore >= 40){ //当买家最后得分小于50，大于等于40时，返利比例为40%
                                    buyrebate = fee * 4 / 10;
                                }
                                if(_buyerTotalScore < 40){ 
                                    if(_buyerTotalScore >= 30){ //当买家最后得分小于40，大于等于30时，返利比例为30%
                                        buyrebate = fee * 3 / 10;
                                    }
                                    if(_buyerTotalScore < 30){ 
                                        if(_buyerTotalScore >= 20){ //当买家最后得分小于30，大于等于20时，返利比例为20%
                                            buyrebate = fee * 2 / 10;
                                        }
                                        if(_buyerTotalScore < 20){ 
                                            if(_buyerTotalScore >= 10){ //当买家最后得分小于20，大于等于10时，返利比例为10%
                                                buyrebate = fee * 1 / 10;
                                            }
                                           if(_buyerTotalScore < 10){ 
                                               if(_buyerTotalScore >= 0){ //当买家最后得分小于10，大于等于0时，返利为0
                                                    buyrebate = 0;
                                                }
                                            }  
                                        }  
                                    }    
                                }
                            }
                        }
                    }
                }
            }
        }
        return buyrebate;
    }

//计算卖家返利(交易提成*返利比例)
    /**
     *totalprice:情报总价,who:卖家账户地址
     */
    function SellRebate(uint256 totalprice, address who) internal whenNotPaused returns (uint256) { 
        
        commission = totalprice / commissionProportion;       //收取1%的交易提成
        _sellerTotalScore = SellerTotalScore(who);     //获取卖家最后得分
        if(_sellerTotalScore <= 100){  
            if(_sellerTotalScore >= 90) {//当卖家最后得分小于100，大于或等于90时，返利比例为90%
                sellrebate = commission * 9 / 10;
            }
            if(_sellerTotalScore < 90){  
                if(_sellerTotalScore >= 80){ //当卖家最后得分小于90，大于或等于80时，返利比例为80%
                    sellrebate = commission * 8 / 10;
                }
                if(_sellerTotalScore < 80){  
                    if(_sellerTotalScore >= 70){ //当卖家最后得分小于80，大于等于70时，返利比例为70%
                        sellrebate = commission * 7 / 10;
                    }
                    if(_sellerTotalScore < 70){ 
                        if(_sellerTotalScore >= 60){ //当卖家最后得分小于70，大于等于60时，返利比例为60%
                            sellrebate = commission * 6 / 10;
                        }
                        if(_sellerTotalScore < 60){ 
                            if(_sellerTotalScore >= 50){ //当卖家最后得分小于60，大于等于50时，返利比例为50%
                                sellrebate = commission * 5 / 10;
                            }
                            if(_sellerTotalScore < 50){ 
                                if(_sellerTotalScore >= 40){ //当卖家最后得分小于50，大于等于40时，返利比例为40%
                                    sellrebate = commission * 4 / 10;
                                }
                                if(_sellerTotalScore < 40){ 
                                    if(_sellerTotalScore >= 30){ //当卖家最后得分小于40，大于等于30时，返利比例为30%
                                        sellrebate = commission * 3 / 10;
                                    }
                                    if(_sellerTotalScore < 30){ 
                                        if(_sellerTotalScore >= 20){ //当卖家最后得分小于30，大于等于20时，返利比例为20%
                                            sellrebate = commission * 2 / 10;
                                        }
                                        if(_sellerTotalScore < 20){ 
                                            if(_sellerTotalScore >= 10){ //当卖家最后得分小于20，大于等于10时，返利比例为10%
                                                sellrebate = commission * 1 / 10;
                                            }
                                           if(_sellerTotalScore < 10){ 
                                               if(_sellerTotalScore >= 0){ //当卖家最后得分小于10，大于等于0时，返利为0
                                                    sellrebate = 0;
                                                }
                                            }  
                                        }  
                                    }    
                                }
                            }
                        }
                    }
                }
            }
        }
        return sellrebate;
    }

//使用权+拥有权
//非定制数据交易的实现（交易金额的第三方托管）  (对应TxControl合约中的添加非定制数据交易函数）
    /**
     * _to:卖家账户地址,totalprice:情报总价,_from:买家账户地址
     */ 
    function beforeDataTransaction(address _to, uint256 totalprice, address _from) public whenNotPaused{
        require(!frozenAccount[_from]);             // 检查发送者账户是否冻结
        require(!frozenAccount[_to]);               // 检查接收者账户是否冻结
        buyerpayment = _Buyerpayment(totalprice);  // 计算买家付款
        _transfer(_from, address(this), buyerpayment); //将买家付款转移到合约地址中
        emit SuccessFunds(_from, true);
  }
 
//非定制数据交易的实现（交易金额转给卖家）    (对应TxControl合约中的确认非定制数据交易函数)
    /**
     * _from:买家账户地址,_to:卖家账户地址,totalprice:情报总价,buyergrade:买家用户等级
     */ 
    function afterDataTransaction(address  _from, address  _to, uint256 totalprice, uint8 buyergrade) public whenNotPaused{
        //如果确认收货
        sellercollection = _Sellercollection(totalprice);   //计算卖家收款
        //对卖家进行评分,获取手续费，计算卖家返利，卖家收款+返利=卖家实际收款
        sellercollection += SellRebate(totalprice, _to); //计算卖家实际收款
        _transfer(address(this), _to, sellercollection); //将卖家收款从合约地址转移到卖家地址
        //对买家进行评分buyergrade，获取手续费，计算买家返利（手续费*折扣），将返利发送给买家
        buyrebate = BuyRebate(totalprice, _from, buyergrade); //计算买家返利
        _transfer(address(this), _from, buyrebate); //将买家返利从合约地址转移到买家地址(再看对不对)
        _UpdateBuycontributionvalue(_from, totalprice);//更新买家贡献值
        _UpdateSellcontributionvalue(_to, totalprice);//更新卖家贡献值
        _UpdateTotalbuyerpayment(_from, totalprice); //更新买家购买情报总金额
        _UpdateTotalsellercollection(_to, totalprice);//更新卖家卖出情报总金额
        _UpdateRelatedSellercredit(_to, 2); //更新卖家成功交易次数
        //更新卖家信用值
        _IncreaseSellercredit(_to);//增加卖家信用值
        _DecreaseSellercredit(_to);//减少卖家信用值
        _UpdateLastbuytime(_from); //更新买家最近一次购买情报的时间
    }

//非定制数据交易退款（交易金额退给买家）
    /**
     * _from:买家账户地址,_to:卖家账户地址(用来修改卖家的信用值),totalprice:情报总价
     */ 
    function dataTransactionRefund(address _from, address _to, uint256 totalprice) public whenNotPaused{
        //如果买家要求退款
        buyerpayment = _Buyerpayment(totalprice);  // 计算买家付款
        _transfer( address(this), _from, buyerpayment);  //将买家付款返还给买家
        _UpdateRelatedSellercredit(_to, 1);//修改卖家退款次数
        //更新卖家信用值
        _DecreaseSellercredit(_to);//减少卖家信用值
        _IncreaseSellercredit(_to);//增加卖家信用值
    }


//实时定制交易的实现（交易金额的第三方托管） (对应TxControl合约中的购买定制数据数据交易函数）
    /**
     * addressNumber:卖家账户数量,value:每个卖家的情报价格,_from:买家账户地址
     */ 
     function beforeRealTimeTransaction(uint256 addressNumber, uint256 value, address _from) public whenNotPaused{
        require(!frozenAccount[_from]);             // 检查发送者账户是否冻结
        totalvalue = addressNumber * value;   //计算定制情报总价
        buyerpayment = _Buyerpayment(totalvalue);  // 计算买家付款
        _transfer(_from, address(this), buyerpayment); //将买家付款转移到合约地址中
        emit SuccessFunds(_from, true);
  }

//实时定制交易的实现（交易金额转给卖家）  (对应TxControl合约中的定制数据数据交易确认函数）
    /**
     * _from:买家账户地址,_to:卖家账户地址列表,value:每个卖家的情报价格,buyergrade:买家用户等级
     */ 
    function afterRealTimeTransaction(address _from, address[] memory _to, uint256 value, uint8 buyergrade) public whenNotPaused{
        for(uint256 i = 0; i < _to.length; i++){
            sellercollection = _Sellercollection(value);   //计算卖家收款
            //对卖家进行评分,获取手续费，计算卖家返利，卖家收款+返利=卖家实际收款
            sellercollection += SellRebate(value, _to[i]); //计算卖家实际收款
            _transfer(address(this), _to[i], sellercollection); //将卖家收款从合约地址转移到卖家地址
            _UpdateSellcontributionvalue(_to[i], value);//更新卖家贡献值
            _UpdateTotalsellercollection(_to[i], value);//更新卖家卖出情报总金额
            _UpdateRelatedSellercredit(_to[i], 2);//更新卖家成功交易次数
            //更新卖家信用
            _IncreaseSellercredit(_to[i]);//增加卖家信用值
            _DecreaseSellercredit(_to[i]);//减少卖家信用值
        }
        //对买家进行评分buyergrade，获取手续费，计算买家返利（手续费*折扣），将返利发送给买家
        buyrebate = BuyRebate(value * _to.length, _from, buyergrade); //计算买家返利
        _transfer(address(this), _from, buyrebate); //将买家返利从合约地址转移到买家地址(再看对不对)
        _UpdateBuycontributionvalue(_from, value * _to.length);//更新买家贡献值
        _UpdateTotalbuyerpayment(_from, value * _to.length); //更新买家购买情报总金额
        _UpdateLastbuytime(_from); //更新买家最近一次购买情报的时间
}

//实时定制交易退款（交易金额退给买家）    (对应TxControl合约中的非定制数据数据交易退款函数)
    /**
     * _from:买家账户地址,_to:卖家账户地址列表(用来修改卖家的信用值),value:每个卖家的情报价格
     */ 
    function realTimeTransactionRefund(address _from, address[] memory _to, uint256 value) public whenNotPaused{
       //如果买家要求退款
        totalvalue = _to.length * value;   //计算定制情报总价
        buyerpayment = _Buyerpayment(totalvalue);  // 计算买家付款
        _transfer( address(this), _from, buyerpayment);  //将买家付款返还给买家
        //修改卖家退款次数，卖家信用值
        for(uint256 i = 0; i < _to.length; i++){
            _UpdateRelatedSellercredit(_to[i], 1);//修改卖家退款次数
            //更新卖家信用
            _DecreaseSellercredit(_to[i]);//减少卖家信用值
            _IncreaseSellercredit(_to[i]);//增加卖家信用值
        }
    }
    
}