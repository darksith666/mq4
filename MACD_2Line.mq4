//+------------------------------------------------------------------+
//|                                                    MACD2Line.mq4 |
//|                                Copyright (c) 2015 michael zhu    |
//|                                    mailto:michaelitg@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2015 michael zhu"
#property link      "mailto:michaelitg@outlook.com"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Green

//---- input parameters
extern int       FastMAPeriod=60;
extern int       SlowMAPeriod=130;
extern int       SignalMAPeriod=45;

datetime alarmtime = 0;

//---- buffers
double MACDLineBuffer[];
double SignalLineBuffer[];
double HistogramBuffer[];

//---- variables
double alpha = 0;
double alpha_1 = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
   //---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,MACDLineBuffer);
   SetIndexDrawBegin(0,SlowMAPeriod);
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT);
   SetIndexBuffer(1,SignalLineBuffer);
   SetIndexDrawBegin(1,SlowMAPeriod+SignalMAPeriod);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(2,HistogramBuffer);
   SetIndexDrawBegin(2,SlowMAPeriod+SignalMAPeriod);
   //---- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACD("+FastMAPeriod+","+SlowMAPeriod+","+SignalMAPeriod+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
   //----
	alpha = 2.0 / (SignalMAPeriod + 1.0);
	alpha_1 = 1.0 - alpha;
   //----
   return(0);
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   //----
   ObjectFind(0, ); 
   ObjectDelete(0, "time");
   //----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int limit;
   int counted_bars = IndicatorCounted();
   //---- check for possible errors
   if (counted_bars<0) return(-1);
   //---- last counted bar will be recounted
   if (counted_bars>0) counted_bars--;
   limit = Bars - counted_bars;

   for(int i=limit; i>=0; i--)
   {
      MACDLineBuffer[i] = iMA(NULL,0,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,i) - iMA(NULL,0,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,i);
      SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
      HistogramBuffer[i] = MACDLineBuffer[i] - SignalLineBuffer[i];
   }
   timecall();
   //----
   return(0);
}
//+------------------------------------------------------------------+
void timecall()
{

color        LabelColor=Blue;
color        ClockColor=Blue;
string       Font="Verdana";
int          FontSize=13;
int          Corner=0;
int BeiJingTZ =8;
int LondonTZ = 0;
int NewYorkTZ = -5;
int SydneyTZ = 10;

   int dstDelta=0;
   if ( DST )
      dstDelta = 1;
  
   datetime GMT = CurTime() - (BrokerTimeZone- dstDelta)*3600;
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
   ObjectSetText( "北京", "北京:",FontSize,Font, LabelColor );  
   ObjectSetText( "北京时间",BeiJingTime,FontSize,Font, ClockColor );
   ObjectSetText( "伦敦", "伦敦:", FontSize,Font, LabelColor );
   ObjectSetText( "伦敦时间",LondonTime,FontSize,Font, ClockColor );
   ObjectSetText( "纽约", "纽约:",FontSize, Font, LabelColor );
   ObjectSetText( "纽约时间",NewYorkTime ,FontSize,Font, ClockColor );
   ObjectSetText( "悉尼", "悉尼:",FontSize, Font, LabelColor );
   ObjectSetText( "悉尼时间",SydneyTime ,FontSize,Font, ClockColor );
   double marginValue=MarketInfo(Symbol(),MODE_MARGINREQUIRED);
   ObjectSetText( "insurance","一手保证金:"+DoubleToStr(marginValue,0),FontSize,Font, ClockColor );
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
   bool r = isReverse2(1,0);
	if(  Period() >= 15 && (mi == a || r) && alarmtime == 0)
	{
	   if( r ) PlaySound("reverse.wav");
	   else if(Symbol() == "AUDUSD") PlaySound("alert2.wav");
	   if( r || Symbol() == "AUDUSD") Print(Symbol()+Period()," alarm , reverse=",r,"@",TimeToStr(TimeCurrent()));
	   if( r || Symbol() == "AUDUSD" ) Alert(Symbol()+Period()+"["+DoubleToString(Open[1] - Close[1])+"] alarm , reverse="+r+"@"+TimeToStr(TimeCurrent()));
	   alarmtime = CurTime();
	}
   else
   {
      if(  alarmtime > 0 && CurTime() - alarmtime > MathMax(120, mi*60/2 )) alarmtime = 0;
   }
   string msg="ATR="+ DoubleToStr( iATR(Symbol(),PERIOD_D1,14,0)*10000,0)
                +" ["+ DoubleToStr( iLow(Symbol(),PERIOD_D1,0),4)
                +"-"+ DoubleToStr( iHigh(Symbol(),PERIOD_D1,0),4)
                +"] 往上:"+ DoubleToStr( (iLow(Symbol(),PERIOD_D1,0)+iATR(Symbol(),PERIOD_D1,14,0)),4)
                +"往下:"+ DoubleToStr( (iHigh(Symbol(),PERIOD_D1,0)- iATR(Symbol(),PERIOD_D1,14,0)),4);
   //ObjectSetText("time", TimeToStr(Time[1])+"xx"+TimeToStr(TimeCurrent())+StringFormat("--%d",Period()*60)+StringFormat("--%02d",m)+"K线"+StringFormat("%02d",mi)+"分"+StringFormat("%02d",s)+"秒"+" 平均成本:"+DoubleToStr(GetOrderAvg(),4)+" 当前价："+DoubleToStr(Bid,4)+"/"+DoubleToStr(Ask,4), 13, "Verdana", Blue);
   ObjectSetText("time", "K线"+StringFormat("%02d",mi)+"分"+StringFormat("%02d",s)+"秒"+" 平均成本:"+DoubleToStr(GetOrderAvg(),4)+" 当前价："+DoubleToStr(Bid,4)+"/"+DoubleToStr(Ask,4), 13, "Verdana", Blue);
   ObjectSetText("msg", msg, 13, "Verdana", Blue);


}

void ObjectMakeLabel( string n, int xoff, int yoff, int window = 1, int Corner=0 ) 
  {
   {
      ObjectCreate( ChartID(), n, OBJ_LABEL, window, 0, 0 );
      ObjectSet( n, OBJPROP_CORNER, Corner );
      ObjectSet( n, OBJPROP_XDISTANCE, xoff );
      ObjectSet( n, OBJPROP_YDISTANCE, yoff );
      ObjectSet( n, OBJPROP_BACK, false );
    }
  }
  
  bool isReverse2(int m, int n)
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
double GetOrderAvg()
{
   double avg = 0;
   int n = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( OrderSymbol()!=Symbol() || OrderType() > OP_SELL) continue;
      //---- check order type 
      avg += OrderOpenPrice();
      n++;
     }
     if( n == 0) return 0;
     return avg/n;
}

