library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;

entity digital_clock is
  port (
    -- INPUTS PORTS

    clk_100: in std_logic;    
    -- the clock of 100MHz

    format : in std_logic;
    -- format button is pressed to swutch between hh:mm and mm:ss format.
        
    set1 : in std_logic;
    set2 : in std_logic;
    set3 : in std_logic;
    set4 : in std_logic;
    -- The four set buttons are used to change the 4 output digits of our display (left to right), there maximum value depends on the mode we are using
    -- If someone wants to reset the time to 00:00:00, then me must make mm:ss as 00:00 and then hh:mm as 00:00

    -- OUTPUT PORTS
    
    anode : out std_logic_vector(3 downto 0) ;
    -- The bit which is 1 will be shown during the refresh period.
    -- anode(3) = '1' means the rightmost digit on "4 digit 7 segment display" will be shown
    -- anode(0) = '1' means the leftmost digit on "4 digit 7 segment display" will be shown
    -- '0' means that anode is at low voltage and hence the voltage at cathode will be higher or equal. And thus that digit will be all dark.

    cathode : out std_logic_vector(7 downto 0) 
    -- The 6 downto 0 vector contians the 0 and 1, which will determine which LED should glow, if a bit is '0' then that LED glows up
    -- The signals are such that (6 downto 0) corrsponds GFEDCBA.  So if cathode(0) ='0' then the LED at A position will glow.  
    -- The decimal place we will decide using cathode(7). If cathode = '0' the the LED corresponding to that decimal will glow. 

  );
end digital_clock ; 

