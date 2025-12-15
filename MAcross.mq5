//+------------------------------------------------------------------+
//|                                                   Rezaeian       |
//|                                     Copyright 2024, AmerAndish :)|
//|                                          https://www.tradeyaar.ir|
//+------------------------------------------------------------------+
#property copyright "AmerAndish :)"
#property link      "https://www.tradeyaar.ir"
#property version   "1.00"


// #define GUARD_MODULE
// #define SYMBOL_MODULE
// #define CALENDAR_MODULE
#define PRICE_AREA_MODULE
// #define TECHNICAL_MODULE


input int FastMAPeriod = 10;     
input int SlowMAPeriod = 30;     
input double LotSize = 0.1;      
input double StopLoss = 200;     
input double TakeProfit = 400;

#include "./filters/tradingFilter.mqh"

// Global variables
TradeFilters trade;

   
 
double FastMA[], SlowMA[];
int handleFast, handleSlow;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ArraySetAsSeries(FastMA,true);
   ArraySetAsSeries(SlowMA,true);

   handleFast = iMA(trade.ExpertSymbol(), trade.ExpertTimeFrame(), FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   handleSlow = iMA(trade.ExpertSymbol(), trade.ExpertTimeFrame(), SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);

   Print("MA Cross EA initialized.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlTick tick;
   if(!SymbolInfoTick(trade.ExpertSymbol(),tick)) return;
   double _Bid = tick.bid;
   double _Ask = tick.ask;
   
   trade.CloseAllPositionsAtDayEnd();

   // Check buy signal
   if(buySignal())
   {
      if(PositionSelect(trade.ExpertSymbol()) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         trade.PositionClose(trade.ExpertSymbol());

      if(!PositionSelect(trade.ExpertSymbol()))
         trade.Buy(LotSize,trade.ExpertSymbol(),_Bid,_Bid-StopLoss*trade.ExpertPoint(),_Bid+TakeProfit*trade.ExpertPoint());
   }

   // Check sell signal
   if(sellSignal())
   {
      if(PositionSelect(trade.ExpertSymbol()) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         trade.PositionClose(trade.ExpertSymbol());

      if(!PositionSelect(trade.ExpertSymbol()))
         trade.Sell(LotSize,trade.ExpertSymbol(),_Ask,_Ask+StopLoss*trade.ExpertPoint(),_Ask-TakeProfit*trade.ExpertPoint());
   }
}
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Check if a bullish MA cross occurred                              |
//+------------------------------------------------------------------+
bool buySignal()
{
   MqlTick tick;
   if(!SymbolInfoTick(trade.ExpertSymbol(),tick)) return false;

   double _Bid = tick.bid;

   CopyBuffer(handleFast, 0, 0, 3, FastMA);
   CopyBuffer(handleSlow, 0, 0, 3, SlowMA);

   if(ArraySize(FastMA) < 2 || ArraySize(SlowMA) < 2)
      return false;

   return (FastMA[1] < SlowMA[1] && FastMA[0] > SlowMA[0]);
}

//+------------------------------------------------------------------+
//| Check if a bearish MA cross occurred                              |
//+------------------------------------------------------------------+
bool sellSignal()
{
   MqlTick tick;
   if(!SymbolInfoTick(trade.ExpertSymbol(),tick)) return false;

   double _Ask = tick.ask;

   CopyBuffer(handleFast, 0, 0, 3, FastMA);
   CopyBuffer(handleSlow, 0, 0, 3, SlowMA);

   if(ArraySize(FastMA) < 2 || ArraySize(SlowMA) < 2)
      return false;

   return (FastMA[1] > SlowMA[1] && FastMA[0] < SlowMA[0]);
}
