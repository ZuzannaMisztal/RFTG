with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;
use Ada.Text_IO;

package body Player_Operations is

   package Roll is new Ada.Numerics.Discrete_Random(Dice_Side);
   package Random_Index is new Ada.Numerics.Discrete_Random(Integer);

   Planet_Sack: Planet_Array(0 .. 47);
   Sack_Availability: Availability_Array(0 .. 47) := (others => True);
   Initial_Planets: Planet_Array(0 .. 15);
   Init_Availability: Availability_Array(0 .. 15) := (others => True);

   procedure Get_Initial_Planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array;
                                Money: in out Credits; Population: in out Dices; Cup: in out Dices) is
      Gen: Random_Index.Generator;
      Ind: Integer;
   begin
      Random_Index.Reset(Gen);

      for I in 0..1 loop
         Ind := Random_Index.Random(Gen) mod 16;
         while Init_Availability(Ind) = False loop
            Ind := Random_Index.Random(Gen) mod 16;
         end loop;

         Init_Availability(Ind) := False;
         Planets(I) := Initial_Planets(Ind);
         Collect_From_Planet(Initial_Planets(Ind), Money, Population, Cup);
      end loop;

      Ind := Random_Index.Random(Gen) mod 48;

      while Sack_Availability(Ind) = False loop
         Ind := Random_Index.Random(Gen) mod 48;
      end loop;

      Sack_Availability(Ind) := False;
      Planet_Queue(0) := Planet_Sack(Ind);
   end Get_Initial_Planets;

   procedure Collect_From_Planet(A_Planet: in Planet; Money: in out Credits; Population: in out Dices; Cup: in out Dices) is
   begin
      Money := Money + A_Planet.Money; -- tutaj moze byc problem jak przekroczy 10

      if A_Planet.Pop_Add /= D_Null then
         for I in Population'Range loop
            if Population(I) = D_Null then
               Population(I) := A_Planet.Pop_Add;
               exit;
            end if;
         end loop;
      end if;

      if A_Planet.Cup_Add /= D_Null then
         for I in Cup'Range loop
            if Cup(I) = D_Null then
               Cup(I) := A_Planet.Cup_Add;
               exit;
            end if;
         end loop;
      end if;
   end Collect_From_Planet;

   procedure Roll_Dices(Cup: in Dices; Roll_Output: out Dice_Array) is
      Dice_Output: Dice;
   begin
      for I in Cup'Range loop
         if Cup(I) /= D_Null then
            Dice_Output.Color := Cup(I);
            Dice_Output.Outcome := Roll_Dice(Cup(I));
            Roll_Output(I) := Dice_Output;
         end if;
      end loop;
   end Roll_Dices;

   function Roll_Dice(Color: in Dice_Color) return Action is
      Result : Dice_Side;
      Gen    : Roll.Generator;
   begin
      Roll.Reset(Gen);
      Result := Roll.Random(Gen);

      if Color = White then
         if Result = 1 or Result = 2 then return Exp;
         elsif Result = 3 then return Roll_Dice(Color);
         elsif Result = 4 then return Sett;
         elsif Result = 5 then return Prod;
         else return Ship;
         end if;
      elsif Color = Red then
         if Result = 1 then return Exp;
         elsif Result = 2 or Result = 3 then return Roll_Dice(Color);
         elsif Result = 4 or Result = 5 then return Sett;
         else return Joker;
         end if;
      elsif Color = Purple then
         if Result = 1 then return Exp;
         elsif Result = 2 then return Roll_Dice(Color);
         elsif Result = 3 or Result = 4 or Result = 5 then return Ship;
         else return Joker;
         end if;
      elsif Color = Blue then
         if Result = 1 then return Exp;
         elsif Result = 2 or Result = 3 then return Prod;
         elsif Result = 4 or Result = 5 then return Ship;
         else return Joker;
         end if;
      elsif Color = Brown then
         if Result = 1 then return Exp;
         elsif Result = 2 or Result = 3 then return Roll_Dice(Color);
         elsif Result = 4 then return Prod;
         elsif Result = 5 then return Ship;
         else return Joker;
         end if;
      elsif Color = Green then
         if Result = 1 then return Exp;
         elsif Result = 2 or Result = 3 then return Sett;
         elsif Result = 4 then return Prod;
         else return Joker;
         end if;
      else
         if Result = 1 then return Roll_Dice(Color);
         elsif Result = 2 then return Sett;
         elsif Result = 3 then return Prod;
         else return Joker;
         end if;
      end if;

   end Roll_Dice;

   function Dices_To_String(Roll_Output: in Dice_Array) return Unbounded_String is
      Result: Unbounded_String := To_Unbounded_String("");
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null then
            Result := Result & Roll_Output(I).Color'Img & ": " & Roll_Output(I).Outcome'Img & "| ";
         end if;
      end loop;
      return Result;
   end Dices_To_String;

   function Number_Of_Occurences(Roll_Output: in Dice_Array; An_Action: in Action) return Integer is
      Result: Integer := 0;
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null and Roll_Output(I).Outcome = An_Action then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Number_Of_Occurences;

   function Pick_Action(Roll_Output: in Dice_Array) return Integer is
      Exp_Num: Integer;
      Sett_Num: Integer;
      Prod_Num: Integer;
      Ship_Num: Integer;
   begin
      Exp_Num := Number_Of_Occurences(Roll_Output, Exp);
      Sett_Num := Number_Of_Occurences(Roll_Output, Sett);
      Prod_Num := Number_Of_Occurences(Roll_Output, Prod);
      Ship_Num := Number_Of_Occurences(Roll_Output, Ship);
      if Sett_Num >= Exp_Num and Sett_Num >= Prod_Num and Sett_Num >= Ship_Num then
         return 2;
      elsif Prod_Num >= Exp_Num and Prod_Num >= Ship_Num then
         return 3;
      elsif Ship_Num >= Exp_Num then
         return 4;
      else
         return 1;
      end if;
   end Pick_Action;

   procedure Jokers_To_Picked_Action(Roll_Output: in out Dice_Array; Picked_Action: in Integer; P : in Positive) is
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Outcome = Joker and Roll_Output(I).Color /= D_Null then
            if Picked_Action = 1 then
               Roll_Output(I).Outcome := Exp;
            elsif Picked_Action = 2 then
               Roll_Output(I).Outcome := Sett;
            elsif Picked_Action = 3 then
               Roll_Output(I).Outcome := Prod;
            else
               Roll_Output(I).Outcome := Ship;
            end if;
         end if;
      end loop;
   end Jokers_To_Picked_Action;

   procedure Explore(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Money: in out Credits; Population: in out Dices) is
      Num          : Integer;
      Times_Stock  : Integer;
      Times_Scout  : Integer;
      Gen          : Random_Index.Generator;
      Ind          : Integer;
      Ind_Queue    : Integer := 0;

   begin
      Num := Number_Of_Occurences(Roll_Output, Exp);
      Times_Stock := Num / 2;
      Times_Scout := Num - Times_Stock;

      while Ind_Queue <= 4 and then Planet_Queue(Ind_Queue).Value > -1 loop
         Ind_Queue := Ind_Queue + 1;
      end loop;
      --Put_Line("Znalezlem pierwsze puste miejsce w planet_queue");

      --jesli planety nie zmieszcza sie w planet_queue przydziel pozostale kostki do magazynowania
      if Times_Scout > 5 - Ind_Queue then
         Times_Stock := Times_Stock + Times_Scout + Ind_Queue - 5;
         Times_Scout := 5 - Ind_Queue;
      end if;

      for I in 1..Num loop
         --znajdz odpowiednia kostke
         for J in Roll_Output'Range loop
            if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Exp then
               --dodaj kostkę do populacji
               for K in Population'Range loop
                  if Population(K) = D_Null then
                     Population(K) := Roll_Output(J).Color;
                     exit;
                  end if;
               end loop;
               Roll_Output(J).Color := D_Null;
               exit;
            end if;
         end loop;
      end loop;
      --Put_Line("Przenioslem kostki do populacji");

      for I in 1..Times_Stock loop
         Money := Money + 2;
      end loop;
      --Put_Line("Zmagazynowalem");

      for I in 1..Times_Scout loop
         Ind := Random_Index.Random(Gen) mod 48;
         while Sack_Availability(Ind) = False loop
            Ind := Random_Index.Random(Gen) mod 48;
         end loop;
         --Put_Line("Wylosowalem planete " & I'Img & "/" & Times_Scout'Img);
         Sack_Availability(Ind) := False;
         Planet_Queue(Ind_Queue) := Planet_Sack(Ind);
         Ind_Queue := Ind_Queue + 1;
      end loop;
      --Put_Line("Zebralem nowe planety do planet_queue");
   end Explore;

   procedure Settle(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Planets: in out Planet_Array; Population: in out Dices;
                    Settlers: in out Dices; Cup: in out Dices; Tiles: in out Positive; Money: in out Credits; P: in Positive) is
      Num                     : Integer;
      Num_Of_Settlers_Already : Integer := 0;
      Num_Needed              : Integer;
      New_Planet_Queue        : Planet_Array(0..4);
   begin
      Num := Number_Of_Occurences(Roll_Output, Sett);
      for I in Settlers'Range loop
         if Settlers(I) /= D_Null then
            Num_Of_Settlers_Already := Num_Of_Settlers_Already + 1;
         end if;
      end loop;

      while Num + Num_Of_Settlers_Already >= Planet_Queue(0).Value loop
         if Planet_Queue(0).Value = -1 then --to oznacza, ze nie ma zadnych planet w kolejce
            Unused_Settlers_To_Cup(Roll_Output, Cup);
            exit;
         end if;
         Num_Needed := Planet_Queue(0).Value - Num_Of_Settlers_Already;
         --przenies Settlers i odpowiednia liczbe kostek z roll_output do populacji
         if Num_Of_Settlers_Already > 0 then
            for I in Settlers'Range loop
               if Settlers(I) /= D_Null then
                  for J in Population'Range loop
                     if Population(J) = D_Null then
                        Population(J) := Settlers(I);
                        Settlers(I) := D_Null;
                        Num_Of_Settlers_Already := Num_Of_Settlers_Already - 1;
                        exit;
                     end if;
                  end loop;
               end if;
            end loop;
         end if;

         for I in 1..Num_Needed loop
         --znajdz odpowiednia kostke
            for J in Roll_Output'Range loop
               if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Sett then
                  --dodaj kostkę do populacji
                  for K in Population'Range loop
                     if Population(K) = D_Null then
                        Population(K) := Roll_Output(J).Color;
                        exit;
                     end if;
                  end loop;
                  Roll_Output(J).Color := D_Null;
                  exit;
               end if;
            end loop;
         end loop;
         Num := Num - Num_Needed;
         --przenies planete z kolejki do zdobytych planet
         collect_from_planet(Planet_Queue(0), Money, Population, Cup);
         Planets(Tiles) := Planet_Queue(0);
         New_Planet_Queue(0..3) := Planet_Queue(1..4);
         Tiles := Tiles + 1;
         Planet_Queue := New_Planet_Queue;
      end loop;

      --przenies pozostale kostki z akcja sett do Settlers
      if Planet_Queue(0).Value > -1 then
         for I in 1..Num loop
            for J in Roll_Output'Range loop
               if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Sett then
                  Settlers(I-1) := Roll_Output(J).Color;
                  Roll_Output(J).Color := D_Null;
                  exit;
               end if;
            end loop;
         end loop;
      end if;
   end Settle;

   procedure Unused_Settlers_To_Cup(Roll_Output: in out Dice_Array; Cup: in out Dices) is
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null and Roll_Output(I).Outcome = Sett then
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Roll_Output(I).Color;
                  Roll_Output(I).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
   end Unused_Settlers_To_Cup;

   procedure Produce(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Cup: in out Dices) is
   begin
      --najpierw probujemy dopasowac do kazdej pustej planety odpowiedni kolor dobra
      for I in Planets'Range loop
         --jesli na planecie mozna wyprodukowac dobro
         if Planets(I).Color /= P_Gray and Planets(I).Value > -1 and Planets(I).Good = D_Null then
            --poszukaj produkujacej kostki w odpowiednim kolorze
            for J in Roll_Output'Range loop
               if Roll_Output(J).Outcome = Prod and then Is_The_Same_Color(Planets(I).Color, Roll_Output(J).Color) then
                  Planets(I).Good := Roll_Output(J).Color;
                  Roll_Output(J).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      --nastepnie wyprodukuj na pozostalych planetach niezaleznie od koloru kostek
      for I in Planets'Range loop
         if Planets(I).Color /= P_Gray and Planets(I).Value > -1 and Planets(I).Good = D_Null then
            for J in Roll_Output'Range loop
               if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Prod then
                  Planets(I).Good := Roll_Output(J).Color;
                  Roll_Output(J).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      --jesli zostaly kosci z akcja produkcji przenies je do kubka
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null and Roll_Output(I).Outcome = Prod then
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Roll_Output(I).Color;
                  Roll_Output(I).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
   end Produce;

   function Is_The_Same_Color(Planet_Col: Planet_Color; Dice_Col: Dice_Color) return Boolean is
   begin
      if Planet_Col = P_Blue and Dice_Col = Blue then
         return True;
      elsif Planet_Col = P_Brown and Dice_Col = Brown then
         return True;
      elsif Planet_Col = P_Green and Dice_Col = Green then
         return True;
      elsif Planet_Col = P_Yellow and Dice_Col = Yellow then
         return True;
      elsif Dice_Col = Purple then -- fioletowa kostka jest liczona jako dowolny kolor
         return True;
      else
         return False;
      end if;
   end Is_The_Same_Color;

   procedure Deliver(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Points: in out Integer;
                     Population: in out Dices; Cup: in out Dices) is
      One_Delivery_Points: Integer;
   begin
      --najpierw staramy sie dostarczyc kostka o kolorze zgodnym z kolorem planety
      for I in Planets'Range loop
         if Planets(I).Value > -1 and Planets(I).Good /= D_Null then
            --poszukaj dostarczajacej kostki w odpowidnim kolorze
            for J in Roll_Output'Range loop
               if Roll_Output(J).Outcome = Ship and then Is_The_Same_Color(Planets(I).Color, Roll_Output(J).Color) then
                  --ocen ile punktow sie nalezy
                  One_Delivery_Points := 2;
                  if Is_The_Same_Color(Planets(I).Color, Planets(I).Good) then
                     One_Delivery_Points := 3;
                  end if;
                  --dodaj do populacji kostke dobra z planety
                  for K in Population'Range loop
                     if Population(K) = D_Null then
                        Population(K) := Planets(I).Good;
                        Planets(I).Good := D_Null;
                        exit;
                     end if;
                  end loop;
                  --dodaj do populacji kostke dostawcy
                  for K in Population'Range loop
                     if Population(K) = D_Null then
                        Population(K) := Roll_Output(J).Color;
                        Roll_Output(J).Color := D_Null;
                        exit;
                     end if;
                  end loop;
                  --przyznaj graczowi punkty
                  Points := Points + One_Delivery_Points;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      --nastepnie dostarczamy pozostalymi kostkami
      for I in Planets'Range loop
         if Planets(I).Value > -1 and Planets(I).Good /= D_Null then
            for J in Roll_Output'Range loop
               if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Ship then
                  One_Delivery_Points := 1;
                  if Is_The_Same_Color(Planets(I).Color, Planets(I).Good) then
                     One_Delivery_Points := 2;
                  end if;
                  --dodaj do populacji kostke dobra z planety
                  for K in Population'Range loop
                     if Population(K) = D_Null then
                        Population(K) := Planets(I).Good;
                        Planets(I).Good := D_Null;
                        exit;
                     end if;
                  end loop;
                  --dodaj do populacji kostke dostawcy
                  for K in Population'Range loop
                     if Population(K) = D_Null then
                        Population(K) := Roll_Output(J).Color;
                        Roll_Output(J).Color := D_Null;
                        exit;
                     end if;
                  end loop;
                  --przyznaj graczowi punkty
                  Points := Points + One_Delivery_Points;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      --niewykorzystane kostki z akcja dostawy przenies do kubka
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null and Roll_Output(I).Outcome = Ship then
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Roll_Output(I).Color;
                  Roll_Output(I).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
   end Deliver;

   procedure Buy_Dices(Population: in out Dices; Cup: in out Dices; Money: in out Credits) is
      Num_Of_Dices_In_Pop : Integer := 0;
      Gen                 : Random_Index.Generator;
      Ind                 : Integer;
   begin
      --policz ile jest kosci w populacji
      for I in Population'Range loop
         if Population(I) /= D_Null then
            Num_Of_Dices_In_Pop := Num_Of_Dices_In_Pop + 1;
         end if;
      end loop;

      --jesli stac Cie na wszystkie kostki kup wszystkie
      if Integer(Money) >= Num_Of_Dices_In_Pop then
         for I in Population'Range loop
            if Population(I) /= D_Null then
               --dodaj kostke do kubka
               for J in Cup'Range loop
                  if Cup(J) = D_Null then
                     Cup(J) := Population(I);
                     Population(I) := D_Null;
                     Money := Money - 1;
                     exit;
                  end if;
               end loop;
            end if;
         end loop;
      --jesli nie, wybierz losowe kosci w liczbie rownej Money
      else
         Random_Index.Reset(Gen);
         for I in 1..Integer(Money) loop
            --wylosuj Indeks pod ktorym znajduje sie kostka
            Ind := Random_Index.Random(Gen) mod 15;
            while Population(Ind) = D_Null loop
               Ind := Random_Index.Random(Gen) mod 15;
            end loop;
            --przenies kostke z populacji do kubka
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Population(Ind);
                  Population(Ind) := D_Null;
                  --i zaplac za nia
                  Money := Money - 1;
                  exit;
               end if;
            end loop;
         end loop;
      end if;

      --zgodnie z zasadami, jesli po kupieniu kosci zostanie 0 kredytow, nalezy przyznac jeden kredyt
      if Money = 0 then
         Money := 1;
      end if;

   end Buy_Dices;

   procedure Unused_Dices_To_Cup(Roll_Output: in out Dice_Array; Cup: in out Dices) is
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null then
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Roll_Output(I).Color;
                  Roll_Output(I).Color := D_Null;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
   end Unused_Dices_To_Cup;

   function Activated_To_String(Activated_Actions: Activated) return Unbounded_String is
      Result: Unbounded_String := To_Unbounded_String("");
   begin
      if Activated_Actions(1) then
         Result := Result & "Explore; ";
      end if;
      if Activated_Actions(2) then
         Result := Result & "Settle; ";
      end if;
      if Activated_Actions(3) then
         Result := Result & "Produce; ";
      end if;
      if Activated_Actions(4) then
         Result := Result & "Ship;";
      end if;
      return Result;
   end Activated_To_String;

   function Points_Total(Planets: in Planet_Array; Points: Integer) return Integer is
      Result : Integer := Points;
   begin
      for I in Planets'Range loop
         if Planets(I).Value > -1 then
            Result := Result + Planets(I).Value;
         end if;
      end loop;
      return Result;
   end Points_Total;

