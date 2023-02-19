--------------------------------------------------------------------------------
--
--   FileName:         hw_image_generator.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/10/2013 Scott Larson
--     Initial Public Release
--
--   Version 1.01 12-Feb-23 soc_t80_vga 
--     Modified to 12-bits video output vector
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all; --UNSIGNED

ENTITY hw_image_generator IS
  GENERIC(
    pixels_y :  INTEGER := 240;   --row that first color will persist until
    pixels_x :  INTEGER := 320);  --column that first color will persist until
  PORT(
    reset_in :  IN   STD_LOGIC;  -- added reset for RAMB synchronisation
    clk_in   :  IN   STD_LOGIC;
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
    red      :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
    green    :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')); --blue magnitude output to DAC
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS
    signal rgb_out  : STD_LOGIC_VECTOR(11 DOWNTO 0);
BEGIN

  u_img_rom: entity work.roms_signal
    generic map(
      imgRow0 => 120,
      imgCol0 => 160
    )
    port map (
      reset_n => reset_in,
      clk  => clk_in,
      en   => disp_ena,
      row  => row,
      col  => column,
      data => rgb_out
    );

  PROCESS(disp_ena, row, column, rgb_out)
  BEGIN
    IF(disp_ena = '1') THEN        --display time
      IF(row < pixels_y AND column < pixels_x) THEN
        red   <= rgb_out(11 downto 8);
        green <= rgb_out(7 downto 4);
        blue  <= rgb_out(3 downto 0);
      ELSE
        red   <= (OTHERS => '1');
        green <= (OTHERS => '1');
        blue  <= (OTHERS => '0');
      END IF;
    ELSE                           --blanking time
      red   <= (OTHERS => '0');
      green <= (OTHERS => '0');
      blue  <= (OTHERS => '0');
    END IF;
  
  END PROCESS;
END behavior;
