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
   string            GetDateTimeString(datetime time);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerData::GetPriceInfo(MqlRates &rates[],string symbol,ENUM_TIMEFRAMES period,int totalBarNumber)
  {
   ArraySetAsSeries(rates,true);
   return (CopyRates(symbol, period, 0, totalBarNumber,rates));
  }
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


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string KillerData::GetDateTimeString(datetime time)
  {
   return TimeToString(time,TIME_DATE)+" " +TimeToString(time,TIME_MINUTES);
  }
//+------------------------------------------------------------------+
