//+------------------------------------------------------------------+
//|                                                  KillerTrade.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "KillerData.mqh"
class KillerTrade
  {

private:
   KillerData        data;
   ulong             SendImmediateBuyOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic);
   ulong             SendImmediateSellOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic);
   ulong             GetExistingPositionId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic);
   ulong             GetExistingPendingOrderId(string symbol,ENUM_ORDER_TYPE orderType,string comment,int magic);
   ENUM_ORDER_TYPE        GetBuyOrderTypeByPrice(double currentPrice,double targetPrice);
   ENUM_ORDER_TYPE        GetSellOrderTypeByPrice(double currentPrice,double targetPrice);
   MqlTradeRequest              GenerateBuyGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0);
   MqlTradeRequest              GenerateSellGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0);


public:
                     KillerTrade();
                    ~KillerTrade();
   ulong             SendBuyOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic);// prevent send duplicate order
   ulong             SendSellOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic);// prevent send duplicate order
   ulong             SendPendingBuyOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0);
   ulong             SendPendingSellOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0);
   int               GetOrderCountByMagic(string symbol,int magic);
   int               DoesPositionExistByMagic(string symbol,int magic);
   int               DoesPositionExistByMagic(string symbol,int magic,ENUM_POSITION_TYPE type);
   void              Buy(ENUM_TIMEFRAMES period,string symbol,double targetPrice,double lots,int slPip,int tpPip,int magic,bool isSetExpiration=true);
   void              Sell(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPip,int tpPip,int magic,bool isSetExpiration = true);
   void              CancelPendingOrderByMagic(string symbol,int magic=0);
   bool              HasReachedMaximumPosition(string symbol, int magic, int maxPos);
   void              CloseAllBuy(string symbol,int magic=0,string comment="");
   void              CloseAllSell(string symbol,int magic=0,string comment="");
   void              CloseAll(string symbol,int magic);
   double            GetWinRatio(string symbol);
   double            GetLotsByKellyCriterion(double winProbility, int tpPoint, int slPoint);
   void              ModifySl(string symbol, ENUM_POSITION_TYPE type,double slPrice,int magic=0);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
KillerTrade::KillerTrade()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
KillerTrade::~KillerTrade()
  {
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendBuyOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic)
  {
   ulong orderId = GetExistingPositionId(symbol,POSITION_TYPE_BUY,comment,magic);
   if(orderId == 0)
     {
      orderId = SendImmediateBuyOrder(symbol, lots, slPip, tpPip, comment, magic);
     }
   return (orderId);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendSellOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic)
  {

   ulong orderId = GetExistingPositionId(symbol,POSITION_TYPE_SELL,comment,magic);
   if(orderId == 0)
     {
      orderId=SendImmediateSellOrder(symbol, lots, slPip, tpPip, comment, magic);
     }
   return (orderId);
  }
