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
int TotalBars = 20;
int ExitBars = 10;
int MaximumPosition = 4;


int CurrentEaMagic = 1105;
KillerData data;
KillerTrade trade;
double UnitLots;
double N;
int ATRHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   int sleepTime = KillerHelper::GetScanWaitingTime(TradeBarPeriod);
   Sleep(sleepTime * 1000);
   EventSetTimer(PeriodSeconds(TradeBarPeriod));
   InitializeParameters();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitializeParameters()// initialize daily for 20 days higest/lowest price
  {
   if(!trade.DoesPositionExistByMagic(TargetSymbol, CurrentEaMagic))
     {
      UnitLots=0.0;//reset Unit
      N = 0.0;
     }

   double high[], low[];
   int totalHighCount = data.GetHighInfo(high,TargetSymbol,TradeBarPeriod,TotalBars + 1);
   int totalLowCount = data.GetLowInfo(low,TargetSymbol,TradeBarPeriod,TotalBars + 1);
   if(totalHighCount == 0 || totalLowCount == 0)
     {
      Alert("Error copying price data ", GetLastError());
      return;
     }
   SetHigestLowestPrice(high,low,TotalBars,"HighestPriceIn20Days","LowestPriceIn20Days");
   SetHigestLowestPrice(high,low,ExitBars,"HighestExitPrice","LowestExitPrice");
   ATRHandle = iATR(TargetSymbol,TradeBarPeriod,TotalBars); // returns a handle for ATR
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetHigestLowestPrice(double &high[], double &low[], int barCount, string HighVariableName, string LowVariableName)
  {
   int h = ArrayMaximum(high, 1, barCount);
   int l = ArrayMinimum(low, 1, barCount);
   GlobalVariableSet(HighVariableName, high[h]);
   GlobalVariableSet(LowVariableName, low[l]);
   Print("Lowest price in previous "+ barCount+" days: "+ NormalizeDouble(low[l],5) + " Highest price in previous " + barCount+" days: "+ NormalizeDouble(high[h],5));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Exit()
  {
   double askPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_ASK),_Digits);
   double bidPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_BID),_Digits);
   Print("Current ask price: "+ NormalizeDouble(askPrice,5) + " Current bid price: " + NormalizeDouble(bidPrice,5));
   CloseOrder(askPrice,bidPrice,(double)GlobalVariableGet("HighestExitPrice"),(double)GlobalVariableGet("LowestExitPrice"));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(UnitLots == 0.0)
     {
      InitUnitLotsAndN(); // need to wait for  iATR handle to be created
     }

   double h = GlobalVariableGet("HighestPriceIn20Days");
   if(h > 0 && UnitLots > 0)
     {
      Exit();
      int orderCount = trade.GetOrderCountByMagic(TargetSymbol,CurrentEaMagic);
      if(orderCount < MaximumPosition)
        {
         Enter(orderCount);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPreviousBreakThroughLoss()
  {
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Enter(int existingOrderCount)
  {
   double askPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_ASK),_Digits);
   double bidPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_BID),_Digits);
   double h = (double)GlobalVariableGet("HighestPriceIn20Days");
   double l = (double)GlobalVariableGet("LowestPriceIn20Days");
   double lastHighBreakThroughPrice = (double)GlobalVariableGet("HighBreakThroughPrice");
   double lastLowBreakThroughPrice = (double)GlobalVariableGet("LowBreakThroughPrice");
   double highBreakThroughPrice = lastHighBreakThroughPrice > 0 ? lastHighBreakThroughPrice : h;
   double lowBreakThroughPrice = lastLowBreakThroughPrice > 0 ? lastLowBreakThroughPrice : l;

   if(askPrice > (highBreakThroughPrice + existingOrderCount * 0.5* N)) //突破20日最高价
     {
      if(existingOrderCount == 0)
        {
         GlobalVariableSet("HighBreakThroughPrice",askPrice);
        }
      if((existingOrderCount == 0 && IsPreviousBreakThroughLoss()) || existingOrderCount>0)
        {
         int slPip = GetslPip();
         trade.SendBuyOrder(TargetSymbol,UnitLots,slPip,0,"EA Buy For Price:" + DoubleToString(askPrice,5),CurrentEaMagic);
         ModifyExistingBuyOrderSl(existingOrderCount);
        }
     }

   if(bidPrice < (lowBreakThroughPrice - (existingOrderCount * 0.5 * N)))//跌破20日最低价
     {
      if(existingOrderCount == 0)
        {
         GlobalVariableSet("LowBreakThroughPrice",bidPrice);
        }
      if((existingOrderCount == 0 && IsPreviousBreakThroughLoss()) || existingOrderCount>0)
        {
         int slPip = GetslPip();
         trade.SendSellOrder(TargetSymbol,UnitLots,slPip,0,"EA Buy For Price:" + DoubleToString(bidPrice,5),CurrentEaMagic);
         ModifyExistingSellOrderSl(existingOrderCount);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyExistingBuyOrderSl(int existingOrderCount)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyExistingSellOrderSl(int existingOrderCount)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOrder(double askPrice, double bidPrice, double highestInPreviousDays, double lowestInPreviousDays)
  {
   if(trade.DoesPositionExistByMagic(TargetSymbol,CurrentEaMagic))
     {
      if(bidPrice <= lowestInPreviousDays)
        {
         trade.CloseAllBuy(TargetSymbol,CurrentEaMagic);
        }
      if(askPrice >= highestInPreviousDays)
        {
         trade.CloseAllSell(TargetSymbol,CurrentEaMagic);
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitUnitLotsAndN()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double ATRValue[];
   CalculateATR(ATRValue);
   N = NormalizeDouble(ATRValue[1],5);
   if(N == 0)
     {
      return 0.0;
     }
   double contractSize = SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pointValue =  SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_TICK_VALUE);
   double absoluteATR = N * contractSize * pointValue ;
   UnitLots =  NormalizeDouble(balance * 0.01 / absoluteATR, 2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateATR(double &ATRValue[])
  {
   ENUM_TIMEFRAMES      MA_Period = TradeBarPeriod;               // The value of the averaging period for the indicator calculation
   int Count = TotalBars;                    // Amount to copy

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
   int orderCount = trade.GetOrderCountByMagic(TargetSymbol,CurrentEaMagic);
   int extraUnit = (orderCount - 1) > 0 ? (orderCount - 1) : 0;
   double slRatio = (2 - 0.5 * extraUnit) * N;
   int slPipPoint= slRatio/data.GetSymbolPip(TargetSymbol);
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
   InitializeParameters();
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
