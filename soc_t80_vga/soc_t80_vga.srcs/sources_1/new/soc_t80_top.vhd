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
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity soc_t80_top is
    port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        sw : in STD_LOGIC_VECTOR(15 downto 0);

        vgaRed : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync : out STD_LOGIC;
        Vsync : out STD_LOGIC;

        O_JB0 : out STD_LOGIC;
        O_JC0 : out STD_LOGIC;
        led : out STD_LOGIC_VECTOR(15 downto 0));
end soc_t80_top;

architecture Behavioral of soc_t80_top is
    signal reset_l : STD_LOGIC;
    signal clk_vga : STD_LOGIC;
    signal clk_cpu : STD_LOGIC;

    signal video_on : STD_LOGIC;
    signal pixel_x, pixel_y : INTEGER;
    signal vgss        : STD_LOGIC_VECTOR(1 downto 0); -- video generator source select to vgen mux

    signal rgb_out_reg : STD_LOGIC_VECTOR(11 downto 0); --register the RGB output signals 
    signal rgb_reg_0   : STD_LOGIC_VECTOR(11 downto 0);
    signal rgb_reg_1   : STD_LOGIC_VECTOR(11 downto 0);
    signal rgb_reg_2   : STD_LOGIC_VECTOR(11 downto 0);

    signal rgb_reg_32  : STD_LOGIC_VECTOR(31 downto 0); --register output from bmp loader 
    signal pix_addr    : UNSIGNED(5 downto 0) := to_unsigned(0, 6);  -- tmp 

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
            i_rst => reset_l,
            i_clk => clk,
            o_clk_div2 => open,
            o_clk_div4 => clk_vga,
            o_clk_div8 => open,
            o_clk_div16 => clk_cpu
        );

    --------------------------------------------------
    -- video subsystem
    --------------------------------------------------
    u_vga_control : entity work.vga_controller
        port map(
            pixel_clk => clk_vga, -- 25 Mhz
            reset_n => reset_l,
            h_sync => Hsync, -- external hsync output
            v_sync => Vsync, -- external vsync output
            disp_ena => video_on,
            column => pixel_x,
            row => pixel_y,
            n_blank => open,
            n_sync => open
        );

    u_video_mux : entity work.mux		
        port map(
            s  => vgss,
            I0 => rgb_reg_0,
            I1 => rgb_reg_1,
            I2 => rgb_reg_2,
            I3 => (others => '0'),
            o  => rgb_out_reg
        );

    --set RGB color on whole screen
    rgb_reg_2 <= sw(11 downto 0);

    --set RGB color on per-pixel basis reading incrementally from the image ROM
    u_img_rom: entity work.rams_20c
        port map (
            clk  => clk_vga,
            we   => '0',
            addr => std_logic_vector(pix_addr), --tmp
            din  => (others => '0'), --read only
            dout => rgb_reg_32
        );
    rgb_reg_1 <= rgb_reg_32(11 downto 0);

    --set a RGB test pattern from the image ROM at a specific location on the screen
    u_bmp_img_gen : entity work.hw_image_generator
        port map(
            reset_in => reset_l, -- reset required to synchronize RAMB
            clk_in   => clk_vga, -- pixel clock
            disp_ena => '1', -- video_on ... tbd, enable is applied to final mux output 
            row      => pixel_y,
            column   => pixel_x,
            red      => rgb_reg_0(11 downto 8),
            green    => rgb_reg_0(7 downto 4),
            blue     => rgb_reg_0(3 downto 0)
            );

    --------------------------------------------------
    -- pixel address process (tmp, tbd?)
    --------------------------------------------------
    pix_addr <= to_unsigned(pixel_x, pix_addr'length);

--    p_pix_addr : process (reset_l, clk_vga)
--    begin
--        if (reset_l = '0') then
--            pix_addr <= to_unsigned(0, pix_addr'length);
--        elsif (rising_edge(clk_vga)) then
--            pix_addr <= pix_addr + 1;
--        end if;
--    end process p_pix_addr;


    --------------------------------------------------
    -- drive outputs, RGB, LED etc.
    --------------------------------------------------
    -- video generator source select from switches
    vgss      <= sw(15 downto 14);

    -- rgb register gated onto VGA signals only during video on time
    vgaRed    <= (rgb_out_reg(11 downto 8)) when video_on = '1' else (others => '0');
    vgaGreen  <= (rgb_out_reg(7 downto 4))  when video_on = '1' else (others => '0');
    vgaBlue   <= (rgb_out_reg(3 downto 0))  when video_on = '1' else (others => '0');

    -- LEDs
    IO_process : process (reset_l, sw) --clk_vga
    begin
        if (reset_l = '0') then
            led(11 downto 0) <= (others => '0');
        else
            led(11 downto 0) <= sw(11 downto 0);
        end if;
    end process IO_process;

end Behavioral;
