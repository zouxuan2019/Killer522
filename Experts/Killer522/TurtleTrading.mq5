//+------------------------------------------------------------------+
//|                                                TurtleTrading.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include "..\..\Include\Killer522\KillerHelper.mqh"
#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"

input ENUM_TIMEFRAMES TradeBarPeriod = PERIOD_D1;
string TargetSymbol="GBPUSD";
int ShortStrategyBars = 20;
int LongStrategyBars = 55;
int MaximumPosition = 4;
int CurrentEaMagic = 1105;

KillerData data;
KillerTrade trade;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   int sleepTime = KillerHelper::GetScanWaitingTime(TradeBarPeriod);
   Sleep(sleepTime * 1000);

   EventSetTimer(PeriodSeconds(TradeBarPeriod));
   DoWork();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   MqlRates totalBars[];
   double high[], low[];

   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,TradeBarPeriod,LongStrategyBars + 1);
   int totalHighCount = data.GetHighInfo(high,TargetSymbol,TradeBarPeriod,LongStrategyBars + 1);
   int totalLowCount = data.GetLowInfo(low,TargetSymbol,TradeBarPeriod,LongStrategyBars + 1);
   if(totalBarCount == 0 || totalHighCount == 0 || totalLowCount == 0)
     {
      Alert("Error copying price data ", GetLastError());
      return;
     }

   int shortHigh,shortLow,longHigh,longLow;
   shortHigh = ArrayMaximum(high, 1, ShortStrategyBars);
   shortLow = ArrayMinimum(low, 1, ShortStrategyBars);
   longHigh = ArrayMaximum(high, 1, LongStrategyBars);
   longLow = ArrayMinimum(low, 1, LongStrategyBars);

   GlobalVariableSet("ShortHigh", totalBars[shortHigh].high);
   GlobalVariableSet("ShortLow", totalBars[shortLow].low);
   GlobalVariableSet("LongHigh", totalBars[longHigh].high);
   GlobalVariableSet("LongLow", totalBars[longLow].low);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double shortHigh = (double)GlobalVariableGet("ShortHigh");
   double shortLow = (double)GlobalVariableGet("ShortLow");
   double longHigh = (double)GlobalVariableGet("LongHigh");
   double longLow = (double)GlobalVariableGet("LongLow");
   if(shortHigh > 0)
     {
      double askPrice = SymbolInfoDouble(TargetSymbol,SYMBOL_ASK);
      double bidPrice = SymbolInfoDouble(TargetSymbol,SYMBOL_BID);
      if(shortHigh > askPrice)
        {
         double lots=GetLots();
         int slPoint = GetSlPoint();
         int tpPoint = GetTpPoint();
         trade.SendBuyOrder(TargetSymbol,lots,slPoint,tpPoint,"EA Buy For Price:" + DoubleToString(askPrice,5),CurrentEaMagic);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLots()
  {
   return 0.1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSlPoint()
  {
   return 1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTpPoint()
  {
   return 1;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

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