//+------------------------------------------------------------------+
ulong KillerTrade::GetExistingPositionId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic)
  {
   int totalPositionNumber = PositionsTotal();
   for(int i = totalPositionNumber - 1; i > 0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_TYPE) == positionType
            && PositionGetInteger(POSITION_MAGIC) == magic && PositionGetString(POSITION_COMMENT)==comment)
           {
            return (i);
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendImmediateBuyOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic)
  {
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   MqlTradeRequest request = GenerateBuyGeneralMqlTradeRequestInfo(symbol,ask,lots,slPip,tpPip,comment,magic,0);
   MqlTradeResult result = {0};
   request.action = TRADE_ACTION_DEAL;
   request.type = ORDER_TYPE_BUY;

   if(!OrderSend(request,result))
     {
      PrintFormat("OrderSend error %d", GetLastError());
     }

   PrintFormat("OrderSend: retcode=%u deal %I64u order = %I64u",result.retcode,result.deal,result.order);
   return(result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendImmediateSellOrder(string symbol,double lots,int slPip,int tpPip,string comment,int magic)
  {
   double price = SymbolInfoDouble(symbol,SYMBOL_BID);
   MqlTradeRequest request= GenerateSellGeneralMqlTradeRequestInfo(symbol,price,lots,slPip,tpPip,comment,magic,0);
   MqlTradeResult result = {0};
   request.action = TRADE_ACTION_DEAL;
   request.type = ORDER_TYPE_SELL;

   if(!OrderSend(request,result))
     {
      PrintFormat("OrderSend error %d", GetLastError());
     }

   PrintFormat("OrderSend: retcode=%u deal %I64u order = %I64u",result.retcode,result.deal,result.order);
   return(result.order);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendPendingBuyOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0)
  {
   ulong orderId = GetExistingPendingOrderId(symbol,ORDER_TYPE_BUY_LIMIT,comment,magic);
   if(orderId>0)
     {
      return 0;
     }
   double targetBuyPrice = NormalizeDouble(price, (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   if(expiration == 0)
     {
      expiration = TimeTradeServer() + (2* PeriodSeconds(period) + 60);
      Print("Expiration0:" +data.GetDateTimeString(expiration));
     }
   else
     {
      Print("Expiration1:" +data.GetDateTimeString(expiration));
     }

   MqlTradeRequest request= GenerateBuyGeneralMqlTradeRequestInfo(symbol,targetBuyPrice,lots,slPip,tpPip,comment,magic,expiration);
   request.action = TRADE_ACTION_PENDING;
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   request.type = GetBuyOrderTypeByPrice(ask,price);
   MqlTradeResult result = {0};
   if(!OrderSend(request,result))
     {
      PrintFormat("OrderSend error %d", GetLastError());
     }

   PrintFormat("OrderSend: retcode=%u deal %I64u order = %I64u",result.retcode,result.deal,result.order);
   return(result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendPendingSellOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0)
  {
   ulong orderId = GetExistingPendingOrderId(symbol,ORDER_TYPE_SELL_LIMIT,comment,magic);
   if(orderId>0)
     {
      return 0;
     }
   double targetBuyPrice = NormalizeDouble(price, (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   if(expiration == 0)
     {
      expiration = TimeTradeServer() + (2* PeriodSeconds(period) + 60);
     }
   MqlTradeRequest request= GenerateSellGeneralMqlTradeRequestInfo(symbol,targetBuyPrice,lots,slPip,tpPip,comment,magic,expiration);
   request.action = TRADE_ACTION_PENDING;
   double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
   request.type = GetSellOrderTypeByPrice(bid,price);
   MqlTradeResult result = {0};
   if(!OrderSend(request,result))
     {
      PrintFormat("OrderSend error %d", GetLastError());
     }

   PrintFormat("OrderSend: retcode=%u deal %I64u order = %I64u",result.retcode,result.deal,result.order);
   return(result.order);
  }

//+------------------------------------------------------------------+
//| Checks if the specified expiration mode is allowed               |
//+------------------------------------------------------------------+
bool IsExpirationTypeAllowed(string symbol,int exp_type)
  {
//--- Obtain the value of the property that describes allowed expiration modes
   int expiration=(int)SymbolInfoInteger(symbol,SYMBOL_EXPIRATION_MODE);
//--- Return true, if mode exp_type is allowed
   return((expiration&exp_type)==exp_type);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE KillerTrade::GetBuyOrderTypeByPrice(double currentPrice,double targetPrice)
  {
   if(targetPrice > currentPrice)
     {
      return ORDER_TYPE_BUY_STOP;
     }
   return ORDER_TYPE_BUY_LIMIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE KillerTrade::GetSellOrderTypeByPrice(double currentPrice,double targetPrice)
  {
   if(targetPrice > currentPrice)
     {
      return ORDER_TYPE_SELL_LIMIT;
     }
   return ORDER_TYPE_SELL_STOP;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MqlTradeRequest KillerTrade::GenerateBuyGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0)
  {
   MqlTradeRequest request = {0};
   request.type_filling = ORDER_FILLING_IOC;
   request.symbol = symbol;
   request.volume =lots;
   request.price = price;
   request.deviation=30;
   long minStopsLevel = SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double symbolPipValue = data.GetSymbolPip(symbol);
   Print("SL Pip:" + slPip+" minStopsLevel:" + minStopsLevel);
   double slPoints = slPip * symbolPipValue;
   double tpPoints= tpPip * symbolPipValue;
   if(slPip > minStopsLevel)
     {
      Print("Order Price"+ DoubleToString(price,5)+ "slPoints:"+ DoubleToString(slPoints,5));
      request.sl = price - slPoints;
     }
   else
     {
      request.sl = price - minStopsLevel * symbolPipValue;
     }

   if(tpPip > minStopsLevel)
     {
      request.tp = price + tpPoints;
     }
   else
     {
      if(tpPip>0)
        {
         request.tp = price + minStopsLevel * symbolPipValue;
        }
     }
   Print("Order SL Price"+ DoubleToString(request.sl,5));
   request.comment = comment;
   request.magic = magic;

   if(expiration > 0)
     {
      request.type_time = ORDER_TIME_SPECIFIED;
      request.expiration = expiration;
     }
   return request;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MqlTradeRequest KillerTrade::GenerateSellGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPip,int tpPip,string comment,int magic,datetime expiration=0)
  {
   MqlTradeRequest request = {0};
   request.type_filling = ORDER_FILLING_IOC;
   request.symbol = symbol;
   request.volume =lots;
   request.price = NormalizeDouble(price,_Digits);
   request.deviation=3;
   long minStopsLevel = SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double symbolPipValue = data.GetSymbolPip(symbol);
   double slPoints = slPip * symbolPipValue;
   double tpPoints= tpPip * symbolPipValue;
   if(slPip > minStopsLevel)
     {
      Print("Order Price"+ DoubleToString(price,5)+ "slPoints:"+ DoubleToString(slPoints,5));
      request.sl = price + slPoints;
     }
   else
     {
      request.sl = price + minStopsLevel * symbolPipValue;
     }

   if(tpPip > minStopsLevel)
     {
      request.tp = price - tpPoints;
     }
   else
     {
      if(tpPip > 0)
        {

         request.tp = price - minStopsLevel * symbolPipValue;
        }
     }
   request.comment = comment;
   request.magic =magic;

   if(expiration > 0)
     {
      request.type_time = ORDER_TIME_SPECIFIED;
      request.expiration = expiration;
     }
   return request;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerTrade::GetOrderCountByMagic(string symbol,int magic)
  {
   int count=0;
   int totalPositionNumber = PositionsTotal();
   for(int i = totalPositionNumber - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         int selectedMagic=PositionGetInteger(POSITION_MAGIC);
         string selectedSymbol=PositionGetString(POSITION_SYMBOL);
         if(selectedSymbol == symbol && (selectedMagic == magic || magic==0))
           {
            count++;
           }
        }
     }
   return(count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerTrade::DoesPositionExistByMagic(string symbol,int magic, ENUM_POSITION_TYPE type)
  {
   int totalPositionNumber = PositionsTotal();
   for(int i = totalPositionNumber - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         int selectedMagic=PositionGetInteger(POSITION_MAGIC);
         string selectedSymbol=PositionGetString(POSITION_SYMBOL);
         if(selectedSymbol == symbol && PositionGetInteger(POSITION_TYPE) == type && (selectedMagic == magic || magic==0))
           {
            return true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
int KillerTrade::DoesPositionExistByMagic(string symbol,int magic)
  {
   int totalPositionNumber = PositionsTotal();
   for(int i = totalPositionNumber - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         int selectedMagic=PositionGetInteger(POSITION_MAGIC);
         string selectedSymbol=PositionGetString(POSITION_SYMBOL);
         if(selectedSymbol == symbol && (selectedMagic == magic || magic==0))
           {
            return true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::Buy(ENUM_TIMEFRAMES period,string targetSymbol,double targetPrice,double lots,int slPip,int tpPip,int magic,bool isSetExpiration=true)
  {
   double currentPrice = SymbolInfoDouble(targetSymbol,SYMBOL_ASK);
   if(currentPrice <= targetPrice)
     {
      Print("CurrentPrice:" + currentPrice + " Target price:" + targetPrice);
      SendBuyOrder(targetSymbol,lots,slPip,tpPip,"EA Buy For Price:" + DoubleToString(targetPrice,5),magic);
     }
   else
     {
      Print("Pending order target price:" + targetPrice);
      int expiration = 0;
      if(!isSetExpiration)
        {
         expiration = TimeTradeServer() + (60 * 60 * 24 * 365); //expire after 1 year
         Print("Set Expiration to 1 year:" + data.GetDateTimeString(expiration));
        }
      else
        {
         Print("setExpiration" + data.GetDateTimeString(expiration));
        }
      SendPendingBuyOrderByPrice(period,targetSymbol,targetPrice,lots,slPip,tpPip,"EA Pending Buy price:" + DoubleToString(targetPrice,5),magic,expiration);
     }
  }

//+------------------------------------------------------------------+
void KillerTrade::Sell(ENUM_TIMEFRAMES period,string targetSymbol,double targetPrice,double lots,int slPip,int tpPip,int magic,bool isSetExpiration=true)
  {

   double currentPrice = SymbolInfoDouble(targetSymbol,SYMBOL_BID);
   if(currentPrice >= targetPrice)
     {
      Print("CurrentPrice:"+currentPrice+" Target price:"+ targetPrice);
      SendSellOrder(targetSymbol,lots,slPip,tpPip,"EA Sell For Price:" + DoubleToString(targetPrice,5),magic);
     }
   else
     {
      int expiration = 0;
      Print("Pending order Target price:" + targetPrice);
      if(!isSetExpiration)
        {
         expiration = TimeTradeServer() + (60 * 60 * 24 * 365 *1); //expire after 1 year
        }
      SendPendingSellOrderByPrice(period,targetSymbol,targetPrice,lots,slPip,tpPip,"EA Pending Sell price:" + DoubleToString(targetPrice,5),magic,expiration);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::CancelPendingOrderByMagic(string symbol,int magic=0)
  {
   int t=OrdersTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==symbol)
        {
         if(magic==0 || OrderGetInteger(ORDER_MAGIC) == magic)
           {
            MqlTradeRequest request= {0};
            MqlTradeResult  result= {0};
            request.action=TRADE_ACTION_REMOVE;
            request.order=OrderGetTicket(i);
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::GetExistingPendingOrderId(string symbol,ENUM_ORDER_TYPE orderType,string comment,int magic)
  {
   int t=OrdersTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_TYPE) == orderType)
        {
         if(magic==0 || OrderGetInteger(ORDER_MAGIC) == magic)
           {
            return (i);
           }
        }
     }
   return (0);
  }
//+------------------------------------------------------------------+
bool KillerTrade::HasReachedMaximumPosition(string symbol, int magic, int maxPos)
  {
   int existingOrderCount = GetOrderCountByMagic(symbol, magic);
   return (existingOrderCount >= maxPos);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::CloseAllBuy(string symbol,int magic=0, string comment="")
  {
   Print("Close All Buy");
   int t = PositionsTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY
            && (magic==0 || (PositionGetInteger(POSITION_MAGIC)==magic)))
           {
            MqlTradeRequest request= {0};
            MqlTradeResult  result= {0};
            request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
            request.symbol   =symbol;                              // 交易品种
            request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
            request.type     =ORDER_TYPE_SELL;                        // 订单类型
            request.price    =SymbolInfoDouble(symbol,SYMBOL_BID); // 持仓价格
            request.type_filling=ORDER_FILLING_IOC;
            request.deviation=100; // 允许价格偏差
            request.position =PositionGetTicket(i);
            request.comment = comment;
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());   // 如果不能发送请求，输出错误

           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::CloseAllSell(string symbol,int magic=0,string comment="")
  {
   Print("Close All Sell");
   int t=PositionsTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && (magic==0 || (PositionGetInteger(POSITION_MAGIC)==magic)))
           {
            MqlTradeRequest request= {0};
            MqlTradeResult  result= {0};
            request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
            request.symbol   =symbol;                              // 交易品种
            request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
            request.type     =ORDER_TYPE_BUY;                        // 订单类型
            request.price    =SymbolInfoDouble(symbol,SYMBOL_ASK); // 持仓价格
            request.deviation=100; // 允许价格偏差
            request.type_filling=ORDER_FILLING_IOC;
            request.position =PositionGetTicket(i);
            request.comment = comment;
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());   // 如果不能发送请求，输出错误
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::CloseAll(string symbol,int magic=0)
  {
   int t=PositionsTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            if(magic==0)
              {
               MqlTradeRequest request= {0};
               MqlTradeResult  result= {0};
               request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
               request.symbol   =symbol;                              // 交易品种
               request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
               request.type     =ORDER_TYPE_SELL;                        // 订单类型
               request.price    =SymbolInfoDouble(symbol,SYMBOL_BID); // 持仓价格
               request.deviation=100; // 允许价格偏差
               request.type_filling=ORDER_FILLING_IOC;
               request.position =PositionGetTicket(i);
               if(!OrderSend(request,result))
                  PrintFormat("OrderSend error %d",GetLastError());   //
              }
            else
              {
               if(PositionGetInteger(POSITION_MAGIC)==magic)
                 {
                  MqlTradeRequest request= {0};
                  MqlTradeResult  result= {0};
                  request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
                  request.symbol   =symbol;                              // 交易品种
                  request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
                  request.type     =ORDER_TYPE_SELL;                        // 订单类型
                  request.price    =SymbolInfoDouble(symbol,SYMBOL_BID); // 持仓价格
                  request.deviation=100; // 允许价格偏差
                  request.type_filling=ORDER_FILLING_IOC;
                  request.position =PositionGetTicket(i);
                  if(!OrderSend(request,result))
                     PrintFormat("OrderSend error %d",GetLastError());
                 }
              }
           }
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
           {
            if(magic==0)
              {
               MqlTradeRequest request= {0};
               MqlTradeResult  result= {0};
               request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
               request.symbol   =symbol;                              // 交易品种
               request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
               request.type     =ORDER_TYPE_BUY;                        // 订单类型
               request.price    =SymbolInfoDouble(symbol,SYMBOL_ASK); // 持仓价格
               request.deviation=100; // 允许价格偏差
               request.type_filling=ORDER_FILLING_IOC;
               request.position =PositionGetTicket(i);
               if(!OrderSend(request,result))
                  PrintFormat("OrderSend error %d",GetLastError());   // 如果不能发送请求，输出错误
              }
            else
              {
               if(PositionGetInteger(POSITION_MAGIC)==magic)
                 {
                  MqlTradeRequest request= {0};
                  MqlTradeResult  result= {0};
                  request.action   =TRADE_ACTION_DEAL;                     // 交易操作类型
                  request.symbol   =symbol;                              // 交易品种
                  request.volume   =PositionGetDouble(POSITION_VOLUME); // 0.1手交易量
                  request.type     =ORDER_TYPE_BUY;                        // 订单类型
                  request.price    =SymbolInfoDouble(symbol,SYMBOL_ASK); // 持仓价格
                  request.deviation=100; // 允许价格偏差
                  request.type_filling=ORDER_FILLING_IOC;
                  request.position =PositionGetTicket(i);
                  if(!OrderSend(request,result))
                     PrintFormat("OrderSend error %d",GetLastError());
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double KillerTrade::GetWinRatio(string symbol)
  {
   double ret=0.0;
   int win=0, loss=0;
//--- request trade history
   HistorySelect(0, TimeTradeServer());
   uint    total = HistoryDealsTotal();
   ulong    ticket=0;
//--- for all deals
   for(uint i = 0; i < total; i++)
     {
      //--- try to get deals ticket
      if((ticket = HistoryDealGetTicket(i))>0)
        {
         //--- get deals properties
         int id = HistoryDealGetInteger(ticket, DEAL_ORDER);
         int entry_type = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         double profit=HistoryDealGetDouble(ticket, DEAL_PROFIT);
         bool isWin = (profit > 0);
         Print("Order:" + id + "Profit:" + profit + "Win:" + isWin);
         //--- only for current symbol
         int entry_out = DEAL_ENTRY_OUT;
         if(symbol == symbol && entry_type == DEAL_ENTRY_OUT)
           {
            if(profit>0)
              {
               win++;
              }
            else
              {
               loss++;
              }
           }
        }
     }

   ret = (win+loss == 0) ? 1.0 : ((double)win / (win+loss));
   Print("Win/Total:" + ret);
   return(ret);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double KillerTrade::GetLotsByKellyCriterion(double winProbility, int tpPoint, int slPoint)
  {
   double winLossRatio = (double)tpPoint/slPoint;
   double f = winProbility - (1-winProbility)/winLossRatio;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maximumLost = f * balance;
   double lots = (double) maximumLost / (slPoint * 10);
   return lots;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::ModifySl(string symbol, ENUM_POSITION_TYPE type,double slPrice,int magic=0)
  {
   int t=PositionsTotal();
   for(int i=t-1; i>=0; i--)
     {
      if(PositionGetTicket(i) > 0 && PositionGetString(POSITION_SYMBOL)==symbol && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
        {
         MqlTradeRequest request = {0};
         MqlTradeResult  result = {0};
         request.action = TRADE_ACTION_SLTP;
         request.position = PositionGetTicket(i);
         request.symbol = symbol;
         request.sl = NormalizeDouble(slPrice,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
        }

     }
  }
//+------------------------------------------------------------------+
