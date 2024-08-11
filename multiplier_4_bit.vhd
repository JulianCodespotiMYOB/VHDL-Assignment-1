library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultiCycleMultiplier is
    Port ( Clock    : in  std_logic;
           Reset    : in  std_logic;
           A        : in  unsigned(15 downto 0);
           B        : in  unsigned(15 downto 0);
           Q        : out unsigned(31 downto 0);
           Start    : in  std_logic;
           Complete : out std_logic);
end MultiCycleMultiplier;

architecture Behavioral of MultiCycleMultiplier is
    type StateType is (Idle, Multiply1, Multiply2, Multiply3, Multiply4, Done);
    signal State : StateType;
    signal Result : unsigned(31 downto 0);
    
    -- 8-bit multiplier function (simulating hardware constraint)
    function multiply_8bit(a, b : unsigned(7 downto 0)) return unsigned is
    begin
        return a * b;
    end function;
begin
    process(Clock, Reset)
        variable aHigh, aLow, bHigh, bLow : unsigned(7 downto 0);
    begin
        if Reset = '1' then
            State <= Idle;
            Result <= (others => '0');
            Complete <= '0';
            Q <= (others => '0');
        elsif rising_edge(Clock) then
            aHigh := A(15 downto 8);
            aLow  := A(7 downto 0);
            bHigh := B(15 downto 8);
            bLow  := B(7 downto 0);
            case State is
                when Idle =>
                    if Start = '1' then
                        State <= Multiply1;
                        Complete <= '0';
                    end if;
                
                when Multiply1 =>
                    Result(15 downto 0) <= multiply_8bit(aLow, bLow);
                    State <= Multiply2;
                
                when Multiply2 =>
                    Result(23 downto 8) <= Result(15 downto 8) + multiply_8bit(aHigh, bLow);
                    State <= Multiply3;
                
                when Multiply3 =>
                    Result(23 downto 8) <= Result(23 downto 8) + multiply_8bit(aLow, bHigh);
                    State <= Multiply4;
                
                when Multiply4 =>
                    Result(31 downto 16) <= Result(31 downto 16) + multiply_8bit(aHigh, bHigh);
                    State <= Done;
                
                when Done =>
                    Q <= Result;
                    Complete <= '1';
                    State <= Idle;
            end case;
        end if;
    end process;
end Behavioral;