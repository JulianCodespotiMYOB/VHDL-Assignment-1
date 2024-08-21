library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity Multiplier16x16 is
  port (Clock    : in  STD_LOGIC;
        Reset    : in  STD_LOGIC;
        A        : in  UNSIGNED(15 downto 0);
        B        : in  UNSIGNED(15 downto 0);
        Q        : out UNSIGNED(31 downto 0);
        Start    : in  STD_LOGIC;
        Complete : out STD_LOGIC);
end entity;

architecture Behavioral of Multiplier16x16 is
  type StateType is (Idle, Mult1, Mult23, Mult4, Done);
  signal State        : StateType;
  signal accumulator  : UNSIGNED(31 downto 0);
  signal multA1, multA2 : unsigned(7 downto 0);
  signal multB1, multB2 : unsigned(7 downto 0);
begin

  -- Process for setting up multiplication operands
  process (State, A, B)
  begin
    case State is
      when Idle =>
        multA1 <= (others => 'U');
        multA2 <= (others => 'U');
        multB1 <= (others => 'U');
        multB2 <= (others => 'U');
      when Mult1 =>
        multA1 <= A(7 downto 0);
        multB1 <= B(7 downto 0);
		  multA2 <= (others => 'U');
		  multB2 <= (others => 'U');
      when Mult23 =>
        multA1 <= A(7 downto 0);
        multA2 <= A(15 downto 8);
        multB1 <= B(15 downto 8);
        multB2 <= B(7 downto 0);
      when Mult4 =>
        multA1 <= A(15 downto 8);
        multB1 <= B(15 downto 8);
		  multA2 <= (others => 'U');
		  multB2 <= (others => 'U');
      when Done =>
        multA1 <= (others => 'U');
        multA2 <= (others => 'U');
        multB1 <= (others => 'U');
        multB2 <= (others => 'U');
    end case;
  end process;

  -- Process for state changes
  process (Clock, Reset)
  begin
    if Reset = '1' then
      State <= Idle;
    elsif rising_edge(Clock) then
      case State is
        when Idle =>
          if Start = '1' then
            State <= Mult1;
          end if;
        when Mult1 =>
          State <= Mult23;
        when Mult23 =>
          State <= Mult4;
        when Mult4 =>
          State <= Done;
        when Done =>
          State <= Idle;
      end case;
    end if;
  end process;

  -- Process for combinational logic and outputs
  process (Clock, Reset)
  begin
    if Reset = '1' then
      Q <= (others => '0');
      Complete <= '0';
      accumulator <= (others => '0');
    elsif rising_edge(Clock) then
      case State is
        when Idle =>
          if Start = '1' then
            Complete <= '0';
            accumulator <= (others => '0');
          end if;
        when Mult1 =>
          accumulator(15 downto 0) <= (multA1 * multB1);
        when Mult23 =>
          accumulator(24 downto 8) <= accumulator(24 downto 8) + (multA1 * multB1) + (multA2 * multB2);
        when Mult4 =>
          accumulator(31 downto 16) <= accumulator(24 downto 16) + (multA1 * multB1);
        when Done =>
          Q <= accumulator;
          Complete <= '1';
      end case;
    end if;
  end process;

end architecture;