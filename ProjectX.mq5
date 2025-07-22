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
   virtual bool      pattern() = 0;
   virtual Direction GetDirection() = 0;
   virtual ActiveNoes GetActiveNoes() = 0;
   virtual void      SetActiveNoes(ActiveNoes value) = 0;
   virtual void      GetBarsData(MqlRates &arr) = 0;
   virtual void      SetTFGroupName(string &name) = 0;
   virtual void      SetTFGroupStart(datetime &start) = 0;
   virtual void      SetTFGroupEnd(datetime &end) = 0;
   virtual datetime  GetTFGroupStart() = 0;
   virtual datetime  GetTFGroupEnd() = 0;
   virtual string    GetTFGroupName() =0;
   virtual ENUM_TIMEFRAMES GetTimeframe() = 0;
   virtual void      SetTF(ENUM_TIMEFRAMES TF) = 0;
   virtual datetime  GetTime() = 0;
   virtual          ~CREATE_LEVELS_PATTERNS() {}
  };
//---
class NOES : public CREATE_LEVELS_PATTERNS
  {
private:

   Direction         dir;
   ActiveNoes        isActive;
   MqlRates          BarsData[1];
   MqlRates          Data[2];
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
     }

   bool              pattern()
     {
      dir = NONE;
      if(/* logic intentionally hidden */) 
        {
         dir = BEAR;
         BarsData[0] = Data[0];
         return true;
        }
      else
         if(/* logic intentionally hidden */)
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
   void              GetBarsData(MqlRates &arr) override {arr = BarsData[0];}
   ENUM_TIMEFRAMES   GetTimeframe() override {return timeframe;}
   string            GetTFGroupName() override {return TFGroupName;}
   datetime          GetTime() override {return BarsData[0].time;}
   datetime          GetTFGroupStart() override {return TFGroupStart;}
   datetime          GetTFGroupEnd() override {return TFGroupEnd;}

   void              SetActiveNoes(ActiveNoes value) override {isActive = value;}
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
      int CurrrentLoadBar = 0;
      for(int i=0; i < ArraySize(Data); i++)
        {
         for(int j = 0; j < ArraySize(Data[i].DATA) - 1; j++)
           {
            noes[CurrrentLoadBar] = new NOES(Data[i].DATA[j + 1], Data[i].DATA[j]);
            noes[CurrrentLoadBar].SetTF(Data[i].TF);
            noes[CurrrentLoadBar].SetTFGroupName(Data[i].Group_Name);
            noes[CurrrentLoadBar].SetTFGroupStart(Data[i].StartPeriod);
            noes[CurrrentLoadBar].SetTFGroupEnd(Data[i].EndPeriod);
            CurrrentLoadBar++;
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

   void              RemoveEmptyPatterns()
     {
      for(int i=0;i<ArraySize(noes);i++)
        {
         if(noes[i].GetDirection() == NONE)
           {
            delete noes[i];
            noes[i] = NULL;
           }
        }
     }

   void              CompactPatternsArray()
     {
      int j = 0;
      for(int i=0; i< ArraySize(noes); i++)
        {
         if(noes[i] != NULL)
           {
            noes[j] = noes[i];
            j++;
           }
        }
      ArrayResize(noes, j);
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
         RemoveEmptyPatterns();
         CompactPatternsArray();
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
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BREAKDOWNS_PATTERNS
  {
private:
public:
  };
//---
class FIXING : public BREAKDOWNS_PATTERNS
  {
private:
public:
  };
//+------------------------------------------------------------------+
//|                              FILTERS                             |
//+------------------------------------------------------------------+
class CLP_Filters
  {
private:
public:
  };
//---
class Filters_Noes : public CLP_Filters
  {
private:
public:

   static void       CheckActive(CREATE_LEVELS_PATTERNS* &arr[])
     {
      int shift_start_patterns = 0;
      int shift_start = 0;
      int shift_end = 0;
      int bars = 0;
      MqlRates pattern;
      MqlRates temp[];
      for(int i=0;i<ArraySize(arr);i++)
        {
         arr[i].GetBarsData(pattern);
         shift_start_patterns = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTime(), false);
         shift_start = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTFGroupStart(), false);
         shift_end = iBarShift(_Symbol, arr[i].GetTimeframe(), arr[i].GetTFGroupEnd(), 0);
         CopyRates(_Symbol, arr[i].GetTimeframe(), shift_end +1, shift_end - shift_start_patterns, temp);
         if(arr[i].GetDirection() == BEAR)
           {
            for(int j=0; j < ArraySize(temp); j++)
              {
               if(/* logic intentionally hidden */)
                 {
                  arr[i].SetActiveNoes(ACTIVE);
                  break;
                 }
               else
                  if(/* logic intentionally hidden */)
                    {
                     arr[i].SetActiveNoes(NEUTRAL);
                     break;
                    }
                  else
                     if(/* logic intentionally hidden */)
                       {
                        arr[i].SetActiveNoes(DISACTIVE);
                        break;
                       }
              }
           }
         else
            if(arr[i].GetDirection() == BULL)
              {
               for(int k=0; k < ArraySize(temp); k++)
                 {
                  if(/* logic intentionally hidden */)
                    {
                     arr[i].SetActiveNoes(ACTIVE);
                     break;
                    }
                  else
                     if(/* logic intentionally hidden */)
                       {
                        arr[i].SetActiveNoes(NEUTRAL);
                        break;
                       }
                     else
                        if(/* logic intentionally hidden */)
                          {
                           arr[i].SetActiveNoes(DISACTIVE);
                           break;
                          }
                 }
              }
        }
     }

  };

//+------------------------------------------------------------------+
//|                    CLP_Filters_Manager                           |
//+------------------------------------------------------------------+
class CLP_Filters_Manager
  {
private:
public:
  };
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void              OnStart()
  {
   ulong starti = GetTickCount64();       // старт замера времени
   long mem_start = TerminalInfoInteger(TERMINAL_MEMORY_USED); // старт памяти

   string name1 = "a";
   ENUM_TIMEFRAMES arr1[] =
     {PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6};
   datetime start1 = D'2025.07.20 00.00';
   datetime end1 = TimeCurrent();

   string name2 = "b";
   ENUM_TIMEFRAMES arr2[] =
     {PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30};
   datetime start2 = D'2025.05.20 00.00';
   datetime end2 = D'2025.07.15 00.00';

   string name3 = "c";
   ENUM_TIMEFRAMES arr3[] =
     {PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6};
   datetime start3 = D'2025.02.26 00.00';
   datetime end3 = D'2025.07.18 00.00';

   TF_Manager TF;
   TF.AddTFGroup(name1, arr1, start1, end1);
   TF.AddTFGroup(name2, arr2, start2, end2);
   TF.AddTFGroup(name3, arr3, start3, end3);

   TimeFrames* groups[];
   TF.GetTFGroups(groups);
   DATA LoadData;
   LoadData.AddDATA(groups);
   DataBars x[];
   LoadData.GetData(x);

   CLP_Manager pattern(x);
   pattern.SetActivePatterns(true);
   pattern.BuildActivePatterns();

   CREATE_LEVELS_PATTERNS* acc[];
   pattern.GetPatterns(acc);

   for(int i=0;i<ArraySize(acc);i++)
     {
      if(acc[i].GetTFGroupName() == name3 && acc[i].GetTimeframe() == PERIOD_H1)
        {
         Print(acc[i].GetTime());
        }
     }

   ulong endi = GetTickCount64(); // конец замера
   long mem_end = TerminalInfoInteger(TERMINAL_MEMORY_USED); // финальная память

   Print("Время выполнения (ms): ", (endi - starti));
   Print("Память до: ", DoubleToString((double)mem_start / 1048576, 2), " MB");
   Print("Память после: ", DoubleToString((double)mem_end / 1048576, 2), " MB");
  }


//+------------------------------------------------------------------+
