with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;
with Player_Operations;
use Player_Operations;
use Ada.Text_IO;

-- narazie wszystko w jednym pliku :(
-- wersja uproszczona: jest 4 Playerów, 4 możliwe akcje, a każdy Player w turze losowo dostaje kafelek
-- jeżeli któryś Player otrzyma 3 kafelki, to gra się kończy (nie rozpatruję kto wygrał)
procedure Roll is

   protected Init_Semafor is
      entry Wait;
      procedure Signal;
   private
      Sem : Boolean := True;
   end Init_Semafor;

  -- nagłówki (semafory)
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

  -- ciała (semafory)
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
               ActivatedActions(PickedAction) := True;
               Ready := Ready + 1;

               if Finish and not F.Get then -- pierwsze zgłoszenie spełnienia warunku końca gry
                  Put_Line("G) Dostałem info o końcu gry.");
                  F.Wait; -- zajmij semafor z końcem gry (ważne dla Playerów)
               end if;

               if Ready = 4 then
                  Put_Line("G) Wszyscy gracze rzucili kośćmi i wybrali akcję.");
                  Ready := 0;
                  for I in 1 .. 4 loop
                     Put_Line("G) Pozwalam grać graczowi" & I'Img & ".");
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
      package Bool_Random is new Ada.Numerics.Discrete_Random(Boolean); -- narazie Player losowo dostaje kafelek
      use Bool_Random;

      -- w każdej rundzie gracz losowo dostaje kafelki (na początek ma 1), jak ma 3, to koniec gry
      Money            : Credits := 1;
      Tiles            : Natural := 0;
      --Roll_Output      : Dice_Array(0..9);
      Population       : Dices(0..9) := (0|1 => White, others => D_Null);
      Cup              : Dices(0..9) := (0|1|2 => White, others => D_Null);
      Planets          : Planet_Array(0..13);
      Planet_Queue     : Planet_Array(0..13);
      ActivatedActions : Activated := (False, False, False, False);
      Finished         : Boolean := False;
      G                : Generator;
      PickedAction     : Positive := P; -- narazie gracz po prostu zawsze wybiera akcję o swoim numerze (P)

   begin
      Reset(G);
      Put_Line("P" & P'Img & ") Rozpoczynam działanie.");

      Init_Semafor.Wait;
      get_initial_planets(Planets, Planet_Queue);
      Init_Semafor.Signal;

      Put_Line("P" & P'Img & ") Początkowe planety: " & Ada.Strings.Unbounded.To_String(Planets(0).Name) & Ada.Strings.Unbounded.To_String(Planets(1).Name));
      --Put_Line(Ada.Strings.Unbounded.To_String(Planets(0).Name));

      loop
         -- rzut kośćmi i wybór akcji
         Put_Line("P" & P'Img & ") Wyrzuciłem kości i wybrałem akcję.");

         Game.Sync(PickedAction, Finished); -- przekaż wybraną akcję
         Sems(P).Wait; -- zawieś się, aż Game nie zwróci ostatecznie aktywowanych akcji i nie pozwoli grać dalej

         if F.Get then -- warunek końca został aktywowany
            Put_Line("P" & P'Img & ") Koniec gry, do widzenia!.");
            exit;
         end if;

         Game.Get(ActivatedActions); -- pobierz akcje wybrane dla tej rundy

         -- wykonanie akcji
         Put_Line("P" & P'Img & ") Wiem, jakie są akcje. Wykonuję swoją turę.");

         if Random(G) then -- gracz losowo dostaje kafelek w każdej turze
            Tiles := Tiles + 1;
            Put_Line("P" & P'Img & ") Dostałem kafelek" & "(" & Tiles'Img & " / 3).");
         end if;

         if Tiles = 3 then -- jeżeli wybudowane już 3 kafelki, to zgłoś koniec
            Put_Line("P" & P'Img & ") Mam 3 kafelki i przy Sync() będę sygnalizował koniec.");
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
