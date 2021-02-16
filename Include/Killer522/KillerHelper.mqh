//+------------------------------------------------------------------+
//|                                                 KillerHelper.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class KillerHelper
  {
public:
                     KillerHelper();
                    ~KillerHelper();
   static int               GetScanWaitingTime(ENUM_TIMEFRAMES barPeriod);
   static int               GetBarCount(int days,ENUM_TIMEFRAMES period);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerHelper:: GetScanWaitingTime(ENUM_TIMEFRAMES barPeriod)
  {
   int interval =PeriodSeconds(barPeriod);
   datetime currentDate = TimeTradeServer();
   int result=interval - (int)currentDate % interval + 60;
   return (result);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int KillerHelper::GetBarCount(int days,ENUM_TIMEFRAMES period)
  {
   return (days*24*60*60 / PeriodSeconds(period));
  }
//+------------------------------------------------------------------+
