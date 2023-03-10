--
-- Description of a ROM with a VHDL signal
--
-- Download: ftp://ftp.xilinx.com/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/roms_signal.vhd
--
library ieee; 
use ieee.std_logic_1164.all; 
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity roms_signal is
    generic (
        imgRow0 : integer := 0;
        imgCol0 : integer := 0);
    port (
        clk  : in std_logic; 
        en   : in std_logic; 
        row  : in  integer;
        col  : in  integer;
        data : out std_logic_vector(11 downto 0)); 
end roms_signal; 

architecture syn of roms_signal is 

    constant imgW : integer := 8;
    constant imgH : integer := 16;

    type rom_type is array (0 to 127) of std_logic_vector (11 downto 0); 

    signal ROM : rom_type := (
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"F00", X"F00", X"F00", X"0F0", X"0F0", X"0F0", X"00F", X"00F",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF",
        X"00F", X"00F", X"0F0", X"0F0", X"F00", X"F00", X"F00", X"FFF"
    ); 

    signal pix_addr : UNSIGNED(6 downto 0);
    -- row and col are considered by the tool as inputs to data so must be registered to infer BRAM
    signal row_r : integer;
    signal col_r : integer;

begin
    process (clk)
    begin
        if (clk'EVENT and clk = '1') then

            row_r <= row;
            col_r <= col;

            if (en = '1') then 
                if (row_r < imgRow0) then
                    pix_addr <= to_unsigned(0, pix_addr'length);
                end if;

                data <= ROM(to_integer(pix_addr));

                if (row_r >= imgRow0) and (row_r < (imgRow0 + imgH)) and 
                   (col_r >= imgCol0) and (col_r < (imgCol0 + imgW))
                then 
                    pix_addr <= pix_addr + 1;
                else 
                    data <= (others => '0');
                end if;
            end if; --en
        end if; 
    end process;
end syn;

