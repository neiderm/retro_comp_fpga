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

        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
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
    signal pixel_x  : INTEGER;
    signal pixel_y  : INTEGER;
    signal vgss     : STD_LOGIC_VECTOR(1 downto 0); -- video generator source select to vgen mux

    signal hsync_out   : STD_LOGIC;
    signal vsync_out   : STD_LOGIC;

    signal rgb_out_reg : STD_LOGIC_VECTOR(11 downto 0); -- register the RGB output signals 
    signal rgb_reg_0   : STD_LOGIC_VECTOR(11 downto 0);
    signal rgb_reg_1   : STD_LOGIC_VECTOR(11 downto 0);
    signal rgb_reg_2   : STD_LOGIC_VECTOR(11 downto 0);

    signal image_y  : INTEGER := 0;

    -- cpu
    signal cpu_addr         : std_logic_vector(15 downto 0);
    signal cpu_data_out     : std_logic_vector(7 downto 0);
    signal cpu_data_in      : std_logic_vector(7 downto 0);

    signal program_rom_din  : std_logic_vector(19 downto 0); -- (7 downto 0)
    signal rams_data_out    : std_logic_vector(7 downto 0);

begin
    --------------------------------------------------
    -- drive output pins 
    --------------------------------------------------
    -- external hsync/vsync outputs
    Hsync <= hsync_out;
    Vsync <= vsync_out;
    --test signals to verify clock rates
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
    -- Instantiate t80
    --------------------------------------------------
    u_cpu : entity work.T80s
        port map(
            RESET_n => reset_l,
            CLK_n   => clk_cpu,
            WAIT_n  => '1', -- cpu_wait_l,
            INT_n   => '1', -- cpu_int_l,
            NMI_n   => '1', -- cpu_nmi_l,
            BUSRQ_n => '1', -- cpu_busrq_l,
            M1_n    => open, -- cpu_m1_l,
            MREQ_n  => open, -- cpu_mreq_l,
            IORQ_n  => open, -- cpu_iorq_l,
            RD_n    => open, -- cpu_rd_l,
            WR_n    => open, -- cpu_wr_l,
            --              RFSH_n  => cpu_rfsh_l,
            --              HALT_n  => cpu_halt_l,
            --              BUSAK_n => cpu_busak_l,
            A       => cpu_addr,
            DI      => cpu_data_in,
            DO      => cpu_data_out
        );


    cpu_data_in <=  program_rom_din(7 downto 0);

    --------------------------------------------------
    -- work RAM
    --------------------------------------------------
  u_rams : entity work.rams_08
    port map (
      a    => cpu_addr(5 downto 0),
      di   => (others => '0'), -- cpu_data_out, -- cpu only source of ram data
      do   => open, -- rams_data_out,
      we   => '0',  -- not(mem_wr_l or work_ram_cs_l), -- write enable, active high
      en   => '1',                                     -- chip enable, active high
      clk  => clk_cpu
      );

    --------------------------------------------------
    -- internal program rom
    --------------------------------------------------
    u_program_rom : entity work.roms_constant
      port map (
        CLK         => clk_cpu,
        EN          => '1', -- cpu_rd_l ?
        ADDR        => cpu_addr(6 downto 0), -- ADDR_BITS
        DATA        => program_rom_din
        );

    --------------------------------------------------
    -- video subsystem
    --------------------------------------------------
    u_vga_control : entity work.vga_controller
        port map(
            pixel_clk => clk_vga, -- 25 Mhz
            reset_n => reset_l,
            h_sync => hsync_out,
            v_sync => vsync_out,
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

    -- set RGB color on whole screen
    rgb_reg_2 <= sw(11 downto 0);

    -- update y locatipn of imgage synchronized to vsync
    vsync_process : process(vsync_out)
    begin
        if (vsync_out'EVENT and vsync_out = '0') then
            image_y <= image_y - 1;
            -- overcome the urge to use '<=' comparison condition and save 7 LUTs!
            if image_y = 0 then
                image_y <= 500; 
            end if;
        end if;
    end process vsync_process;

    -- set RGB image from the bitmap image ROM
    u_img_rom: entity work.rams_20c
        generic map(
            FileName => "rgb.bmp.dat"
        )
        port map (
            clk     => clk_vga,
            row     => pixel_y,
            col     => pixel_x,
            dout    => rgb_reg_1,
            imgRow0 => 120,
            imgCol0 => image_y
        );

    -- set RGB test pattern from the image ROM at a specific location on the screen
    u_bmp_img_gen : entity work.hw_image_generator
        port map(
            clk_in   => clk_vga, -- pixel clock
            disp_ena => '1', -- video_on ... tbd, enable is applied to final mux output 
            row      => pixel_y,
            column   => pixel_x,
            red      => rgb_reg_0(11 downto 8),
            green    => rgb_reg_0(7 downto 4),
            blue     => rgb_reg_0(3 downto 0)
            );
    
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
    IO_process : process(reset_l, sw)
    begin
        if (reset_l = '0') then
            led(11 downto 0) <= (others => '0');
        else
            led(11 downto 0) <= sw(11 downto 0);
        end if;
    end process IO_process;

end Behavioral;
