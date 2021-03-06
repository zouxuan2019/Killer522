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

ENUM_TIMEFRAMES TradeBarPeriod = PERIOD_D1;
string TargetSymbol="EURUSD";
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
   return InitializeParameters();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InitializeParameters()// initialize daily for 20 days higest/lowest price
  {
   bool exists = trade.DoesPositionExistByMagic(TargetSymbol, CurrentEaMagic);
   Print("Does Position exist: "+exists);
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
      return(INIT_FAILED);
     }
   SetHigestLowestPrice(high,low,TotalBars,"HighestPriceIn20Days","LowestPriceIn20Days");
   SetHigestLowestPrice(high,low,ExitBars,"HighestExitPrice2","LowestExitPrice2");
   ATRHandle = iATR(TargetSymbol,TradeBarPeriod,TotalBars); // returns a handle for ATR
   if(ATRHandle==INVALID_HANDLE)
     {
      PrintFormat("%s: failed to create iATR, error code %d",__FUNCTION__,GetLastError());
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
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

   CloseOrder(askPrice,bidPrice,(double)GlobalVariableGet("HighestExitPrice2"),(double)GlobalVariableGet("LowestExitPrice2"));
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
      return true;
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

         Print("Order:" + id + "Profit:" + profit);
         //--- only for current symbol
         int entry_out = DEAL_ENTRY_OUT;
         if(symbol == symbol && entry_type == DEAL_ENTRY_OUT)
           {
            totalProfit += profit;
           }
        }
     }
   return totalProfit < 0;
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
   double lastHighBreakOutPrice = (double)GlobalVariableGet("HighBreakOutPrice1");
   double lastLowBreakOutPrice = (double)GlobalVariableGet("LowBreakOutPrice1");
   double highBreakOutPrice = lastHighBreakOutPrice > 0 ? lastHighBreakOutPrice : h;
   double lowBreakOutPrice = lastLowBreakOutPrice > 0 ? lastLowBreakOutPrice : l;
   double symbolPipValue = data.GetSymbolPip(TargetSymbol);

   double breakPrice = highBreakOutPrice + existingOrderCount * 0.5* N;
