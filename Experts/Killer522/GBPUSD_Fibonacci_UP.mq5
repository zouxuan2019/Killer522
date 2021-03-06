//+------------------------------------------------------------------+
//|                                          GBPUSD_Fibonacci_UP.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "..\..\Include\Killer522\KillerHelper.mqh"
#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"
#include "..\..\Include\Killer522\KillerEnum.mqh"
#include "..\..\Include\Killer522\KillerPositionManagement.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int FrameworkTotalBarNumber = 112; //框架K线数量1
int FrameworkFirstBarNumber = 11; //框架K线数量2
ENUM_TIMEFRAMES FrameworkBarPeriod = PERIOD_H4; //框架K线周期
ENUM_TIMEFRAMES TradeBarPeriod = PERIOD_M12; //交易K线周期
int TradeBarNumber = 33;
int LongLowerShadowDef = 3; //长下阴线定义
int EliminateBarNumber = 7; //连续下降排除值
input int SLPoint = 49;
input int TPPoint = 25;
int ContinueRaiseBarCount = 3;

double DefaultLots = 0.5;//默认下单量
string TargetSymbol = "GBPUSD";
int CurrentEaMagic = 2222;
string FibonacciComment = "";
double FirstTargetPrice;
double SecondTargetPrice;
int MaximumPosition = 3;
KillerData data;
KillerTrade trade;
double WinProbility = 0.3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   KillerPositionManagement::SetInitialBalance();
   int sleepTime = KillerHelper::GetScanWaitingTime(TradeBarPeriod);
   Sleep(sleepTime * 1000);

   EventSetTimer(PeriodSeconds(TradeBarPeriod));
   DoWork();
   return(INIT_SUCCEEDED);
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(KillerPositionManagement::ShouldStopEAByBalance()||KillerPositionManagement::ShouldStopEAByEquity(TargetSymbol,CurrentEaMagic))
     {
      trade.CancelPendingOrderByMagic(TargetSymbol,CurrentEaMagic);
      trade.CloseAll(TargetSymbol,CurrentEaMagic);
      EventKillTimer();
     }

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   DoWork();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   ResetObject();
   MqlRates totalBars[];
   double high[], low[];

   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,FrameworkBarPeriod,FrameworkTotalBarNumber + 1);
   int totalHighCount = data.GetHighInfo(high,TargetSymbol,FrameworkBarPeriod,FrameworkTotalBarNumber + 1);
   int totalLowCount = data.GetLowInfo(low,TargetSymbol,FrameworkBarPeriod,FrameworkTotalBarNumber + 1);
   if(totalBarCount == 0 || totalHighCount == 0 || totalLowCount == 0)
     {
      Alert("Error copying price data ", GetLastError());
      return;
     }
   DrawAllFibonacci(totalBars,high,low);
   if(FibonacciComment != "")
     {
      SuperCommentLab(FibonacciComment);
     }

   double currentPrice = SymbolInfoDouble(TargetSymbol,SYMBOL_ASK);
   if(currentPrice > FirstTargetPrice)
     {
      double lots = DefaultLots;
      if(currentPrice > SecondTargetPrice)
        {
         lots *= 2;
        }
      StartLowerShadowEA(lots);
     }