architecture functioning of digital_clock is

    -- A good explaination about these components is given where they have been defined

    component make_clk_1s
      port(
        clk_100 : in std_logic;
        clk_1s : out std_logic
      );
    end component;
    -- This returns a 1s clock signal from a 100MHz clock; 

    component dig_to_seg
      port(
        digit : in integer;
        segment : out std_logic_vector(6 downto 0)
      );
    end component;
    -- This takes a digit from 0 to 9 and returns the corresponding binary for 7 segment display in GFEDCBA fashion.

    component make_clk_1ms
      port(
        clk_100 : in std_logic;
        clk_1ms : out std_logic
      );
    end component;
    -- This returns a 1ms clock signal from a 100MHz clock; 

    component make_blink
      port(
        clk_100 : in std_logic;
        blink : out std_logic
      );
    end component;
    -- This returns a clock signal from a 100MHz clock;
    -- The output signal remains '1' for 0.8s and '0' for remaining 0.2 sec 

    signal mode : std_logic := '0';
    -- mode ='0' means hh:mm format and mode ='1' means mm:ss format.
    -- This signal toggles everytime there is a rising edge in format.

    signal digit1 : std_logic_vector(6 downto 0) ;
    signal digit2 : std_logic_vector(6 downto 0) ;
    signal digit3 : std_logic_vector(6 downto 0) ;
    signal digit4 : std_logic_vector(6 downto 0) ;
    -- The digit_i contains info about the ith digit to be displayed on the "4 digit 7 segment display".
    -- The 6 downto 0 vector contians the binary which will determine which LEDs of the 7 segment dispplay willl glow.
    -- '0' means it will glow and '1' means it will not glow, because 0 means low voltage and thus current will pass from anode to cathode and thus it will glow. 

    signal clk_1s : std_logic;
    -- this will be our 1 sec clock

    signal clk_1ms : std_logic;
    -- this will be our 1ms clock

    signal blink : std_logic:='0';
    -- This signal remains '1' for 0.8s and '0' for remaining 0.2 sec 
    -- So that the decimal flashes for 0.2 sec.

    signal cnt : integer :=0;
    -- this will determine which anode will be at high voltage.
    -- cnt =0 means leftmost digit

    signal hour : integer := 0 ;
    signal minute : integer :=0 ;
    signal second : integer :=0 ;
    -- these will denote our hour, minute and seconds, that are going to be displayed on the 4 digit 7 segment display
    -- They will be converted to a binary, that is going to be shown on 7 segment display

    signal d1 : integer :=0 ;
    signal d2 : integer :=0 ;
    signal d3 : integer :=0 ;
    signal d4 : integer :=0 ;
    -- these contain the digits we are going to display
    -- d1 denotes the integer form of leftmost digit and d4 denotes the integer form of rightmost digit.
    -- They are in the range 0 to 9.

 
  begin

    -- We will make the 1s clock
    create_1s_clock : make_clk_1s port map ( clk_100 => clk_100 , clk_1s => clk_1s );

    -- We will make the 1ms clock
    create_1ms_clock : make_clk_1ms port map ( clk_100 => clk_100 , clk_1ms => clk_1ms );

    -- We will make the blink signal
    create_blink : make_blink port map ( clk_100 => clk_100 , blink => blink );

    process( format ) begin
      if (rising_edge(format)) then   -- whenever the format switch is pressed, we want to change the mode of display on screen.
          mode <= not mode;           -- Mode changes to opposite sign. 
      end if ; 
    end process;

    process (clk_1s,mode,set1,set2,set3,set4) begin

    -- Changing the value of hours, minutes and seconds using the set buttons

      -- When we are changing in the hh:mm format 
      if (mode='0') then

        -- Dealing with hour
        if (rising_edge(set1)) then   -- we want to increase the leftmost digit on digital clock
          if (hour>=20) then
            hour <= hour -20;         -- because 22 on pressing set1 should change to 02
          elsif (hour>=14) then
            hour <= hour -10;         -- because 14 on pressing set1 should change to 04 (not 24)
          else
            hour <= hour +10;         -- because 11 should change to 21, 06 should change to 16
          end if;
        end if ;
        if (rising_edge(set2)) then   -- we want to increase the second leftmost digit.
          if (hour mod 10 = 9) then
            hour <= hour - 9;         -- because 19 should change to 10
          elsif (hour=23) then
            hour <= hour -3;          -- because 23 should change to 20
          else
            hour <= hour +1;          -- because 22 should change to 23, 07 should change to 08
          end if;       
        end if ;

        -- Dealing with minutes
        if (rising_edge(set3)) then   -- increasing the second rightmost digit
          if (minute >=50) then
            minute <= minute - 50;    -- because 56 should change to 06
          else
            minute <= minute +10;     -- in normal case, like 17 should change to 26;
          end if;
        end if;
        if (rising_edge(set4)) then   -- increasing the rightmost digit
          if (minute mod 10=9) then   
            minute <= minute-9;       -- because 59 should change to 50
          else
            minute <= minute + 1;     -- normally should increase by 1, like 45 should change to 46.
          end if;
        end if;

      -- When we are changing the mm:ss format ie mode ='1';
      else

        -- Dealing with minute
        if (rising_edge(set1)) then
          if (minute >=50) then
            minute <= minute - 50;
          else
            minute <= minute +10;
          end if;
        end if;
        if (rising_edge(set2)) then
          if (minute mod 10=9) then
            minute <= minute-9;
          else
            minute <= minute + 1;
          end if;
        end if;

        -- Dealing with seconds
        if (rising_edge(set3)) then
          if ( second >=50) then
            second <= second - 50;
          else
            second <= second +10;
          end if;
        end if;
        if (rising_edge(set4)) then
          if (second mod 10=9) then
            second <= second-9;
          else
            second <= second + 1;
          end if;
        end if;

      end if;

      -- Changing the hour, minutes and second with every rising edge of the 1s clock signal
      -- this is done when we are not giving any change digit command, else there will be a clash between signal assignments  
      if ( set1='0' and set2='0' and set3='0' and set4='0'  and rising_edge(clk_1s) ) then
        second <= second + 1;  
      if (second>=60) then      -- 60 seconds have completed and thus time to increase minute 
        minute <= minute + 1;
        second <= 0;            -- Because we don't show 60 on clock, it must reset to 00
      if (minute >=60) then
        hour <= hour + 1;       -- 60 minutes have completed and thus time to increase hour
        minute <= 0;            -- we don't show 60 minutes and thus we reset the value to 00
      if (hour>=24) then
        hour <= 0;              -- 24 hours have completed and it's a new bright day, also we don't show 24 made it 00
      end if;
      end if;
      end if ;        
      end if ;
    
    end process;
    -- By now we have obtained the value of hh:mm:ss
    -- Remaining task is to convert them in the 7 segment display form.

    process (mode,hour,minute,second) begin
    -- obtaining the digits to be displayed on digital clock,

      if (mode='0') then      -- when we want to show the hh:mm format
        d1 <= hour/10;        -- Leftmost digit on clock         
        d2 <= hour mod 10;
        d3 <= minute/10;
        d4 <= minute mod 10;  -- Rightmost digit on clock
      else                    -- When we want to show in mm:ss format
        d1 <= minute/10;      -- Leftmost digit on clock         
        d2 <= minute mod 10;
        d3 <= second/10;
        d4 <= second mod 10;  -- Rightmost digit on clock
      end if;

    end process;

    -- Converting the integer digits into their 7 segment display binary
    make_digit1 : dig_to_seg port map(digit => d1 , segment => digit1);
    make_digit2 : dig_to_seg port map(digit => d2 , segment => digit2);
    make_digit3 : dig_to_seg port map(digit => d3 , segment => digit3);
    make_digit4 : dig_to_seg port map(digit => d4 , segment => digit4);

    
    -- Implementing the refresh period part
    -- 4ms is the refresh period and hence 1ms is the digit period.
    process (clk_1ms, digit1, digit2, digit3, digit4, blink, mode) begin 

        if (rising_edge(clk_1ms)) then
          cnt <= cnt +1;      -- because after 1ms we need to change the digit we aree displaying 
          cnt <= cnt mod 4;   -- to make sure that it is always between 0,1,2,3
        end if ;

        if (cnt =0) then
          anode <= "0001";    --Leftmost digit will glow
          cathode(6 downto 0) <= digit1;
          cathode(7) <= '1';  -- This decimal point should never glow
        elsif (cnt =1) then
          anode <= "0010";    -- Second leftmost digit will glow
          cathode(6 downto 0) <= digit2;
          cathode(7) <= '0';  -- This decimal shoud always glow since (basically it works as the semicolon in "hh:mm" or "mm:ss") 
        elsif (cnt =2) then
          anode <= "0100";    -- Second rightmost digit should glow
          cathode(6 downto 0) <= digit3;
          cathode(7) <= '1';  -- this decimal should never glow
        elsif (cnt =3) then
          anode <= "1000";    -- Rigthmost digit must glow
          cathode(6 downto 0) <= digit4;
          if (mode = '0') then    -- If hh:mm format is used the the last decimal point will blink every second
            cathode(7) <= blink;  -- this will be '0' for nearly 0.2s and hence will glow during that time, off for next 0.8s
          else
            cathode(7) <= '1';    -- if mm:ss format is used then it will never glow
          end if;
        end if;

    end process;
  

