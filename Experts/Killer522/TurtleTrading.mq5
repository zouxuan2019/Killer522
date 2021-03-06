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
int BreakOutFirstOrderId = 0;
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

   CloseOrder(askPrice,bidPrice,(double)GlobalVariableGet("HighestExitPrice"),(double)GlobalVariableGet("LowestExitPrice"));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(UnitLots == 0.0)
     {
      InitUnitLotsAndN(); //need to wait for iATR handle to be created
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
bool IsPreviousBreakOutLoss()
  {
   if(BreakOutFirstOrderId==0)
     {
      return true;
     }
   else
     {
      HistorySelect(0, TimeTradeServer());
      uint    total = HistoryDealsTotal();
      ulong    ticket=0;
      double totalProfit;
      //--- for all deals
      for(uint i = BreakOutFirstOrderId; i < total; i++)
        {
         //--- try to get deals ticket
         if((ticket = HistoryDealGetTicket(i))>0)
           {
            //--- get deals properties
            int id = HistoryDealGetInteger(ticket, DEAL_ORDER);
            int entry_type = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            double profit=HistoryDealGetDouble(ticket, DEAL_PROFIT);
            //--- only for current symbol
            int entry_out = DEAL_ENTRY_OUT;
            if(symbol == symbol && entry_type == DEAL_ENTRY_OUT)
              {
               totalProfit += profit;
              }
           }
        }
      return(totalProfit > 0);
     }
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
   double lastHighBreakOutPrice = (double)GlobalVariableGet("HighBreakOutPrice");
   double lastLowBreakOutPrice = (double)GlobalVariableGet("LowBreakOutPrice");
   double highBreakOutPrice = lastHighBreakOutPrice > 0 ? lastHighBreakOutPrice : h;
   double lowBreakOutPrice = lastLowBreakOutPrice > 0 ? lastLowBreakOutPrice : l;

   if(askPrice > (highBreakOutPrice + existingOrderCount * 0.5* N)) //突破20日最高价
     {
      if(existingOrderCount == 0)
        {
         Print("New high breakout at price: " + DoubleToString(askPrice,5));
         GlobalVariableSet("HighBreakOutPrice",askPrice);
        }
      else
        {
         Print("Add on order at previous breakout price: " + DoubleToString(highBreakOutPrice,5)+" Number: " + (existingOrderCount+1));
        }
      if((existingOrderCount == 0 && IsPreviousBreakOutLoss()) || existingOrderCount>0)
        {
         ModifyExistingBuyOrderSl(existingOrderCount);
         int slPip = GetslPip();
          Print("Send Buy order");
         int orderId = trade.SendBuyOrder(TargetSymbol,UnitLots,slPip,0,"EA Buy For Price:" + DoubleToString(askPrice,5),CurrentEaMagic);
         if(orderId==0)
           {
            Print("Buy order failed");
           }
         if(existingOrderCount == 0 && orderId!=0)
           {
            BreakOutFirstOrderId = orderId;
           }

        }
     }

   if(bidPrice < (lowBreakOutPrice - (existingOrderCount * 0.5 * N)))//跌破20日最低价
     {
      if(existingOrderCount == 0)
        {
         Print("New low breakout at price: " + DoubleToString(bidPrice,5));
         GlobalVariableSet("LowBreakOutPrice",bidPrice);
        }
      else
        {
         Print("Add on order at previous breakout price: " + DoubleToString(lowBreakOutPrice,5) +" Number: " + (existingOrderCount+1));
        }
      if((existingOrderCount == 0 && IsPreviousBreakOutLoss()) || existingOrderCount>0)
        {
         ModifyExistingSellOrderSl(existingOrderCount);
         int slPip = GetslPip();
         Print("Send Sell order");
         int orderId = trade.SendSellOrder(TargetSymbol,UnitLots,slPip,0,"EA Buy For Price:" + DoubleToString(bidPrice,5),CurrentEaMagic);
         if(orderId==0)
           {
            Print("Sell order failed");
           }
         if(existingOrderCount == 0 && orderId!=0)
           {
            BreakOutFirstOrderId = orderId;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyExistingBuyOrderSl(int existingOrderCount)
  {
   if(existingOrderCount==0)
      return;
   Print("Modify Buy position sl");
   trade.ModifySl(TargetSymbol,false,POSITION_TYPE_BUY,0.5*N, CurrentEaMagic);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyExistingSellOrderSl(int existingOrderCount)
  {
   if(existingOrderCount==0)
      return;
   Print("Modify Sell position sl");
   trade.ModifySl(TargetSymbol,false,POSITION_TYPE_SELL,0.5*N, CurrentEaMagic);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOrder(double askPrice, double bidPrice, double highestInPreviousDays, double lowestInPreviousDays)
  {
   if(bidPrice <= lowestInPreviousDays)
     {
      if(trade.DoesPositionExistByMagic(TargetSymbol,CurrentEaMagic,POSITION_TYPE_BUY))
        {
         Print("Current ask price: "+ NormalizeDouble(askPrice,5) + " Current bid price: " + NormalizeDouble(bidPrice,5));
         Print("HigestExitPrice: "+ NormalizeDouble(highestInPreviousDays,5) + " Lowest bid price: " + NormalizeDouble(lowestInPreviousDays,5));
         Print("CloseAllBuy");
         trade.CloseAllBuy(TargetSymbol,CurrentEaMagic,"Reached 10 days lowest price Exit");
        }
     }
   if(askPrice >= highestInPreviousDays)
     {
      if(trade.DoesPositionExistByMagic(TargetSymbol,CurrentEaMagic,POSITION_TYPE_SELL))
        {
         Print("Current ask price: "+ NormalizeDouble(askPrice,5) + " Current bid price: " + NormalizeDouble(bidPrice,5));
         Print("HigestExitPrice: "+ NormalizeDouble(highestInPreviousDays,5) + " Lowest bid price: " + NormalizeDouble(lowestInPreviousDays,5));
         Print("CloseAllSell");
         trade.CloseAllSell(TargetSymbol,CurrentEaMagic,"Reached 10 days higest price Exit");
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
   N = NormalizeDouble(ATRValue[1],_Digits);
   if(N == 0)
     {
      return;
     }
   double contractSize = SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pointValue =  SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_TICK_VALUE);
   double absoluteATR = N * contractSize * pointValue ;
   UnitLots =  NormalizeDouble(balance * 0.01 / absoluteATR, 2);
   Print("N: "+ N+" UnitLots: " + UnitLots);
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
