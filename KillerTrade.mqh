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
   ulong             GetExistingOrderId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic);
   ENUM_ORDER_TYPE        GetOrderTypeByPrice(double currentPrice,double targetPrice);
   MqlTradeRequest              GenerateBuyGeneralMqlTradeRequestInfo(string symbol, double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);


public:
                     KillerTrade();
                    ~KillerTrade();
   ulong             SendBuyOrder(string symbol,double lots,int slPoint,int tpPoint,string comment,int magic);// prevent send duplicate order
   ulong             SendPendingOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0);
   int               GetOrderCountByMagic(string symbol,int magic);
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

   ulong orderId=GetExistingOrderId(symbol,POSITION_TYPE_BUY,comment,magic);
   if(orderId==0)
     {
      orderId=SendImmediateBuyOrder(symbol, lots, slPoint, tpPoint, comment, magic);
     }
   return (orderId);
  }


//+------------------------------------------------------------------+
ulong KillerTrade::GetExistingOrderId(string symbol,ENUM_POSITION_TYPE positionType,string comment,int magic)
  {
   int totalPositionNumber = PositionsTotal();
   for(int i=totalPositionNumber - 1; i > 0; i--)
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
   MqlTradeRequest request= GenerateBuyGeneralMqlTradeRequestInfo(symbol,ask,lots,slPoint,tpPoint,comment,magic,0);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong KillerTrade::SendPendingOrderByPrice(ENUM_TIMEFRAMES period,string symbol,double price,double lots,int slPoint,int tpPoint,string comment,int magic,datetime expiration=0)
  {
   double targetBuyPrice = NormalizeDouble(price, (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   expiration = TimeCurrent() + (2* PeriodSeconds(period) + 60);
   MqlTradeRequest request= GenerateBuyGeneralMqlTradeRequestInfo(symbol,targetBuyPrice,lots,slPoint,tpPoint,comment,magic,expiration);
   request.action = TRADE_ACTION_PENDING;
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   request.type = GetOrderTypeByPrice(ask,price);
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
ENUM_ORDER_TYPE KillerTrade::GetOrderTypeByPrice(double currentPrice,double targetPrice)
  {
   if(targetPrice > currentPrice)
     {
      return ORDER_TYPE_BUY_STOP;
     }
   return ORDER_TYPE_BUY_LIMIT;
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
