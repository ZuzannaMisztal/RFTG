with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

package Player_Operations is

   -- typy
   type Activated is array (1 .. 4) of Boolean; -- tablica z aktywowanymi przez Playerów akcjami (indeksy 1 - 4)
   type Credits is new Integer range 0..10;
   type Dice_Color is (White, Red, Purple, Blue, Brown, Green, Yellow, D_Null);
   type Planet_Color is (P_Gray, P_Blue, P_Brown, P_Green, P_Yellow);
   type Action is (Exp, Sett, Prod, Ship, Joker);
   type Dice_Side is new Integer range 1..6;
   type Dice is record
      Color    : Dice_Color;
      Outcome  : Action;
   end record;
   type Dices is array (Integer range <>) of Dice_Color;
   type Dice_Array is array (Integer range <>) of Dice;
   type Planet is record
      Name     : Unbounded_String;
      Color    : Planet_Color;
      Value    : Integer range 0..6;
      Pop_add  : Dice_Color;
      Cup_add  : Dice_Color;
      Good     : Dice_Color;
      Money    : Credits := 0;
   end record;
   type Planet_Array is array (Integer range <>) of Planet;
   type Availability_Array is array (Integer range <>) of Boolean;
   
   procedure get_initial_planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array);

end Player_Operations;
