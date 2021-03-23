//+------------------------------------------------------------------+
//|                                                 OpenPrice_EA.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"
#include "..\..\Include\Killer522\KillerHelper.mqh"
//--- input parameters
input ENUM_TIMEFRAMES BarPeriod = PERIOD_D1;//K线周期
input string TargetSymbol ="GBPUSD"; // 目标货币对
KillerData data;
KillerTrade trade;
int CurrentEaMagic = 1989;
int ATRHandle;
int MaximumTrade = 1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetCurrentDayOpenPrice();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetCurrentDayOpenPrice()
  {
   ATRHandle = iATR(TargetSymbol,BarPeriod,4); // returns a handle for ATR
   MqlRates totalBars[];
   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,BarPeriod,1);
   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
   GlobalVariableSet("OpenPrice", totalBars[0].open);
   GlobalVariableSet("CurrentDate", TimeToString(TimeTradeServer(),TIME_DATE));
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateATR(double &ATRValue[])
  {
   ENUM_TIMEFRAMES      MA_Period = BarPeriod;               // The value of the averaging period for the indicator calculation
   int Count = 2;                    // Amount to copy
   ArraySetAsSeries(ATRValue,true);       // Set the ATRValue to timeseries, 0 is the oldest.
   if(CopyBuffer(ATRHandle,0,0,Count,ATRValue) > 0)     // Copy value of ATR to ATRValue
     {
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsDateChanged()
  {
   string lastStoredDate = GlobalVariableGet("CurrentDate");
   string currentDate = TimeToString(TimeTradeServer(),TIME_DATE);
   return lastStoredDate == currentDate;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(IsDateChanged())
     {
      SetCurrentDayOpenPrice();
      trade.CancelPendingOrderByMagic(TargetSymbol, CurrentEaMagic);
     }
   DoWork();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   Print("Current bar period:" + BarPeriod);
   int existingOrderCount = trade.GetOrderCountByMagic(TargetSymbol,CurrentEaMagic);
   Print("Existing Order Count :" + existingOrderCount);
   if(existingOrderCount >= MaximumTrade)
     {
      Print("Existing Order Count is  " + existingOrderCount +",Skip current scan");
      return;
     }
   double ATRValue[];
   CalculateATR(ATRValue);
   double ask = SymbolInfoDouble(TargetSymbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(TargetSymbol,SYMBOL_BID);
   double openPrice = double(GlobalVariableGet("OpenPrice"));
   double atr = ATRValue[0];
   if(bid > openPrice)
     {
      double targetPrice = openPrice + atr * 0.15;
      int slPip = GetSellSlPip(targetPrice, openPrice, atr);
      int tpPip = GetSellTpPip(targetPrice, openPrice, atr);
      trade.Sell(BarPeriod,TargetSymbol,targetPrice, 0.1, slPip, tpPip, CurrentEaMagic,true);
     }
     
   if(ask < openPrice)
     {
      double targetPrice = openPrice - atr * 0.15;
      int slPip = GetBuySlPip(targetPrice, openPrice, atr);
      int tpPip = GetBuyTpPip(targetPrice, openPrice, atr);
      trade.Buy(BarPeriod,TargetSymbol,targetPrice, 0.1, slPip, tpPip, CurrentEaMagic,true);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSellSlPip(double targetPrice, double openPrice, double atr)
  {
   double slPrice = openPrice + atr * 0.382;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (slPrice - targetPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSellTpPip(double targetPrice, double openPrice, double atr)
  {
   double tpPrice = openPrice - atr * 0.618;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (targetPrice - tpPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetBuySlPip(double targetPrice, double openPrice, double atr)
  {
   double slPrice = openPrice - atr * 0.382;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (targetPrice - slPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetBuyTpPip(double targetPrice, double openPrice, double atr)
  {
   double tpPrice = openPrice + atr * 0.618;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (tpPrice - targetPrice)/symbolPipValue;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
