-- Git account : Nguyen Hoang Nguyen
-- Author      : Nguyen Hoang Nguyen
-- Student ID  : CE200306
-- Purpose     : Testbench Lab04 - bounce hai chieu, glitch ngan, 2 chu ky, reset (T0-T6)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab04_tb is
end entity lab04_tb;

architecture sim of lab04_tb is
  constant CLK_PERIOD : time    := 20 ns;
  constant N_SIM      : positive := 5;
  constant SETTLE     : time    := (N_SIM + 8) * CLK_PERIOD;

  signal clk          : STD_LOGIC := '0';
  signal i_sw_raw     : STD_LOGIC := '1';  
  signal i_rst        : STD_LOGIC := '0'; 
  signal o_led        : STD_LOGIC;
  signal o_dbg_stable : STD_LOGIC;
  signal done         : STD_LOGIC := '0';
begin
 
  clk_proc : process
  begin
    while done = '0' loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  DUT : entity work.lab04
    generic map (STABLE_CYCLES => N_SIM)
    port map (
      clk          => clk,
      i_sw_raw     => i_sw_raw,
      i_rst        => i_rst,
      o_led        => o_led,
      o_dbg_stable => o_dbg_stable
    );

  stimulus : process
   
    procedure drive(p : STD_LOGIC; dur : time) is
    begin
      i_sw_raw <= not p;
      wait for dur;
    end procedure;

   
    procedure bounce(new_p : STD_LOGIC) is
    begin
      drive(new_p,     CLK_PERIOD);
      drive(not new_p, CLK_PERIOD);
      drive(new_p,     CLK_PERIOD);
      drive(not new_p, CLK_PERIOD);
    end procedure;
  begin
    
    i_rst <= '0'; drive('0', 4 * CLK_PERIOD);
    i_rst <= '1'; wait for 3 * CLK_PERIOD;
    assert o_led = '0'        report "T0 FAILED: LED must reset to 0"    severity error;
    assert o_dbg_stable = '0' report "T0 FAILED: stable must reset to 0" severity error;

    
    drive('1', 3 * CLK_PERIOD);
    drive('0', SETTLE);
    assert o_dbg_stable = '0' report "T1a FAILED: short press glitch accepted" severity error;
    assert o_led = '0'        report "T1a FAILED: glitch toggled LED"          severity error;

    
    bounce('1');
    drive('1', SETTLE);
    assert o_dbg_stable = '1' report "T1 FAILED: press was not accepted" severity error;
    assert o_led = '0'        report "T1 FAILED: press must not toggle LED" severity error;

    
    wait for 20 * CLK_PERIOD;
    assert o_dbg_stable = '1' report "T2 FAILED: stable changed while held" severity error;
    assert o_led = '0'        report "T2 FAILED: LED changed while pressed"  severity error;

    
    bounce('0');
    drive('0', SETTLE);
    assert o_dbg_stable = '0' report "T3 FAILED: release was not accepted"     severity error;
    assert o_led = '1'        report "T3 FAILED: first release must toggle ON" severity error;

   
    wait for 20 * CLK_PERIOD;
    assert o_led = '1' report "T4 FAILED: LED changed without new release" severity error;

   
    bounce('1');
    drive('1', SETTLE);
    assert o_led = '1' report "T5 FAILED: press caused a toggle" severity error;
    bounce('0');
    drive('0', SETTLE);
    assert o_led = '0' report "T5 FAILED: second release must toggle OFF" severity error;

   
    drive('1', SETTLE);
    drive('0', SETTLE);
    assert o_led = '1' report "T6 FAILED: setup toggle before reset" severity error;
    i_rst <= '0'; wait for 2 * CLK_PERIOD;
    i_rst <= '1'; wait for 4 * CLK_PERIOD;
    assert o_led = '0'        report "T6 FAILED: reset did not clear LED"    severity error;
    assert o_dbg_stable = '0' report "T6 FAILED: reset did not clear stable" severity error;
    wait for SETTLE;
    assert o_led = '0' report "T6 FAILED: false event after reset" severity error;

    report "LAB04: ALL SELF-CHECKING TESTS PASSED" severity note;
    done <= '1';
    wait;
  end process;
end architecture sim;
