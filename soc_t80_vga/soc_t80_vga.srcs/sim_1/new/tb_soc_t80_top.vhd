----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2023 06:13:01 PM
-- Design Name: 
-- Module Name: tb_soc_t80_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 10.2.2023 22:49:59 UTC

library ieee;
use ieee.std_logic_1164.all;

entity tb_soc_t80_top is
end tb_soc_t80_top;

architecture tb of tb_soc_t80_top is

    component soc_t80_top
        port (clk   : in std_logic;
              reset : in std_logic;
              sw    : in std_logic_vector (15 downto 0);
              led   : out std_logic_vector (15 downto 0));
    end component;

    signal clk   : std_logic := '0'; -- clock must be in known state for sim to start!
    signal reset : std_logic;
     -- initial condition of sw must be in known state!
    signal sw    : std_logic_vector (15 downto 0) := "0000101001011010"; --  (others => '0');
    signal led   : std_logic_vector (15 downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    -- Reset and clock
    clk <= NOT clk AFTER 5ns;
    reset <= '1', '0' AFTER 10ns;

    dut : soc_t80_top
    port map (clk   => clk,
              reset => reset,
              sw    => sw,
              led   => led);

--    -- Clock generation
--    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

--    -- EDIT: Check that clk is really your main clock signal
--    clk <= TbClock;

--    stimuli : process
--    begin
--        -- EDIT Adapt initialization as needed
--        sw <= (others => '0');

--        -- Reset generation
--        -- EDIT: Check that reset is really your reset signal
--        reset <= '1';
--        wait for 100 ns;
--        reset <= '0';
--        wait for 100 ns;

--        -- EDIT Add stimuli here
--        wait for 100 * TbPeriod;

--        -- Stop the clock and hence terminate the simulation
--        TbSimEnded <= '1';
--        wait;
--    end process;

end tb;

---- Configuration block below is required by some simulators. Usually no need to edit.

--configuration cfg_tb_soc_t80_top of tb_soc_t80_top is
--    for tb
--    end for;
--end cfg_tb_soc_t80_top;
