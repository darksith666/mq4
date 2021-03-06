//+------------------------------------------------------------------+
//|                                                        Bands.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Bollinger Bands"
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 DodgerBlue
#property indicator_color2 DodgerBlue
#property indicator_color3 DodgerBlue
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2

//--- indicator parameters
extern int    InpBandsPeriod=20;      // Bands Period
input int    InpBandsShift=0;        // Bands Shift
input double InpBandsDeviations=2.0; // Bands Deviations
//--- buffers
double ExtMovingBuffer[];
double ExtUpperBuffer[];
double ExtLowerBuffer[];
double ExtStdDevBuffer[];

bool DST=False;   //-----夏令时
extern string comm = "FXCM 3 FOREX-USA 9 FOREX AU 1";
extern int BrokerTimeZone=0;
extern bool EnableAlert = false;
extern bool EnableAlertLow = false;
extern bool EnableAlertHigh = false;

extern int     NumberOfDays=50;
extern string  AsiaBegin   ="00:00";
extern string  AsiaEnd     ="10:00";
extern color   AsiaColor   =Goldenrod;
extern string  EurBegin    ="07:00";
extern string  EurEnd      ="16:00";
extern color   EurColor    =Tan;
extern string  USABegin1    ="13:30";
extern string  USAEnd1      ="18:00";
extern string  USABegin2    ="18:00";
extern string  USAEnd2      ="23:00";
extern color   USAColor1    =PaleGreen;
extern color   USAColor2    =Lime;
//----- Variabes
datetime       DateTrade, TimeBeginObject, TimeEndObject;
int            i, BarBegin, BarEnd;
double         PriceHighObject, PriceLowObject;

datetime alarmtime = 0;
int      lastbar;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- 1 additional buffer used for counting.
   IndicatorBuffers(4);
   IndicatorDigits(Digits);
//--- middle line
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMovingBuffer);
   SetIndexShift(0,InpBandsShift);
   SetIndexLabel(0,"Bands SMA");
//--- upper band
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ExtUpperBuffer);
   SetIndexShift(1,InpBandsShift);
   SetIndexLabel(1,"Bands Upper");
//--- lower band
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,ExtLowerBuffer);
   SetIndexShift(2,InpBandsShift);
   SetIndexLabel(2,"Bands Lower");
//--- work buffer
   SetIndexBuffer(3,ExtStdDevBuffer);
//--- check for input parameter
   if(InpBandsPeriod<=0)
     {
      Print("Wrong input parameter Bands Period=",InpBandsPeriod);
      return(INIT_FAILED);
     }