end architecture;


-- Below are the entities which are used as components.

-- Making a 1Hz clock from a clock of frequency 100Mz
library ieee ;
use ieee.std_logic_1164.all ;

entity make_clk_1s is
  port (
    clk_100 : in std_logic;
    clk_1s : out std_logic  -- the output 1s clock
  ) ;
end make_clk_1s;

architecture functioning of make_clk_1s is
    signal counter : integer :=0;
begin
  process (clk_100) begin
    if (rising_edge(clk_100)) then
        counter <= counter + 1;
        if (counter>= 100000000) then -- because the 100MHz clock will have 10^8 periods (or rising edge) in 1 sec
            counter <= 0;
        end if ;
    end if;
  end process;
    -- Now for first half the counter clk_1s will remain 0 and for the remaining it will be 1
    clk_1s <= '0' when counter < 50000000 else '1'; 
    
end functioning ;

-- For converting a digit into it's 7 segment display
library ieee ;
use ieee.std_logic_1164.all ;

entity dig_to_seg is
  port (
    digit : in integer;                         -- the digit from 0 to 9 which we want to convert
    segment : out std_logic_vector(6 downto 0)  -- the binary for 7 segment display
  ) ;
end dig_to_seg;

architecture functioning of dig_to_seg is
begin  
  -- The bulb to be glowed must be assigned 0 (not 1 sicne we need to pass low voltage to actually glow it)
  process(digit)
    begin
      case(digit) is    -- Hard coding the binary values
      when 0 =>  segment <= "1000000";
      when 1 =>  segment <= "1111001";
      when 2 =>  segment <= "0100100";
      when 3 =>  segment <= "0110000";
      when 4 =>  segment <= "0011001"; 
      when 5 =>  segment <= "0010010";    
      when 6 =>  segment <= "0000010";
      when 7 =>  segment <= "1111000";   
      when 8 =>  segment <= "0000000";
      when others =>  segment <= "0010000"; -- 9
      end case;
  end process;

end functioning ;

-- Making a 1ms clock signal from a clock of frequency 100Mz
library ieee ;
use ieee.std_logic_1164.all ;

entity make_clk_1ms is
  port (
    clk_100 : in std_logic;
    clk_1ms : out std_logic
  ) ;
end make_clk_1ms;

architecture functioning of make_clk_1ms is
    signal counter : integer :=0;
begin
  process (clk_100) begin
    if (rising_edge(clk_100)) then
        counter <= counter + 1;
        if (counter>= 100000) then
            counter <= 0;
        end if ;
    end if;
  end process;
    -- Now for first half the counter clk_1ms will remain 0 and for the remaining it will be 1
    clk_1ms <= '0' when counter < 50000 else '1';
    
end functioning ;


-- Making a Blink clock from a clock of frequency 100Mz
library ieee ;
use ieee.std_logic_1164.all ;

entity make_blink is
  port (
    clk_100 : in std_logic;
    blink : out std_logic
  ) ;
end make_blink;

architecture functioning of make_blink is
    signal counter : integer :=0;
begin
  process (clk_100) begin
    if (rising_edge(clk_100)) then
        counter <= counter + 1;
        if (counter>= 100000000) then
            counter <= 0;
        end if ;
    end if;
  end process;
    -- Now for first 0.8s blink will remain 1 and for the remaining it will be 0
    blink <= '1' when counter < 80000000 else '0';
    
end functioning ;