begin
   -- implementacja kafelków planet
   Initial_Planets(0) := (To_Unbounded_String("Alpha Centuri"), P_Brown, 1, D_Null, D_Null, Brown, 0);
   Initial_Planets(1) := (To_Unbounded_String("Stara ziemia"), P_Gray, 3, Purple, D_null, D_Null, 0);
   Initial_Planets(2) := (To_Unbounded_String("Zaginiona ziemska kolonia"), P_Blue, 2, D_Null, D_Null, Blue, 0);
   Initial_Planets(3) := (To_Unbounded_String("Umierajaca planeta"), P_Gray, 0, D_Null, D_Null, D_Null, 8);
   Initial_Planets(4) := (To_Unbounded_String("Uszkodzona fabryka obcych"), P_Yellow, 1, Yellow, D_Null, D_Null, 0);
   Initial_Planets(5) := (To_Unbounded_String("Starozytna rasa"), P_Green, 0, D_Null, D_Null, Green, 0);
   Initial_Planets(6) := (To_Unbounded_String("Kolonia seperatystow"), P_Gray, 2, D_Null, Red, D_Null, 0);
   Initial_Planets(7) := (To_Unbounded_String("Planeta pielgrzymek"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Initial_Planets(8) := (To_Unbounded_String("Stacja obslugi tunelu"), P_Brown, 3, D_Null, Brown, D_Null, 0);
   Initial_Planets(9) := (To_Unbounded_String("Planeta Generycznie wsp..."), P_Gray, 2, D_Null, Green, D_Null, 0);
   Initial_Planets(10) := (To_Unbounded_String("Obudzona baza obcych"), P_Yellow, 3, Red, D_Null, D_Null, 0);
   Initial_Planets(11) := (To_Unbounded_String("Ostatni Gnarssz"), P_Green, 0, Green, D_Null, D_Null, 0);
   Initial_Planets(12) := (To_Unbounded_String("Ukryta forteca"), P_Gray, 2, Red, D_Null, D_Null, 0);
   Initial_Planets(13) := (To_Unbounded_String("Kamien z Rosetty"), P_Gray, 1, Yellow, D_Null, D_Null, 0);
   Initial_Planets(14) := (To_Unbounded_String("Kosmiczne centrum handlowe"), P_Blue, 0, D_Null, Blue, D_Null, 0);
   Initial_Planets(15) := (To_Unbounded_String("Planeta meteor"), P_Brown, 1, Brown, D_Null, D_Null, 0);

   Planet_Sack(0) := (To_Unbounded_String("Centrala instytutu"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(1) := (To_Unbounded_String("Odlegla planeta"), P_Green, 4, D_Null, Green, D_Null, 1);
   Planet_Sack(2) := (To_Unbounded_String("Piata kolumna"), P_Gray, 1, D_Null, Red, D_Null, 0);
   Planet_Sack(3) := (To_Unbounded_String("Nowa winlandia"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(4) := (To_Unbounded_String("Planeta ze zlozami przypraw"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(5) := (To_Unbounded_String("Masowy eksport"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Planet_Sack(6) := (To_Unbounded_String("Brama kosmiczna"), P_Gray, 3, Purple, D_Null, D_Null, 0);
   Planet_Sack(7) := (To_Unbounded_String("Planeta handlowa"), P_Gray, 3, Purple, D_Null, D_Null, 0);
   Planet_Sack(8) := (To_Unbounded_String("Krzemowa planeta"), P_Brown, 4, D_Null, D_Null, Brown, 1);
   Planet_Sack(9) := (To_Unbounded_String("Arka wymarlej rasy"), P_Green, 5, D_Null, D_Null, Green, 1);
   Planet_Sack(10) := (To_Unbounded_String("Galaktyczny osrodek spa"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Planet_Sack(11) := (To_Unbounded_String("Terraformowana planeta"), P_Gray, 5, Purple, D_Null, D_Null, 2);
   Planet_Sack(12) := (To_Unbounded_String("Zbiegle roboty"), P_Brown, 2, D_Null, Red, D_Null, 0);
   Planet_Sack(13) := (To_Unbounded_String("Nadzorcy wspom. Genet."), P_Green, 3, D_Null, Green, D_Null, 0);
   Planet_Sack(14) := (To_Unbounded_String("Rafineria paliwa"), P_Brown, 3, D_Null, D_Null, Brown, 0);
   Planet_Sack(15) := (To_Unbounded_String("Galaktyczna stacja paliw"), P_Brown, 3, D_Null, D_Null, Brown, 0);
   Planet_Sack(16) := (To_Unbounded_String("Planeta arsenal"), P_Brown, 4, D_Null, D_Null, Brown, 1);
   Planet_Sack(17) := (To_Unbounded_String("Planeta turystyczna"), P_Gray, 4, Purple, D_Null, D_Null, 1);
   Planet_Sack(18) := (To_Unbounded_String("Opuszczona baza obcych"), P_Yellow, 4, D_Null, D_Null, Yellow, 0);
   Planet_Sack(19) := (To_Unbounded_String("Mglawica planetarna"), P_Brown, 3, D_Null, D_Null, Brown, 0);
   Planet_Sack(20) := (To_Unbounded_String("Straznicy obcych"), P_Yellow, 6, D_Null, Yellow, D_Null, 3);
   Planet_Sack(21) := (To_Unbounded_String("P. o wysokiej grawitacji"), P_Gray, 1, D_Null, Red, D_Null, 0);
   Planet_Sack(22) := (To_Unbounded_String("Kryjowka kosmicznych nomadow"), P_Blue, 1, Blue, D_Null, D_Null, 0);
   Planet_Sack(23) := (To_Unbounded_String("Centrum transportowe"), P_Gray, 4, Purple, D_Null, D_Null, 1);
   Planet_Sack(24) := (To_Unbounded_String("Zaginiona flota"), P_Yellow, 6, D_Null, Yellow, D_Null, 3);
   Planet_Sack(25) := (To_Unbounded_String("Opuszczona biblioteka obcych"), P_Yellow, 6, D_Null, D_Null, Yellow,  2);
   Planet_Sack(26) := (To_Unbounded_String("Opuszczona kolonia obcych"), P_Yellow, 5, D_Null, D_Null, Yellow, 1);
   Planet_Sack(27) := (To_Unbounded_String("Zautomatyzowany zwiadowca obcych"), P_Yellow, 4, D_Null, Yellow, D_Null, 1);
   Planet_Sack(28) := (To_Unbounded_String("Planeta bogata w surowce"), P_Brown, 2, D_Null, Brown, D_Null, 0);
   Planet_Sack(29) := (To_Unbounded_String("Swiadome roboty"), P_Gray, 2, D_Null, Red, D_Null, 0);
   Planet_Sack(30) := (To_Unbounded_String("Strefa wystepowania komet"), P_Brown, 3, D_Null, D_Null, Brown, 0);
   Planet_Sack(31) := (To_Unbounded_String("Centrum informacyjne"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Planet_Sack(32) := (To_Unbounded_String("Autorskie gatunki S.I."), P_Green, 5, D_Null, D_Null, Green, 1);
   Planet_Sack(33) := (To_Unbounded_String("Planeta gornicza"), P_Brown, 3, D_Null, D_Null, Brown, 0);
   Planet_Sack(34) := (To_Unbounded_String("Diamentowa planeta"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(35) := (To_Unbounded_String("Kolonia artystow"), P_Blue, 1, Blue, D_Null, D_Null, 0);
   Planet_Sack(36) := (To_Unbounded_String("Kosmiczne symbionty S.A."), P_Green, 4, D_Null, Green, D_Null, 1);
   Planet_Sack(37) := (To_Unbounded_String("Port kosmiczny"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(38) := (To_Unbounded_String("Planeta plag"), P_Green, 3, D_Null, Green, D_Null, 0);
   Planet_Sack(39) := (To_Unbounded_String("Neosurvivalowcy"), P_Blue, 1, Blue, D_Null, D_Null, 0);
   Planet_Sack(40) := (To_Unbounded_String("Zlosliwe formy zycia"), P_Green, 4, D_Null, D_Null, Green, 0);
   Planet_Sack(41) := (To_Unbounded_String("Zaginiony okręt obcych"), P_Yellow, 5, D_Null, Yellow, D_Null, 2);
   Planet_Sack(42) := (To_Unbounded_String("Bogata planeta"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Planet_Sack(43) := (To_Unbounded_String("Odosobniona planeta"), P_Blue, 1, Blue, D_Null, D_Null, 0);
   Planet_Sack(44) := (To_Unbounded_String("Planeta dzungla"), P_Green, 4, D_Null, D_Null, Green, 0);
   Planet_Sack(45) := (To_Unbounded_String("Pas asteroid"), P_Brown, 2, D_Null, Brown, D_Null, 0);
   Planet_Sack(46) := (To_Unbounded_String("Radioaktywna planeta"), P_Brown, 2, D_Null, Brown, D_Null, 0);
   Planet_Sack(47) := (To_Unbounded_String("Planeta banitow"), P_Gray, 2, D_Null, Red, D_Null, 0);

end Player_Operations;
