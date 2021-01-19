with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

package Player_Operations is

   -- typy
   type Activated is array (1 .. 4) of Boolean; -- tablica z aktywowanymi przez Playerów akcjami (indeksy 1 - 4)
   type Credits is new Integer;
   type Dice_Color is (White, Red, Purple, Blue, Brown, Green, Yellow, D_Null);
   type Planet_Color is (P_Gray, P_Blue, P_Brown, P_Green, P_Yellow);
   type Action is (Exp, Sett, Prod, Ship, Joker);
   type Dice_Side is new Integer range 1..6;
   type Dice is record
      Color    : Dice_Color := D_Null;
      Outcome  : Action;
   end record;
   type Dices is array (Integer range <>) of Dice_Color;
   type Dice_Array is array (Integer range <>) of Dice;
   type Planet is record
      Name     : Unbounded_String;
      Color    : Planet_Color;
      Value    : Integer range -1..6 := -1; -- minus 1 to wartosc oznaczajaca brak planety
      Pop_add  : Dice_Color;
      Cup_add  : Dice_Color;
      Good     : Dice_Color;
      Money    : Credits := 0;
   end record;
   type Planet_Array is array (Integer range <>) of Planet;
   type Availability_Array is array (Integer range <>) of Boolean;
   
   procedure get_initial_planets(Planets: out Planet_Array; Planet_Queue: out Planet_Array;
                                 Money: in out Credits; Population: in out Dices; Cup: in out Dices);
   
   procedure collect_from_planet(A_Planet: in Planet; Money: in out Credits; Population: in out Dices; Cup: in out Dices);
   
   procedure roll_dices(Cup: in Dices; Roll_Output: out Dice_Array);
   
   function roll_dice(Color: in Dice_Color) return Action;
   
   function dices_to_string(Roll_Output: in Dice_Array) return Unbounded_String;

   function number_of_occurences(Roll_Output: in Dice_Array; An_Action: in Action) return Integer;
   
   function pick_action(Roll_Output: in Dice_Array) return Integer;
   
   procedure jokers_to_picked_action(Roll_Output: in out Dice_Array; PickedAction: in Integer);
   
   procedure explore(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Money: in out Credits; Population: in out Dices);
   
   procedure settle(Roll_Output: in out Dice_Array; Planet_Queue: in out Planet_Array; Planets: in out Planet_Array; Population: in out Dices;
                    Settlers: in out Dices; Cup: in out Dices; Tiles: in out Positive; Money: in out Credits);
   
   procedure unused_settlers_to_cup(Roll_Output: in out Dice_Array; Cup: in out Dices);
   
   procedure produce(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Cup: in out Dices);
   
   function is_the_same_color(Planet_Col: Planet_Color; Dice_Col: Dice_Color) return Boolean;
   
   procedure deliver(Roll_Output: in out Dice_Array; Planets: in out Planet_Array; Points: in out Integer;
                     Population: in out Dices; Cup: in out Dices);
  
   procedure buy_dices(Population: in out Dices; Cup: in out Dices; Money: in out Credits);
   
   procedure unused_dices_to_cup(Roll_Output: in out Dice_Array; Cup: in out Dices);
   
   function activated_to_string(ActivatedActions: Activated) return Unbounded_String;
   
   function points_total(Planets: in Planet_Array; Points: Integer) return Integer;
   
end Player_Operations;
