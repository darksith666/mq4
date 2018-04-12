//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Averages Convergence/Divergence"
#property strict

#include <MovingAverages.mqh>

//--- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  Silver
#property  indicator_color2  Red
#property  indicator_width1  2
//--- indicator parameters
input int InpFastEMA=100;   // Fast EMA Period
input int InpSlowEMA=200;   // Slow EMA Period
input int InpSignalSMA=30;  // Signal SMA Period
input int Gap = 3;
input int TrendEMAN = 5;   //EMA for trend limit
input int Cal = 1000;       //how many candles to calculate
input int space = 20;  
//--- indicator buffers
double    ExtMacdBuffer[];
double    ExtSignalBuffer[];
double    ExtSignalBuffer2[50000];
//--- right input parameters flag
bool      ExtParameters=false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   IndicatorDigits(Digits+1);
//--- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexDrawBegin(1,InpSignalSMA);
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer);
   SetIndexBuffer(1,ExtSignalBuffer);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexBuffer(2,ExtSignalBuffer2);
//--- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACD("+IntegerToString(InpFastEMA)+","+IntegerToString(InpSlowEMA)+","+IntegerToString(InpSignalSMA)+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
//--- check for input parameters
   if(InpFastEMA<=1 || InpSlowEMA<=1 || InpSignalSMA<=1 || InpFastEMA>=InpSlowEMA)
     {
      Print("Wrong input parameters");
      ExtParameters=false;
      return(INIT_FAILED);
     }
   else
      ExtParameters=true;