//---
   SetIndexDrawBegin(0,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(1,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(2,InpBandsPeriod+InpBandsShift);
   
   MakeAllLabels();
   
   DeleteObjects();
   for(i=0; i<NumberOfDays; i++)
     {
      CreateObjects("AS"+i, AsiaColor);
      CreateObjects("EU"+i, EurColor);
      CreateObjects("USA"+i, USAColor1);
      CreateObjects("USB"+i, USAColor2);
     }
   if( Period() < 15) InpBandsPeriod = 100;  
   if( Period() == 15) InpBandsPeriod = 50;  
   IndicatorSetString(INDICATOR_SHORTNAME,"Bands("+IntegerToString(InpBandsPeriod)+")");   
//--- initialization done
   return(INIT_SUCCEEDED);
  }


void MakeAllLabels()
{
   ObjectMakeLabel ("time",15,15, 0, CORNER_RIGHT_LOWER);
   ObjectMakeLabel( "msg", 15,35, 0, CORNER_RIGHT_LOWER );
   //----------------------------------------------
   ObjectMakeLabel( "Beijing", 15,35 );
   ObjectMakeLabel( "Beijingt", 95, 35 );
   ObjectMakeLabel( "London", 15, 52 );
   ObjectMakeLabel( "Londont", 95, 52 );
   ObjectMakeLabel( "NewYork", 15,69 );
   ObjectMakeLabel( "NewYorkt", 95,69 );
   ObjectMakeLabel( "Server", 15,69 +17);
   ObjectMakeLabel( "Servert", 95,69+17 );
   ObjectMakeLabel( "policy", 15,69+35);
   ObjectMakeLabel( "insurance", 15,69+35+17);

}

int deinit()
{
   //---- 
   ObjectDelete(0, "time");
   ObjectDelete(0, "msg");
   ObjectDelete(0, "London");
   ObjectDelete(0, "Londont");
   ObjectDelete(0, "NewYork");
   ObjectDelete(0, "NewYorkt");
   ObjectDelete(0, "insurance");
   ObjectDelete(0, "Server");
   ObjectDelete(0, "Severt");
   ObjectDelete(0, "Beijing");
   ObjectDelete(0, "Beijingt");
   ObjectDelete(0, "policy");
   //----
   DeleteObjects();
   return(0);
}

//+------------------------------------------------------------------+
void timecall()
{

color        LabelColor=Black;
color        ClockColor=Blue;
string       Font="Verdana";
int          FontSize=13;
int          Corner=0;
int BeiJingTZ =8;
int LondonTZ = 1;
int NewYorkTZ = -4;
int SydneyTZ = 10;

   int dstDelta=0;
   if ( DST )
      dstDelta = 1;
  
   datetime GMT = CurTime() - (BrokerTimeZone)*3600;
   datetime BeiJing = GMT + ( BeiJingTZ ) * 3600;
   datetime London = GMT + (LondonTZ ) * 3600;
   datetime NewYork = GMT + (NewYorkTZ ) * 3600;
   datetime Sydney = GMT + (SydneyTZ + dstDelta) * 3600;
   
   //Print( brokerTime, " ", GMT, " ", local, " ", london, " ", tokyo, " ", newyork  );
  
   string BeiJingTime = TimeToStr(BeiJing, TIME_MINUTES  );
   string LondonTime = TimeToStr(London, TIME_MINUTES  );
   string NewYorkTime = TimeToStr(NewYork, TIME_MINUTES  );
   string SydneyTime = TimeToStr(Sydney, TIME_MINUTES  );
   
   if( ObjectFind(ChartID(), "msg") == false)
     {
         MakeAllLabels();
     } 
   ObjectSetText( "Beijing", "Beijing:",FontSize,Font, LabelColor );  
   ObjectSetText( "Beijingt",BeiJingTime,FontSize,Font, ClockColor );
   ObjectSetText( "London", "London:", FontSize,Font, LabelColor );
   ObjectSetText( "Londont",LondonTime,FontSize,Font, ClockColor );
   ObjectSetText( "NewYork", "NewYork:",FontSize, Font, LabelColor );
   ObjectSetText( "NewYorkt",NewYorkTime ,FontSize,Font, ClockColor );
   ObjectSetText( "Server", "Server:",FontSize, Font, LabelColor );
   ObjectSetText( "Servert", TimeToStr(CurTime(), TIME_MINUTES  ) ,FontSize,Font, ClockColor );
   double marginValue=MarketInfo(Symbol(),MODE_MARGINREQUIRED);
   ObjectSetText( "insurance","Deposite:"+DoubleToStr(marginValue,0)+"  Point:"+Point,FontSize,Font, ClockColor );
   ObjectSetText( "policy", "Spreads："+DoubleToStr(MarketInfo(Symbol(),MODE_SPREAD),0)+"--"+DoubleToStr(Ask, Digits),FontSize,Font, ClockColor);
   CandleTime();
}

void CandleTime()
{
	double i;
   int mi,m,s;
   m=Time[0]+Period()*60-CurTime();
   i=m/60.0;
   s=m%60;
   mi=(m-m%60)/60;
   int a = 0;
   bool r = isReverse(1,0);
   int d = 4;
   double dd = 0.0001;
	if( Ask > 10){ d = 2; dd = 0.1;}
	if( Ask > 1000) dd = 1;
	if(  Period() >= 60 && (mi == a || r) && alarmtime == 0)
	{
	   string as = "阳线";
	   if( Open[0] > Close[0]) as = "阴线";
	   if( r && EnableAlert == true) Alert(Symbol()+"-"+IntegerToString(Period())+"["+DoubleToString(Ask,d)+"],"+as+" reverse="+IntegerToString(r)+"@"+TimeToStr(TimeCurrent()));
	   alarmtime = CurTime();
	}
   else
   {
      if(  alarmtime > 0 && CurTime() - alarmtime > MathMax(120, mi*60/2 )) alarmtime = 0;
   }
   double atr = iATR(NULL, PERIOD_D1, 3, 0);
   ObjectSetText("time", "K Line"+StringFormat("%02d",mi)+":"+StringFormat("%02d",s)+" Avg Cost:"+DoubleToStr(GetOrderAvg(0),d)+"/"+DoubleToStr(GetOrderAvg(1),d)/*+" 当前价："+DoubleToStr(Bid,d)+"/"+DoubleToStr(Ask,d)*/, 13, "Verdana", Blue);
   string msg="["+DoubleToStr(ExtUpperBuffer[lastbar] - ExtLowerBuffer[lastbar],d)+"]ATR="+DoubleToStr(atr, Digits)+" ["+DoubleToStr(iLow(NULL, PERIOD_D1, 0)+atr, Digits)+"-"+DoubleToStr(iHigh(NULL, PERIOD_D1, 0)-atr, Digits)+"] ";
   ObjectSetText("msg", msg, 13, "Verdana", Blue);


}

void ObjectMakeLabel( string n, int xoff, int yoff, int window = 0, int Corner=0 ) 
  {
   {
      ObjectCreate( ChartID(), n, OBJ_LABEL, window, 0, 0 );
      ObjectSet( n, OBJPROP_CORNER, Corner );
      ObjectSet( n, OBJPROP_XDISTANCE, xoff );
      ObjectSet( n, OBJPROP_YDISTANCE, yoff );
      ObjectSet( n, OBJPROP_BACK, false );
      ObjectSet( n, OBJPROP_FONTSIZE, 8);
    }
  }
 

  bool isReverse(int m, int n)
{
   if(MathAbs(Open[m] - Close[m]) < 3*Point)  return false;
   
   if( Open[m] < Close[m])
   {
      if( Open[n] > Close[n] && Close[n] < Open[m]) return true;
   }
   else
   {
      if( Open[n] < Close[n] && Close[n] > Open[m]) return true;
   }   
   return false;
}
double GetOrderAvg(int otype = -1)
{
   double avg = 0;
   int n = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( OrderSymbol()!=Symbol() || OrderType() > OP_SELL || (OrderType() != otype && otype != -1)) continue;
      //---- check order type 
      avg += OrderOpenPrice();
      n++;
     }
     if( n == 0) return 0;
     return avg/n;
}
//+------------------------------------------------------------------+
void DoAlert(string UD)
{
   if (!NewBar()) return;
   //PlaySound ("Alert2");
   Alert(Symbol()," ",Period()," Boll Touch at ",UD);
}

