library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Multiplier16x16_TB is
end Multiplier16x16_TB;

architecture Behavioral of Multiplier16x16_TB is
    signal Clock    : STD_LOGIC := '0';
    signal Reset    : STD_LOGIC := '0';
    signal A, B     : UNSIGNED(15 downto 0) := (others => '0');
    signal Q        : UNSIGNED(31 downto 0);
    signal Start    : STD_LOGIC := '0';
    signal Complete : STD_LOGIC;

    constant ClockPeriod : time := 10 ns;

    -- Updated test case record type
    type TestCase is record
        a, b: unsigned(15 downto 0);
        expected: unsigned(31 downto 0);
        description: string(1 to 50);
    end record;

    -- Updated array of test cases
    type TestCaseArray is array (natural range <>) of TestCase;
    constant testCases : TestCaseArray := (
        ("0000000000000000", "0000000000000000", "00000000000000000000000000000000", "Edge case: 0 * 0                                  "),
        ("0000000000000001", "0000000000000000", "00000000000000000000000000000000", "Edge case: 1 * 0                                  "),
        ("1111111111111111", "1111111111111111", "11111111111111100000000000000001", "Edge case: 65535 * 65535 (max * max)              "),
        ("0000000000000101", "0000000000000011", "00000000000000000000000000001111", "Simple case: 5 * 3                                "),
        ("0000000011111111", "0000000011111111", "00000000000000001111111000000001", "Larger number: 255 * 255                          "),
        ("1111111111111111", "0000000000000001", "00000000000000001111111111111111", "Boundary case: 65535 * 1 (max * 1)                "),
        ("1000000000000000", "0000000000000010", "00000000000000010000000000000000", "Boundary case: 32768 * 2 (middle * 2)             "),
		  ("1000000000000000", "1000000000000000", "01000000000000000000000000000000", "Carry over case (by 1 value): 32768 * 32768       "),
        ("0010011100001111", "0010011100001111", "00000101111101011001001011100001", "Carry over case: 9999 * 9999                      ")
    );

begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: entity work.Multiplier16x16
        port map (
            Clock    => Clock,
            Reset    => Reset,
            A        => A,
            B        => B,
            Q        => Q,
            Start    => Start,
            Complete => Complete
        );

    -- Clock process
    ClockProcess: process
    begin
        Clock <= '0';
        wait for ClockPeriod/2;
        Clock <= '1';
        wait for ClockPeriod/2;
    end process;

    -- Stimulus process
    StimulusProcess: process
    begin
        -- Reset
        Reset <= '1';
        wait for ClockPeriod*2;
        Reset <= '0';
        wait for ClockPeriod;

        -- Run test cases
        for i in testCases'range loop
            -- Set inputs
            A <= testCases(i).a;
            B <= testCases(i).b;

            -- Start multiplication
            Start <= '1';
            wait for ClockPeriod;
            Start <= '0';

            -- Wait for completion
            wait until Complete = '1';

            -- Check result
            assert Q = testCases(i).expected
                report "Test case " & integer'image(i) & " failed: " & testCases(i).description
                severity error;

            -- Wait before next test case
            wait for ClockPeriod*2;
        end loop;

        -- Add these lines after the loop
        report "Simulation finished" severity note;
        wait;
    end process;

end Behavioral;