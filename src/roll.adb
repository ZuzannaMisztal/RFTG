with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with Player_Operations;
use Player_Operations;

procedure Roll is

    -- nagłówki (semafory)
   protected Sack_Semaphore is -- worek z planetami
      entry Wait;
      procedure Signal;
   private
      Sem : Boolean := True;
   end Sack_Semaphore;

   protected Init_Semaphore is -- początkowy semafor do inicjalizacji
      entry Wait;
      procedure Signal;
   private
      Sem : Boolean := True;
   end Init_Semaphore;

  -- każdy Player ma swój semafor S; dzięki niemu czeka ze swoją turą, aż Game ustali akcje na podstawie rzutów
  protected type S is
    entry Wait; -- to będzie wywoływać Player (zajmij zasób Sem)
    procedure Signal; -- to będzie wywoływać Game (zwolnij zasób Sem - pozwól Playerowi wykonać turę)
    private
      Sem : Boolean := True; -- początkowo żaden gracz nie może wykonać swojej tury
  end S;

  protected F is -- semafor kontrolujący, czy warunek końca gry został spełniony
    entry Wait; -- Game zajmuje zasób sygnalizując koniec
    function Get return Boolean; -- do sprawdzania przez Playerów czy już koniec
    private
      Sem : Boolean := False;
  end F;

  -- nagłówki (procesy)
  task Game is -- główne zadanie koordynujące grę
    entry Sync(P : in Positive; Picked_Action : in Positive; Finish : in Boolean; Points : in Integer); -- wejście do synchronizacji Playerów po rzutach koścmi
    entry Get(A : in out Activated); -- dla Playerów, żeby mogli odczytać, jakie akcje zostały aktywowane w tej turze
  end Game;

  task type Player(P : Positive); -- każdy Player ma swój identyfikator P (żeby wiadomo było, kto wygrał)

   -- ciała (semafory)
   protected body Sack_Semaphore is
      entry Wait when Sem is
      begin
         Sem := False;
      end Wait;

      procedure Signal is
      begin
         Sem := True;
      end Signal;

   end Sack_Semaphore;

   protected body Init_Semaphore is
      entry Wait when Sem is
      begin
         Sem := False;
      end Wait;

      procedure Signal is
      begin
         Sem := True;
      end Signal;
   end Init_Semaphore;

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
    Activated_Actions : Activated := (False, False, False, False); -- początkowo żadna akcja nie jest aktywowana
    Max_Points : Integer := 0; -- maksymalna liczba punktów (do ustalenia, kto wygrał)
    Points_Array : array (1 .. 4) of Integer; -- tablica przechowująca aktualną liczbę punktów graczy
    Won : Integer := 0; -- ilu graczy uzyskało maksymalny wynik (do remisu)

   begin
      Put_Line("G) Rozpoczynam działanie.");
      loop
         select
            -- Player daje znać, którą akcję aktywował i czy zebrał 3 Tiles
            accept Sync(P : in Positive; Picked_Action : in Positive; Finish : in Boolean; Points : in Integer) do
              
               Points_Array(P) := Points;

               if Ready = 0 then
                  Activated_Actions := (False, False, False, False);
               end if;

               Activated_Actions(Picked_Action) := True;
               Ready := Ready + 1;

               if Finish then -- pierwsze zgłoszenie spełnienia warunku końca gry
                  Put_Line("G) Dostałem info o końcu gry.");
                  Finished := True; -- zajmij semafor z końcem gry (ważne dla Playerów)
               end if;

               if Ready = 4 then
                  Put_Line("G) Nowa tura.");
                  Put_Line("G) Aktywowane akcje: " & To_String(Activated_To_String(Activated_Actions)) & ".");
                  Ready := 0;

                  if Finished then -- Game może zakończyć swoje działanie
                     F.Wait;
                  end if;
                    
                  for I in 1 .. 4 loop
                     Sems(I).Signal; -- pozwól graczom wykonać swoje tury
                  end loop;
               end if;
            end Sync;

            if F.Get then -- koniec gry, podaj zwycięzce/ów
               for I in Points_Array'Range loop -- ustal maximum
                  if Points_Array(I) > Max_Points then 
                    Max_Points := Points_Array(I);
                  end if;
               end loop;

               for I in Points_Array'Range loop -- sprawdź, kto ma maksymalną liczbę punktów
                  if Points_Array(I) = Max_Points then 
                    Put_Line("G) Wygrał gracz numer" & I'Img & ".");
                    Won := Won + 1;
                  end if;
               end loop;

               if Won > 1 then
                  Put_Line("G) A więc remis!");
               end if;

               Put_Line("G) Do widzenia!");
               exit;
            end if;
         or
            accept Get(A : in out Activated) do -- do zwracania Playerom ostatecznie aktywowanych akcji
               A := Activated_Actions;
            end Get;
         end select;
      end loop;
   end Game;

   task body Player is -- Playerzy o numerach 1 - 4

      Money             : Credits := 1;
      Tiles             : Positive := 2;
      Roll_Output       : Dice_Array(0 .. 14);
      Population        : Dices(0 .. 14) := (0|1 => White, others => D_Null);
      Cup               : Dices(0 .. 14) := (0|1|2|3 => White, others => D_Null);
      Planets           : Planet_Array(0 .. 11);
      Planet_Queue      : Planet_Array(0 .. 4);
      Settlers          : Dices(0 .. 5) := (others => D_Null);
      Points            : Integer := 0;
      Activated_Actions : Activated := (False, False, False, False);
      Finished          : Boolean := False;
      Picked_Action     : Positive;

   begin
      Put_Line("P" & P'Img & ") Rozpoczynam działanie.");

      Init_Semaphore.Wait;
      Get_Initial_Planets(Planets, Planet_Queue, Money, Population, Cup);
      Init_Semaphore.Signal;

      loop
         Roll_Dices(Cup, Roll_Output); -- rzut koścmi
         Picked_Action := Pick_Action(Roll_Output); -- wybór akcji
         Jokers_To_Picked_Action(Roll_Output, Picked_Action, P); -- wykorzystanie ewentualnych jokerów
          
         Game.Sync(P, Picked_Action, Finished, Points_Total(Planets, Points)); -- przekaż wybraną akcję
         Sems(P).Wait; -- zawieś się, aż Game nie zwróci ostatecznie aktywowanych akcji i nie pozwoli grać dalej

         if F.Get then -- warunek końca został aktywowany
            Put_Line("P" & P'Img & ") Koniec gry. Mam " & Points_Total(Planets, Points)'Img & " pkt, do widzenia!");
            exit;
         end if;

         Game.Get(Activated_Actions); -- pobierz akcje wybrane dla tej rundy

         -- wykonanie akcji
         if Activated_Actions(1) then -- eksploracja
            Sack_Semaphore.Wait;
            Put_Line("P" & P'Img & ") Eksploruję.");
            Explore(Roll_Output, Planet_Queue, Money, Population);
            Put_Line("P" & P'Img & ") Skończyłem eksplorację.");
            Sack_Semaphore.Signal;
         end if;

         if Activated_Actions(2) then -- kolonizacja
            Put_Line("P" & P'Img & ") Osiedlam. Miałem planet: " & Tiles'Img & ".");
            Settle(Roll_Output, Planet_Queue, Planets, Population, Settlers, Cup, Tiles, Money, P);
            Put_Line("P" & P'Img & ") Osiedliłem. Mam planet: " & Tiles'Img & ".");
         end if;

         if Activated_Actions(3) then -- produkcja
            Put_Line("P" & P'Img & ") Produkuję dobra.");
            Produce(Roll_Output, Planets, Cup);
            Put_Line("P" & P'Img & ") Skończyłem produkować.");
         end if;

         if Activated_Actions(4) then -- dostawa
            Put_Line("P" & P'Img & ") Dostarczam dobra");
            Deliver(Roll_Output, Planets, Points, Population, Cup);
            Put_Line("P" & P'Img & ") Skonczyłem dostarczać dobra.");
         end if;

         Unused_Dices_To_Cup(Roll_Output, Cup); -- odłożenie nieużywanych kości do kubeczka
         Put_Line("P" & P'Img & ") Przeniosłem nieużyte kości do kubka.");
         Buy_Dices(Population, Cup, Money); -- zakup kości do rzucania w następnej turze
         Put_Line("P" & P'Img & ") Kupiłem kości.");

         if Tiles >= 7 then -- jeżeli wybudowano 7 planet (Player ma 7 kafelków), to zgłoś koniec
            Put_Line("P" & P'Img & ") Mam  7 planet i przy Game.Sync() będę sygnalizował koniec.");
            Finished := True;
         end if;

      end loop;
   end Player;

-- utworzenie graczy
P1 : Player(1);
P2 : Player(2);
P3 : Player(3);
P4 : Player(4);

-- pętla główna
begin
   Put_Line("--- POCZĄTEK PROCEDURY GŁÓWNEJ ---");
   Put_Line("--- KONIEC PROCEDURY GŁÓWNEJ ---");
end Roll;
