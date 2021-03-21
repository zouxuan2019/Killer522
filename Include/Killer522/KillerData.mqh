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
public:
                     KillerData();
                    ~KillerData();
   int               GetPriceInfo(MqlRates &rates[],string symbol,ENUM_TIMEFRAMES period,int days);
   int               GetLowInfo(double &lows[],string symbol,ENUM_TIMEFRAMES period,int totalBarNumber);
   int               GetHighInfo(double &highs[],string symbol,ENUM_TIMEFRAMES period,int totalBarNumber);
   double            GetSymbolPip(string symbol);
   double            GetSymbolPipValue(string symbol);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerData::GetHighInfo(double &highs[],string symbol,ENUM_TIMEFRAMES period,int totalBarNumber)
  {
   ArraySetAsSeries(highs,true);
   return (CopyHigh(symbol, period, 0, totalBarNumber,highs));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerData::GetLowInfo(double &lows[],string symbol,ENUM_TIMEFRAMES period,int totalBarNumber)
  {
   ArraySetAsSeries(lows,true);
   return (CopyLow(symbol, period, 0, totalBarNumber,lows));
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
double KillerData::GetSymbolPip(string symbol)
  {
   return SymbolInfoDouble(symbol,SYMBOL_POINT) * 10;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double KillerData::GetSymbolPipValue(string symbol)
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
//+------------------------------------------------------------------+
