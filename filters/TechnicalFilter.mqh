//+------------------------------------------------------------------+
//|                                             TechnicalFilter.mqh  |
//|                        Copyright 2025, AmerAndish :)             |
//|                                          https://www.tradeyaar.ir|
//+------------------------------------------------------------------+
#property copyright "AmerAndish :)"
#property link      "https://www.tradeyaar.ir"
#property version   "1.00"

input group  "==== TECHNICAL FILTERS ===="
// Expert Advisor Inputs for Technical Filters
input group "ADX Filter"
input bool EnableADX = false;                // Enable ADX Filter
input ENUM_TIMEFRAMES ADXTimeframe = PERIOD_CURRENT; // ADX Timeframe
input int ADXPeriod = 14;                    // ADX Period
input double ADXThreshold = 25.0;            // ADX Threshold (allow if ADX > threshold)

input group "ATR Filter"
input bool EnableATR = false;                // Enable ATR Filter
input ENUM_TIMEFRAMES ATRTimeframe = PERIOD_CURRENT; // ATR Timeframe
input int ATRPeriod = 14;                    // ATR Period
input double ATRThreshold = 0.01;            // ATR Threshold (allow if ATR > threshold)

input group "MA Filter"
input bool EnableMA = false;                 // Enable MA Filter
input ENUM_TIMEFRAMES MATimeframe = PERIOD_CURRENT; // MA Timeframe
input int MAPeriod = 50;                     // MA Period
input ENUM_MA_METHOD MAMethod = MODE_SMA;    // MA Method
input ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE; // MA Applied Price

input group "RSI Filter"
input bool EnableRSI = false;                // Enable RSI Filter
input ENUM_TIMEFRAMES RSITimeframe = PERIOD_CURRENT; // RSI Timeframe
input int RSIPeriod = 14;                    // RSI Period
input ENUM_APPLIED_PRICE RSIPrice = PRICE_CLOSE; // RSI Applied Price
input double RSIOverbought = 70.0;           // RSI Overbought Level
input double RSIOversold = 30.0;             // RSI Oversold Level

input group "ATR Compare Filter"
input bool EnableATRCompare = false;         // Enable ATR(x) > ATR(y) Filter
input ENUM_TIMEFRAMES ATRTimeframeX = PERIOD_CURRENT; // ATR(x) Timeframe
input int ATRPeriodX = 14;                   // ATR(x) Period
input ENUM_TIMEFRAMES ATRTimeframeY = PERIOD_H1; // ATR(y) Timeframe
input int ATRPeriodY = 14;                   // ATR(y) Period

input group "MACD Filter"
input bool EnableMACD = false;               // Enable MACD Filter
input ENUM_TIMEFRAMES MACDTimeframe = PERIOD_CURRENT; // MACD Timeframe
input int MACDFast = 12;                     // MACD Fast EMA Period
input int MACDSlow = 26;                     // MACD Slow EMA Period
input int MACDSignal = 9;                    // MACD Signal SMA Period
input ENUM_APPLIED_PRICE MACDPrice = PRICE_CLOSE; // MACD Applied Price

//+------------------------------------------------------------------+
//| TechnicalFilter class: Filters trades based on technical         |
//| indicators with configurable parameters and timeframes.          |
//+------------------------------------------------------------------+
class TechnicalFilter {
private:
   // Get current price based on order type
   double GetCurrentPrice(const string sym, ENUM_ORDER_TYPE ord_type, double prc) {
      if (prc == 0.0) {
         double ask, bid;
         SymbolInfoDouble(sym, SYMBOL_ASK, ask);
         SymbolInfoDouble(sym, SYMBOL_BID, bid);
         return (ord_type == ORDER_TYPE_BUY || ord_type == ORDER_TYPE_BUY_LIMIT || ord_type == ORDER_TYPE_BUY_STOP) ? ask : bid;
      }
      return prc;
   }

public:
   TechnicalFilter() {}
   ~TechnicalFilter() {}
   
