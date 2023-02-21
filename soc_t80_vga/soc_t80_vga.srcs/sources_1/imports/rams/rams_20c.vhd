--
-- Initializing Block RAM from external data file
--
-- Download: ftp://ftp.xilinx.com/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/rams_2oc.vhd
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity rams_20c is
    generic (
        imgRow0 : integer := 0;
        imgCol0 : integer := 0;
        FileName : string;
        VGA_BITS   : integer := 12;  -- VGA bus width
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 6
    );
    port (
        reset_n : in std_logic;
        clk : in std_logic;
        row : in integer;
        col : in integer;
        dout : out std_logic_vector(VGA_BITS-1 downto 0)
    );
end rams_20c;

architecture syn of rams_20c is

    type RamType is array(0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    impure function InitRamFromFile (RamFileName : in string) return RamType is
        FILE RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM : RamType;
    begin
        for I in RamType'range loop
            readline (RamFile, RamFileLine);
            read (RamFileLine, RAM(I)); -- requires std_logic_textio
        end loop;
        return RAM;
    end function;

    signal RAM : RamType := InitRamFromFile(FileName);
    signal addr : UNSIGNED(ADDR_WIDTH-1 downto 0);

    -- temp hard code image size
    constant imgW : integer := 8;
    constant imgH : integer := 8;

begin
    process (clk, reset_n)
    begin
        if (reset_n = '0') then
            dout <= (others => '0');
        elsif (clk'EVENT and clk = '1') then

            if (row = imgRow0) and (col = imgCol0) then
                addr <= to_unsigned(0, addr'length);
            end if;

            if (row >= imgRow0) and (row < (imgRow0 + imgH)) and
               (col >= imgCol0) and (col < (imgCol0 + imgW)) then

                dout <= RAM(to_integer(addr))(VGA_BITS-1 downto 0); --reads out only part of data out
                addr <= addr + 1;
            else
                dout <= (others => '0');
            end if;
        end if;
    end process;
end syn;
