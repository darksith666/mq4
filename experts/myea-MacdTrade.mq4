//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq4 |
//|                      Copyright ?2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+

#include <common.mqh>
extern int  MaxLots = 5;
extern double TakeProfit = 600;
extern double Lots = 1; //0.1
extern double StopLoss = 100;

extern double ReversePercent = 0;  //don't reverse for GER30 1H/M15
extern double AddPercent = 1.2; //Add Plan trade lots percent 0.2=>1.2
extern double AddRate = 0.1;   //Add Plan mark position 0.4=>0.1 0.6 is also better
extern double PlanRate = 0;  //Add Plan trade position 0.2 => 0, since GER30很少会再回测
extern double LimitRate = 0.2;  //Add Plan trade position up limit
extern string version= "6.04R";  //Release version
extern string comment1 = "manOrder=1:immediate buy/sell 2:immediate reverse trade 0: normal";
extern int    manOrder = 0;   //
extern string comment11 = "manOrderOp=0-Buy 1-Sell";
extern int    manOrderOp = 0;  //
extern int    manTrend = -1;   //
datetime ptime = 0;
datetime ptime2 = 0;
datetime ptime3 = 0;
datetime ptime4 = 0;
datetime dp3 = 0;
datetime lasttime = 0;
  
#define MAGICMA  20131018

double myATR(int t, int s, int p)
{
   int i;
   double c1, max, tmax;
   max = 0;
   tmax = 0;
   for( i = s; i <= p+s; i++)
   {
      max = iHigh(NULL, t, i) - iLow(NULL, t, i);
      c1 = MathAbs(iHigh(NULL, t, i) - iClose(NULL, t, i+1));
      if( max < c1) max = c1;
      c1 = MathAbs(iLow(NULL, t, i) - iClose(NULL, t, i+1));
      if( max < c1) max = c1;
      tmax += max; 
   }
   return(tmax / p);
}

int start()
  {
   double lots, tk, sl, RevPercent;
   
   if( manOrder == 1)
   {
        int tt = GetOrder(MAGICMA, OP_SELL);
        if( tt == -1 )
            OpenOrder(manOrderOp, Lots, StopLoss, TakeProfit, MAGICMA, ReversePercent);
        manOrder = 0;
        return(0);
   }
   
   string comment, sss[2];
   sss[0] = "区间交易";
   sss[1] = "趋势交易";
   string ss[2];
   ss[0] = "买";
   ss[1] = "卖";
   
   { //add position
      ClosePendingOrder(MAGICMA);
      comment = "BollerTrade:"+sss[1]+"加仓";
      AddOrder2(MAGICMA, LotsOptimized(AddPercent), AddRate, TakeProfit, PlanRate, LimitRate,comment,MaxLots);
   }
   
   {
      lots = Lots;
      tk = TakeProfit;
      sl = StopLoss;
      RevPercent = ReversePercent;
   }

   double updown = iCustom(NULL, PERIOD_M1, "MACD", 100, 200, 30, 3, 5, 300, 20, 2, 11);
   int op = -1;
   if( updown == -2) op = 1;
   else if( updown == 2) op = 0;
   
   if( manOrder == 2){
      op = manOrderOp;
      manOrder = 0;
   }
   int trend = 1;
   
   if( op != -1  ) 
   {
      int t = GetOrder(MAGICMA, OP_SELL);
      //double angle = iCustom(NULL, 0, "MA_Angle", 97, 48, 2, 0, 0);
      if( t == -1 ){
            comment = "BollerTrade:"+sss[trend]+"新"+ss[op]+"单";
            OpenOrder(op, lots, sl, tk, MAGICMA, RevPercent, comment);
      }
      else{
            comment = "BollerTrade:"+sss[trend]+"反手开"+ss[op]+"单"+"[原"+ss[OrderType()]+"单"+t+"]";
            OpenReverseOrder(t, op, lots, sl, tk, MAGICMA, RevPercent,comment);
      }
      if( TimeCurrent() - ptime > 360)
      {
         ptime = TimeCurrent();
         Print(comment,"@",TimeToStr(ptime));
      }
      /*纯粹使用信号开平仓，不使用加仓和反手系统，无论如何调整止盈和止损，都无法实现正盈利
      int tt = GetOrder(MAGICMA+40, OP_SELL);
      if( tt == -1 ) OpenShortOrder(op, ShortLots, ShortSL, ShortTK, MAGICMA+40);
      else CloseOrder(tt, op);
      */
      Sleep(60000);
   }
   //Print(TimeToStr(TimeCurrent(), TIME_DATE), skiptime1, StringFind(TimeToStr(TimeCurrent(), TIME_DATE), skiptime1));
   /*
      if( TimeCurrent() - ptime2 > 360)
      {
         ptime2 = TimeCurrent();
         Print("========xxxxxxxtrend=",trend,"op=",op,"atr=",iATR(NULL, 30, autoTrendPeriod, 0),"sum=",sum / autoTrendRange,"@",TimeToStr(ptime2));
      }
      */
   return(0);
  }
// the end.