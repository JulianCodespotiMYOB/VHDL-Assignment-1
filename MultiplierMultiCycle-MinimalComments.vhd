library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity MultiplierMultiCycle is
  port (
    Clock    : in  STD_LOGIC;
    Reset    : in  STD_LOGIC;
    A        : in  unsigned(15 downto 0);
    B        : in  unsigned(15 downto 0);
    Q        : out unsigned(31 downto 0);
    Start    : in  STD_LOGIC;
    Complete : out STD_LOGIC
  );
end entity;

architecture Behavioral of MultiplierMultiCycle is
  type TheStates is (Idle, Right, Inner, Inner2, Left);
  signal state              : TheStates;
  signal currentA, currentB : unsigned(7 downto 0);
  signal currentMult        : unsigned(15 downto 0); -- 8x8 multiplication result
  signal currentAdd         : unsigned(15 downto 0);
  signal accumulator        : unsigned(31 downto 0);
  signal result             : unsigned(16 downto 0); -- 17-bit for carry handling
begin
  -- Efficient multiplexing for 8-bit operands
  currentA <= A(7 downto 0) when state = Right or state = Inner else
              A(15 downto 8);
  currentB <= B(7 downto 0) when state = Right or state = Inner2 else
              B(15 downto 8);

  -- Single 8x8 multiplier reused across states
  currentMult <= currentA * currentB;

  -- Accumulator selection with carry consideration
  currentAdd <= accumulator(23 downto 8) when state /= Left else
                resize(accumulator(24 downto 16), 16);

  -- 17-bit addition for potential carry in Inner2 state
  result <= resize(currentAdd, 17) + resize(currentMult, 17) when state /= Idle else
            (others => '0');

  -- Direct accumulator to output connection
  Q <= accumulator;

  -- Optimized state machine with folded states
  StateMachine: process (Start, Reset, Clock)
  begin
    if (Reset = '1') then
      state <= Idle;
      Complete <= '0';
    elsif rising_edge(Clock) then
      case state is
        when Idle =>
          Complete <= '0';
          if (Start = '1') then
            state <= Right;
          end if;
        when Right =>
          state <= Inner;
        when Inner =>
          state <= Inner2;
        when Inner2 =>
          state <= Left;
        when Left =>
          state <= Idle;
          Complete <= '1';
      end case;
    end if;
  end process;

  -- Accumulator logic with state-specific bit management
  Synch: process (Reset, Clock)
  begin
    if Reset = '1' then
      accumulator <= (others => '0');
    elsif rising_edge(Clock) then
      case state is
        when Idle | Right =>
          accumulator(31 downto 0) <= resize(result(15 downto 0), 32); -- First partial product
        when Inner | Inner2 =>
          accumulator(24 downto 8) <= result(16 downto 0); -- Middle products with carry
        when Left =>
          accumulator(31 downto 16) <= result(15 downto 0); -- Final partial product
      end case;
    end if;
  end process;
end architecture;