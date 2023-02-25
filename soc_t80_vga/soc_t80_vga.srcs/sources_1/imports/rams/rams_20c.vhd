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
        FileName : string := "rgb.bmp.dat"; -- override default file name in component instantiation 
        VGA_BITS : integer := 12  -- VGA bus width
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
    --
    -- (1) load bitmap header
    --
    subtype byte_type is std_logic_vector(7 downto 0);
    type header_type is array (0 to 53) of byte_type;

    type bmp_info_type is record
        width  : integer;
        height : integer;
    end record;

    impure function ReadHeaderFromFile (RamFileName : in string) return bmp_info_type is
        file bmp_file : text;
        variable RamFileLine : line;
        variable bmp_dims : bmp_info_type;
        variable header : header_type;
        variable read_index : integer := 0;
    begin
        file_open(bmp_file, RamFileName, read_mode); -- todo error handling?
        -- read header from file
        for i in header_type'range loop
            readline (bmp_file, RamFileLine);
            hread (RamFileLine, header(i)); -- requires VHDL 2008
        end loop;
        file_close(bmp_file);
        -- extract image dimensions (see help here https://vhdlwhiz.com/read-bmp-file/)
        bmp_dims.width := to_integer(unsigned(header(18))) + 
                          to_integer(unsigned(header(19))) * 2 ** 8 + 
                          to_integer(unsigned(header(20))) * 2 ** 16 + 
                          to_integer(unsigned(header(21))) * 2 ** 24;
        bmp_dims.height := to_integer(unsigned(header(22))) + 
                           to_integer(unsigned(header(23))) * 2 ** 8 + 
                           to_integer(unsigned(header(24))) * 2 ** 16 + 
                           to_integer(unsigned(header(25))) * 2 ** 24;
        return bmp_dims;
    end function;

    constant bmp_hdr : bmp_info_type := ReadHeaderFromFile(FileName);
    --
    -- (2) load image data
    --
    constant bmp_img_sz : integer := bmp_hdr.height * bmp_hdr.width;
    -- byte buffer for input from bitmap image data section in file
    -- size is image size +1 to allow newline reading to end of file
    type bmp_img_dat_type is array (0 to bmp_img_sz * 3) of byte_type;

    -- use 12-bit RGB output, which is specific to the FPGA board VGA output for now
    subtype rgb444_type is std_logic_vector(VGA_BITS-1 downto 0);
    type rgb_data_type is array (0 to bmp_img_sz - 1) of rgb444_type;

    type bmp_type is record
        dimensions : bmp_info_type;
        pixel_data : rgb_data_type;
    end record;

    impure function InitRamFromFile (RamFileName : in string) return bmp_type is
        file bmp_file : text;
        variable RamFileLine : line;
        variable pix_data_buf : bmp_img_dat_type; -- temp byte buffer to read in bmp image data
        variable read_index : integer := 0;
        variable bmp_data : bmp_type;  -- object returned from function
    begin
        file_open(bmp_file, RamFileName, read_mode);
        -- read BMP header from file (only needed to skip over header to image data)
        for i in header_type'range loop
            readline (bmp_file, RamFileLine);
        end loop;

        bmp_data.dimensions.width := bmp_hdr.width;
        bmp_data.dimensions.height := bmp_hdr.height;

        -- read RGB image data from file
        read_index := 0;
        while(not ENDFILE(bmp_file)) loop  -- note readline called past the end of file
            readline (bmp_file, RamFileLine);
            hread (RamFileLine, pix_data_buf(read_index));  -- read into tmp rgb byte buffer
            read_index := read_index + 1;
        end loop;
        file_close(bmp_file);

        -- convert rgb888 to rgb444 (VGA_BITS=12)
        for read_index in rgb_data_type'range loop
            bmp_data.pixel_data(read_index)(11 downto 8) := pix_data_buf(read_index * 3 + 2)(7 downto 4);
            bmp_data.pixel_data(read_index)(7 downto 4)  := pix_data_buf(read_index * 3 + 1)(7 downto 4);
            bmp_data.pixel_data(read_index)(3 downto 0)  := pix_data_buf(read_index * 3 + 0)(7 downto 4);
        end loop;

        return bmp_data;
    end function;
    --
    -- read bitmap file into image ram
    --
    constant bmp_dat : bmp_type := InitRamFromFile(FileName);
    constant imgW : integer := bmp_dat.dimensions.width;
    constant imgH : integer := bmp_dat.dimensions.height;
    --
    signal addr : integer;
    signal row_r : integer;
    signal col_r : integer;

begin
    process (clk, reset_n)
    begin
        if (clk'EVENT and clk = '1') then
            row_r <= row;
            col_r <= col;
            --if (row = imgRow0) and (col = imgCol0) then -- didn't work right with addr as integer
            if (row_r < imgRow0) then
                addr <= 0;
            end if;

            dout <= bmp_dat.pixel_data(addr);
                
            if (row_r >= imgRow0) and (row_r < (imgRow0 + imgH)) and
               (col_r >= imgCol0) and (col_r < (imgCol0 + imgW))
            then
                addr <= addr + 1;
            else
                dout <= (others => '0');
            end if;
        end if;

    end process;
end syn;
