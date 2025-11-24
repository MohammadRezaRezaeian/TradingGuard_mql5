//+------------------------------------------------------------------+
//|                                             CalendarFilter.mqh   |
//|                        Copyright 2025, AmerAndish :)             |
//|                                          https://www.tradeyaar.ir|
//+------------------------------------------------------------------+
#property copyright "AmerAndish :)"
#property link      "https://www.tradeyaar.ir"
#property version   "1.00"

input group  "==== CALENDAER FILTERS ===="
// Expert Advisor Inputs for Calendar Filter
input group "Trading Days"
input bool TradeMonday    = true;  // Trade on Monday
input bool TradeTuesday   = true;  // Trade on Tuesday
input bool TradeWednesday = true;  // Trade on Wednesday
input bool TradeThursday  = true;  // Trade on Thursday
input bool TradeFriday    = true;  // Trade on Friday
input bool TradeSaturday  = true; // Trade on Saturday
input bool TradeSunday    = true; // Trade on Sunday

input group "Trading Hours"
input string TimeWindow1Start = "00:00"; // Time Window 1 Start (HH:MM)
input string TimeWindow1End   = "23:50"; // Time Window 1 End (HH:MM)
input string TimeWindow2Start = "00:00"; // Time Window 2 Start (HH:MM)
input string TimeWindow2End   = "00:00"; // Time Window 2 End (HH:MM)
input string TimeWindow3Start = "00:00"; // Time Window 3 Start (HH:MM)
input string TimeWindow3End   = "00:00"; // Time Window 3 End (HH:MM)

//+------------------------------------------------------------------+
//| CalendarFilter class: Filters trades based on economic calendar  |
//| events, trading days, and trading hours.                        |
//+------------------------------------------------------------------+
class CalendarFilter {
private:
   // Check if current day is allowed for trading
   bool IsTradingDayAllowed() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      switch(dt.day_of_week) {
         case 1: return TradeMonday;
         case 2: return TradeTuesday;
         case 3: return TradeWednesday;
         case 4: return TradeThursday;
         case 5: return TradeFriday;
         case 6: return TradeSaturday;
         case 0: return TradeSunday;
         default: return false;
      }
   }
   
   // Convert HH:MM string to minutes since midnight
   int TimeStringToMinutes(string timeStr) {
      string parts[];
      if (StringSplit(timeStr, ':', parts) != 2) return -1;
      int hours = (int)StringToInteger(parts[0]);
      int minutes = (int)StringToInteger(parts[1]);
      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return -1;
      return hours * 60 + minutes;
   }
   
   // Check if current time is within any of the allowed time windows
   bool IsTradingTimeAllowed() {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int currentMinutes = dt.hour * 60 + dt.min;
      
      // Check each time window
      int start1 = TimeStringToMinutes(TimeWindow1Start);
      int end1 = TimeStringToMinutes(TimeWindow1End);
      int start2 = TimeStringToMinutes(TimeWindow2Start);
      int end2 = TimeStringToMinutes(TimeWindow2End);
      int start3 = TimeStringToMinutes(TimeWindow3Start);
      int end3 = TimeStringToMinutes(TimeWindow3End);
      
      // Validate and check Window 1
      if (start1 >= 0 && end1 >= 0 && start1 <= end1) {
         if (currentMinutes >= start1 && currentMinutes <= end1) return true;
      }
      
      // Validate and check Window 2
      if (start2 >= 0 && end2 >= 0 && start2 <= end2) {
         if (currentMinutes >= start2 && currentMinutes <= end2) return true;
      }
      
      // Validate and check Window 3
      if (start3 >= 0 && end3 >= 0 && start3 <= end3) {
         if (currentMinutes >= start3 && currentMinutes <= end3) return true;
      }
      
      return false;
   }
   
   // Placeholder for checking high-impact news events
   bool IsHighImpactNews() {
      // Simulated check for high-impact news events
      // Replace with actual calendar data access, e.g., using MQL5's Calendar functions
      datetime currentTime = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(currentTime, dt);
      // Simulate high-impact news at 14:00 (e.g., NFP release time)
      return (dt.hour == 14 && dt.min >= 0 && dt.min <= 30);
   }

public:
   CalendarFilter() {}
   ~CalendarFilter() {}
   
   // Checks if trading is allowed based on inputs and trade parameters
   bool ApplyFilter(const string symbol, ENUM_ORDER_TYPE order_type, double volume, 
                    double price, double sl, double tp, 
                    ENUM_ORDER_TYPE_TIME type_time, datetime expiration, 
                    double limit_price, ulong ticket) {
      // Check trading day
      if (!IsTradingDayAllowed()) {
         Print("CalendarFilter: Trading blocked - Current day is not allowed.");
         return false;
      }
      
      // Check trading hours
      if (!IsTradingTimeAllowed()) {
         Print("CalendarFilter: Trading blocked - Outside allowed trading hours.");
         return false;
      }
      
      // Check for high-impact news
      //if (IsHighImpactNews()) {
      //   Print("CalendarFilter: Trading blocked due to high-impact news.");
      //   return false;
      //}
      
      // Example: Additional filter using trade parameters
      // Block high-volume trades (> 1.0 lots) for specific symbols during volatile hours
      if (volume > 1.0 && StringFind(symbol, "EURUSD", 0) >= 0) {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         if (dt.hour >= 13 && dt.hour <= 15) { // Example: Volatile hours for EURUSD
            Print("CalendarFilter: High-volume trade blocked for ", symbol, " during volatile hours.");
            return false;
         }
      }
      
      return true;
   }
};
//+------------------------------------------------------------------+