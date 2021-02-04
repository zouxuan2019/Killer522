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
input int      AnalyzeWeekDays = 14;//分析天数
input double StopLevel = 12;//止损
input double TakeProfit = 8;//止盈
input ENUM_TIMEFRAMES BarPeriod = PERIOD_M15;//K线周期

int magic = 8941;
int continueBarCount = 3;

KillerData data;
MqlRates rates[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
//1. Get 14*24*60/15 M15 bars data
   int totalBarCount = data.GetPriceInfo(rates,Symbol(),BarPeriod,AnalyzeWeekDays);
   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
//2. Find bars with low price less than open (rising)/close(falling) 5 points
//3. Find the 3rd bar which continue increase, get the close price

   MqlRates matchBars[continueBarCount];
   int matchBarCount = getMatchBar(matchBars,rates,totalBarCount);
   if(matchBarCount == continueBarCount)
     {
      //4. Send buy order when the prices reaches the close price in #3
     }
  }

//5. Delete order when the price increase to tp or decrease to sl
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMatchBar(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {
   int matchBarCount = 0;
   for(int i = 0; i < totalBarCount; i++)
     {
      if(matchBarCount == continueBarCount)
        {
         break;
        }

      if(IsCandleWithLongLowLine(rates[i]))
        {
         if(IsLowPriceLowerThanLaterBar(rates[i],matchBars,matchBarCount))
           {
            matchBars[matchBarCount]=rates[i];
            matchBarCount++;
            continue;
           }
         else
           {
            break;
           }
        }
     }
   return matchBarCount;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsLowPriceLowerThanLaterBar(MqlRates &currentBar, MqlRates &foundBars[],int foundCount)
  {
   if(foundCount == 0)
     {
      return (true);
     }
   MqlRates compareBar=foundBars[foundCount-1];
   return (currentBar.low < compareBar.low);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsCandleWithLongLowLine(MqlRates &rate)
  {
   double longLowLineThreshold = 0.0005;
   if(IsRisingCandle(rate) && rate.open-rate.low >= longLowLineThreshold)
     {
      return (true);
     }

   if(!IsRisingCandle(rate) && rate.close-rate.low >= longLowLineThreshold)
     {
      return (true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsRisingCandle(MqlRates &rate)
  {
   return (rate.open < rate.close);
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

//+------------------------------------------------------------------+
