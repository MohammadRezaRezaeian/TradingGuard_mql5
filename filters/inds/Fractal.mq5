//+------------------------------------------------------------------+
//|                                                     Fractals.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_color1  clrGray
#property indicator_color2  clrGray
#property indicator_label1  "Fractal Up"
#property indicator_label2  "Fractal Down"

input int depth = 2;

//--- indicator buffers
double ExtUpperBuffer[];
double ExtLowerBuffer[];
//--- 10 pixels upper from high price
int    ExtArrowShift=-10;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtUpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLowerBuffer,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_ARROW,217);
   PlotIndexSetInteger(1,PLOT_ARROW,218);
//--- arrow shifts when drawing
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,ExtArrowShift);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-ExtArrowShift);
//--- sets drawing line empty value--
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//|  Fractals on 5 bars                                              |
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
   if(rates_total<2*depth)
      return(0);

   int start;
//--- clean up arrays
   if(prev_calculated<7)
     {
      start=2*depth;
      ArrayInitialize(ExtUpperBuffer,EMPTY_VALUE);
      ArrayInitialize(ExtLowerBuffer,EMPTY_VALUE);
     }
   else
      start=rates_total-5;
//--- main cycle of calculations
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      //--- Upper Fractal
      ExtUpperBuffer[i]=upper_fractal(i,high);

      //--- Lower Fractal
      ExtLowerBuffer[i]=lower_fractal(i,low);
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }

//+------------------------------------------------------------------+



double upper_fractal(int index, const double &high[])
{
   for(int i=1; i<depth+1 && !IsStopped(); i++)
   {
      if( (high[index-depth] < high[index-depth+i]) || (high[index-depth] < high[index-depth-i]) ) return EMPTY_VALUE;
   }
   return high[index-depth];
}


double lower_fractal(int index, const double &low[])
{
   for(int i=1; i<depth+1 && !IsStopped(); i++)
   {
      if( (low[index-depth] > low[index-depth+i]) || (low[index-depth] > low[index-depth-i]) ) return EMPTY_VALUE;
   }
   return low[index-depth];
}