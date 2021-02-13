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
input int TotalBarNumber = 48;//k线数量
input int StopLevelPoint = 22;//止损点数
input int TakeProfitPoint = 20;//止盈点数
input ENUM_TIMEFRAMES BarPeriod = PERIOD_M15;//K线周期
input string targetSymbol ="GBPUSD"; // 目标货币对

int continueRaiseBarCount = 3; // 3 continue rasing bar
input int longLowLineDef = 3; //下阴线

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
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetScanWaitingTime()
  {
   int interval =PeriodSeconds(BarPeriod);
   datetime currentDate = TimeTradeServer();
   int result=interval- (int)currentDate % interval + 60;
   return (result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMatchBar(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {

   int matchBarCount = 0;
   string latestBarDate= data.GetDateTimeString(totalBars[0].time);
   Print("Latest bar date:" + latestBarDate+" total bar count:"+totalBarCount);

   if(!IsCandleWithLongLowerShadow(totalBars[0]))// If latest bar doesn't have long low line, then discard the order
     {
      return (matchBarCount);
     }

   int matchBarIndexs[];
   ArrayResize(matchBarIndexs,continueRaiseBarCount);

   for(int i = 0; i < totalBarCount; i++)
     {
      Print("matchBarCount:"+matchBarCount+" continueRaiseBarCount:"+continueRaiseBarCount);
      if(matchBarCount == continueRaiseBarCount)
        {
         break;
        }

      if(IsCandleWithLongLowerShadow(totalBars[i]))
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

      Print(date + "open :"+rate.open +" close :"+rate.close +"low :"+ rate.low + " Low Line =close -low:"+(rate.close-rate.low)+"IsCandleWithLongLowLine： "+IsCandleWithLongLowerShadow(rate));
     }
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
   for(int i = compareBarIndex + 1; i <= currentIndex; i++)
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
bool IsCandleWithLongLowerShadow(MqlRates &rate)
  {
   double longLowLineThreshold = longLowLineDef * data.GetSymbolPoint(targetSymbol);
   if(rate.open <= rate.close)
     {
      return (rate.open-rate.low >= longLowLineThreshold);
     }

   else //(rate.open > rate.close)
     {
      return (rate.close-rate.low >= longLowLineThreshold);
     }
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
   int existingOrderCount= trade.GetOrderCountByMagic(targetSymbol,currentEaMagic);
   Print("Existing Order Count :" + existingOrderCount);
   if(existingOrderCount >= 3)
     {
      Print("Existing Order Count is  " + existingOrderCount +",Skip current scan");
      return;
     }
//1. Get 14*24*60/15 M15 bars data
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
   ArrayResize(matchBars,continueRaiseBarCount);
   string latestBarDate = data.GetDateTimeString(totalBars[0].time);
   int matchBarCount = getMatchBar(matchBars,totalBars,totalBarCount);
   if(matchBarCount == continueRaiseBarCount)
     {
      Print("Matched bars - 1："+TimeToString(matchBars[0].time,TIME_DATE)+" " +TimeToString(matchBars[0].time,TIME_MINUTES)+"===2:"+TimeToString(matchBars[1].time,TIME_DATE)+" " +TimeToString(matchBars[1].time,TIME_MINUTES)+"===3："+TimeToString(matchBars[2].time,TIME_DATE)+" " +TimeToString(matchBars[2].time,TIME_MINUTES));
      Print("Ready to order at price:"+ matchBars[0].close);
      for(int i=0; i < continueRaiseBarCount; i++)
        {
         Print("Found matched bar:" + i + " open:" + matchBars[i].open + ",close:" + matchBars[i].close + ",low:" + matchBars[i].low);
         PrintLowLineInfo(matchBars[i]);
        }

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
