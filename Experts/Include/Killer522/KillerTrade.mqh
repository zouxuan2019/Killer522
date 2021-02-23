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
   ulong             SendImmediateBuyOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic);
   ulong             SendImmediateSellOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic);
   ulong             GetExistingOrderId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic);
   ENUM_ORDER_TYPE        GetBuyOrderTypeByPrice(double currentPrice,double targetPrice);
   ENUM_ORDER_TYPE        GetSellOrderTypeByPrice(double currentPrice,double targetPrice);
   MqlTradeRequest              GenerateBuyGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);
   MqlTradeRequest              GenerateSellGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);


public:
                     KillerTrade();
                    ~KillerTrade();
   ulong             SendBuyOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic);// prevent send duplicate order
   ulong             SendSellOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic);// prevent send duplicate order
   ulong             SendPendingBuyOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);
   ulong             SendPendingSellOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);
   int               GetOrderCountByMagic(string symbol,int magic);
   void              Buy(ENUM_TIMEFRAMES period,string symbol,double targetPrice,double lots,int slPoint,int tpPoint,int magic,bool isSetExpiration=true);
   void              Sell(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,int magic,bool isSetExpiration = true);
   void              CancelPendingOrderByMagic(string symbol,int magic=0);
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
ulong KillerTrade::SendBuyOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic)
  {

   ulong orderId = GetExistingOrderId(symbol,POSITION_TYPE_BUY,comment,magic);
   if(orderId == 0)
     {
      orderId = SendImmediateBuyOrder(symbol, lots, slPoint, tpPoint, comment, magic);
     }
   return (orderId);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendSellOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic)
  {

   ulong orderId = GetExistingOrderId(symbol,POSITION_TYPE_SELL,comment,magic);
   if(orderId == 0)
     {
      orderId=SendImmediateSellOrder(symbol, lots, slPoint, tpPoint, comment, magic);
     }
   return (orderId);
  }
//+------------------------------------------------------------------+
ulong KillerTrade::GetExistingOrderId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic)
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
ulong KillerTrade::SendImmediateBuyOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic)
  {
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   MqlTradeRequest request = GenerateBuyGeneralMqlTradeRequestInfo(symbol,ask,lots,slPoint,tpPoint,comment,magic,0);
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
ulong KillerTrade::SendImmediateSellOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic)
  {
   double price = SymbolInfoDouble(symbol,SYMBOL_BID);
   MqlTradeRequest request= GenerateSellGeneralMqlTradeRequestInfo(symbol,price,lots,slPoint,tpPoint,comment,magic,0);
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
ulong KillerTrade::SendPendingBuyOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0)
  {
   double targetBuyPrice = NormalizeDouble(price, (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   if(expiration == 0)
     {
      expiration = TimeCurrent() + (2* PeriodSeconds(period) + 60);
     }
   MqlTradeRequest request= GenerateBuyGeneralMqlTradeRequestInfo(symbol,targetBuyPrice,lots,slPoint,tpPoint,comment,magic,expiration);
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
ulong KillerTrade::SendPendingSellOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0)
  {
   double targetBuyPrice = NormalizeDouble(price, (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   if(expiration == 0)
     {
      expiration = TimeCurrent() + (2* PeriodSeconds(period) + 60);
     }
   MqlTradeRequest request= GenerateSellGeneralMqlTradeRequestInfo(symbol,targetBuyPrice,lots,slPoint,tpPoint,comment,magic,expiration);
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
MqlTradeRequest KillerTrade::GenerateBuyGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0)
  {
   MqlTradeRequest request = {0};
   request.type_filling = ORDER_FILLING_IOC;
   request.symbol = symbol;
   request.volume =lots;
   request.price = price;
   request.deviation=3;
   long minStopsLevle = SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double symbolPointValue = data.GetSymbolPoint(symbol);
   if(slPoint > minStopsLevle)
     {
      request.sl=price - slPoint * symbolPointValue;
     }

   if(tpPoint > minStopsLevle)
     {
      request.tp= price + tpPoint * symbolPointValue;
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
//|                                                                  |
//+------------------------------------------------------------------+
MqlTradeRequest KillerTrade::GenerateSellGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0)
  {
   MqlTradeRequest request = {0};
   request.type_filling = ORDER_FILLING_IOC;
   request.symbol = symbol;
   request.volume =lots;
   request.price = price;
   request.deviation=3;
   long minStopsLevle = SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double symbolPointValue = data.GetSymbolPoint(symbol);
   if(slPoint > minStopsLevle)
     {
      request.sl=price + slPoint * symbolPointValue;
     }

   if(tpPoint > minStopsLevle)
     {
      request.tp= price - tpPoint * symbolPointValue;
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
         if(selectedSymbol == symbol
            && selectedMagic == magic)
           {
            count++;
           }
        }
     }
   return(count);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerTrade::Buy(ENUM_TIMEFRAMES period,string targetSymbol,double targetPrice,double lots,int slPoint,int tpPoint,int magic,bool isSetExpiration=true)
  {
   double currentPrice = SymbolInfoDouble(targetSymbol,SYMBOL_ASK);
   if(currentPrice <= targetPrice) // Need to confirm with JL
     {
      Print("CurrentPrice:"+currentPrice+" Target price:"+ targetPrice);
      SendBuyOrder(targetSymbol,lots,slPoint,tpPoint,"EA Buy For Price:" + DoubleToString(targetPrice,5),magic);
     }
   else
     {
      Print("Pending order target price:" + targetPrice);
      datetime expiration;
      if(!isSetExpiration)
        {
         expiration = TimeCurrent() + (60 * 60 * 24 * 365 *1); //expire after 100 years
        }
      SendPendingBuyOrderByPrice(period,targetSymbol,targetPrice,lots,slPoint,tpPoint,"EA Pending Order price:" + DoubleToString(targetPrice,5),magic,expiration);
     }
  }

//+------------------------------------------------------------------+
void KillerTrade::Sell(ENUM_TIMEFRAMES period,string targetSymbol,double targetPrice,double lots,int slPoint,int tpPoint,int magic,bool isSetExpiration=true)
  {

   double currentPrice = SymbolInfoDouble(targetSymbol,SYMBOL_BID);
   if(currentPrice >= targetPrice)
     {
      Print("CurrentPrice:"+currentPrice+" Target price:"+ targetPrice);
      SendSellOrder(targetSymbol,lots,slPoint,tpPoint,"EA Sell For Price:" + DoubleToString(targetPrice,5),magic);
     }
   else
     {
      int expiration = 0;
      Print("Pending order Target price:" + targetPrice);
      if(!isSetExpiration)
        {
         expiration = TimeCurrent() + (60 * 60 * 24 * 365 *1); //expire after 1 year
        }
      SendPendingSellOrderByPrice(period,targetSymbol,targetPrice,lots,slPoint,tpPoint,"EA Pending Sell Order price:" + DoubleToString(targetPrice,5),magic,expiration);
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


//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
