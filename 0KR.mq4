//+------------------------------------------------------------------+
//|                                        Custom Moving Average.mq4 |
//|                      Copyright ?2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_chart_window
//---- indicator parameters
extern int TrendRange = 6;
extern int Cal = 400;
extern int KS = 0;
extern int timeframe = 0; //PERIOD_D1;
int ExtDepth=12;
int ExtDeviation=5;
int ExtBackstep=3;
//---- indicator buffers
double BufferZig[];
int space = 100;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   if( Period() > timeframe) timeframe = Period();
   IndicatorBuffers(1);
   SetIndexStyle(0, DRAW_NONE);
   SetIndexBuffer(0, BufferZig);
   return(0);
  }
  
int deinit()
{
   for( int i = 0; i <= Cal; i++)
   {
      ObjectDelete(0, "ArrowKR"+i);
      ObjectDelete(0, "LineKR"+i);
   }
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
deinit();

int t = 0;
BufferZig[Cal] = 0;
for( int i = Cal-1; i >= 0; i--) 
{
BufferZig[i] = BufferZig[i+1];
double zigpoint[4];
datetime zigtime[4];
ArrayInitialize(zigpoint,0.0);
/*
double tr = TrendRange;
if( Period() >= 30) tr *= Period() / 15;
if( high1 - low1 > tr && zigtime[0] - zigtime[1] > 16*Period()*60)  //趋势成立
*/
int ii = iBarShift(Symbol(), timeframe, Time[i]);
{
   //if( zigpoint[0] == low1 )  //空头
   {
      if( ( iOpen(Symbol(), timeframe, ii+1) > iClose(Symbol(), timeframe, ii+1) && iOpen(Symbol(), timeframe, ii) <= iClose(Symbol(), timeframe, ii+1)+1 && iClose(Symbol(), timeframe, ii) > iOpen(Symbol(), timeframe, ii+1) ) 
          || (BufferZig[i+1] < 0 && iClose(Symbol(), timeframe, ii) > MathAbs(BufferZig[i+1]) )  )
      {
         t++;
         BufferZig[i] = iOpen(Symbol(), timeframe, ii);
         //if( StringFind(TimeToStr(Time[i]), "2014.04.01 02") != -1 && i == 0) Print("Find i=",i,"t0-t1=",TimeToStr(zigtime[1]),"-",TimeToStr(zigtime[0]),"p0-p1",zigpoint[1],"-",zigpoint[0],"K1=",Open[i+1],"-",Close[i+1],"K0=",Open[0],"-",Close[0],"BufferZig=",BufferZig[i],"tr=",tr,"h-l=",high1-low1,"@",TimeToStr(Time[i]));
         //break;
      }
   }
   //else
   {
      if( (iOpen(Symbol(), timeframe, ii+1) < iClose(Symbol(), timeframe, ii+1) && iOpen(Symbol(), timeframe, ii) >= iClose(Symbol(), timeframe, ii+1)-1 && iClose(Symbol(), timeframe, ii) < iOpen(Symbol(), timeframe, ii+1) )
         || ( iClose(Symbol(), timeframe, ii) < BufferZig[i+1] ) )
      {  t++;
         BufferZig[i] = -iOpen(Symbol(), timeframe, ii);
         //if( StringFind(TimeToStr(Time[i]), "2014.04.01 02") != -1 && i == 0) Print("Find i=",i,"t0-t1=",TimeToStr(zigtime[1]),"-",TimeToStr(zigtime[0]),"p0-p1",zigpoint[1],"-",zigpoint[0],"K1=",Open[i+1],"-",Close[i+1],"K0=",Open[0],"-",Close[0],"BufferZig=",BufferZig[i],"tr=",tr,"h-l=",high1-low1,"@",TimeToStr(Time[i]));
         //break;
      }
   }
   double s = space * Point;
   if( BufferZig[i] > 0)
   {
         if( BufferZig[i+1] < 0)
         {ObjectCreate("ArrowKR"+i, OBJ_ARROW, 0, Time[i], Low[i]); //OBJ_ARROW_UP
         ObjectSet("ArrowKR"+i,OBJPROP_ARROWCODE,108);
         ObjectSet("ArrowKR"+i, OBJPROP_COLOR, Lime);
         ObjectSet("ArrowKR"+i, OBJPROP_WIDTH, 3);
         }
         if( zigpoint[0] > 0)
         {
         ObjectCreate("LineKR"+i, OBJ_TREND, 0, zigtime[0], zigpoint[0],zigtime[1],zigpoint[1]);
         ObjectSet("LineKR"+i, OBJPROP_COLOR, Lime);
         ObjectSet("LineKR"+i, OBJPROP_WIDTH, 3);
         }
   }
   else
   {
         if( BufferZig[i+1] > 0){
         ObjectCreate("ArrowKR"+i, OBJ_ARROW, 0, Time[i], High[i]+2*s);//OBJ_ARROW_DOWN
         ObjectSet("ArrowKR"+i,OBJPROP_ARROWCODE,108);
         ObjectSet("ArrowKR"+i, OBJPROP_COLOR, Red);
         ObjectSet("ArrowKR"+i, OBJPROP_WIDTH, 3);
         }
         if( zigpoint[0] > 0){
         ObjectCreate("LineKR"+i, OBJ_TREND, 0, zigtime[0], zigpoint[0],zigtime[1],zigpoint[1]);
         ObjectSet("LineKR"+i, OBJPROP_COLOR, Lime);
         ObjectSet("LineKR"+i, OBJPROP_WIDTH, 3);
         }
   }
}
}
//Print("The Count is ",cout,",| zigpoint=",DoubleToStr(zigpoint[cout],Digits),",| zigtime=",TimeToStr(zigtime[cout],TIME_DATE|TIME_SECONDS));
//ObjectCreate("HLine"+cout,OBJ_HLINE,0,zigtime[cout],zigpoint[cout]);
//ObjectSet("HLine"+cout, OBJPROP_WIDTH, 2);
/*
   string aaa = TimeToStr(Time[0]);
   if( BufferZig[0] == 1 && StringFind(aaa, "2014.05.19 21") != -1 )
      Print("---------zigzag Singal: BufferZig[0]=",BufferZig[0],"Close[0]=",Close[0],"high1=",high1,"high2=",high2);
*/
//Comment("0KR get total ",t," signals.");
return 0;
}