----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/11/2023 08:05:33 AM
-- Design Name: 
-- Module Name: clock_div_pow2 - Behavioral
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
--   Copied VHDL code from tutorial at:
--     https://surf-vhdl.com/how-to-implement-clock-divider-vhdl/#Figure5
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clock_div_pow2 is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        o_clk_div2 : out std_logic;
        o_clk_div4 : out std_logic;
        o_clk_div8 : out std_logic;
        o_clk_div16 : out std_logic
    );
end clock_div_pow2;

architecture rtl of clock_div_pow2 is

    signal clk_divider : unsigned(3 downto 0);

begin
    p_clk_divider : process (i_rst, i_clk)
    begin
        if (i_rst = '0') then
            clk_divider <= (others => '0');
        elsif (rising_edge(i_clk)) then
            clk_divider <= clk_divider + 1;
        end if;
    end process p_clk_divider;

    o_clk_div2 <= clk_divider(0);
    o_clk_div4 <= clk_divider(1);
    o_clk_div8 <= clk_divider(2);
    o_clk_div16 <= clk_divider(3);

end rtl;
