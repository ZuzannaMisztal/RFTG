with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
with Player_Operations;
use Player_Operations;
use Ada.Text_IO;

procedure Roll is

    -- nagłówki (semafory)
   protected Sack_Semafor is
      entry Wait;
      procedure Signal;
   private
      Sem : Boolean := True;
   end Sack_Semafor;

   protected Init_Semafor is
      entry Wait;
      procedure Signal;
   private
      Sem : Boolean := True;
   end Init_Semafor;

  -- każdy Player ma swój semafor S; dzięki niemu czeka ze swoją turą, aż Game ustali akcje na podstawie rzutów
  protected type S is
    entry Wait; -- to będzie wywoływać Player (zajmij zasób Sem)
    procedure Signal; -- to będzie wywoływać Game (zwolnij zasób Sem - pozwól Playerowi wykonać turę)
    private
      Sem : Boolean := True; -- początkowo żaden gracz nie może wykonać swojej tury
  end S;

  protected F is -- semafor kontrolujący, czy warunek końca gry został spełniony (Player zdobył 3 Tiles)
    entry Wait; -- Game zajmuje zasób sygnalizując koniec
    function Get return Boolean; -- do sprawdzania czy już koniec
    private
      Sem : Boolean := False;
  end F;

  -- nagłówki (procesy)
  task Game is -- główne zadanie koordynujące grę
    entry Sync(PickedAction : in Positive; Finish : in Boolean); -- wejście do synchronizacji Playerów po rzutach koścmi
    entry Get(A : in out Activated); -- dla Playerów, żeby mogli odczytać, jakie akcje zostały aktywowane w tej turze
  end Game;

  task type Player(P : Positive); -- każdy Player ma swój identyfikator P (żeby wiadomo było, kto wygrał)

   -- ciała (semafory)
   protected body Sack_Semafor is
      entry Wait when Sem is
      begin
         Sem := False;
      end Wait;
      procedure Signal is
      begin
         Sem := True;
      end Signal;
   end Sack_Semafor;

   protected body Init_Semafor is
      entry Wait when Sem is
      begin
         Sem := False;
      end Wait;
      procedure Signal is
      begin
         Sem := True;
      end Signal;
   end Init_Semafor;

  protected body S is
    entry Wait when Sem = False is -- zajęcie zasobu przez Playera
    begin
      Sem := True;
    end Wait;

    procedure Signal is -- zwolnienie zasobu przez Game
    begin
        Sem := False;
    end Signal;
  end S;

  protected body F is
    entry Wait when Sem = False is -- zajęcie zasobu przez Game, warunek końca gry został spełniony
    begin
      Sem := True;
    end Wait;

    function Get return Boolean is
    begin
      return Sem;
    end Get;
  end F;

  -- tablica semaforów graczy (każdy gracz ma swój)
  Sems : array (1 .. 4) of S;

   -- ciała (procesy)
   task body Game is
    Ready : Integer := 0; -- l. gotowych Playerów (tych którzy zgłosili wybraną akcję i czekają na aktywację)
    Finished : Boolean := False; -- zmienna pomocnicza - czy zadanie Game może się zakończyć
    ActivatedActions : Activated := (False, False, False, False); -- początkowo żadna akcja nie jest aktywowana

   begin
      Put_Line("G) Rozpoczynam działanie.");
      loop
         select
            -- Player daje znać, którą akcję aktywował i czy zebrał 3 Tiles
            accept Sync(PickedAction : in Positive; Finish : in Boolean) do
               Put_Line("G) Dostałem info od gracza (wybrana akcja: " & PickedAction'Img & ").");
               if Ready = 0 then
                  ActivatedActions := (False, False, False, False);
               end if;
               ActivatedActions(PickedAction) := True;
               Ready := Ready + 1;

               if Finish and not F.Get then -- pierwsze zgłoszenie spełnienia warunku końca gry
                  Put_Line("G) Dostałem info o końcu gry.");
                  F.Wait; -- zajmij semafor z końcem gry (ważne dla Playerów)
               end if;

               if Ready = 4 then
                  --Put_Line("G) Wszyscy gracze rzucili kośćmi i wybrali akcję.");
                  Put_Line("Aktywowane akcje: " & To_String(activated_to_string(ActivatedActions)));
                  Ready := 0;
                  for I in 1 .. 4 loop
                     --Put_Line("G) Pozwalam grać graczowi" & I'Img & ".");
                     Sems(I).Signal; -- pozwól graczom wykonać swoje tury
                  end loop;

                  if F.Get then -- Game może zakończyć swoje działanie
                     Finished := True;
                  end if;
               end if;
            end Sync;

            if Finished then
               Put_Line("G) Ogłaszam kto wygrał, do widzenia!");
               exit;
            end if;
         or
            accept Get(A : in out Activated) do -- do zwraca Playerom ostatecznie aktywowanych akcji
               A := ActivatedActions;
            end Get;
         end select;
      end loop;
   end Game;

   task body Player is -- Playerzy o numerach 1 - 4

      Money            : Credits := 1;
      Tiles            : Positive := 2;
      Roll_Output      : Dice_Array(0..14);
      Population       : Dices(0..14) := (0|1 => White, others => D_Null);
      Cup              : Dices(0..14) := (0|1|2|3 => White, others => D_Null);
      Planets          : Planet_Array(0..11);
      Planet_Queue     : Planet_Array(0..4);
      Settlers         : Dices(0..5) := (others => D_Null);
      Points           : Integer := 0;
      ActivatedActions : Activated := (False, False, False, False);
      Finished         : Boolean := False;
      PickedAction     : Positive := P; -- narazie gracz po prostu zawsze wybiera akcję o swoim numerze (P)

   begin
      Put_Line("P" & P'Img & ") Rozpoczynam działanie.");

      Init_Semafor.Wait;
      get_initial_planets(Planets, Planet_Queue, Money, Population, Cup);
      Init_Semafor.Signal;

      Put_Line("P" & P'Img & ") Początkowe planety: " & To_String(Planets(0).Name) & "; " & To_String(Planets(1).Name));

      loop
         -- rzut kośćmi i wybór akcji
         roll_dices(Cup, Roll_Output);
         Put_Line("P" & P'Img & ") Rzucilem kosci.");
         PickedAction := pick_action(Roll_Output);
         Put_Line("P" & P'Img & ") " & To_String(dices_to_string(Roll_Output)) & " Picked = " & PickedAction'Img);

         jokers_to_picked_action(Roll_Output, PickedAction);

         Game.Sync(PickedAction, Finished); -- przekaż wybraną akcję
         Sems(P).Wait; -- zawieś się, aż Game nie zwróci ostatecznie aktywowanych akcji i nie pozwoli grać dalej

         if F.Get then -- warunek końca został aktywowany
            Put_Line("P" & P'Img & ") Koniec gry. Mam " & points_total(Planets, Points)'Img & " punktów");
            exit;
         end if;

         Game.Get(ActivatedActions); -- pobierz akcje wybrane dla tej rundy

         -- wykonanie akcji

         if ActivatedActions(1) then
            Sack_Semafor.Wait;
            Put_Line("P" & P'Img & ") Eksploruje.");
            explore(Roll_Output, Planet_Queue, Money, Population);
            Put_Line("P" & P'Img & ") Skonczylem eksploracje.");
            Sack_Semafor.Signal;
         end if;

         if ActivatedActions(2) then
            Put_Line("P" & P'Img & ") Osiedlam. Mialem planet: " & Tiles'Img);
            settle(Roll_Output, Planet_Queue, Planets, Population, Settlers, Cup, Tiles, Money);
            Put_Line("P" & P'Img & ") Osiedlilem. Mam planet: " & Tiles'Img);
         end if;

         if ActivatedActions(3) then
            Put_Line("P" & P'Img & ") Produkuje dobra");
            produce(Roll_Output, Planets, Cup);
            Put_Line("P" & P'Img & ") Skonczylem produkowac");
         end if;

         if ActivatedActions(4) then
            Put_Line("P" & P'Img & ") Dostarczam dobra");
            deliver(Roll_Output, Planets, Points, Population, Cup);
            Put_Line("P" & P'Img & ") Skonczylem dostarczac dobra");
         end if;

         unused_dices_to_cup(Roll_Output, Cup);
         Put_Line("P" & P'Img & ") Przenioslem nieuzyte kosci do kubka");
         buy_dices(Population, Cup, Money);
         Put_Line("P" & P'Img & ") Kupilem kosci");

         if Tiles >= 7 then -- jeżeli wybudowano 7 planet, to zgłoś koniec
            Put_Line("P" & P'Img & ") Mam  7 planet i przy Sync() będę sygnalizował koniec.");
            Finished := True;
         end if;

      end loop;
   end Player;

-- utworzenie graczy
P1 : Player(1);
P2 : Player(2);
P3 : Player(3);
P4 : Player(4);
begin
   Put_Line("POCZĄTEK PROCEDURY GŁÓWNEJ.");
   Put_Line("KONIEC PROCEDURY GŁÓWNEJ.");
end Roll;
