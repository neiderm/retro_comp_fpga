----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2023 07:49:45 PM
-- Design Name: 
-- Module Name: soc_t80_top - Behavioral
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity soc_t80_top is
    Port ( clk : in STD_LOGIC;
          reset: in STD_LOGIC;
            sw : in STD_LOGIC_VECTOR(15 downto 0);
         O_JB0 : out STD_LOGIC;
         O_JC0 : out STD_LOGIC;
           led : out STD_LOGIC_VECTOR(15 downto 0));
end soc_t80_top;

architecture Behavioral of soc_t80_top is
    signal reset_l : STD_LOGIC;
    signal clk_vga : STD_LOGIC;
    signal clk_cpu : STD_LOGIC;
begin
    --------------------------------------------------
    -- drive test output pins to verify clock rates
    --------------------------------------------------
    O_JB0 <= clk_vga;
    O_JC0 <= clk_cpu;

    --------------------------------------------------
    -- invert the active high reset to active low 
    --------------------------------------------------
    reset_l <= not reset;

    --------------------------------------------------
    -- clocks
    --------------------------------------------------
    u_clocks : entity work.clock_div_pow2
        port map(
            i_rst       => reset_l,
            i_clk       => clk,
            o_clk_div2  => open,
            o_clk_div4  => clk_vga,
            o_clk_div8  => open,
            o_clk_div16 => clk_cpu
        );

    ledsproc : process (reset_l, sw)
    begin
        if (reset_l = '0') then
            led <= (others => '0');
        else
            led <= sw;
        end if;
    end process ledsproc;

end Behavioral;