// Print("current price:" + DoubleToString(askPrice,5) +"breakPrice:"+DoubleToString(breakPrice,5) + " HighBreakoutPrice:"+ DoubleToString(highBreakOutPrice,5) + " ExistingOrderCount:"+ existingOrderCount+ "N:"+ N);

   if(askPrice > (highBreakOutPrice + existingOrderCount * 0.5* N)) //突破20日最高价
     {
      Print("break high : current price:" + DoubleToString(askPrice,5) + " HighBreakoutPrice:"+ DoubleToString(highBreakOutPrice,5) + " ExistingOrderCount:"+ existingOrderCount+ "N:"+ N);
      bool isPreviousLoss = true;
      if(existingOrderCount == 0)
        {
         isPreviousLoss = IsPreviousBreakOutLoss();
         if(isPreviousLoss == false)
           {
            BreakOutFirstOrderId = 0;
           }
        }
      Print("existingOrderCount:"+ existingOrderCount+"IsPreviousBreakOutLoss:"+isPreviousLoss);
      if(((existingOrderCount == 0 && isPreviousLoss) || existingOrderCount > 0))
        {
         if(existingOrderCount == 0)
           {
            highBreakOutPrice = askPrice;
            Print("New high breakout at price: " + DoubleToString(askPrice,5));
           }
         else
           {
            Print("Add on order at previous breakout price: " + DoubleToString(askPrice,5)+" Number: " + (existingOrderCount+1));
           }

         int slPip = GetslPip();
         Print("Send Buy order, sl:"+slPip);
         int newExistingOrderCount = trade.GetOrderCountByMagic(TargetSymbol, CurrentEaMagic);
         if(newExistingOrderCount != existingOrderCount)
           {
            Print("Conflicts1");
            return;
           }

         int orderId = trade.SendBuyOrder(TargetSymbol,UnitLots,slPip,0,"No:" + (existingOrderCount+1) + "BO:" + NormalizeDouble(highBreakOutPrice,_Digits),CurrentEaMagic);
         if(orderId==0)
           {
            Print("Buy order failed");
           }
         //else
          // {
           // double slPrice = NormalizeDouble(askPrice - slPip * symbolPipValue,_Digits);
          //  ModifyExistingOrderSl(existingOrderCount,slPrice);
          // }
         if(existingOrderCount == 0 && orderId!=0)
           {
            BreakOutFirstOrderId = orderId;
            GlobalVariableSet("HighBreakOutPrice1",askPrice);
           }
        }
     }

   if(bidPrice < (lowBreakOutPrice - (existingOrderCount * 0.5 * N)))//跌破20日最低价
     {
      Print("break high : current price:" + DoubleToString(bidPrice,5) + " LowBreakoutPrice:"+ DoubleToString(lowBreakOutPrice,5) + " ExistingOrderCount:"+ existingOrderCount+ "N:"+ N);
      bool isPreviousLoss = true;
      if(existingOrderCount == 0)
        {
         isPreviousLoss = IsPreviousBreakOutLoss();
         if(isPreviousLoss == false)
           {
            BreakOutFirstOrderId = 0;
           }
        }
      if(((existingOrderCount == 0 && isPreviousLoss) || existingOrderCount>0))
        {
         if(existingOrderCount == 0)
           {
            lowBreakOutPrice = bidPrice;
            Print("New low breakout at price: " + DoubleToString(bidPrice,5));
           }
         else
           {
            Print("Add on order at previous breakout price: " + DoubleToString(bidPrice,5) +" Number: " + (existingOrderCount+1));
           }
         int slPip = GetslPip();
         Print("Send Sell order");
         int newExistingOrderCount = trade.GetOrderCountByMagic(TargetSymbol, CurrentEaMagic);
         if(newExistingOrderCount != existingOrderCount)
           {
            Print("Conflicts2");
            return;
           }
         int orderId = trade.SendSellOrder(TargetSymbol,UnitLots,slPip,0,"No:" + (existingOrderCount+1)+ "BO:" + NormalizeDouble(lowBreakOutPrice,_Digits),CurrentEaMagic);
         if(orderId == 0)
           {
            Print("Sell order failed");
           }
        // else
           //{
           // double slPrice = NormalizeDouble(bidPrice + slPip*symbolPipValue,_Digits);
           // ModifyExistingOrderSl(existingOrderCount,slPrice);
           //}
         if(existingOrderCount == 0 && orderId!=0)
           {

            BreakOutFirstOrderId = orderId;
            GlobalVariableSet("LowBreakOutPrice1",bidPrice);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyExistingOrderSl(int existingOrderCount,double slPrice)
  {
   if(existingOrderCount==0)
      return;
   Print("Modify position sl");
   trade.ModifySl(TargetSymbol,POSITION_TYPE_BUY,slPrice, CurrentEaMagic);
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
         GlobalVariableSet("HighBreakOutPrice1",0);
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
         GlobalVariableSet("LowBreakOutPrice1",0);
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
   double slRatio = 0.5 * N;
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   if(HistoryDealSelect(trans.deal))
     {
      ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
      ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(trans.deal, DEAL_REASON);
      if(EnumToString(deal_entry) == "DEAL_ENTRY_OUT" && EnumToString(deal_reason) == "DEAL_REASON_SL")
        {
         Print("SL Event triggered");
         int exitingOrderCount = trade.GetOrderCountByMagic(TargetSymbol, CurrentEaMagic);
         if(exitingOrderCount == 0)
           {
            GlobalVariableSet("HighBreakOutPrice1",0);
            GlobalVariableSet("LowBreakOutPrice1",0);
           }
        }
     }
  }

//+------------------------------------------------------------------+
