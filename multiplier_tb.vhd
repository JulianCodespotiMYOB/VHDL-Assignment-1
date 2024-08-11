library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultiCycleMultiplier_TB is
end MultiCycleMultiplier_TB;

architecture Behavioral of MultiCycleMultiplier_TB is
    -- Component Declaration
    component MultiCycleMultiplier
        Port ( Clock    : in  std_logic;
               Reset    : in  std_logic;
               A        : in  unsigned(15 downto 0);
               B        : in  unsigned(15 downto 0);
               Q        : out unsigned(31 downto 0);
               Start    : in  std_logic;
               Complete : out std_logic);
    end component;

    -- Signal Declarations
    signal Clock    : std_logic := '0';
    signal Reset    : std_logic := '0';
    signal A, B     : unsigned(15 downto 0) := (others => '0');
    signal Q        : unsigned(31 downto 0);
    signal Start    : std_logic := '0';
    signal Complete : std_logic;

    -- Clock period definition
    constant Clock_period : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: MultiCycleMultiplier port map (
        Clock => Clock,
        Reset => Reset,
        A => A,
        B => B,
        Q => Q,
        Start => Start,
        Complete => Complete
    );

    -- Clock process
    Clock_process: process
    begin
        Clock <= '0';
        wait for Clock_period/2;
        Clock <= '1';
        wait for Clock_period/2;
    end process;

    -- Stimulus process
    Stimulus_process: process
    begin
        -- Initialize
        Reset <= '1';
        wait for Clock_period*2;
        Reset <= '0';
        wait for Clock_period;

        -- Test case 1: 5 * 3
        A <= to_unsigned(5, 16);
        B <= to_unsigned(3, 16);
        Start <= '1';
        wait for Clock_period;
        Start <= '0';
        wait until Complete = '1';
        assert Q = 15 report "Test case 1 failed!" severity error;
        wait for Clock_period*2;

        -- Test case 2: 255 * 255
        A <= to_unsigned(255, 16);
        B <= to_unsigned(255, 16);
        Start <= '1';
        wait for Clock_period;
        Start <= '0';
        wait until Complete = '1';
        assert Q = 65025 report "Test case 2 failed!" severity error;
        wait for Clock_period*2;

        -- Test case 3: 1000 * 2000
        A <= to_unsigned(1000, 16);
        B <= to_unsigned(2000, 16);
        Start <= '1';
        wait for Clock_period;
        Start <= '0';
        wait until Complete = '1';
        assert Q = 2000000 report "Test case 3 failed!" severity error;
        wait for Clock_period*2;

        -- End simulation
        report "Simulation finished successfully";
        wait;
    end process;

end Behavioral;