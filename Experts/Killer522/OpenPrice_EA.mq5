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
string TargetSymbol ="GBPUSD"; // 目标货币对
KillerData data;
KillerTrade trade;
int CurrentEaMagic = 1989;
int ATRHandle;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   int sleepTime = KillerHelper::GetScanWaitingTime(BarPeriod);
   Sleep(sleepTime * 1000);
   EventSetTimer(PeriodSeconds(BarPeriod));
   ATRHandle = iATR(TargetSymbol,BarPeriod,5); // returns a handle for ATR
   DoWork();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOpenPrice()
  {
   MqlRates totalBars[];
   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,BarPeriod,1);
   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return 0.0;
     }
   return totalBars[0].open;

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   trade.CancelPendingOrderByMagic(TargetSymbol, CurrentEaMagic);
   double ATRValue[];
   CalculateATR(ATRValue);
   double openPrice = GetOpenPrice();
   double atr = ATRValue[0];
   if(atr > 0)
     {
      Print("Current Date:" + TimeToString(TimeTradeServer(),TIME_DATE) +" ATR:"+atr);

      double targetPrice1 = openPrice + atr * 0.15;

      int slPip1 = GetSellSlPip(targetPrice1, openPrice, atr);
      int tpPip1 = GetSellTpPip(targetPrice1, openPrice, atr);
      Print("OpenPrice:"+ NormalizeDouble(openPrice,5) + "TargetPrice1:"+targetPrice1 +" sl1:"+slPip1 + " tp1:"+tpPip1);
      trade.SendPendingSellOrderByPrice(BarPeriod,TargetSymbol,targetPrice1, 0.1, slPip1, tpPip1, "EA Pending Sell price:" + DoubleToString(targetPrice1,5), CurrentEaMagic);


      double targetPrice2 = openPrice - atr * 0.15;
      int slPip2 = GetBuySlPip(targetPrice2, openPrice, atr);
      int tpPip2 = GetBuyTpPip(targetPrice2, openPrice, atr);
      Print("OpenPrice:"+ NormalizeDouble(openPrice,5) + "TargetPrice2:"+targetPrice2 +" sl2:"+slPip2 + " tp2:"+tpPip2);
      trade.SendPendingBuyOrderByPrice(BarPeriod,TargetSymbol,targetPrice2, 0.1, slPip2, tpPip2,"EA Pending Buy price:" + DoubleToString(targetPrice2,5), CurrentEaMagic);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSellSlPip(double targetPrice, double openPrice, double atr)
  {
   double slPrice = targetPrice + atr * 0.5;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (slPrice - targetPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSellTpPip(double targetPrice, double openPrice, double atr)
  {
   double tpPrice = targetPrice - atr * 0.85;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (targetPrice - tpPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetBuySlPip(double targetPrice, double openPrice, double atr)
  {
   double slPrice = targetPrice - atr * 0.50;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (targetPrice - slPrice)/symbolPipValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetBuyTpPip(double targetPrice, double openPrice, double atr)
  {
   double tpPrice = targetPrice + atr * 0.8;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);
   return (tpPrice - targetPrice)/symbolPipValue;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   DoWork();
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
