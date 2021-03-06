//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#include "KillerTrade.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class KillerPositionManagement
  {
public:

                     KillerPositionManagement();
                    ~KillerPositionManagement();
   static bool               ShouldStopEAByBalance();
   static bool              ShouldStopEAByEquity(string symbol, int magic);
   static void       SetInitialBalance();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool KillerPositionManagement::ShouldStopEAByBalance()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double initialBalance = (double)GlobalVariableGet("InitialBalance");
   bool result=balance/initialBalance<=0.5;
   if(result)
     {
      Print("InitialBalance:" + initialBalance + " Current Balance:" + balance + "ratio:"+balance/initialBalance);
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool KillerPositionManagement::ShouldStopEAByEquity(string symbol, int magic)
  {
   for(int i= PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         if(PositionGetInteger(POSITION_MAGIC) == magic && PositionGetString(POSITION_SYMBOL) == symbol)
           {
            double profit= PositionGetDouble(POSITION_PROFIT);
            double equity = AccountInfoDouble(ACCOUNT_EQUITY);
            if(profit / equity >= 0.3)
              {
               Print("Position No:" + ticket + "Profit:" + profit +"equity:"+ equity);
               return true;
              }
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KillerPositionManagement::SetInitialBalance()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   GlobalVariableSet("InitialBalance", balance);
  }
//+------------------------------------------------------------------+