bool NewBar()
{
   static datetime ndt  = 0;
   if (ndt != Time[0])
   {
      ndt = Time[0];
      return(true);
   }
   return(false);
}

void toucher()
{
     // 1. Prices were rising.
      // 2. Prices touched the upper band.
      // 3. The price bar closed lower than it
      // opened when prices were previously rising.
      // or vice versa 
      if ((High[1]>=ExtUpperBuffer[lastbar-1] && Close[0] < ExtUpperBuffer[lastbar])||
   	    (Low[1]<=ExtUpperBuffer[lastbar-1] && Close[0] > ExtUpperBuffer[lastbar])  )
   	{
		   if( EnableAlertHigh) DoAlert("Upper");
	   }
      if ((Low[1]<=ExtLowerBuffer[lastbar-1] && Close[0] > ExtLowerBuffer[lastbar])  ||
          (High[1]>=ExtLowerBuffer[lastbar-1] && Close[0] < ExtLowerBuffer[lastbar])    )
      {
         if( EnableAlertLow) DoAlert("Lower");
	   }
}

//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,pos;
//---
   if(rates_total<=InpBandsPeriod || InpBandsPeriod<=0)
      return(0);
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtMovingBuffer,false);
   ArraySetAsSeries(ExtUpperBuffer,false);
   ArraySetAsSeries(ExtLowerBuffer,false);
   ArraySetAsSeries(ExtStdDevBuffer,false);
   ArraySetAsSeries(close,false);