//trade.CloseAllExpired(TargetSymbol,CurrentEaMagic);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StartLowerShadowEA(double lots)
  {
   Print("Start Lower Shadow EA");
   if(trade.HasReachedMaximumPosition(TargetSymbol,CurrentEaMagic,MaximumPosition))
     {
      return;
     }
//1. Get 14*24*60/15 M12 bars data
   MqlRates totalBars[];
   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,TradeBarPeriod,TradeBarNumber);
   if(totalBarCount == 0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
//2. Find bars with low price less than open (rising)/close(falling) 5 points
//3. Find the 3rd bar which continue increase, get the close price
   MqlRates matchBars[];
   ArrayResize(matchBars,ContinueRaiseBarCount);
   int matchBarCount = getMatchBar(matchBars,totalBars,totalBarCount);
   if(matchBarCount == ContinueRaiseBarCount)
     {
      Print("Matched bars - 1：" + data.GetDateTimeString(matchBars[0].time) + "===2:"+data.GetDateTimeString(matchBars[1].time) + "===3：" + data.GetDateTimeString(matchBars[2].time));
      Print("Ready to order at price:" + matchBars[0].close);
      double latestBarClosePrice = matchBars[0].close;
      //4. Send buy order when the prices reaches the close price in #3, set sl & tp
      trade.Buy(TradeBarPeriod,TargetSymbol,latestBarClosePrice,lots,SLPoint,TPPoint,CurrentEaMagic);
     }
   else
     {
      Print("No matched bars");
     }
   Print("End Lower Shadow EA");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMatchBar(MqlRates &matchBars[],MqlRates &totalBars[], int totalBarCount)
  {
   int matchBarCount = 0;
   string latestBarDate= data.GetDateTimeString(totalBars[0].time);
   Print("Latest bar date:" + latestBarDate+" total bar count:"+totalBarCount);

   if(!IsCandleWithLongLowerShadow(totalBars[1]))// If latest bar doesn't have long low line, then discard the order
     {
      return (matchBarCount);
     }

   int matchBarIndexs[];
   ArrayResize(matchBarIndexs,ContinueRaiseBarCount);

   for(int i = 1; i < totalBarCount; i++)
     {
      Print("matchBarCount:" + matchBarCount + " continueRaiseBarCount:" + ContinueRaiseBarCount);
      if(matchBarCount == ContinueRaiseBarCount)
        {
         break;
        }

      if(IsCandleWithLongLowerShadow(totalBars[i]))
        {
         if(IsLowPriceInRaisingTrend(totalBars,i,matchBars,matchBarCount,matchBarIndexs))
           {
            matchBars[matchBarCount] = totalBars[i];
            matchBarIndexs[matchBarCount] = i;
            matchBarCount++;
            if(matchBarCount == 1 && IsPriceKeepFalling(totalBars,i))//If latest bar in falling trend
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
bool IsLowPriceInRaisingTrend(MqlRates &totalBars[],int currentIndex, MqlRates &matchedBars[],int foundCount, int &matchBarIndex[])
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
bool IsPriceKeepFalling(MqlRates &totalBars[],int currentIndex)
  {
   return false;
   bool isFalling=true;
   if(currentIndex < EliminateBarNumber)
     {
      return false;
     }
   for(int i = 1; i <= EliminateBarNumber; i++)
     {
      if(totalBars[currentIndex].low > totalBars[currentIndex-i].low)
        {
         isFalling = false;
        }

     }
   return isFalling;
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
   double longLineThreshold = LongLowerShadowDef * data.GetSymbolPip(TargetSymbol);
   return (MathMin(rate.open, rate.close) - rate.low) >= longLineThreshold;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetObject()
  {
   FibonacciComment = "";
   SuperCommentLab(FibonacciComment);
   ObjectDelete(TargetSymbol,"Fibonacci1");
   ObjectDelete(TargetSymbol,"Fibonacci2");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawAllFibonacci(MqlRates &totalBars[], double &high[], double &low[])
  {
   int h1,l1,h2,l2;
   h1 = ArrayMaximum(high, 1, FrameworkTotalBarNumber);
   l1 = ArrayMinimum(low, 1, FrameworkTotalBarNumber);

   h2 = ArrayMaximum(high, 1, FrameworkFirstBarNumber);
   l2 = ArrayMinimum(low, 1, FrameworkFirstBarNumber);

   datetime startDateTime1, endDateTime1;
   startDateTime1=totalBars[FrameworkTotalBarNumber].time;
   endDateTime1=totalBars[1].time;
   DrawFibonacci(TargetSymbol,"Fibonacci1",totalBars,startDateTime1,endDateTime1,h1,l1,CurrentEaMagic);

   datetime startDateTime2, endDateTime2;
   startDateTime2=totalBars[FrameworkFirstBarNumber].time;
   endDateTime2=totalBars[1].time;
   DrawFibonacci(TargetSymbol,"Fibonacci2",totalBars,startDateTime2,endDateTime2,h2,l2,CurrentEaMagic);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawFibonacci(string symbol,string name,MqlRates &totalBars[],datetime startDateTime,datetime endDateTime,int highestCandle, int lowestCandle,string magic)
  {
   ObjectCreate(symbol,
                name,
                OBJ_FIBO,
                0,
                endDateTime,
                totalBars[highestCandle].high,
                startDateTime,
                totalBars[lowestCandle].low
               );
   FibonacciComment += GenerateComment(name, magic);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GenerateComment(string objectName,string magic)
  {
   datetime DateTime0 = ObjectGetInteger(0,objectName,OBJPROP_TIME,0);
   double PriceLevel100 = ObjectGetDouble(0,objectName,OBJPROP_PRICE,0);
   datetime DateTime1 = ObjectGetInteger(0,objectName,OBJPROP_TIME,1);
   double PriceLevel0 = ObjectGetDouble(0,objectName,OBJPROP_PRICE,1);
   double PriceLevel0618 = GetPriceByPercentage(PriceLevel0,PriceLevel100,0.618);
   double PriceLevel05 = GetPriceByPercentage(PriceLevel0,PriceLevel100,0.5);

   if(objectName == "Fibonacci1")
     {
      FirstTargetPrice = PriceLevel0618;
     }
   else
     {
      SecondTargetPrice = PriceLevel0618;
     }
   return "\n"+ objectName + " Start: " + DateTime1
          + " End: " + DateTime0 +"\n"
          + " PriceLevel 0: " + PriceLevel0+ "\n"+
          " PriceLevel 0.5: " + PriceLevel05 + "\n" +
          " PriceLevel 0.618: " + PriceLevel0618 +
          " PriceLevel 100: " + PriceLevel100
          ;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPriceByPercentage(double price_0,double price_100,double percentage)
  {
   double priceDifference = MathAbs(price_0 - price_100) * percentage; //get the price difference between the required percentage level and 0%
   return (price_100 > price_0)
          ? NormalizeDouble(price_0 + priceDifference, Digits())
          : NormalizeDouble(price_0 - priceDifference, Digits())
          ;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SuperCommentLab(string commentText)
  {
   string sep = "\n";
   ushort u_sep = StringGetCharacter(sep,0);
   string result[];
   int k = StringSplit(commentText,u_sep,result);
   for(int i=0; i<k; i++)
     {
      CommentLab(i,10+i*25,result[i]);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommentLab(string label_name,int yCor,string CommentText)
  {
   string CommentLabel;
   int CommentIndex = 0;

   StringTrimLeft(CommentText);

   if(CommentText == "")
     {
      return;
     }


   ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,label_name, OBJPROP_CORNER, 0);
//--- set X coordinate
   ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,20);
//--- set Y coordinate
   ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,yCor);
//--- define text color
   ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrGoldenrod);
//--- define text for object Label
   ObjectSetString(0,label_name,OBJPROP_TEXT,CommentText);
//--- define font
   ObjectSetString(0,label_name,OBJPROP_FONT,"Arial");
//--- define font size
   ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,16);
//--- 45 degrees rotation clockwise
//    ObjectSetDouble(0,label_name,OBJPROP_ANGLE,-45);
//--- disable for mouse selecting
   ObjectSetInteger(0,label_name,OBJPROP_SELECTABLE,true);
//--- draw it on the chart
   ChartRedraw(0);

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   return trade.GetWinRatio(TargetSymbol);
  }
//+------------------------------------------------------------------+
