with Ada.Numerics.Discrete_Random;

package body Player_Operations is
   
   package Roll is new Ada.Numerics.Discrete_Random(Dice_Side);
   package Random_Index is new Ada.Numerics.Discrete_Random(Integer);
   
   Planet_Sack: Planet_Array(0..5);
   Sack_Availability: Availability_Array(0..5) := (others => True);
   Initial_Planets: Planet_Array(0..6);
   Init_Availability: Availability_Array(0..6) := (others => True);
   
--   procedure  get_initial_planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array;
--                                  Players_Money: in out Credits; Population: in out Dices; Cup: in out Dices) is
   procedure get_initial_planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array) is
      gen: Random_Index.Generator;
      ind: Integer;
   begin
      Random_Index.Reset(gen);
      for I in 0..1 loop
         ind := Random_Index.Random(gen) mod 7;
         while Init_Availability(ind) = False loop
            ind := Random_Index.Random(gen) mod 7;
         end loop;
         Init_Availability(ind) := False;
         Planets(I) := Initial_Planets(ind);
      end loop;
      
      ind := Random_Index.Random(gen) mod 6;
      while Sack_Availability(ind) = False loop
         ind := Random_Index.Random(gen) mod 6;
      end loop;
      Sack_Availability(ind) := False;
      Planet_Queue(0) := Planet_Sack(ind);
   end get_initial_planets;

begin
   Initial_Planets(0) := (To_Unbounded_String("Alpha Centuri"), P_Brown, 1, D_Null, D_Null, Brown, 0);   
   Initial_Planets(1) := (To_Unbounded_String("Stara ziemia"), P_Gray, 3, Purple, D_null, D_Null, 0);
   Initial_Planets(2) := (To_Unbounded_String("Zaginiona ziemska kolonia"), P_Blue, 2, D_Null, D_Null, Blue, 0);
   Initial_Planets(3) := (To_Unbounded_String("Umierajaca planeta"), P_Gray, 0, D_Null, D_Null, D_Null, 8);
   Initial_Planets(4) := (To_Unbounded_String("Uszkodzona fabryka obcych"), P_Yellow, 1, Yellow, D_Null, D_Null, 0);
   Initial_Planets(5) := (To_Unbounded_String("Starozytna rasa"), P_Green, 0, D_Null, D_Null, Green, 0);
   Initial_Planets(6) := (To_Unbounded_String("Kolonia seperatystow"), P_Gray, 2, D_Null, Red, D_Null, 0);

   Planet_Sack(0) := (To_Unbounded_String("Centrala instytutu"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(1) := (To_Unbounded_String("Odlegla planeta"), P_Green, 4, D_Null, Green, D_Null, 1);
   Planet_Sack(2) := (To_Unbounded_String("Piata kolumna"), P_Gray, 1, D_Null, Red, D_Null, 0);
   Planet_Sack(3) := (To_Unbounded_String("Nowa winlandia"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(4) := (To_Unbounded_String("Planeta ze zlozami przypraw"), P_Blue, 2, D_Null, Blue, D_Null, 0);
   Planet_Sack(5) := (To_Unbounded_String("Masowy eksport"), P_Blue, 3, D_Null, D_Null, Blue, 0);
end Player_Operations;
