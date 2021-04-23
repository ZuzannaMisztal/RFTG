-- nagłówki funkcji i procedur Playerów (określenie tego, jak Playerzy wykonują swoje tury)

with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

package Player_Operations is

   -- typy
   type Activated is array (1 .. 4) of Boolean; -- tablica z aktywowanymi przez Playerów akcjami (indeksy 1 - 4)
   type Credits is new Integer;
   type Dice_Color is (White, Red, Purple, Blue, Brown, Green, Yellow, D_Null);
   type Planet_Color is (P_Gray, P_Blue, P_Brown, P_Green, P_Yellow);
   type Action is (Exp, Sett, Prod, Ship, Joker);
   type Dice_Side is new Integer range 1 .. 6;
   type Dice is record
      Color    : Dice_Color := D_Null;
      Outcome  : Action;
   end record;
   type Dices is array (Integer range <>) of Dice_Color;
   type Dice_Array is array (Integer range <>) of Dice;
   type Planet is record
      Name     : Unbounded_String;
      Color    : Planet_Color;
      Value    : Integer range -1 .. 6 := -1; -- minus 1 to wartosc oznaczajaca brak planety
      Pop_Add  : Dice_Color;
      Cup_Add  : Dice_Color;
      Good     : Dice_Color;
      Money    : Credits := 0;
   end record;
   type Planet_Array is array (Integer range <>) of Planet;
   type Availability_Array is array (Integer range <>) of Boolean;

   -- procedury i funkcje używane w czasie tur Playerów
   procedure Get_Initial_Planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array;
                                 Money: in out Credits; Population: in out Dices; Cup: in out Dices);

   procedure Collect_From_Planet(A_Planet: in Planet; Money: in out Credits; Population: in out Dices; Cup: in out Dices);

   procedure Roll_Dices(Cup: in Dices; Roll_Output: out Dice_Array);

   function Roll_Dice(Color: in Dice_Color) return Action;

   function Dices_To_String(Roll_Output: in Dice_Array) return Unbounded_String;

   function Number_Of_Occurences(Roll_Output: in Dice_Array; An_Action: in Action) return Integer;

   function Pick_Action(Roll_Output: in Dice_Array) return Integer;

   procedure Jokers_To_Picked_Action(Roll_Output: in out Dice_Array; Picked_Action: in Integer; P : in Positive);

   procedure Explore(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Money: in out Credits;
                                                                                    Population: in out Dices);

   procedure Settle(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Planets: in out Planet_Array;
                        Population: in out Dices; Settlers: in out Dices; Cup: in out Dices; Tiles: in out Positive;
                                                                             Money: in out Credits; P: in Positive);

   procedure Unused_Settlers_To_Cup(Roll_Output: in out Dice_Array; Cup: in out Dices);

   procedure Produce(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Cup: in out Dices);

   function Is_The_Same_Color(Planet_Col: Planet_Color; Dice_Col: Dice_Color) return Boolean;

   procedure Deliver(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Points: in out Integer;
                     Population: in out Dices; Cup: in out Dices);

   procedure Buy_Dices(Population: in out Dices; Cup: in out Dices; Money: in out Credits);

   procedure Unused_Dices_To_Cup(Roll_Output: in out Dice_Array; Cup: in out Dices);

   function Activated_To_String(Activated_Actions: Activated) return Unbounded_String;

   function Points_Total(Planets: in Planet_Array; Points: Integer) return Integer;

end Player_Operations;
