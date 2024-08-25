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
  signal currentMult        : unsigned(15 downto 0); -- For multiplication result
  signal currentAdd         : unsigned(15 downto 0); -- For addition result
  signal result             : unsigned(16 downto 0); -- Result after addition of currentMult and currentAdd
  signal accumulator        : unsigned(31 downto 0); -- For the accumulation of the result from each state

begin
  -- Multiplexers for selecting appropriate 8-bit portions of A and B. This intentionally uses when else to avoid latches and to minimize the number of gates as opposed to
  -- creating gates for each state.
  -- Combinational logic for the currentA and currentB signals
  currentA <= A(7 downto 0) when state = Right or state = Inner else
              A(15 downto 8);
  currentB <= B(7 downto 0) when state = Right or state = Inner2 else
              B(15 downto 8);

  -- Perform 8x8 bit multiplication
  -- Combinational logic for the currentMult signal
  currentMult <= currentA * currentB;

  -- Select appropriate portion of accumulator for addition
  -- Combinational logic for the currentAdd signal
  -- During the Left state, we only care about the Third quadrant from the right side of the accumulator, which is (23 downto 16)
  -- in addition to the potential carry over from the previous step, which is (24).
  -- Otherwise for inner and inner2, we care about the middle 2 quadrants from the accumulator, which is (23 downto 8).
  -- This does not have to be 24 downto 8 because the result of Inner1 can only ever be 16 bits, and although the result of Inner2 CAN be 17 bits
  -- after it's been added with the currentMult, the accumulator will not have a carry over from the previous step, so currentAdd can never be 17 bits, only result.
  currentAdd <= accumulator(23 downto 8) when state /= Left else
                resize(accumulator(24 downto 16), 16);

  -- Result: add multResult to currentAdd (17-bit addition)
  -- If the state is Idle, the result is 0.
  -- Otherwise, the result is the addition of the currentAdd and currentMult, resized to 17 bits.
  -- This is done to ensure that the addition is done correctly and to cater for any carry overs.
  -- Although both currentAdd and currentMult are 16 bits, their sum can potentially be 17 bits.
  -- The 17-bit result allows for proper handling of the carry in subsequent operations.
  -- This also faciliates the synthesizer to create a MAC (Multiply and Accumulate) unit instead of a multiplier and adder during advanced synthesis.
  result <= resize(currentAdd, 17) + resize(currentMult, 17) when state /= Idle else
              (others => '0');

  -- Connect accumulator to output
  -- This is the final result of the multiplication. We are assigning the accumulator to the output.
  -- This allows us to remove the final stage, 'Done', as the accumulator will be assigned to the output at the end of the multiplication.
  -- and we can simply use the Complete signal to indicate when the multiplication is complete and the result is ready, also
  -- at the end of the multiplication.
  Q <= accumulator;

  -- State machine control

  StateMachine: process (Start, Reset, Clock)
  begin
    if (Reset = '1') then
      state <= Idle;
      Complete <= '0';
    elsif rising_edge(Clock) then
      case state is
        when Idle =>
          -- Reset the Complete signal to 0 when we are in Idle state.
          -- This is because the Complete signal is used to indicate when the multiplication is complete and the result is ready.
          -- We don't want to set it to 1 when we are in Idle state because at this point, the accumulator - and hence the output -
          -- does not represent the result of the multiplication as we have set the upper 16 bits to 0 at this point.
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
          -- Set the Complete signal to 1 when we are in the Left state.
          -- This is because the Left state is the final state of the multiplication and the result is ready.
          Complete <= '1';
      end case;
    end if;
  end process;

  -- Synchronous accumulator logic to store the results

  Synch: process (Reset, Clock)
  begin
    if Reset = '1' then
      accumulator <= (others => '0');
    elsif rising_edge(Clock) then
      case state is
        -- When we are in Idle or Right state, we are not accumulating the result of the multiplication.
        -- We are simply setting the accumulator to the result of the first partial product.
        -- Additionally we're able to fold these two states into one since nothing actually happens in Idle since the
        -- result is 0 at this point. Thus we can simply assign the result to the accumulator in the Idle state since
        -- the result is 0 at this point, and folding these two states into one reduces the number of states which
        -- in turn reduces the number of 32 bit multiplexers in our design.
        when Idle | Right =>
          accumulator(31 downto 0) <= resize(result(15 downto 0), 32); -- Store first partial product
        -- For Inner and Inner2 states, we accumulate the result differently:
        -- Inner: Ideally, we'd use accumulator(15 downto 8) for currentAdd.
        -- Inner2: We'd use accumulator(23 downto 8) for currentAdd.
        -- However, we use accumulator(23 downto 8) for both states to reuse the same adder circuit.
        -- This optimization works because:
        -- 1. In Inner, bits 23-16 of accumulator are always 0, so including them doesn't affect the result.
        -- 2. In Inner2, we need all bits 23-8, so this range is perfect.
        -- By using the same bit range for both states, we can use a single adder circuit,
        -- reducing hardware complexity and potentially improving performance.
        -- The result is then stored in accumulator(24 downto 8), allowing for any carry from the addition.
        when Inner | Inner2 =>
          accumulator(24 downto 8) <= result(16 downto 0); -- Store middle partial product
        -- In the Left state, we're handling the final partial product.
        -- We store the result in the upper 16 bits of the accumulator (31 downto 16).
        -- This completes the multiplication process, as the lower bits were already set in previous states.
        -- After this, the accumulator contains the full 32-bit result of the 16x16 multiplication.
        -- We also need to consider the carry over from the accumulator from the previous step.
        -- So when we're adding the existing bits in the accumulator, we would need to consider bits
        -- 24 downto 16 of the accumulator.
        when Left =>
          accumulator(31 downto 16) <= result(15 downto 0); -- Store final partial product
      end case;
    end if;
  end process;

end architecture;
