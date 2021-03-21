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
#include "..\..\Include\Killer522\KillerPositionManagement.mqh"

input ENUM_TIMEFRAMES TradeBarPeriod = PERIOD_D1;
string TargetSymbol="GBPUSD";
int StrategyBars = 20;
int CloseBars = 10;
int MaximumPosition = 4;
int CurrentEaMagic = 1105;

KillerData data;
KillerTrade trade;
double Unit;
double BuyClosePrice;
double SellClosePrice;
bool IsInitialized;
int ATRHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//int sleepTime = KillerHelper::GetScanWaitingTime(TradeBarPeriod);
//Sleep(sleepTime * 1000);
   KillerPositionManagement::SetInitialBalance();
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

   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,TradeBarPeriod,StrategyBars + 1);
   int totalHighCount = data.GetHighInfo(high,TargetSymbol,TradeBarPeriod,StrategyBars + 1);
   int totalLowCount = data.GetLowInfo(low,TargetSymbol,TradeBarPeriod,StrategyBars + 1);
   if(totalBarCount == 0 || totalHighCount == 0 || totalLowCount == 0)
     {
      Alert("Error copying price data ", GetLastError());
      return;
     }

   int h,l;
   h = ArrayMaximum(high, 1, StrategyBars);
   l = ArrayMinimum(low, 1, StrategyBars);

   GlobalVariableSet("HighestPrice", totalBars[h].high);
   GlobalVariableSet("LowestPrice", totalBars[l].low);

   ATRHandle = iATR(TargetSymbol,TradeBarPeriod,StrategyBars); // returns a handle for ATR
   SetClosePrice(high,low);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetClosePrice(double &high[], double &low[])
  {
   int h,l;
   h = ArrayMaximum(high, 1, CloseBars);
   l = ArrayMinimum(low, 1, CloseBars);
   BuyClosePrice = low[l];
   SellClosePrice = high[h];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(Unit==0)
     {
      SetUnit();
     }
   double h = GlobalVariableGet("HighestPrice");
   if(h > 0 && Unit > 0)
     {
      double askPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_ASK),_Digits);
      double bidPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_BID),_Digits);
      int positionCount = GetPositionUnitsByMagic(TargetSymbol,CurrentEaMagic,Unit);
      if(positionCount >= MaximumPosition)
        {
         return;
        }
      SendOrder(askPrice,bidPrice);
      CloseOrder(askPrice,bidPrice);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendOrder(double askPrice, double bidPrice)
  {
   double h = (double)GlobalVariableGet("HighestPrice");
   double l = (double)GlobalVariableGet("LowestPrice");
   if(askPrice > h)//突破20日最高价
     {
      double lots = Unit;
      if(lots==0)
        {
         return;
        }
      int slPip = GetslPip();
      trade.SendBuyOrder(TargetSymbol,lots,slPip,0,"EA Buy For Price:" + DoubleToString(askPrice,5),CurrentEaMagic);
     }
   if(bidPrice < l)//突破20日最低价
     {
      double lots = Unit;
      if(lots == 0)
        {
         return;
        }
      int slPip = GetslPip();
      trade.SendSellOrder(TargetSymbol,lots,slPip,0,"EA Buy For Price:" + DoubleToString(bidPrice,5),CurrentEaMagic);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOrder(double askPrice, double bidPrice)
  {
   if(trade.GetOrderCountByMagic(TargetSymbol,CurrentEaMagic)>0)
     {
      if(bidPrice <= BuyClosePrice)
        {
         trade.CloseAllBuy(TargetSymbol,CurrentEaMagic);
        }
      if(askPrice >= SellClosePrice)
        {
         trade.CloseAllSell(TargetSymbol,CurrentEaMagic);
        }
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPositionUnitsByMagic(string symbol,int magic, double unitLots)
  {
   double totalLots=0.0;
   int totalPositionNumber = PositionsTotal();
   for(int i = totalPositionNumber - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i)>0)
        {
         int selectedMagic = PositionGetInteger(POSITION_MAGIC);
         string selectedSymbol = PositionGetString(POSITION_SYMBOL);
         if(selectedSymbol == symbol && (selectedMagic == magic || magic==0))
           {
            totalLots += PositionGetDouble(POSITION_VOLUME);
           }
        }
     }
   return((int)(totalLots/unitLots));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetUnit()
  {
   Unit = GetOneUnitLots();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOneUnitLots()
  {
   double initialBalance = (double)GlobalVariableGet("InitialBalance");
   double ATRValue[];
   CalculateATR(ATRValue);
   double N = NormalizeDouble(ATRValue[1],5);
   if(N == 0)
     {
      return 0;
     }
   double contractSize = SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pointValue =  SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_TICK_VALUE);
   double absoluteATR = N * contractSize * pointValue ;
   return NormalizeDouble(initialBalance * 0.01 / absoluteATR, 2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateATR(double &ATRValue[])
  {
   ENUM_TIMEFRAMES      MA_Period = TradeBarPeriod;               // The value of the averaging period for the indicator calculation
   int Count = StrategyBars;                    // Amount to copy

   ArraySetAsSeries(ATRValue,true);       // Set the ATRValue to timeseries, 0 is the oldest.
   if(CopyBuffer(ATRHandle,0,0,Count,ATRValue) > 0)     // Copy value of ATR to ATRValue
     {
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetslPip()
  {
   int positionUnint = GetPositionUnitsByMagic(TargetSymbol,CurrentEaMagic,Unit);
   int extraPositionUnint = positionUnint -1;
   double slRatio = (2 - 0.5 * extraPositionUnint) * Unit;
   int slPipPoint= (slRatio * SymbolInfoDouble(TargetSymbol,SYMBOL_TRADE_CONTRACT_SIZE))/data.GetSymbolPip(TargetSymbol);
   return slPipPoint;
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
