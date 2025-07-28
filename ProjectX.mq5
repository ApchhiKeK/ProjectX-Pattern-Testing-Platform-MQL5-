//+------------------------------------------------------------------+
//|                                                     ProjectX.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| GLOBAL                                                           |
//+------------------------------------------------------------------+
struct DataBars
  {
   MqlRates          DATA[];
   ENUM_TIMEFRAMES   TF;
   string            Group_Name;
   datetime          StartPeriod;
   datetime          EndPeriod;
  };

MqlRates Bar;  // Переменная для вывода MqlRates структуры
//+------------------------------------------------------------------+
//| ENUM                                                             |
//+------------------------------------------------------------------+
enum Direction
  {
   NONE = 0,
   BEAR,
   BULL,
  };

enum ActiveNoes
  {
   NEUTRAL = 0,
   ACTIVE,
   DISACTIVE,
  };

enum BreackdownStatus
  {
   WAITING = 0,
   SUCCESS,
   FAIL,
  };

enum BD_name
  {
   BD_Fixing = 0,
   BD_Timeout,
  };

enum SignalRange
  {
   OpenClose = 0,
   HighLow,
  };

enum FIRSTBD
  {
   NOT_BD = 0,
   FIRST,
   NOTFIRST,
  };
//+------------------------------------------------------------------+
//|                              TIMEFRAMES                          |
//+------------------------------------------------------------------+
class TimeFrames
  {
public:
   virtual void      GetGroupTF(ENUM_TIMEFRAMES &arr[]) = 0;
   virtual datetime  GetStart() = 0;
   virtual datetime  GetEnd() = 0;
   virtual string    GetGroupName() = 0;
  };
//---
class GroupsTimeFrames:public TimeFrames
  {
private:
   ENUM_TIMEFRAMES   group[];
   datetime          start;
   datetime          end;
   string            name;
public:
                     GroupsTimeFrames(string &gname, ENUM_TIMEFRAMES &arr[], datetime &dStart, datetime &dEnd)
     {
      start = dStart;
      end = dEnd;
      name = gname;
      ArrayResize(group, ArraySize(arr));
      for(int i=0 ; i < ArraySize(arr); i++)
        {group[i] = arr[i];}
     }

   void              GetGroupTF(ENUM_TIMEFRAMES &arr[]) override
     {
      ArrayResize(arr, ArraySize(group));
      for(int i=0; i < ArraySize(group); i++)
        {arr[i] = group[i];}
     }

   datetime          GetStart() override {return start;}
   datetime          GetEnd() override {return end;}
   string            GetGroupName() override {return name;}
  };

//+------------------------------------------------------------------+
//|                     TF_MANAGER                                   |
//+------------------------------------------------------------------+
class TF_Manager
  {
private:
   TimeFrames*       TF_Groups[];
   int               SizeTfGroups;
public:
                     TF_Manager() {ArrayFree(TF_Groups); SizeTfGroups = 0;}

   void              AddTFGroup(string &name, ENUM_TIMEFRAMES &arr[], datetime &start, datetime &end)
     {
      ArrayResize(TF_Groups, SizeTfGroups +1);
      TF_Groups[SizeTfGroups] = new GroupsTimeFrames(name, arr, start, end);
      SizeTfGroups++;
     }

   void              GetTFGroups(TimeFrames* &arr[])
     {
      ArrayResize(arr, ArraySize(TF_Groups));
      for(int i=0; i < ArraySize(TF_Groups); i++)
        {
         arr[i] = TF_Groups[i];
        }
     }
  };

//+------------------------------------------------------------------+
//|              DATA                                                |
//+------------------------------------------------------------------+
class DATA
  {
private:
   DataBars          data[];
public:
   void              AddDATA(TimeFrames* &arr[]) //Функция загрузки баров в DATA
     {
      ENUM_TIMEFRAMES temp_pGroup[];
      int count_data = 0;
      int bars = 0;
      int start_bars = 0;
      int shift = 0;
      int idx = 0;
      for(int i=0; i < ArraySize(arr); i++)
        {
         arr[i].GetGroupTF(temp_pGroup);
         count_data = count_data + ArraySize(temp_pGroup);
         ArrayResize(data, count_data);
         for(int j=0; j < ArraySize(temp_pGroup); j++)
           {
            bars = Bars(_Symbol, temp_pGroup[j], arr[i].GetStart(), arr[i].GetEnd());
            start_bars = iBarShift(_Symbol,temp_pGroup[j], arr[i].GetStart(), false);
            shift = iBarShift(_Symbol, temp_pGroup[j], arr[i].GetEnd(), false);
            data[idx].TF = temp_pGroup[j];
            data[idx].Group_Name = arr[i].GetGroupName();
            data[idx].StartPeriod = arr[i].GetStart();
            data[idx].EndPeriod = arr[i].GetEnd();
            if(shift + 1 > start_bars)
              {
               Print("Нулевой или отрицательный диапазон времени для TF ", EnumToString(temp_pGroup[j]), ". Прекращаем выполнение.");
               return;
              }
            CopyRates(_Symbol, temp_pGroup[j], shift + 1, bars, data[idx].DATA);
            idx++;
           }
        }
     }

   void              GetData(DataBars &arr[])
     {
      ArrayResize(arr, ArraySize(data));
      for(int i=0;i<ArraySize(data);i++)
        {
         arr[i] = data[i];
        }
     }
  };
