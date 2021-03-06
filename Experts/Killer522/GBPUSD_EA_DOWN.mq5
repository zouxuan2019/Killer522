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
#include "..\..\Include\Killer522\KillerHelper.mqh"
//--- input parameters
input int TotalBarNumber = 19;//k线数量
input int StopLevelPoint = 44;//止损点数
input int TakeProfitPoint = 81;//止盈点数
input ENUM_TIMEFRAMES BarPeriod = PERIOD_M20;//K线周期
input string targetSymbol ="GBPUSD"; // 目标货币对

int continueFallingBarCount = 3; // 3 continue rasing bar
input int LongUpperShadowDef = 5; //上阴线
input int KeepRaisingBarCount = 3; //连续上升k线数量

KillerData data;
KillerTrade trade;
int currentEaMagic=3524;
int MaximumTrade = 1;
double WinProbility = 0.38;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   int sleepTime = KillerHelper::GetScanWaitingTime(BarPeriod);
   Sleep(sleepTime*1000);

   EventSetTimer(PeriodSeconds(BarPeriod));
   DoWork();
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMatchBar(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {

   int matchBarCount = 0;
   string latestBarDate= data.GetDateTimeString(totalBars[0].time);
   Print("Latest bar date:" + latestBarDate+" total bar count:"+totalBarCount);

   if(!IsCandleWithLongUpperShadow(totalBars[1]))// If latest bar doesn't have long low line, then discard the order
     {
      return (matchBarCount);
     }

   int matchBarIndexs[];
   ArrayResize(matchBarIndexs,continueFallingBarCount);

   for(int i = 1; i < totalBarCount; i++)
     {
      Print("matchBarCount:"+matchBarCount+" continueFallingBarCount:"+continueFallingBarCount);
      if(matchBarCount == continueFallingBarCount)
        {
         break;
        }

      if(IsCandleWithLongUpperShadow(totalBars[i]))
        {
         if(IsHighPriceInFallingTrend(totalBars,i,matchBars,matchBarCount,matchBarIndexs))
           {
            matchBars[matchBarCount] = totalBars[i];
            matchBarIndexs[matchBarCount] = i;
            matchBarCount++;
            if(matchBarCount == 1 && IsPriceKeepRaising(totalBars,i))//If latest bar in falling trend
              {
               break;
              }
            continue;
           }
        }
     }
   return matchBarCount;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Test(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {
   string latestBarDate= data.GetDateTimeString(totalBars[0].time);
   int count= getMatchBar(matchBars,totalBars,totalBarCount);

   Print(latestBarDate +"matched bar count is :"+count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintLowLineInfo(MqlRates &rate)
  {
   string date= TimeToString(rate.time,TIME_DATE)+" " +TimeToString(rate.time,TIME_MINUTES);
   if(rate.open <= rate.close)
     {
      Print(date + "open :"+rate.open +" close :"+rate.close +"low :"+ rate.low+" Low Line = open -low :"+ (rate.open-rate.low));
     }

   else
     {

      Print(date + "open :"+rate.open +" close :"+rate.close +"low :"+ rate.low + " Low Line =close -low:"+(rate.close-rate.low)+"IsCandleWithLongLowLine： "+IsCandleWithLongUpperShadow(rate));
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHighPriceInFallingTrend(MqlRates &totalBars[],int currentIndex, MqlRates &matchedBars[],int foundCount, int &matchBarIndex[])
  {
   if(foundCount == 0)
     {
      return (true);
     }
   int compareBarIndex = matchBarIndex[foundCount-1];
   MqlRates compareBar = matchedBars[foundCount-1];
   bool isFallingTrend = IsPriceInTheMiddleLowerThanPreviousBar(totalBars, currentIndex, compareBarIndex);
   bool result=(totalBars[currentIndex].high > compareBar.high) && isFallingTrend;
   return (result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceKeepRaising(MqlRates &totalBars[],int currentIndex)
  {
   bool isRaising=true;
   if(currentIndex < KeepRaisingBarCount)
     {
      return false;
     }
   for(int i = 1; i <= KeepRaisingBarCount; i++)
     {
      if(totalBars[currentIndex].high < totalBars[currentIndex-i].high)
        {
         isRaising = false;
        }

     }
   return isRaising;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceInTheMiddleLowerThanPreviousBar(MqlRates &totalBars[],int currentIndex,int compareBarIndex)
  {
   bool result = true;
   for(int i = compareBarIndex + 1; i <= currentIndex; i++)
     {
      if(totalBars[i].high > totalBars[currentIndex].high)
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
bool IsCandleWithLongUpperShadow(MqlRates &rate)
  {
   double longLineThreshold = LongUpperShadowDef * data.GetSymbolPip(targetSymbol);
   return (rate.high - MathMax(rate.open, rate.close)) >= longLineThreshold;
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
void DoWork()
  {
   Print("Current bar period:"+BarPeriod);
   int existingOrderCount= trade.GetOrderCountByMagic(targetSymbol,currentEaMagic);
   Print("Existing Order Count :" + existingOrderCount);
   if(existingOrderCount >= MaximumTrade)
     {
      Print("Existing Order Count is  " + existingOrderCount +",Skip current scan");
      return;
     }
//1. Get TotalBarNumber data
   MqlRates totalBars[];
   int totalBarCount = data.GetPriceInfo(totalBars,targetSymbol,BarPeriod,TotalBarNumber);

   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
//2. Find bars with low price less than open (rising)/close(falling) 5 points
//3. Find the 3rd bar which continue increase, get the close price

   MqlRates matchBars[];
   ArrayResize(matchBars,continueFallingBarCount);
   string latestBarDate = data.GetDateTimeString(totalBars[0].time);
   int matchBarCount = getMatchBar(matchBars,totalBars,totalBarCount);
   if(matchBarCount == continueFallingBarCount)
     {
      Print("Matched bars - 1："+data.GetDateTimeString(matchBars[0].time)+"===2:"+data.GetDateTimeString(matchBars[0].time)+"===3："+data.GetDateTimeString(matchBars[0].time));
      Print("Ready to order at price:"+ matchBars[0].close);
      for(int i=0; i < continueFallingBarCount; i++)
        {
         Print("Found matched bar:" + i + " open:" + matchBars[i].open + ",close:" + matchBars[i].close + ",low:" + matchBars[i].low);
         PrintLowLineInfo(matchBars[i]);
        }

      double latestBarClosePrice = matchBars[0].close;
      //4. Send buy order when the prices reaches the close price in #3, set sl & tp
      double lots = NormalizeDouble(trade.GetLotsByKellyCriterion(WinProbility, TakeProfitPoint, StopLevelPoint),2);
      trade.Sell(BarPeriod,targetSymbol,latestBarClosePrice,lots,StopLevelPoint,TakeProfitPoint,currentEaMagic);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester()
  {
   return trade.GetWinRatio(targetSymbol);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