//--- initial zero
   if(prev_calculated<1)
     {
      for(i=0; i<InpBandsPeriod; i++)
        {
         ExtMovingBuffer[i]=EMPTY_VALUE;
         ExtUpperBuffer[i]=EMPTY_VALUE;
         ExtLowerBuffer[i]=EMPTY_VALUE;
        }
     }
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   int mpos = pos;
   int mrates_total = rates_total;
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      //--- middle line
      ExtMovingBuffer[i]=SimpleMA(i,InpBandsPeriod,close);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,close,ExtMovingBuffer,InpBandsPeriod);
      //--- upper line
      ExtUpperBuffer[i]=ExtMovingBuffer[i]+InpBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtLowerBuffer[i]=ExtMovingBuffer[i]-InpBandsDeviations*ExtStdDevBuffer[i];
      //---
     }
     if( Period() <= -5) 
     {
         for(i=mpos; i<mrates_total && !IsStopped(); i++) ExtMovingBuffer[i]=EMPTY_VALUE;
      
     }
     lastbar = rates_total-1;
     timecall();
     toucher();
     TradeTime();
	   //if( NewBar() ) Print("Band:",Low[1],"-",ExtLowerBuffer[rates_total-2],"-",Close[0],"-",ExtLowerBuffer[rates_total-1],"=",ExtMovingBuffer[rates_total-1],"pos=",pos,"ratestotal=",rates_total);
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position>=period)
     {
      //--- calcualte StdDev
      for(int i=0; i<period; i++)
         StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
      StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
     }
//--- return calculated value
   return(StdDev_dTmp);
  }
//+------------------------------------------------------------------+
int TradeTime()
  {
   int    counted_bars=IndicatorCounted();
//----
   DateTrade=CurTime();
   for(i=0; i<NumberOfDays; i++)
     {
      DrawObjects(DateTrade, "AS"+i, AsiaBegin, AsiaEnd);
      DrawObjects(DateTrade, "EU"+i, EurBegin, EurEnd);
      DrawObjects(DateTrade, "USA"+i, USABegin1, USAEnd1);
      DrawObjects(DateTrade, "USB"+i, USABegin2, USAEnd2);
      DateTrade=decDateTradeDay(DateTrade);
      while(TimeDayOfWeek(DateTrade)> 5)
         DateTrade=decDateTradeDay(DateTrade);
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateObjects(string NameObject, color ColorObject)
  {
   ObjectCreate(NameObject, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
   ObjectSet(NameObject, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(NameObject, OBJPROP_COLOR, ColorObject);
   ObjectSet(NameObject, OBJPROP_BACK, True);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteObjects()
  {
   for(i=0; i < NumberOfDays; i++)
     {
      ObjectDelete("AS"+i);
      ObjectDelete("EU"+i);
      ObjectDelete("USA"+i);
      ObjectDelete("USB"+i);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawObjects(datetime DateTrade, string NameObject, string TimeBegin, string TimeEnd)
  {
   TimeBeginObject=StrToTime(TimeToStr(DateTrade, TIME_DATE)+" "+TimeBegin);
   TimeEndObject=StrToTime(TimeToStr(DateTrade, TIME_DATE)+" "+TimeEnd);
   BarBegin=iBarShift(NULL, 0, TimeBeginObject);
   BarEnd=iBarShift(NULL, 0, TimeEndObject);
   PriceHighObject=High[iHighest(NULL, 0, MODE_HIGH, BarBegin - BarEnd, BarEnd)];
   PriceLowObject=Low [iLowest (NULL, 0, MODE_LOW , BarBegin - BarEnd, BarEnd)];
   ObjectSet(NameObject, OBJPROP_TIME1 , TimeBeginObject);
   ObjectSet(NameObject, OBJPROP_PRICE1, PriceHighObject);
   ObjectSet(NameObject, OBJPROP_TIME2 , TimeEndObject);
   ObjectSet(NameObject, OBJPROP_PRICE2, PriceLowObject);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime decDateTradeDay (datetime DateTrade)
  {
   int ty=TimeYear(DateTrade);
   int tm=TimeMonth(DateTrade);
   int td=TimeDay(DateTrade);
   int th=TimeHour(DateTrade);
   int ti=TimeMinute(DateTrade);
//----
   td--;
   if (td==0)
     {
      tm--;
      if (tm==0)
        {
         ty--;
         tm=12;
        }
      if (tm==1 || tm==3 || tm==5 || tm==7 || tm==8 || tm==10 || tm==12)
         td=31;
      if (tm==2)
         if (MathMod(ty, 4)==0)
            td=29;
         else
            td=28;
      if (tm==4 || tm==6 || tm==9 || tm==11)
         td=30;
     }
//----   
   return(StrToTime(ty+"."+tm+"."+td+" "+th+":"+ti));
  }
//+------------------------------------------------------------------+