//+------------------------------------------------------------------+
//|           CLP                                                    |
//+------------------------------------------------------------------+
class CREATE_LEVELS_PATTERNS
  {
private:
public:

   virtual bool               pattern() = 0;

   virtual Direction          GetDirection() = 0;
   virtual ActiveNoes         GetActiveNoes() = 0;
   virtual BreackdownStatus   GetBreakdownStatus() = 0;
   virtual void               GetBarsData(MqlRates &arr) = 0;
   virtual void               GetExtremumStart(MqlRates &bar) = 0;
   virtual void               GetExtremumEnd(MqlRates &bar) = 0;
   virtual void               GetFixBDBar(MqlRates &bar) = 0;
   virtual datetime           GetTFGroupStart() = 0;
   virtual datetime           GetTFGroupEnd() = 0;
   virtual string             GetTFGroupName() =0;
   virtual datetime           GetTime() = 0;
   virtual ENUM_TIMEFRAMES    GetTimeframe() = 0;
   virtual FIRSTBD            GetIsFirst() = 0;

   virtual void               SetExtremumStart(MqlRates &bar) = 0;
   virtual void               SetExtremumEnd(MqlRates &bar) = 0;
   virtual void               SetFixBDBar(MqlRates &bar) = 0;
   virtual void               SetBreakdownStatus(BreackdownStatus value) = 0;
   virtual void               SetActiveNoes(ActiveNoes &value) = 0;
   virtual void               SetTFGroupName(string &name) = 0;
   virtual void               SetTFGroupStart(datetime &start) = 0;
   virtual void               SetTFGroupEnd(datetime &end) = 0;
   virtual void               SetTF(ENUM_TIMEFRAMES TF) = 0;
   virtual void               SetIsFirst(FIRSTBD value) = 0;
   virtual                    ~CREATE_LEVELS_PATTERNS() {}
  };
//---
class NOES : public CREATE_LEVELS_PATTERNS
  {
private:

   Direction         dir;
   ActiveNoes        isActive;
   BreackdownStatus  isSuccess;
   FIRSTBD           isFirst;
   MqlRates          BarsData[1];
   MqlRates          Data[2];
   MqlRates          ExtremumStart;
   MqlRates          ExtremumEnd;
   MqlRates          FixBDBar;
   ENUM_TIMEFRAMES   timeframe;
   string            TFGroupName;
   datetime          TFGroupStart;
   datetime          TFGroupEnd;

public:

                     NOES(MqlRates &arr1, MqlRates &arr2) : CREATE_LEVELS_PATTERNS()
     {
      dir = NONE;
      timeframe = 0;
      ZeroMemory(BarsData);
      Data[0] = arr1;
      Data[1] = arr2;
      isSuccess = WAITING;
      isFirst = NOT_BD;
     }

   bool              pattern()
     {
      dir = NONE;
      if(Data[1].close < Data[1].open && Data[0].close > Data[0].open && Data[0].low < Data[1].low && Data[0].close > Data[1].high)
        {
         dir = BEAR;
         BarsData[0] = Data[0];
         return true;
        }
      else
         if(Data[1].close > Data[1].open && Data[0].close < Data[0].open && Data[0].high > Data[1].high && Data[0].close < Data[1].low)
           {
            dir = BULL;
            BarsData[0] = Data[0];
            return true;
           }
         else
           {
            return false;
           }
     }

   Direction         GetDirection() override {return dir;}
   ActiveNoes        GetActiveNoes() override {return isActive;}
   BreackdownStatus  GetBreakdownStatus() override {return isSuccess;}
   void              GetBarsData(MqlRates &arr) override {arr = BarsData[0];}
   void              GetExtremumStart(MqlRates &bar) override {bar = ExtremumStart;}
   void              GetExtremumEnd(MqlRates &bar) override {bar = ExtremumEnd;}
   void              GetFixBDBar(MqlRates &bar) override {bar = FixBDBar;}
   ENUM_TIMEFRAMES   GetTimeframe() override {return timeframe;}
   string            GetTFGroupName() override {return TFGroupName;}
   datetime          GetTime() override {return BarsData[0].time;}
   datetime          GetTFGroupStart() override {return TFGroupStart;}
   datetime          GetTFGroupEnd() override {return TFGroupEnd;}
   FIRSTBD           GetIsFirst() override {return isFirst;}

   void              SetExtremumStart(MqlRates &bar) override {ExtremumStart = bar;}
   void              SetExtremumEnd(MqlRates &bar) override {ExtremumEnd = bar;}
   void              SetFixBDBar(MqlRates &bar) {FixBDBar = bar;}
   void              SetActiveNoes(ActiveNoes &value) override {isActive = value;}
   void              SetBreakdownStatus(BreackdownStatus value) override {isSuccess = value;}
   void              SetTFGroupName(string &name) override {TFGroupName = name;}
   void              SetTFGroupStart(datetime &start) override {TFGroupStart = start;}
   void              SetTFGroupEnd(datetime &end) override {TFGroupEnd = end;}
   void              SetTF(ENUM_TIMEFRAMES TF) override
     {
      if(TF > 0)
        {timeframe = TF;}
      else
        {timeframe = 0;}
     }
   void              SetIsFirst(FIRSTBD value) override {isFirst = value;}
  };

