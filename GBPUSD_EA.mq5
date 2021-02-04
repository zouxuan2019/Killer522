//+------------------------------------------------------------------+
//|                                                    GBPUSD_EA.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "..\..\Include\Killer522\KillerData.mqh"
//--- input parameters
input int      AnalyzeWeekDays=14;//分析天数
input double StopLevel=12;//止损
input double TakeProfit=8;//止盈
input ENUM_TIMEFRAMES BarPeriod=PERIOD_M15;//K线周期

KillerData data;
MqlRates rates[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
//1. Get 14*24*60/15 M15 bars data
   int barCount=data.GetPriceInfo(rates,Symbol(),BarPeriod,AnalyzeWeekDays);
   if(barCount==0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
//2. Find bars with low price less than open (yang)/close(yin) 5 points
   MqlRates targetBars[3];
   for(int i=0; i<barCount; i++)
     {
      if(IsRisingCandle(rates[i]))
        {
        }
      //3. Find the 3rd bar which continue increase, get the close price
      //4. Send buy order when the prices reaches the close price in #3
      //5. Delete order when the price increase to tp or decrease to sl


     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool IsRisingCandle(MqlRates rate)
     {
      return (rate.open<rate.close);
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   void OnDeinit(const int reason)
     {

     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   void OnTick()
     {


     }

//+------------------------------------------------------------------+
   
