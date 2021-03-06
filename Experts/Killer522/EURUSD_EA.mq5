//+------------------------------------------------------------------+
//|                                                    EURUSD_EA.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "..\..\Include\Killer522\KillerHelper.mqh"
#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"

enum ENUM_FIBONACCILEVELS
  {
   Level0191=1,
   Level0236=2,
   Level0382=3,
   Level05=4,
   Level0618=5,
   Level0707=6,
   Level1191=7,
   Level1272=8,
   Level1382=9,
   Level1414=10,
   Level15=11,
   Level1618=12
  };

input int TotalBarNumber=121;//K线数量
input ENUM_TIMEFRAMES BarPeriod = PERIOD_H4;//K线周期
KillerData data;
KillerTrade trade;
int currentEaMagic1=2255;
int currentEaMagic2=2256;
input string targetSymbol ="EURUSD"; // 目标货币对
input int FirstBatch = 5 ; // 第一轮对比
input int SecondBatch = 50; // 第二轮对比
input double slFibonaciiPerc = 0.2;
input ENUM_FIBONACCILEVELS targetPricePercRaising = Level0618;
input ENUM_FIBONACCILEVELS targetPricePercFalling = Level05;
input ENUM_FIBONACCILEVELS tpFabinaciPercRaising = Level1191;
input ENUM_FIBONACCILEVELS tpFibonaciPercFalling = Level0382;
string comment = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   int sleepTime = KillerHelper::GetScanWaitingTime(BarPeriod);
   Sleep(sleepTime*1000);

   EventSetTimer(PeriodSeconds(BarPeriod));
   DoWork();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   ResetObject();
   MqlRates totalBars[];
   double high[],low[];

   int totalBarCount = data.GetPriceInfo(totalBars,targetSymbol,BarPeriod,TotalBarNumber);
   int totalHighCount = data.GetHighInfo(high,targetSymbol,BarPeriod,TotalBarNumber);
   int totalLowCount = data.GetLowInfo(low,targetSymbol,BarPeriod,TotalBarNumber);
   if(totalBarCount == 0 || totalHighCount==0 || totalLowCount==0)
     {
      Alert("Error copying price data ",GetLastError());
      return;
     }
   DrawAllFibonacci(totalBars,high,low);

   if(comment!="")
     {
      Comment(comment);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawAllFibonacci(MqlRates &totalBars[], double &high[], double &low[])
  {
   int h1,l1,h2,l2,h3,l3;
   h1 = ArrayMaximum(high, 1, FirstBatch);
   l1 = ArrayMinimum(low, 1, FirstBatch);

   h2 = ArrayMaximum(high, FirstBatch - 1, SecondBatch);
   l2 = ArrayMinimum(low, FirstBatch - 1, SecondBatch);

   h3 = ArrayMaximum(high, SecondBatch - 1, TotalBarNumber - FirstBatch - SecondBatch);
   l3 = ArrayMinimum(low, SecondBatch - 1, TotalBarNumber - FirstBatch - SecondBatch);
   double previousH1 = (double)GlobalVariableGet("HighestValue1");
   double previousH2 = (double)GlobalVariableGet("HighestValue2");
   double previousL1 = (double)GlobalVariableGet("LowestValue1");
   double previousL2 = (double)GlobalVariableGet("LowestValue2");
   double currentH1,currentL1,currentH2,currentL2;

   if(high[h1] >= high[h2])
     {
      int l12=l1;
      if(low[l1] > low[l2])
        {
         l12=l2;
        }
      Print("Fibonacci1 Higest Candle" + h1  +" " + data.GetDateTimeString(totalBars[h1].time) + ", Lowest Candle" + l12  +" " + data.GetDateTimeString(totalBars[l12].time));
      currentH1 = high[h1];
      currentL1 = low[l12];
      bool isSameFibonacciAsPrevious=(currentH1==previousH1&&currentL1==previousL1);
      Print("Previous H1:" + previousH1 +" PreviousL1:"+ previousL1 +" CurrentH1:" + currentH1 + " CurrentL1:" + currentL1);
      DrawFibonacci(targetSymbol,"Fibonacci1",totalBars,h1,l12,currentEaMagic1,isSameFibonacciAsPrevious);
     }
   else // h1 < h2
     {
      if(low[l2] > low[l1])
        {
         Print("Low1: " + low[l1] +"Low2:"+ low[l2]);
         Print("Fibonacci2 Higest Candle" + h2  +" " + data.GetDateTimeString(totalBars[h2].time) + ", Lowest Candle" + l1  +" " + data.GetDateTimeString(totalBars[l1].time));
         currentH1 = high[h2];
         currentL1 = low[l1];
         Print("Previous H1:" + previousH1 +" PreviousL1:"+ previousL1 +" CurrentH1:" + currentH1 + " CurrentL1:" + currentL1);
         bool isSameFibonacciAsPrevious=(currentH1==previousH1 && currentL1==previousL1);
         DrawFibonacci(targetSymbol,"Fibonacci2", totalBars, h2, l1,currentEaMagic1,isSameFibonacciAsPrevious);

        }
     }
   GlobalVariableSet("HighestValue1", currentH1);
   GlobalVariableSet("LowestValue1", currentL1);


   if(high[h3] > high[h2] && high[h2]>high[h1] && low[l1]<low[l2])
     {
      currentH2 = high[h3];
      currentL2 = low[l1];
      bool isSameFibonacciAsPrevious=(currentH2==previousH2&&currentL2==previousL2);
      Print("Previous H2:" + previousH2 +" PreviousL2:"+ previousL2 +" CurrentH2:" + currentH2 + " CurrentL2:" + currentL2);
      DrawFibonacci(targetSymbol,"Fibonacci3",totalBars,h3,l1,currentEaMagic2,isSameFibonacciAsPrevious);

     }

   if(high[h1] > high[h2] && high[h2]>high[h3] && low[l1]>low[l2] && low[l2]>low[l3])
     {
      currentH2 = high[h1];
      currentL2 = low[l3];
      bool isSameFibonacciAsPrevious = (currentH2==previousH2 && currentL2==previousL2);
      Print("Previous H2:" + previousH2 +" PreviousL2:"+ previousL2 +" CurrentH2:" + currentH2 + " CurrentL2:" + currentL2);
      DrawFibonacci(targetSymbol,"Fibonacci4",totalBars,h1,l3,currentEaMagic2,isSameFibonacciAsPrevious);

     }
   GlobalVariableSet("HighestValue2",currentH2);
   GlobalVariableSet("LowestValue2",currentL2);


   if(previousH1>0 && previousL1>0 && (currentH1 > previousH1 || currentL1 < previousL1))
     {
      //Cancel all pending order for currentEaMagic1
      trade.CancelPendingOrderByMagic(targetSymbol,currentEaMagic1);
     }
   if(previousH2>0 && previousL2>0 && (currentH2 > previousH2 || currentL2 < previousL2))
     {
      //Cancel all pending order for currentEaMagic2
      trade.CancelPendingOrderByMagic(targetSymbol,currentEaMagic2);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetObject()
  {
   comment = "";
   Comment(comment);
   ObjectDelete(targetSymbol,"Fibonacci1");
   ObjectDelete(targetSymbol,"Fibonacci2");
   ObjectDelete(targetSymbol,"Fibonacci3");
   ObjectDelete(targetSymbol,"Fibonacci4");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawFibonacci(string symbol,string name,MqlRates &totalBars[],int highestCandle, int lowestCandle,string magic,bool isSameFibonacciAsPrevious)
  {
   int startIndex = highestCandle, endIndex = lowestCandle;
   if(totalBars[highestCandle].time > totalBars[lowestCandle].time)
     {
      startIndex = lowestCandle;
      endIndex = highestCandle;
     }
   ObjectCreate(symbol,
                name,
                OBJ_FIBO,
                0,
                totalBars[endIndex].time,
                totalBars[highestCandle].high,
                totalBars[startIndex].time,
                totalBars[lowestCandle].low
               );
   bool isRaisingTrend = IsRaisingTrend(totalBars, highestCandle, lowestCandle);
   comment += GenerateCommentAndDoTrade(name, isRaisingTrend, magic,isSameFibonacciAsPrevious);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsRaisingTrend(MqlRates &totalBars[], int highestCandle, int lowestCandle)
  {
   return totalBars[lowestCandle].time < totalBars[highestCandle].time;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoTrade(double targetPrice,double tpPrice,double slPrice, bool isRaisingTrend,string magic)
  {
   int positionCount = trade.GetOrderCountByMagic(targetSymbol,0);
   if(positionCount >= 8)
     {
      return;
     }
   int tpPoint,slPoint;
   tpPoint = MathAbs(tpPrice - targetPrice) / data.GetSymbolPip(targetSymbol);
   slPoint = MathAbs(targetPrice - slPrice) / data.GetSymbolPip(targetSymbol);
   Print("tpPoint:" + tpPoint + "slPoint:"+ slPoint);
   if(isRaisingTrend)
     {
      trade.Buy(PERIOD_CURRENT,Symbol(),targetPrice,0.1,slPoint,tpPoint,magic,false);
     }
   else
     {
      trade.Sell(PERIOD_CURRENT,Symbol(),targetPrice,0.1,slPoint,tpPoint,magic,false);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FibonacciLevelToDouble(ENUM_FIBONACCILEVELS enum_fl)
  {
   switch(enum_fl)
     {
      case Level0191:
         return 0.191;
         break;
      case Level0236:
         return 0.236;
         break;
      case Level0382:
         return 0.382;
         break;
      case Level05:
         return 0.5;
         break;
      case Level0618:
         return 0.618;
         break;
      case Level0707:
         return 0.707;
         break;
      case Level1191:
         return 1.191;
         break;
      case Level1272:
         return 1.272;
         break;
      case Level1382:
         return 1.382;
         break;
      case Level1414:
         return 1.414;
         break;
      case Level15:
         return 1.5;
         break;
      case Level1618:
         return 1.618;
         break;
      default:
         return 0.0;
         break;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GenerateCommentAndDoTrade(string objectName, bool isRaisingTrend,string magic,bool isSameFibonacciAsPrevious)
  {
   datetime DateTime0 = ObjectGetInteger(0,objectName,OBJPROP_TIME,0);
   double PriceLevel100 = ObjectGetDouble(0,objectName,OBJPROP_PRICE,0);
   datetime DateTime1 = ObjectGetInteger(0,objectName,OBJPROP_TIME,1);
   double PriceLevel0 = ObjectGetDouble(0,objectName,OBJPROP_PRICE,1);
   double BuyPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(targetPricePercRaising));
   double BuyTpPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(tpFabinaciPercRaising));
   double BuySlPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(targetPricePercRaising) - slFibonaciiPerc);
   double SellPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(targetPricePercFalling));
   double SellTpPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(tpFibonaciPercFalling));
   double SellSlPrice = GetPriceByPercentage(PriceLevel0,PriceLevel100,FibonacciLevelToDouble(targetPricePercFalling) + slFibonaciiPerc);

   if(!isSameFibonacciAsPrevious)
     {
      double targetPrice, tpPrice,slPrice;
      if(isRaisingTrend)
        {
         targetPrice = BuyPrice;
         tpPrice = BuyTpPrice;
         slPrice = BuySlPrice;
        }
      else
        {
         targetPrice = SellPrice;
         tpPrice = SellTpPrice;
         slPrice = SellSlPrice;
        }
      Print("isRaisingTrend:"+ isRaisingTrend+ " targetPrice:" + targetPrice+" tpPrice:"+tpPrice+" slPrice:"+slPrice);

      DoTrade(targetPrice,tpPrice,slPrice,isRaisingTrend,magic);
     }

   Print("Skip current trade");

   return "\n"+ objectName + " DateTime0: " + DateTime0+
          " DateTime1: " + DateTime1 +"\n" +
          " PriceLevel BuyPrice: " + BuyPrice +
          " PriceLevel BuyTpPrice: " + BuyTpPrice +
          " PriceLevel SellPrice: " + SellPrice +"\n" +
          " PriceLevel SellTpPrice: " + SellTpPrice +
          " PriceLevel 100: " + PriceLevel100 +
          " PriceLevel 0: " + PriceLevel0+ "\n"
          ;
  }

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
//---
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   DoWork();
  }
//+------------------------------------------------------------------+
