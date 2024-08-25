library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library std;
  use std.textio.all;

entity testbench is
end entity;

architecture behavior of testbench is

  -- ports of UUT
  signal Clock    : STD_LOGIC             := '0';
  signal A        : unsigned(15 downto 0) := (others => '0');
  signal B        : unsigned(15 downto 0) := (others => '0');
  signal Q        : unsigned(31 downto 0) := (others => '0');
  signal Start    : STD_LOGIC             := '0';
  signal Complete : STD_LOGIC             := '0';
  signal reset    : STD_LOGIC             := '0';
  --  File to log results to
  file logFile : TEXT;

  constant clockHigh   : TIME := 5 ns;
  constant clockLow    : TIME := 5 ns;
  constant clockPeriod : TIME := clockHigh + clockLow;

  signal simComplete : BOOLEAN := false;

begin

  --****************************************************
  -- Clock Generator
  --
  ClockGen: process

  begin
    while not simComplete loop
      clock <= '0';
      wait for clockHigh;
      clock <= '1';
      wait for clockLow;
    end loop;

    wait; -- stop process looping
  end process;

  --****************************************************
  -- Stimulus Generator
  --

  Stimulus: process
    --*******************************************************
    -- Write a message to the logfile & transcript
    --
    --  message => string to write
    --
    procedure writeMsg(message : STRING
                      ) is

      variable assertMsgBuffer : STRING(1 to 4096); -- string for assert message
      variable writeMsgBuffer  : line;              -- buffer for write messages

    begin
      write(writeMsgBuffer, message);
      assertMsgBuffer(writeMsgBuffer.all'RANGE) := writeMsgBuffer.all;
      writeline(logFile, writeMsgBuffer);
      deallocate(writeMsgBuffer);
      report assertMsgBuffer severity note;
    end procedure;

    procedure doMultiply(stimulusA : unsigned(15 downto 0);
                         stimulusB : unsigned(15 downto 0)
                        ) is

      variable assertMsgBuffer : STRING(1 to 4096); -- string for assert message
      variable writeMsgBuffer  : line;              -- buffer for write messages
      variable expectedQ       : unsigned(31 downto 0);
      variable actualQ         : unsigned(31 downto 0);

    begin

      write(writeMsgBuffer, STRING'("A = "), left);
      write(writeMsgBuffer, to_integer(stimulusA));
      write(writeMsgBuffer, STRING'(", B = "), left);
      write(writeMsgBuffer, to_integer(stimulusB));

      --  Fill out with your test sequence for the multiplier
      A <= stimulusA;
      B <= stimulusB;

      Start <= '1';
      wait until rising_edge(Clock);
      Start <= '0';

      wait until complete = '1';
      wait until rising_edge(Clock);

      expectedQ := stimulusA * stimulusB;
      actualQ := Q;

      -- Check result
      assert actualQ = expectedQ
        report "Multiplication error: expected " & INTEGER'image(to_integer(expectedQ)) & ", but got " & INTEGER'image(to_integer(actualQ))
        severity error;

      write(writeMsgBuffer, STRING'(", Q = "), left);
      write(writeMsgBuffer, to_integer(actualQ));
      if actualQ = expectedQ then
        write(writeMsgBuffer, STRING'(" (Correct)"));
      else
        write(writeMsgBuffer, STRING'(" (Incorrect, expected "));
        write(writeMsgBuffer, to_integer(expectedQ));
        write(writeMsgBuffer, STRING'(")"));
      end if;

      assertMsgBuffer(writeMsgBuffer.all'RANGE) := writeMsgBuffer.all;
      writeline(logFile, writeMsgBuffer);
      deallocate(writeMsgBuffer);
      report assertMsgBuffer severity note;
    end procedure;

    variable openStatus : file_open_status;

  begin -- Stimulus

    file_open(openStatus, logFile, "results.txt", WRITE_MODE);

    writeMsg(STRING'("Simulation starting."));

    -- initial reset
    A <= (others => '0');
    B <= (others => '0');
    Start <= '0';

    reset <= '1';
    wait for 10 ns;
    reset <= '0';
    wait until falling_edge(Clock);
    -- Test cases - modify as needed.
    doMultiply("0000000000000000", "0000000000000000"); -- 0 * 0
    doMultiply("0000000000000000", "1111111111111111"); -- 0 * 65535
    doMultiply("0000000000000001", "0000000000000000"); -- 1 * 0
    doMultiply("0000000000000001", "0000000000000001"); -- 1 * 1
    doMultiply("0000000000000001", "1111111111111111"); -- 1 * 65535
    doMultiply("1111111111111111", "0000000000000001"); -- 65535 * 1
    doMultiply("0000000100000000", "0000000011111111"); -- 256 * 255
    doMultiply("0000000011111111", "0000000011111111"); -- 255 * 255
    doMultiply("1111111111111111", "1111111100000011"); -- 65535 * 65283
    doMultiply("1111111111111111", "1111111100000010"); -- 65535 * 65282
    doMultiply("1000000000000000", "1000000000000000"); -- 32768 * 32768
    doMultiply("1111111111111111", "1111111111111111"); -- 65535 * 65535

    wait for 20 ns;

    writeMsg(STRING'("Simulation completed."));

    file_close(logFile);

    simComplete <= true; -- stop clock & simulation

    wait;

  end process;

  uut: entity work.MultiplierMultiCycle
    port map (
      reset    => reset,
      Clock    => Clock,
      A        => A,
      B        => B,
      Q        => Q,
      Start    => Start,
      Complete => Complete
    );

end architecture;