   // Checks if trading is allowed based on technical indicators and trade parameters
   bool ApplyFilter(const string symbol, ENUM_ORDER_TYPE order_type, double volume, 
                    double price, double sl, double tp, 
                    ENUM_ORDER_TYPE_TIME type_time, datetime expiration, 
                    double limit_price, ulong ticket) {
      // ADX Filter: Allow if ADX > threshold (trending market)
      if (EnableADX) {
         double adx[];
         ArrayResize(adx, 1);
         if (CopyBuffer(iADX(symbol, ADXTimeframe, ADXPeriod), 0, 0, 1, adx) != 1) return false;
         if (adx[0] <= ADXThreshold) {
            Print("TechnicalFilter: ADX filter failed - ADX (", adx[0], ") <= threshold (", ADXThreshold, ")");
            return false;
         }
      }
      
      // ATR Filter: Allow if ATR > threshold (sufficient volatility)
      if (EnableATR) {
         double atr[];
         ArrayResize(atr, 1);
         if (CopyBuffer(iATR(symbol, ATRTimeframe, ATRPeriod), 0, 0, 1, atr) != 1) return false;
         if (atr[0] <= ATRThreshold) {
            Print("TechnicalFilter: ATR filter failed - ATR (", atr[0], ") <= threshold (", ATRThreshold, ")");
            return false;
         }
      }
      
      // MA Filter: For buy-like orders, allow if current price > MA; for sell-like < MA
      if (EnableMA) {
         double ma[];
         ArrayResize(ma, 1);
         if (CopyBuffer(iMA(symbol, MATimeframe, MAPeriod, 0, MAMethod, MAPrice), 0, 0, 1, ma) != 1) return false;
         double curr_price = GetCurrentPrice(symbol, order_type, price);
         bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP);
         if ((is_buy && curr_price <= ma[0]) || (!is_buy && curr_price >= ma[0])) {
            Print("TechnicalFilter: MA filter failed - Price (", curr_price, ") not ", (is_buy ? "above" : "below"), " MA (", ma[0], ")");
            return false;
         }
      }
      
      // RSI Filter: Avoid overbought for buys, oversold for sells
      if (EnableRSI) {
         double rsi[];
         ArrayResize(rsi, 1);
         if (CopyBuffer(iRSI(symbol, RSITimeframe, RSIPeriod, RSIPrice), 0, 0, 1, rsi) != 1) return false;
         bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP);
         if ((is_buy && rsi[0] >= RSIOverbought) || (!is_buy && rsi[0] <= RSIOversold)) {
            Print("TechnicalFilter: RSI filter failed - RSI (", rsi[0], ") is ", (is_buy ? "overbought" : "oversold"));
            return false;
         }
      }
      
      // ATR Compare Filter: Allow if ATR(x) > ATR(y)
      if (EnableATRCompare) {
         double atr_x[], atr_y[];
         ArrayResize(atr_x, 1);
         ArrayResize(atr_y, 1);
         if (CopyBuffer(iATR(symbol, ATRTimeframeX, ATRPeriodX), 0, 0, 1, atr_x) != 1) return false;
         if (CopyBuffer(iATR(symbol, ATRTimeframeY, ATRPeriodY), 0, 0, 1, atr_y) != 1) return false;
         if (atr_x[0] <= atr_y[0]) {
            Print("TechnicalFilter: ATR Compare filter failed - ATR(x) (", atr_x[0], ") <= ATR(y) (", atr_y[0], ")");
            return false;
         }
      }
      
      // MACD Filter: For buy-like, allow if MACD > Signal; for sell-like < Signal
      if (EnableMACD) {
         double macd[], signal[];
         ArrayResize(macd, 1);
         ArrayResize(signal, 1);
         int handle = iMACD(symbol, MACDTimeframe, MACDFast, MACDSlow, MACDSignal, MACDPrice);
         if (CopyBuffer(handle, 0, 0, 1, macd) != 1 || CopyBuffer(handle, 1, 0, 1, signal) != 1) return false;
         bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP);
         if ((is_buy && macd[0] <= signal[0]) || (!is_buy && macd[0] >= signal[0])) {
            Print("TechnicalFilter: MACD filter failed - MACD (", macd[0], ") not ", (is_buy ? "above" : "below"), " Signal (", signal[0], ")");
            return false;
         }
      }
      
      return true;
   }
};
//+------------------------------------------------------------------+