//+------------------------------------------------------------------+
//|                          CLP_MANAGER                             |
//+------------------------------------------------------------------+
class CLP_Manager
  {
private:

   CREATE_LEVELS_PATTERNS* patterns[];
   CREATE_LEVELS_PATTERNS* noes[];
   DataBars          Data[];
   bool              Noes;

   void              SearchNoes()
     {
      int count_data = 0;
      for(int i=0; i < ArraySize(Data); i++)
        {
         for(int j=0; j < ArraySize(Data[i].DATA); j++)
           {
            count_data++;
           }
        }
      int totalNoes = count_data - ArraySize(Data);
      if(totalNoes <= 0)
        {
         return;
        }
      ArrayResize(noes, totalNoes);
      int CurrentLoadBar = 0;
      for(int i=0; i < ArraySize(Data); i++)
        {
         for(int j = 0; j < ArraySize(Data[i].DATA) - 1; j++)
           {
            noes[CurrentLoadBar] = new NOES(Data[i].DATA[j + 1], Data[i].DATA[j]);
            noes[CurrentLoadBar].SetTF(Data[i].TF);
            noes[CurrentLoadBar].SetTFGroupName(Data[i].Group_Name);
            noes[CurrentLoadBar].SetTFGroupStart(Data[i].StartPeriod);
            noes[CurrentLoadBar].SetTFGroupEnd(Data[i].EndPeriod);
            CurrentLoadBar++;
           }
        }
      for(int i = 1; i < ArraySize(noes); i++)
        {
         if(noes[i].GetTimeframe() == noes[i - 1].GetTimeframe())
           {noes[i].pattern();}
        }
     }

   void              SortByDate()
     {
      CREATE_LEVELS_PATTERNS* temp;
      for(int i=0; i < ArraySize(patterns) -1 ;i++)
        {
         for(int j=0; j < ArraySize(patterns) - i - 1; j++)
           {
            if(patterns[j + 1].GetTime() > patterns[j].GetTime())
              {
               temp = patterns[j + 1];
               patterns[j + 1] = patterns[j];
               patterns[j] = temp;
              }
           }
        }
     }

   void              RemoveEmptyPatterns(CREATE_LEVELS_PATTERNS* &arr[])
     {
      for(int i=0;i<ArraySize(arr);i++)
        {
         if(arr[i].GetDirection() == NONE)
           {
            delete arr[i];
            arr[i] = NULL;
           }
        }
     }

   void              CompactPatternsArray(CREATE_LEVELS_PATTERNS* &arr[])
     {
      int j = 0;
      for(int i=0; i< ArraySize(arr); i++)
        {
         if(arr[i] != NULL)
           {
            arr[j] = arr[i];
            j++;
           }
        }
      ArrayResize(arr, j);
     }

public:

                     CLP_Manager(DataBars &data[])
     {
      ArrayResize(Data, ArraySize(data));
      ArrayFree(patterns);
      ArrayFree(noes);
      for(int i=0; i < ArraySize(data); i++)
        {
         Data[i] = data[i];
        }
     }

   void              GetPatterns(CREATE_LEVELS_PATTERNS* &arr[])
     {
      ArrayResize(arr, ArraySize(patterns));
      for(int i=0; i < ArraySize(patterns); i++)
        {
         arr[i] = patterns[i];
        }
     }

   void              SetActivePatterns(bool isNoes)
     {
      Noes = isNoes;
     }

   void              BuildActivePatterns()
     {
      if(Noes)
        {
         SearchNoes();
         RemoveEmptyPatterns(noes);
         CompactPatternsArray(noes);
         int current_size = ArraySize(patterns);
         ArrayResize(patterns, current_size + ArraySize(noes));
         for(int i= 0; i < ArraySize(noes); i++)
           {
            patterns[i + current_size] = noes[i];
            noes[i] = NULL;
           }
         ArrayFree(noes);
        }
      SortByDate();
     }

   void              drawlvls()
     {
      MqlRates          temp;
      for(int i=0;i<ArraySize(patterns);i++)
        {
         patterns[i].GetBarsData(temp);
         if(patterns[i].GetDirection() == BEAR)
           {
            ObjectCreate(0,"noes" + IntegerToString(i), OBJ_TREND, 0, temp.time, temp.low, temp.time + 600, temp.low);
            ObjectSetInteger(0, "noes" + IntegerToString(i), OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, "noes" + IntegerToString(i), OBJPROP_WIDTH, 3);
            ObjectCreate(0,"target" + IntegerToString(i), OBJ_TREND, 0, temp.time, temp.high + (temp.high - temp.low) * 1.618, temp.time + 600, temp.high + (temp.high - temp.low) * 1.618);
            ObjectSetInteger(0, "target" + IntegerToString(i), OBJPROP_COLOR, clrAliceBlue);
            ObjectSetInteger(0, "target" + IntegerToString(i), OBJPROP_WIDTH, 3);
           }
         else
            if(patterns[i].GetDirection() == BULL)
              {
               ObjectCreate(0,"noes" + IntegerToString(i), OBJ_TREND, 0, temp.time, temp.high, temp.time + 600, temp.high);
               ObjectSetInteger(0, "noes" + IntegerToString(i), OBJPROP_COLOR, clrGreen);
               ObjectSetInteger(0, "noes" + IntegerToString(i), OBJPROP_WIDTH, 3);
               ObjectCreate(0,"target" + IntegerToString(i), OBJ_TREND, 0, temp.time, temp.low - (temp.high - temp.low) * 1.618, temp.time + 600, temp.low - (temp.high - temp.low) * 1.618);
               ObjectSetInteger(0, "target" + IntegerToString(i), OBJPROP_COLOR, clrAliceBlue);
               ObjectSetInteger(0, "target" + IntegerToString(i), OBJPROP_WIDTH, 3);
              }
        }
     }

   void              drawBD()
     {
      MqlRates start;
      MqlRates end;
      for(int i=0;i<ArraySize(patterns);i++)
        {
         patterns[i].GetExtremumStart(start);
         patterns[i].GetExtremumEnd(end);
         if(patterns[i].GetDirection() == BEAR)
           {
            ObjectCreate(0,"BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJ_TREND, 0, start.time, start.close, end.time, end.close);
            ObjectSetInteger(0, "BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJPROP_COLOR, clrWhite);
            ObjectSetInteger(0, "BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJPROP_WIDTH, 3);
           }
         else
            if(patterns[i].GetDirection() == BULL)
              {
               ObjectCreate(0, "BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJ_TREND, 0, start.time, start.close, end.time, end.close);
               ObjectSetInteger(0, "BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJPROP_COLOR, clrWhite);
               ObjectSetInteger(0, "BD " + IntegerToString(i) + " TF: " + EnumToString(patterns[i].GetTimeframe()), OBJPROP_WIDTH, 3);
              }
        }
     }

   void              DeleteDisactiveNoes()
     {
      for(int i=0;i<ArraySize(patterns);i++)
        {
         if(patterns[i].GetActiveNoes() == DISACTIVE)
           {
            delete patterns[i];
            patterns[i] = NULL;
           }
        }
      CompactPatternsArray(patterns);
     }

   void              DeleteFBFailNoes()
     {
      for(int i=0;i<ArraySize(patterns);i++)
        {
         if(patterns[i].GetBreakdownStatus() == FAIL)
           {
            delete patterns[i];
            patterns[i] = NULL;
           }
        }
      CompactPatternsArray(patterns);
     }

   void              DeleteNotFirst()
     {
      for(int i=0;i<ArraySize(patterns);i++)
        {
         if(patterns[i].GetIsFirst() == NOTFIRST)
           {
            delete patterns[i];
            patterns[i] = NULL;
           }
        }
      CompactPatternsArray(patterns);
     }

   //+------------------------------------------------------------------+
   //|                ~CLP_Manager()                                    |
   //+------------------------------------------------------------------+
                    ~CLP_Manager()
     {
      for(int i=0;i<ArraySize(patterns);i++)
        {
         delete patterns[i];
         patterns[i] = NULL;
        }
      ArrayFree(patterns);
     }
  };

//+------------------------------------------------------------------+
//|                              FILTERS                             |
//+------------------------------------------------------------------+
class CLP_Filters
  {
private:
public:
   virtual void      CheckActive() = 0;
  };
//---
class Filters_Noes : public CLP_Filters
  {
private:
   CLP_Manager*      patterns;
   CREATE_LEVELS_PATTERNS* arr[];
public:
                     Filters_Noes(CLP_Manager &obj)
     {
      patterns = &obj;
      patterns.GetPatterns(arr);
     }

   void              CheckActive() override
     {
      int shift_start_patterns = 0;
      int shift_start = 0;
      int shift_end = 0;
      MqlRates pattern;
      MqlRates temp[];
      ActiveNoes isActive;
      for(int i=0;i<ArraySize(arr);i++)
        {
         arr[i].GetBarsData(pattern);
         shift_start_patterns = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTime(), false);
         shift_start = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTFGroupStart(), false);
         shift_end = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTFGroupEnd(), false);
         CopyRates(_Symbol, arr[i].GetTimeframe(), shift_end, shift_start_patterns - shift_end, temp);
         for(int j=0;j<ArraySize(temp);j++) //вынести переменную в глобал
           {
            if(arr[i].GetDirection() == BEAR)
              {
               if(temp[j].high >= pattern.high + (pattern.high - pattern.low) *1.618 && temp[j].low > pattern.low)
                 {
                  isActive = ACTIVE;
                  arr[i].SetActiveNoes(isActive);
                  break;
                 }
               else
                  if(temp[j].high < pattern.high + (pattern.high - pattern.low) * 1.618 && temp[j].low > pattern.low)
                    {
                     isActive = NEUTRAL;
                     arr[i].SetActiveNoes(isActive);
                    }
                  else
                     if(temp[j].high < pattern.high + (pattern.high - pattern.low) *1.618 && temp[j].low < pattern.low)
                       {
                        isActive = DISACTIVE;
                        arr[i].SetActiveNoes(isActive);
                        break;
                       }
              }
            else
               if(arr[i].GetDirection() == BULL)
                 {
                  if(temp[j].low <= pattern.low - (pattern.high - pattern.low) *1.618 && temp[j].high < pattern.high)
                    {
                     isActive = ACTIVE;
                     arr[i].SetActiveNoes(isActive);
                     break;
                    }
                  else
                     if(temp[j].low > pattern.low - (pattern.high - pattern.low) * 1.618 && temp[j].high < pattern.high)
                       {
                        isActive = NEUTRAL;
                        arr[i].SetActiveNoes(isActive);
                       }
                     else
                        if(temp[j].low > pattern.low - (pattern.high - pattern.low) * 1.618 && temp[j].high > pattern.high)
                          {
                           isActive = DISACTIVE;
                           arr[i].SetActiveNoes(isActive);
                           break;
                          }
                 }
           }
        }
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CLP_Filters_Manager
  {
private:

   bool              isNoesFiltered;
   CLP_Filters*      filters;
   CLP_Manager*      patterns;

   void              FilterNoeses()
     {
      filters = new Filters_Noes(patterns);
      filters.CheckActive();
     }

public:

                     CLP_Filters_Manager(CLP_Manager &obj)
     {
      patterns = &obj;
     }

   void              Filtered()
     {
      if(isNoesFiltered)
        {
         FilterNoeses();
         delete filters;
        }
     }

   void              SetActiveFilter(bool noes)
     {
      isNoesFiltered = true;
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BREAKDOWNS_PATTERNS
  {
private:
public:

   virtual void      CheckBreakdown() = 0;

  };

//---
class FIXING : public BREAKDOWNS_PATTERNS
  {
private:
   CLP_Manager*               patterns;
   CREATE_LEVELS_PATTERNS*    arr[];
   TimeFrames*                tfgroups[];
   int                        count_fbars;
   int                        count_fbars_fpoints;
   int                        shift_start_patterns;
   int                        shift_start;
   int                        shift_end;
   int                        bars;
   double                     count_fpoints;
   MqlRates                   pattern;
   MqlRates                   temp[];

   void              SetBDSucces(CREATE_LEVELS_PATTERNS &noes, MqlRates &tmp)
     {
      noes.SetBreakdownStatus(SUCCESS);
      noes.SetFixBDBar(tmp);
     }

public:
                     FIXING(CLP_Manager &obj_clp, TF_Manager &obj_tfm, int CountFixingBars, int CountFixBarsPoints, double CountFixingPoints) : BREAKDOWNS_PATTERNS() //добавить переменную для целового уровня
     {
      patterns = &obj_clp;
      patterns.GetPatterns(arr);
      obj_tfm.GetTFGroups(tfgroups);
      count_fbars = CountFixingBars;
      count_fpoints = CountFixingPoints * _Point;
      count_fbars_fpoints = CountFixBarsPoints;
      shift_start_patterns = 0;
      shift_start = 0;
      shift_end = 0;
      bars = 0;
      ArrayResize(temp, 0);
     }

   void              CheckBreakdown() override
     {
      for(int i=0;i<ArraySize(tfgroups);i++)
        {
         for(int j=ArraySize(arr) -1; j >= 0; j--)
           {
            if(arr[j].GetTFGroupName() == tfgroups[i].GetGroupName())
              {
               bool attention = false;
               int count_close = 0;
               arr[j].GetBarsData(pattern);
               shift_start_patterns = iBarShift(_Symbol, arr[j].GetTimeframe(), arr[j].GetTime(), false);
               shift_end = iBarShift(_Symbol, arr[j].GetTimeframe(), arr[j].GetTFGroupEnd(), false);
               bars = shift_start_patterns - shift_end;
               CopyRates(_Symbol,arr[j].GetTimeframe(), shift_end, bars, temp);
               //Print("range " + IntegerToString(ArraySize(temp)));
               if(arr[j].GetDirection() == BEAR)
                 {
                  for(int k=1; k<ArraySize(temp); k++)
                    {
                     if(count_close < count_fbars || (count_close < count_fbars_fpoints && pattern.low - temp[k].close < count_fpoints))
                       {
                        if(attention == false)
                          {
                           if(temp[k].low < pattern.low)
                             {
                              attention = true;
                              if(temp[k].close < pattern.low)
                                {
                                 count_close++;
                                }
                             }
                          }
                        else
                           if(temp[k].close < pattern.high)
                             {
                              if(temp[k].close < pattern.low)
                                {
                                 count_close++;
                                }
                              else
                                {
                                 count_close = 0;
                                }
                             }
                           else
                              if(temp[k].close > pattern.high)
                                {
                                 arr[j].SetBreakdownStatus(FAIL);
                                 break;
                                }
                       }
                     else
                        if(count_close >= count_fbars || (count_close >= count_fbars_fpoints && pattern.low - temp[k].close >= count_fpoints))
                          {
                           if(k > 0 && temp[k -1].close > temp[k-1].open)
                             {
                              SetBDSucces(arr[j], temp[k-1]);
                              break;
                             }
                           else
                              if(temp[k].close > temp[k].open)
                                {
                                 SetBDSucces(arr[j], temp[k]);
                                 break;
                                }
                          }
                    }
                 }
               else
                  if(arr[j].GetDirection() == BULL)
                    {
                     for(int t=1; t<ArraySize(temp); t++)
                       {
                        if(count_close < count_fbars || (count_close < count_fbars_fpoints && temp[t].close - pattern.high < count_fpoints))
                          {
                           if(attention == false)
                             {
                              if(temp[t].high > pattern.high)
                                {
                                 attention = true;
                                 if(temp[t].close > pattern.high)
                                   {
                                    count_close++;
                                   }
                                }
                             }
                           else
                              if(temp[t].close > pattern.low)
                                {
                                 if(temp[t].close > pattern.high)
                                   {
                                    count_close++;
                                   }
                                 else
                                   {
                                    count_close = 0;
                                   }
                                }
                              else
                                 if(temp[t].close < pattern.low)
                                   {
                                    arr[j].SetBreakdownStatus(FAIL);
                                    break;
                                   }
                          }
                        else
                           if(count_close >= count_fbars || (count_close >= count_fbars_fpoints && temp[t].close - pattern.high >= count_fpoints))
                             {
                              if(t > 0 && temp[t -1].close < temp[t-1].open)
                                {
                                 SetBDSucces(arr[j], temp[t-1]);
                                 break;
                                }
                              else
                                 if(temp[t].close < temp[t].open)
                                   {
                                    SetBDSucces(arr[j], temp[t]);
                                    break;
                                   }
                             }
                       }
                    }
              }
            //MqlRates bvc;
            //arr[j].GetFixBDBar(bvc);
            //Print("bvc " + bvc.close);
           }
        }
     }
  };

//+------------------------------------------------------------------+
//|           BD_Manager                                             |
//+------------------------------------------------------------------+
class BD_Manager
  {
private:

   CLP_Manager*            clp;
   BREAKDOWNS_PATTERNS*    bd_fix;
   bool                    isFixing;

public:

                     BD_Manager(CLP_Manager &obj_clp, TF_Manager &obj_tf, int count_fixbars, int count_fixbarspoints, double count_fixpoints, BD_name name) // Для других сделать перегрузку конструктора
     {
      if(name == BD_Fixing)
        {
         clp = &obj_clp;
         bd_fix = new FIXING(&obj_clp, &obj_tf, count_fixbars, count_fixbarspoints, count_fixpoints);
         isFixing = fixing;
        }
     }

   void              BD_patterns()
     {
      if(isFixing)
        {
         bd_fix.CheckBreakdown();
        }
     }
                    ~BD_Manager()
     {
      delete bd_fix;
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class DATASIGNALS
  {
private:

   SignalRange                RangeSig;
   TF_Manager*                tfm_m;
   CLP_Manager*               clp_m;
   CREATE_LEVELS_PATTERNS*    clp[];
   TimeFrames*                tfgroups[];

public:

                     DATASIGNALS(SignalRange value, TF_Manager &tfm_obj, CLP_Manager &clp_obj)
     {
      RangeSig = value;
      tfm_m = &tfm_obj;
      clp_m = &clp_obj;
      clp_m.GetPatterns(clp);
      tfm_obj.GetTFGroups(tfgroups);
     }

   void              Extremums()
     {
      for(int i=0;i<ArraySize(tfgroups);i++)
        {
         for(int j=ArraySize(clp) - 1; j >= 0; j--)
           {
            if(clp[j].GetBreakdownStatus() == SUCCESS)
              {
               if(clp[j].GetTFGroupName() == tfgroups[i].GetGroupName())
                 {
                  MqlRates fixbar;
                  MqlRates pattern;
                  MqlRates temp[];
                  MqlRates exstart;
                  MqlRates exend;
                  clp[j].GetFixBDBar(fixbar);
                  clp[j].GetBarsData(pattern);
                  double max_exstart = pattern.close;
                  double min_exstart = pattern.close;
                  double max_exend = pattern.close;
                  double min_exend = pattern.close;
                  int shift_start_patterns = 0;
                  int shift_start = 0;
                  int shift_end = 0;
                  int bars = 0;
                  shift_start_patterns = iBarShift(_Symbol, clp[j].GetTimeframe(), clp[j].GetTime(), false);
                  shift_end = iBarShift(_Symbol, clp[j].GetTimeframe(), fixbar.time, false);
                  bars = shift_start_patterns - shift_end;
                  CopyRates(_Symbol, clp[j].GetTimeframe(), shift_end, shift_start_patterns - shift_end, temp);
                  for(int t=1;t<ArraySize(temp);t++)
                    {
                     if(clp[j].GetBreakdownStatus() == SUCCESS)
                       {
                        if(clp[j].GetDirection() == BEAR)
                          {
                           if(temp[t].high > max_exstart)
                             {
                              max_exstart = temp[t].high;
                              exstart = temp[t];
                             }
                           if(temp[t].low < max_exend)
                             {
                              max_exend = temp[t].low;
                              exend = temp[t];
                             }
                          }
                        else
                           if(clp[j].GetDirection() == BULL)
                             {
                              if(temp[t].low < min_exstart)
                                {
                                 min_exstart = temp[t].low;
                                 exstart = temp[t];
                                }
                              if(temp[t].high > min_exend)
                                {
                                 min_exend = temp[t].high;
                                 exend = temp[t];
                                }
                             }
                       }
                    }
                  clp[j].SetExtremumStart(exstart);
                  clp[j].SetExtremumEnd(exend);
                 }
              }
           }
        }
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SIGNALS_FILTERS
  {
public:
private:
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class FIRST_BD_FILTER : public SIGNALS_FILTERS
  {
private:
   CREATE_LEVELS_PATTERNS* clp[];
   CLP_Manager*      clp_m;
   TimeFrames*       tf[];
public:
                     FIRST_BD_FILTER(CLP_Manager &obj_clpm, TF_Manager &obj_tfm) : SIGNALS_FILTERS()
     {
      obj_clpm.GetPatterns(clp);
      clp_m = &obj_clpm;
      obj_tfm.GetTFGroups(tf);
     }

   void              CheckFirstDB()
     {
      MqlRates temp[];
      MqlRates ex_clp;
      int shiftstart = 0;
      int shiftend = 0;
      int bars = 0;
      for(int i=0; i < ArraySize(tf); i++)
        {
         for(int j=0; j<ArraySize(clp); j++)
           {
            if(clp[j].GetTFGroupName() == tf[i].GetGroupName() && clp[j].GetBreakdownStatus() == SUCCESS)
              {
               for(int t=j + 1; t<ArraySize(clp);t++)
                 {
                  if(clp[t].GetBreakdownStatus() == WAITING && clp[t].GetIsFirst() != NOTFIRST)
                    {
                     clp[j].GetExtremumStart(ex_clp);
                     shiftstart = iBarShift(_Symbol, clp[j].GetTimeframe(), clp[t].GetTime(), false);
                     shiftend = iBarShift(_Symbol, clp[j].GetTimeframe(), clp[j].GetTime(), false);
                     bars = shiftstart - shiftend;
                     CopyRates(_Symbol, clp[j].GetTimeframe(), shiftend, bars, temp);
                     if(clp[j].GetDirection() == BEAR && clp[t].GetDirection() == BEAR)
                       {
                        for(int y=0; y < ArraySize(temp); y++)
                          {
                           if(temp[y].high >= ex_clp.high)
                             {
                              clp[t].SetIsFirst(FIRST);
                              break;
                             }
                           else
                              if(temp[y].high < ex_clp.high)
                                {
                                 clp[t].SetIsFirst(NOTFIRST);
                                }
                          }
                       }
                     else
                        if(clp[j].GetDirection() == BULL && clp[t].GetDirection() == BULL)
                          {
                           for(int r=0; r < ArraySize(temp); r++)
                             {
                              if(temp[r].low <= ex_clp.low)
                                {
                                 clp[t].SetIsFirst(FIRST);
                                 break;
                                }
                              else
                                 if(temp[r].low > ex_clp.low)
                                   {
                                    clp[t].SetIsFirst(NOTFIRST);
                                   }
                             }
                          }
                    }
                 }
              }
           }
        }
     }
     
     void CheckDubleSignals()
     {
     for()
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
bool fixing =     true;
bool del_fixing = true;
bool del_delfilternoes = true;
bool del_notfirst = true;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void              OnStart()
  {
   ulong starti = GetTickCount64();       // старт замера времени
   long mem_start = TerminalInfoInteger(TERMINAL_MEMORY_USED); // старт памяти

   string name1 = "a";
   ENUM_TIMEFRAMES arr1[] =
     {PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6}; //PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6
   datetime start1 = D'2025.07.20 10:00';
   datetime end1 = TimeCurrent();

//string name2 = "b";
// ENUM_TIMEFRAMES arr2[] =
//  {PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30};
// datetime start2 = D'2025.07.15 00.00';
// datetime end2 = TimeCurrent();

//string name3 = "с";
//ENUM_TIMEFRAMES arr3[] =
//   {PERIOD_H1,PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6}; //, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6}
// datetime start3 = D'2025.07.25 00.00';
// datetime end3 = TimeCurrent();

   TF_Manager TF;
   TF.AddTFGroup(name1, arr1, start1, end1);
//TF.AddTFGroup(name2, arr2, start2, end2);
//TF.AddTFGroup(name3, arr3, start3, end3);

   TimeFrames* groups[];
   TF.GetTFGroups(groups);
   DATA LoadData;
   LoadData.AddDATA(groups);
   DataBars x[];
   LoadData.GetData(x);

   CLP_Manager pattern(x);
   pattern.SetActivePatterns(true);
   pattern.BuildActivePatterns();

   CREATE_LEVELS_PATTERNS* aee[];
   pattern.GetPatterns(aee);
   Print("Общее количество " + IntegerToString(ArraySize(aee)));

   CLP_Filters_Manager axx(pattern);
   axx.SetActiveFilter(true);
   axx.Filtered();
   if(del_delfilternoes)
     {
      pattern.DeleteDisactiveNoes();
     }

   pattern.GetPatterns(aee);
   Print("Не пробитые: " + IntegerToString(ArraySize(aee))); //до

   if(fixing)
     {
      BD_Manager bd_fixing(pattern, TF, 3, 2, 20, BD_Fixing);
      bd_fixing.BD_patterns();
     }

   if(del_fixing)
     {
      pattern.DeleteFBFailNoes();
     }

   pattern.GetPatterns(aee);
   Print("Не пробитые и поломанные: " + IntegerToString(ArraySize(aee))); //после

   DATASIGNALS abb(OpenClose, TF, pattern);
   Print("Ищем экстремумы");
   abb.Extremums();
   Print("Экстремумы найдены");


   FIRST_BD_FILTER gg(pattern, TF);
   gg.CheckFirstDB();

   if(del_notfirst)
     {
      pattern.DeleteNotFirst();
     }

   pattern.drawlvls();
   pattern.drawBD();

   for(int i=0;i<ArraySize(groups);i++)
     {
      delete groups[i];
      groups[i] = NULL;
     }
   ArrayFree(groups); //ЭТО ВСЁ ПЕРВИЧНАЯ ХУЕТА КОТОРАЯ БУДЕТ ОБРАБАТЫВАТЬСЯ ПРИ ИНИЦИАЛИЗАЦИИ, ПОТОМ БУДЕТ РАБОАТЬ ЧЕРЕЗ i**

   ulong endi = GetTickCount64(); // конец замера
   long mem_end = TerminalInfoInteger(TERMINAL_MEMORY_USED); // финальная память

   Print("Время выполнения (ms): ", (endi - starti));
   Print("Память до: ", DoubleToString((double)mem_start / 1048576, 2), " MB");
   Print("Память после: ", DoubleToString((double)mem_end / 1048576, 2), " MB");
  }
//+------------------------------------------------------------------+

