//+------------------------------------------------------------------+
//|                                                    GBPUSD_EA.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"
//--- input parameters
input int      AnalyzeWeekDays = 15;//分析天数
input int StopLevelPoint = 19;//止损点数
input int TakeProfitPoint = 25;//止盈点数
input ENUM_TIMEFRAMES BarPeriod = PERIOD_M30;//K线周期
input string targetSymbol ="GBPUSD"; // 目标货币对

int continueRaiseBarCount = 3; // 3 continue rasing bar
int longLowLineDef = 5;

KillerData data;
KillerTrade trade;
int currentEaMagic=8941;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   int sleepTime=GetScanWaitingTime();
   Sleep(sleepTime*1000);
   EventSetTimer(PeriodSeconds(BarPeriod));
   DoWork();
//---
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetScanWaitingTime()
  {
   int interval =PeriodSeconds(BarPeriod);
   datetime currentDate = TimeLocal();
   int result=interval- (int)currentDate % interval + 60;
   return (result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMatchBar(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {
   int matchBarCount = 0;
   if(!IsCandleWithLongLowLine(totalBars[1]))// If previous bar doesn't have long low line, then discard the order
     {
      return (matchBarCount);
     }
   int matchBarIndexs[];
   ArrayResize(matchBarIndexs,continueRaiseBarCount);

   for(int i = 1; i < totalBarCount; i++)
     {
      if(matchBarCount == continueRaiseBarCount)
        {
         break;
        }

      if(IsCandleWithLongLowLine(totalBars[i]))
        {
         if(IsLowPriceLowerThanLaterBar(totalBars,i,matchBars,matchBarCount,matchBarIndexs))
           {
            matchBars[matchBarCount] = totalBars[i];
            matchBarIndexs[matchBarCount] = i;
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
bool IsLowPriceLowerThanLaterBar(MqlRates &totalBars[],int currentIndex, MqlRates &matchedBars[],int foundCount, int &matchBarIndex[])
  {
   if(foundCount == 0)
     {
      return (true);
     }
   int compareBarIndex = matchBarIndex[foundCount-1];
   MqlRates compareBar = matchedBars[foundCount-1];
   bool isRaisingTrend = IsPriceInTheMiddleHigerThanPreviousBar(totalBars, currentIndex, compareBarIndex);
   bool result=(totalBars[currentIndex].low < compareBar.low) && isRaisingTrend;
   return (result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceInTheMiddleHigerThanPreviousBar(MqlRates &totalBars[],int currentIndex,int compareBarIndex)
  {
   bool result = true;
   for(int i = compareBarIndex+1; i <= currentIndex; i++)
     {
      if(totalBars[i].low < totalBars[currentIndex].low)
        {
         result = false;
         break;
        }
     }
   return (result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsCandleWithLongLowLine(MqlRates &rate)
  {
   double longLowLineThreshold = longLowLineDef * data.GetSymbolPoint(targetSymbol);
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
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {


  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   DoWork();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   int existingOrderCount= trade.GetOrderCountByMagic(targetSymbol,currentEaMagic);
   if(existingOrderCount>=3)
     {
      Print("Existing Order Count is  "+existingOrderCount +",Skip current scan");
      return;
     }
//1. Get 14*24*60/15 M15 bars data
   MqlRates targetRates[];
   int totalBarCount = data.GetPriceInfo(targetRates,targetSymbol,BarPeriod,AnalyzeWeekDays);
   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
//2. Find bars with low price less than open (rising)/close(falling) 5 points
//3. Find the 3rd bar which continue increase, get the close price

   MqlRates matchBars[];
   ArrayResize(matchBars,continueRaiseBarCount);
   int matchBarCount = getMatchBar(matchBars,targetRates,totalBarCount);
   if(matchBarCount == continueRaiseBarCount)
     {
      Print("Matched bars - 1："+TimeToString(matchBars[0].time,TIME_DATE)+" " +TimeToString(matchBars[0].time,TIME_MINUTES)+"===2:"+TimeToString(matchBars[1].time,TIME_DATE)+" " +TimeToString(matchBars[1].time,TIME_MINUTES)+"===3："+TimeToString(matchBars[2].time,TIME_DATE)+" " +TimeToString(matchBars[2].time,TIME_MINUTES));
      Print("Ready to order at price:"+ matchBars[0].close);
      double latestBarClosePrice = matchBars[0].close;
      //4. Send buy order when the prices reaches the close price in #3, set sl & tp
      double currentPrice = SymbolInfoDouble(targetSymbol,SYMBOL_ASK);
      if(currentPrice <= latestBarClosePrice) // Need to confirm with JL
        {
         Print("CurrentPrice:"+currentPrice+" Last close price:"+ matchBars[0].close);
         trade.SendBuyOrder(targetSymbol,0.1,StopLevelPoint,TakeProfitPoint,"EA Buy For Price:" + DoubleToString(latestBarClosePrice,5),currentEaMagic);
        }
      else
        {
         Print("Pending order Last close price:" + latestBarClosePrice);
         trade.SendPendingOrderByPrice(BarPeriod,targetSymbol,latestBarClosePrice,0.1,StopLevelPoint,TakeProfitPoint,"EA Pending Order price:" + DoubleToString(latestBarClosePrice,5),currentEaMagic);
        }
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