//--- initialization done
   return(INIT_SUCCEEDED);
  }
  
  void OnDeinit(const int reason)
  {
     for( int i = 0; i <= Cal; i++)
      {
         ObjectDelete(0, "MACDKR"+i);
      }
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const datetime& time[],
                 const double& open[],
                 const double& high[],
                 const double& low[],
                 const double& close[],
                 const long& tick_volume[],
                 const long& volume[],
                 const int& spread[])
  {
   int i,limit;
   
      for( int i = 0; i < Cal; i++)
      {
         ExtSignalBuffer2[i] = 0;
      }
//---
   if(rates_total<=InpSignalSMA || !ExtParameters)
      return(0);
//--- last counted bar will be recounted
   limit=rates_total-prev_calculated;
   if(prev_calculated>0)
      limit++;
//--- macd counted in the 1-st buffer
   for(i=0; i<limit; i++)
      ExtMacdBuffer[i]=iMA(NULL,0,InpFastEMA,0,MODE_EMA,PRICE_CLOSE,i)-
                    iMA(NULL,0,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
//--- signal line counted in the 2-nd buffer
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- done
   int cause, found;
   int j;
   double s = space * Point;
   string causestring[3] = {"顶底形态","穿过零轴","穿过信号线"};
   color color1[3] = {clrBlue, clrDarkViolet, clrLightSeaGreen};
   color color2[3] = {clrRed, clrMagenta, clrDarkOrchid};
   for( i = Cal-10; i > 10; i--)
   {
      if( i < Cal - 40){
         found = 0;
         for( j = i + 20; j > i; j--){
          //if( i == 188 && Symbol() == "US30" && Period() == 1 )Print(j, "=", ExtSignalBuffer2[j]); 
          if( ExtSignalBuffer2[j] != 0) {found = 1; break;}
         }
         if( found == 1) continue;
      } 

      cause = 0;
      if( ExtMacdBuffer[i] > TrendEMAN ){
         if( (ExtMacdBuffer[i+Gap] < ExtMacdBuffer[i] && ExtMacdBuffer[i-Gap] < ExtMacdBuffer[i]) ||
             (ExtMacdBuffer[i-3] < 0 && ExtMacdBuffer[i] < 0 && ExtMacdBuffer[i+3] > 0) ||
             (ExtMacdBuffer[i] > TrendEMAN && ExtMacdBuffer[i-3] < ExtSignalBuffer[i+7] && ExtMacdBuffer[i] < ExtSignalBuffer[i+8] && ExtMacdBuffer[i+3] > ExtSignalBuffer[i+9]))
         {
   
               if(ExtMacdBuffer[i-Gap] < 0 && ExtMacdBuffer[i] < 0 && ExtMacdBuffer[i+Gap] > 0) cause = 1;
               else if(ExtMacdBuffer[i-3] < ExtSignalBuffer[i+7] && ExtMacdBuffer[i] < ExtSignalBuffer[i+8] && ExtMacdBuffer[i+3] > ExtSignalBuffer[i+9]) continue; //cause = 2;
               ObjectCreate("MACDKR"+i, OBJ_ARROW, 0, Time[i], High[i]+2*s);//OBJ_ARROW_DOWN
               ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,242);
               ObjectSet("MACDKR"+i, OBJPROP_WIDTH, 3);
               ObjectSetString(0, "MACDKR"+i, OBJPROP_TEXT, causestring[cause]);
               ObjectSet("MACDKR"+i, OBJPROP_COLOR, color2[cause]);
               ExtSignalBuffer2[i] = -1;
               if( i < Cal - 200){
                  found = 0;
                  for( j = i + 1; j < i+200; j++){
                   //if( i == 188 && Symbol() == "US30" && Period() == 1 )Print(j, "=", ExtSignalBuffer2[j]); 
                   if( ExtSignalBuffer2[j] != 0) {found = ExtSignalBuffer2[j]; break;}
                  }
                  if( found < 0){
                     ExtSignalBuffer2[i] = -2;
                     ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,68);
                  }
               } 
         }
      }
      if( ExtMacdBuffer[i] < -TrendEMAN)
      {
        if( (ExtMacdBuffer[i+Gap] > ExtMacdBuffer[i] && ExtMacdBuffer[i-Gap] > ExtMacdBuffer[i]) ||
          (ExtMacdBuffer[i-3] > 0 && ExtMacdBuffer[i] > 0 && ExtMacdBuffer[i+3] < 0) ||
          (ExtMacdBuffer[i] < -TrendEMAN && ExtMacdBuffer[i-3] > ExtSignalBuffer[i+7] && ExtMacdBuffer[i] > ExtSignalBuffer[i+8] && ExtMacdBuffer[i+3] < ExtSignalBuffer[i+9]))
         {
            if(ExtMacdBuffer[i-Gap] > 0 && ExtMacdBuffer[i] > 0 && ExtMacdBuffer[i+Gap] < 0) cause = 1;
            else if(ExtMacdBuffer[i-3] > ExtSignalBuffer[i+7] && ExtMacdBuffer[i] > ExtSignalBuffer[i+8] && ExtMacdBuffer[i+3] < ExtSignalBuffer[i+9]) continue; //cause = 2;
            ObjectCreate("MACDKR"+i, OBJ_ARROW, 0, Time[i], Low[i]); //OBJ_ARROW_UP
            ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,241);
            ObjectSet("MACDKR"+i, OBJPROP_WIDTH, 3);
            ObjectSetString(0, "MACDKR"+i, OBJPROP_TEXT, causestring[cause]);
            ObjectSet("MACDKR"+i, OBJPROP_COLOR, color1[cause]);
            ExtSignalBuffer2[i] = 1;
            if( i < Cal - 200){
               found = 0;
               for( j = i + 1; j < i+200; j++){
                //if( i == 188 && Symbol() == "US30" && Period() == 1 )Print(j, "=", ExtSignalBuffer2[j]); 
                if( ExtSignalBuffer2[j] != 0) {found = ExtSignalBuffer2[j]; break;}
               }
               if( found > 0){
                  ExtSignalBuffer2[i] = 2;
                  ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,67);
               }
            }
         }
      }
   }
   return(rates_total);
  }
//+------------------------------------------------------------------+