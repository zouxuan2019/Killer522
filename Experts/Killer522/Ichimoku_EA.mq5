//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "..\..\Include\Killer522\KillerData.mqh"
#include "..\..\Include\Killer522\KillerTrade.mqh"
#include "..\..\Include\Killer522\KillerHelper.mqh"

int                  tenkan_sen=9;              // period of Tenkan-sen
int                  kijun_sen=26;              // period of Kijun-sen
int                  senkou_span_b=52;          // period of Senkou Span B
ENUM_TIMEFRAMES      BarPeriod = PERIOD_CURRENT;     // timeframe
string TargetSymbol = _Symbol;
bool IsCurrentCloudGreen;
bool IsCurrentTenkanGraterThanKijun;
KillerData data;
KillerTrade trade;
int handle;
double slPercentage = 0.02;
int CurrentEaMagic =210513;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//GetOpenCloseTime();
   handle =  iCustom(Symbol(),PERIOD_CURRENT,"Killer522\\IchimokuZX",9,26,52);
   int sleepTime = KillerHelper::GetScanWaitingTime(BarPeriod);
   Sleep(sleepTime * 1000);
   DoWork();
   EventSetTimer(PeriodSeconds(BarPeriod));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetOpenCloseTime()
  {
   MqlDateTime open, close;
   datetime openDT, closeDT;
   bool sessionTrade = SymbolInfoSessionTrade(TargetSymbol, MONDAY, 0, openDT, closeDT);
   TimeToStruct(openDT, open);
   PrintFormat("Opening Time(%d),Closing Time(%d) ", open.hour);
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
//|                                                                  |
//+------------------------------------------------------------------+
void DoWork()
  {
   if(handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
                  TargetSymbol,
                  EnumToString(BarPeriod),
                  GetLastError());
      //--- the indicator is stopped early
      return;
     }

   double         Tenkan_sen_Buffer[];
   double         Kijun_sen_Buffer[];
   double         Senkou_Span_A_Buffer[];
   double         Senkou_Span_B_Buffer[];
   double         Chinkou_Span_Buffer[];

   ArraySetAsSeries(Tenkan_sen_Buffer,true);
   ArraySetAsSeries(Kijun_sen_Buffer,true);
   ArraySetAsSeries(Senkou_Span_A_Buffer,true);
   ArraySetAsSeries(Senkou_Span_B_Buffer,true);
   ArraySetAsSeries(Chinkou_Span_Buffer,true);

   CopyBuffer(handle,0,0,3,Tenkan_sen_Buffer);
   CopyBuffer(handle,1,0,3,Kijun_sen_Buffer);
   CopyBuffer(handle,2,0,3,Senkou_Span_A_Buffer);
   CopyBuffer(handle,3,0,3,Senkou_Span_B_Buffer);
   CopyBuffer(handle,4,0,3,Chinkou_Span_Buffer);
   PrintComment(0,Tenkan_sen_Buffer,Kijun_sen_Buffer,Senkou_Span_A_Buffer,Senkou_Span_B_Buffer,Chinkou_Span_Buffer);
   PlaceOrder(Tenkan_sen_Buffer,Kijun_sen_Buffer,Senkou_Span_A_Buffer,Senkou_Span_B_Buffer,Chinkou_Span_Buffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceOrder(double &Tenkan_sen_Buffer[], double &Kijun_sen_Buffer[], double &Senkou_Span_A_Buffer[], double &Senkou_Span_B_Buffer[], double &Chinkou_Span_Buffer[])
  {
   double tenkanSenValue0= NormalizeDouble(Tenkan_sen_Buffer[0],_Digits);
   double kijunSenValue0= NormalizeDouble(Kijun_sen_Buffer[0],_Digits);
   double senkouSpanAValue0= NormalizeDouble(Senkou_Span_A_Buffer[0],_Digits);
   double senkouSpanBValue0= NormalizeDouble(Senkou_Span_B_Buffer[0],_Digits);

   double tenkanSenValue1= NormalizeDouble(Tenkan_sen_Buffer[1],_Digits);
   double kijunSenValue1= NormalizeDouble(Kijun_sen_Buffer[1],_Digits);
   double senkouSpanAValue1= NormalizeDouble(Senkou_Span_A_Buffer[1],_Digits);
   double senkouSpanBValue1= NormalizeDouble(Senkou_Span_B_Buffer[1],_Digits);
   bool isCurrentCloudGreen = senkouSpanAValue0 > senkouSpanBValue0;
   bool isPreviousCloudGreen = senkouSpanAValue1 > senkouSpanBValue1;
   bool isCloudColorChanged = (isCurrentCloudGreen != isPreviousCloudGreen);
   bool IsCurrentTenkanGraterThanKijun = tenkanSenValue0 > kijunSenValue0;
   bool IsPreviousTenkanGraterThanKijun = tenkanSenValue1 > kijunSenValue1;
   bool isTKLineCrossChanged = IsCurrentTenkanGraterThanKijun != IsPreviousTenkanGraterThanKijun;
   string orderType;
   if(isCloudColorChanged || isTKLineCrossChanged)
     {
      if(isCurrentCloudGreen && IsCurrentTenkanGraterThanKijun)
        {
         orderType = "Buy";
        }
      if(!isCurrentCloudGreen && !IsCurrentTenkanGraterThanKijun)
        {
         orderType = "Sell";
        }
     }
   if(orderType == NULL)
     {
      return;
     }

   MqlRates totalBars[];
   int totalBarCount = data.GetPriceInfo(totalBars,TargetSymbol,BarPeriod,2);
   double targetPrice = totalBars[1].close;
   int slPip = GetSellSlPip(targetPrice, slPercentage);
   double positionSize = GetPositionSize(targetPrice);
   Print("TargetPrice:" + targetPrice + " sl1:" + slPip);
   datetime expiration = TimeTradeServer() + (3* PeriodSeconds(BarPeriod) + 60);// check with Derrick
   if(orderType == "Sell")
     {
      trade.SendPendingSellOrderByPrice(BarPeriod,TargetSymbol,targetPrice, positionSize, slPip, 0, "EA Pending Sell price:" + DoubleToString(targetPrice,5), CurrentEaMagic, expiration);
     }
   else
     {
      trade.SendPendingBuyOrderByPrice(BarPeriod,TargetSymbol,targetPrice, positionSize, slPip, 0,"EA Pending Buy price:" + DoubleToString(targetPrice,5), CurrentEaMagic, expiration);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   AdjustPositionSl(TargetSymbol,CurrentEaMagic);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AdjustPositionSl(string symbol, int magic)
  {

   int t=PositionsTotal();
   for(int i=t-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL)==symbol && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
        {
         PositionSelectByTicket(ticket);
         ENUM_POSITION_TYPE positionType = PositionGetInteger(POSITION_TYPE);
         double openPrice =  PositionGetDouble(POSITION_PRICE_OPEN);
         double oldSl = PositionGetDouble(POSITION_SL);
         if(IsProfitIncreasedToThreadhold(oldSl,positionType))
           {
            double slPrice = positionType == POSITION_TYPE_BUY ? (oldSl *(1+slPercentage)) : (oldSl * (1- slPercentage));
            MqlTradeRequest request = {0};
            MqlTradeResult  result = {0};
            request.action = TRADE_ACTION_SLTP;
            request.position = ticket;
            request.symbol = symbol;
            request.sl = NormalizeDouble(slPrice,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsProfitIncreasedToThreadhold(double oldSlPrice, ENUM_POSITION_TYPE positionType)
  {
   if(positionType ==POSITION_TYPE_BUY)
     {
      double bidPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_BID),_Digits);
      return (bidPrice >= oldSlPrice*(1+ 2*slPercentage));
     }
   double askPrice = NormalizeDouble(SymbolInfoDouble(TargetSymbol,SYMBOL_ASK),_Digits);
   return (askPrice <= oldSlPrice* (1- 2*slPercentage));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSellSlPip(double targetPrice, double slPercentage)
  {
   double slDifference= targetPrice * slPercentage;
   int slPipPoint= slDifference / data.GetSymbolPip(TargetSymbol);
   return slPipPoint;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPositionSize(double targetPrice)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double contractSize = SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pointValue =  SymbolInfoDouble(TargetSymbol, SYMBOL_TRADE_TICK_VALUE);
   double absoluteLoss = targetPrice * slPercentage * contractSize * pointValue ;
   double lots =  NormalizeDouble(balance * slPercentage / absoluteLoss, 2);
   return lots;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintComment(int index, double &Tenkan_sen_Buffer[], double &Kijun_sen_Buffer[], double &Senkou_Span_A_Buffer[], double &Senkou_Span_B_Buffer[], double &Chinkou_Span_Buffer[])
  {
   double tenkanSenValue= NormalizeDouble(Tenkan_sen_Buffer[index],_Digits);
   double kijunSenValue= NormalizeDouble(Kijun_sen_Buffer[index],_Digits);
   double senkouSpanAValue= NormalizeDouble(Senkou_Span_A_Buffer[index],_Digits);
   double senkouSpanBValue= NormalizeDouble(Senkou_Span_B_Buffer[index],_Digits);
   double chinkouSpanValue= NormalizeDouble(Chinkou_Span_Buffer[index],_Digits);
   string currentDate =  TimeToString(TimeTradeServer(),TIME_DATE);


   string CurrentValuesComment=  "Symbol:"+ TargetSymbol
                                 +"\nCurrent Date:" + currentDate
                                 + "\n PreTenkanSenValue: " + tenkanSenValue
                                 + "\n PreKijunSenValue: " + kijunSenValue +"\n"
                                 + " PreSenkouSpanAValue: " + senkouSpanAValue+ "\n"+
                                 " PreSenkouSpanBValue: " + senkouSpanBValue;
// + "\n" + " ChinkouSpanValue: " + chinkouSpanValue ;
   SuperCommentLab(CurrentValuesComment);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SuperCommentLab(string commentText)
  {
   string sep = "\n";
   ushort u_sep = StringGetCharacter(sep,0);
   string result[];
   int k = StringSplit(commentText,u_sep,result);
   for(int i=0; i<k; i++)
     {
      CommentLab(i,10+i*25,result[i]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommentLab(string label_name,int yCor,string CommentText)
  {
   string CommentLabel;
   int CommentIndex = 0;

   StringTrimLeft(CommentText);

   if(CommentText == "")
     {
      return;
     }


   ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,label_name, OBJPROP_CORNER, 0);
//--- set X coordinate
   ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,20);
//--- set Y coordinate
   ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,yCor);
//--- define text color
   ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrGoldenrod);
//--- define text for object Label
   ObjectSetString(0,label_name,OBJPROP_TEXT,CommentText);
//--- define font
   ObjectSetString(0,label_name,OBJPROP_FONT,"Arial");
//--- define font size
   ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,16);
//--- 45 degrees rotation clockwise
//    ObjectSetDouble(0,label_name,OBJPROP_ANGLE,-45);
//--- disable for mouse selecting
   ObjectSetInteger(0,label_name,OBJPROP_SELECTABLE,true);
//--- draw it on the chart
   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   DoWork();
  }

//+------------------------------------------------------------------+
