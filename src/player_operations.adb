with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;
use Ada.Text_IO;

package body Player_Operations is
   
   package Roll is new Ada.Numerics.Discrete_Random(Dice_Side);
   package Random_Index is new Ada.Numerics.Discrete_Random(Integer);
   
   Planet_Sack: Planet_Array(0..47);
   Sack_Availability: Availability_Array(0..47) := (others => True);
   Initial_Planets: Planet_Array(0..15);
   Init_Availability: Availability_Array(0..15) := (others => True);
   
  
   procedure get_initial_planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array;
                                Money: in out Credits; Population: in out Dices; Cup: in out Dices) is
      gen: Random_Index.Generator;
      ind: Integer;
   begin
      Random_Index.Reset(gen);
      for I in 0..1 loop
         ind := Random_Index.Random(gen) mod 16;
         while Init_Availability(ind) = False loop
            ind := Random_Index.Random(gen) mod 16;
         end loop;
         Init_Availability(ind) := False;
         Planets(I) := Initial_Planets(ind);
         collect_from_planet(Initial_Planets(ind), Money, Population, Cup);
      end loop;
      
      ind := Random_Index.Random(gen) mod 48;
      while Sack_Availability(ind) = False loop
         ind := Random_Index.Random(gen) mod 48;
      end loop;
      Sack_Availability(ind) := False;
      Planet_Queue(0) := Planet_Sack(ind);
   end get_initial_planets;

   procedure collect_from_planet(A_Planet: in Planet; Money: in out Credits; Population: in out Dices; Cup: in out Dices) is
   begin
      Money := Money + A_Planet.Money; -- tutaj moze byc problem jak przekroczy 10
      
      if A_Planet.Pop_add /= D_Null then
         for I in Population'Range loop
            if Population(I) = D_Null then
               Population(I) := A_Planet.Pop_add;
               exit;
            end if;
         end loop;
      end if;
      
      if A_Planet.Cup_add /= D_Null then
         for I in Cup'Range loop
            if Cup(I) = D_Null then
               Cup(I) := A_Planet.Cup_add;
               exit;
            end if;
         end loop;
      end if;
   end collect_from_planet;
   
   procedure roll_dices(Cup: in Dices; Roll_Output: out Dice_Array) is
      Dice_Output: Dice;
   begin
      for I in Cup'Range loop
         if Cup(I) /= D_Null then
            Dice_Output.Color := Cup(I);
            Dice_Output.Outcome := roll_dice(Cup(I));
            Roll_Output(I) := Dice_Output;
         end if;
      end loop;
   end roll_dices;      
        
   function roll_dice(Color: in Dice_Color) return Action is
      result : Dice_Side;
      gen    : Roll.Generator;
   begin
      Roll.Reset(gen);
      result := Roll.Random(gen);
      if color = White then
         if result = 1 or result = 2 then return Exp;
         elsif result = 3 then return roll_dice(Color);
         elsif result = 4 then return Sett;
         elsif result = 5 then return Prod;
         else return Ship;
         end if;
      elsif color = Red then
         if result = 1 then return Exp;
         elsif result = 2 or result = 3 then return roll_dice(Color);
         elsif result = 4 or result = 5 then return Sett;
         else return Joker;
         end if;
      elsif color = Purple then
         if result = 1 then return Exp;
         elsif result = 2 then return roll_dice(Color);
         elsif result = 3 or result = 4 or result = 5 then return Ship;
         else return Joker;
         end if;
      elsif color = Blue then
         if result = 1 then return Exp;
         elsif result = 2 or result = 3 then return Prod;
         elsif result = 4 or result = 5 then return Ship;
         else return Joker;
         end if;
      elsif color = Brown then
         if result = 1 then return Exp;
         elsif result = 2 or result = 3 then return roll_dice(Color);
         elsif result = 4 then return Prod;
         elsif result = 5 then return Ship;
         else return Joker;
         end if;
      elsif color = Green then
         if result = 1 then return Exp;
         elsif result = 2 or result = 3 then return Sett;
         elsif result = 4 then return Prod;
         else return Joker;
         end if;
      else
         if result = 1 then return roll_dice(Color);
         elsif result = 2 then return Sett;
         elsif result = 3 then return Prod;
         else return Joker;
         end if;
      end if;
   end roll_dice;

   function dices_to_string(Roll_Output: in Dice_Array) return Unbounded_String is
      result: Unbounded_String := To_Unbounded_String("");
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null then
            result := result & Roll_Output(I).Color'Img & ": " & Roll_Output(I).Outcome'Img & "| ";
         end if;
      end loop;
      return result;
   end dices_to_string;
   
   function number_of_occurences(Roll_Output: in Dice_Array; An_Action: in Action) return Integer is
      result: Integer := 0;
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Color /= D_Null and Roll_Output(I).Outcome = An_Action then
            result := result + 1;
         end if;
      end loop;
      return result;
   end number_of_occurences;
   
   function pick_action(Roll_Output: in Dice_Array) return Integer is
      Exp_Num: Integer;
      Sett_Num: Integer;
      Prod_Num: Integer;
      Ship_Num: Integer;
   begin
      Exp_Num := number_of_occurences(Roll_Output, Exp);
      Sett_Num := number_of_occurences(Roll_Output, Sett);
      Prod_Num := number_of_occurences(Roll_Output, Prod);
      Ship_Num := number_of_occurences(Roll_Output, Ship);
      if Sett_Num >= Exp_Num and Sett_Num >= Prod_Num and Sett_Num >= Ship_Num then
         return 2;
      elsif Prod_Num >= Exp_Num and Prod_Num >= Ship_Num then
         return 3;
      elsif Ship_Num >= Exp_Num then
         return 4;
      else
         return 1;
      end if;
   end pick_action;
   
   procedure jokers_to_picked_action(Roll_Output: in out Dice_Array; PickedAction: in Integer) is
   begin
      for I in Roll_Output'Range loop
         if Roll_Output(I).Outcome = Joker then
            if PickedAction = 1 then
               Roll_Output(I).Outcome := Exp;
            elsif PickedAction = 2 then
               Roll_Output(I).Outcome := Sett;
            elsif PickedAction = 3 then
               Roll_Output(I).Outcome := Prod;
            else
               Roll_Output(I).Outcome := Ship;
            end if;
         end if;
      end loop;
   end jokers_to_picked_action;
   
   procedure explore(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Money: in out Credits; Population: in out Dices) is
      num          : Integer;
      times_stock  : Integer;
      times_scout  : Integer;
      gen          : Random_Index.Generator;
      ind          : Integer;
      ind_queue    : Integer := 0;
      
   begin
      num := number_of_occurences(Roll_Output, Exp);
      times_stock := num / 2;
      times_scout := num - times_stock;
      
      while ind_queue <= 4 and then Planet_Queue(ind_queue).Value > -1 loop
         ind_queue := ind_queue + 1;
      end loop;
      --Put_Line("Znalezlem pierwsze puste miejsce w planet_queue");
      
      --jesli planety nie zmieszcza sie w planet_queue przydziel pozostale kostki do magazynowania
      if times_scout > 5 - ind_queue then
         times_stock := times_stock + times_scout + ind_queue - 5;
         times_scout := 5 - ind_queue;
      end if;
      
      for I in 1..num loop
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
      
      for I in 1..times_stock loop
         Money := Money + 2;
      end loop;
      --Put_Line("Zmagazynowalem");
      
      for I in 1..times_scout loop
         ind := Random_Index.Random(gen) mod 48;
         while Sack_Availability(ind) = False loop
            ind := Random_Index.Random(gen) mod 48;
         end loop;
         --Put_Line("Wylosowalem planete " & I'Img & "/" & times_scout'Img);
         Sack_Availability(ind) := False;
         Planet_Queue(ind_queue) := Planet_Sack(ind);
         ind_queue := ind_queue + 1;
      end loop;
      --Put_Line("Zebralem nowe planety do planet_queue");
   end explore;

   procedure settle(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Planets: in out Planet_Array; Population: in out Dices;
                    Settlers: in out Dices; Cup: in out Dices; Tiles: in out Positive; Money: in out Credits; P: in Positive) is
      num                     : Integer;
      num_of_settlers_already : Integer := 0;
      num_needed              : Integer;
      new_planet_queue        : Planet_Array(0..4); 
   begin
      num := number_of_occurences(Roll_Output, Sett);
      for I in Settlers'Range loop
         if Settlers(I) /= D_Null then
            num_of_settlers_already := num_of_settlers_already + 1;
         end if;
      end loop;
      
      Put_Line("P" & P'Img & ") Number of settlers already = " & num_of_settlers_already'Img);
      while num + num_of_settlers_already >= Planet_Queue(0).Value loop
         if Planet_Queue(0).Value = -1 then --to oznacza, ze nie ma zadnych planet w kolejce
            unused_settlers_to_cup(Roll_Output, Cup);
            Put_Line("P" & P'Img & ") Nie ma planet w kolejce");
            exit;
         end if;
         num_needed := Planet_Queue(0).Value - num_of_settlers_already;
         --przenies settlers i odpowiednia liczbe kostek z roll_output do populacji
         if num_of_settlers_already > 0 then
            for I in Settlers'Range loop
               if Settlers(I) /= D_Null then
                  for J in Population'Range loop
                     if Population(J) = D_Null then
                        Population(J) := Settlers(I);
                        Settlers(I) := D_Null;
                        num_of_settlers_already := num_of_settlers_already - 1;
                        exit;
                     end if;
                  end loop;
               end if;
            end loop;
         end if;
         Put_Line("P" & P'Img & ") Przenioslem settlers do populacji");
         
         for I in 1..num_needed loop
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
         num := num - num_needed;
         Put_Line("P" & P'Img & ") Przenioslem odopowiednia liczbe kostek z akcja sett do populacji");
         --przenies planete z kolejki do zdobytych planet
         collect_from_planet(Planet_Queue(0), Money, Population, Cup);
         Planets(Tiles) := Planet_Queue(0);
         new_planet_queue(0..3) := Planet_Queue(1..4);
         Tiles := Tiles + 1;
         Planet_Queue := new_planet_queue;
         Put_Line("P" & P'Img & ") Osiedlilem planete");
      end loop;
      
      --przenies pozostale kostki z akcja sett do Settlers
      if Planet_Queue(0).Value > -1 then
         for I in 1..num loop
            for J in Roll_Output'Range loop
               if Roll_Output(J).Color /= D_Null and Roll_Output(J).Outcome = Sett then
                  Settlers(I-1) := Roll_Output(J).Color; 
                  Roll_Output(J).Color := D_Null;
                  exit;
               end if;
            end loop;
         end loop;
      end if;
      Put_Line("P" & P'Img & ") Przenioslem pozostale kostki do settlers");
   end settle;
   
   procedure unused_settlers_to_cup(Roll_Output: in out Dice_Array; Cup: in out Dices) is
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
   end unused_settlers_to_cup;
   
   procedure produce(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Cup: in out Dices) is
   begin
      --najpierw probujemy dopasowac do kazdej pustej planety odpowiedni kolor dobra
      for I in Planets'Range loop
         --jesli na planecie mozna wyprodukowac dobro
         if Planets(I).Color /= P_Gray and Planets(I).Value > -1 and Planets(I).Good = D_Null then
            --poszukaj produkujacej kostki w odpowiednim kolorze
            for J in Roll_Output'Range loop
               if Roll_Output(J).Outcome = Prod and then is_the_same_color(Planets(I).Color, Roll_Output(J).Color) then
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
   end produce;
   
   function is_the_same_color(Planet_Col: Planet_Color; Dice_Col: Dice_Color) return Boolean is
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
   end is_the_same_color;              
   
   procedure deliver(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Points: in out Integer;
                     Population: in out Dices; Cup: in out Dices) is
      one_delivery_points: Integer;
   begin
      --najpierw staramy sie dostarczyc kostka o kolorze zgodnym z kolorem planety
      for I in Planets'Range loop
         if Planets(I).Value > -1 and Planets(I).Good /= D_Null then
            --poszukaj dostarczajacej kostki w odpowidnim kolorze
            for J in Roll_Output'Range loop
               if Roll_Output(J).Outcome = Ship and then is_the_same_color(Planets(I).Color, Roll_Output(J).Color) then
                  --ocen ile punktow sie nalezy
                  one_delivery_points := 2;
                  if is_the_same_color(Planets(I).Color, Planets(I).Good) then
                     one_delivery_points := 3;
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
                  Points := Points + one_delivery_points;
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
                  one_delivery_points := 1;
                  if is_the_same_color(Planets(I).Color, Planets(I).Good) then
                     one_delivery_points := 2;
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
                  Points := Points + one_delivery_points;
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
   end deliver;
   
   procedure buy_dices(Population: in out Dices; Cup: in out Dices; Money: in out Credits) is
      num_of_dices_in_pop : Integer := 0;
      gen                 : Random_Index.Generator;
      ind                 : Integer;
   begin
      --policz ile jest kosci w populacji
      for I in Population'Range loop
         if Population(I) /= D_Null then
            num_of_dices_in_pop := num_of_dices_in_pop + 1;
         end if;
      end loop;
      
      --jesli stac Cie na wszystkie kostki kup wszystkie
      if Integer(Money) >= num_of_dices_in_pop then
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
         Random_Index.Reset(gen);
         for I in 1..Integer(Money) loop
            --wylosuj indeks pod ktorym znajduje sie kostka
            ind := Random_Index.Random(gen) mod 15;
            while Population(ind) = D_Null loop
               ind := Random_Index.Random(gen) mod 15;
            end loop;
            --przenies kostke z populacji do kubka
            for J in Cup'Range loop
               if Cup(J) = D_Null then
                  Cup(J) := Population(ind);
                  Population(ind) := D_Null;
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
  
   end buy_dices;
            
   procedure unused_dices_to_cup(Roll_Output: in out Dice_Array; Cup: in out Dices) is
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
   end unused_dices_to_cup;
   
   function activated_to_string(ActivatedActions: Activated) return Unbounded_String is
      result: Unbounded_String := To_Unbounded_String("");
   begin
      if ActivatedActions(1) then
         result := result & "Explore; ";
      end if;
      if ActivatedActions(2) then
         result := result & "Settle; ";
      end if;
      if ActivatedActions(3) then
         result := result & "Produce; ";
      end if;
      if ActivatedActions(4) then
         result := result & "Ship;";
      end if;
      return result;
   end activated_to_string;
   
   function points_total(Planets: in Planet_Array; Points: Integer) return Integer is
      result : Integer := Points;
   begin
      for I in Planets'Range loop
         if Planets(I).Value > -1 then
            result := result + Planets(I).Value;
         end if;
      end loop;
      return result;
   end points_total;
   
begin
   Initial_Planets(0) := (To_Unbounded_String("Alpha Centuri"), P_Brown, 1, D_Null, D_Null, Brown, 0);   
   Initial_Planets(1) := (To_Unbounded_String("Stara ziemia"), P_Gray, 3, Purple, D_null, D_Null, 0);
   Initial_Planets(2) := (To_Unbounded_String("Zaginiona ziemska kolonia"), P_Blue, 2, D_Null, D_Null, Blue, 0);
   Initial_Planets(3) := (To_Unbounded_String("Umierajaca planeta"), P_Gray, 0, D_Null, D_Null, D_Null, 8);
   Initial_Planets(4) := (To_Unbounded_String("Uszkodzona fabryka obcych"), P_Yellow, 1, Yellow, D_Null, D_Null, 0);
   Initial_Planets(5) := (To_Unbounded_String("Starozytna rasa"), P_Green, 0, D_Null, D_Null, Green, 0);
   Initial_Planets(6) := (To_Unbounded_String("Kolonia seperatystow"), P_Gray, 2, D_Null, Red, D_Null, 0);
   Initial_Planets(7) := (To_Unbounded_String("Planeta pielgrzymek"), P_Blue, 3, D_Null, D_Null, Blue, 0);
   Initial_Planets(8) := (To_Unbounded_String("Stacja obslugi tunelu"), P_Brown, 3, D_Null, Brown, D_Null, 0);
   Initial_Planets(9) := (To_Unbounded_String("Planeta generycznie wsp..."), P_Gray, 2, D_Null, Green, D_Null, 0);
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
   Planet_Sack(13) := (To_Unbounded_String("Nadzorcy wspom. genet."), P_Green, 3, D_Null, Green, D_Null, 0);
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
