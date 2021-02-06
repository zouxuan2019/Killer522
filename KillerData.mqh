//+------------------------------------------------------------------+
//|                                                   KillerData.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
class KillerData
  {
private:
   int               GetBarCount(int days,ENUM_TIMEFRAMES period);

public:
                     KillerData();
                    ~KillerData();
   int               GetPriceInfo(MqlRates &rates[],string symbol,ENUM_TIMEFRAMES period,int days);
   double            GetSymbolPoint(string symbol);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerData::GetPriceInfo(MqlRates &rates[],string symbol,ENUM_TIMEFRAMES period,int days)
  {
   ArraySetAsSeries(rates,true);
   int barCount = GetBarCount(days,period);
   return (CopyRates(symbol, period, 0, barCount,rates));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerData::GetBarCount(int days,ENUM_TIMEFRAMES period)
  {
   return (days*24*60*60 / PeriodSeconds(period));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
KillerData::KillerData()
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
KillerData::~KillerData()
  {
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double KillerData::GetSymbolPoint(string symbol)
  {
   return SymbolInfoDouble(symbol,SYMBOL_POINT) * 10;
  }
//+------------------------------------------------------------------+
