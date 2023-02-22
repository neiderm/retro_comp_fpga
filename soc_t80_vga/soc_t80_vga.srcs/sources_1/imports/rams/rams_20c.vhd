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
    type header_type is array (0 to 53) of std_logic_vector (7 downto 0);

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
        -- extract image dimensions
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

    constant bmp_hdr : bmp_info_type := ReadHeaderFromFile("rgb.bmp.dat"); -- FileName

    --
    -- (2) load image data
    --
    constant bmp_img_sz : integer := bmp_hdr.height * bmp_hdr.width * 3 + 1; -- temp 1 byte EOF
    subtype byte_type is std_logic_vector(7 downto 0);
    type bmp_img_dat_type is array (0 to bmp_img_sz-1) of byte_type;

    -- use 12-bit RGB output, which is specific to the FPGA board VGA output for now
    type rgb_data_type is array (0 to bmp_img_sz-1) of std_logic_vector (VGA_BITS-1 downto 0);

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
        while(not ENDFILE(bmp_file)) loop  -- until end of file is reached (todo ... 1 extra line)
            readline (bmp_file, RamFileLine);
            hread (RamFileLine, pix_data_buf(read_index));  -- read into tmp rgb byte buffer
            read_index := read_index + 1;
        end loop;
        file_close(bmp_file);

        -- read rgb888 into array of rgb444 (VGA_BITS=12)
        read_index := 0;
        while ( read_index < (bmp_data.dimensions.width * bmp_data.dimensions.height)) loop
            assert (read_index < rgb_data_type'length);
            bmp_data.pixel_data(read_index)(11 downto 8) := pix_data_buf(read_index * 3 + 2)(7 downto 4);
            bmp_data.pixel_data(read_index)(7 downto 4)  := pix_data_buf(read_index * 3 + 1)(7 downto 4);
            bmp_data.pixel_data(read_index)(3 downto 0)  := pix_data_buf(read_index * 3 + 0)(7 downto 4);
            read_index := read_index + 1;
        end loop;

        return bmp_data;
    end function;
    --
    -- declare and initialize the image ram
    --
    constant bmp_dat : bmp_type := InitRamFromFile("rgb.bmp.dat"); -- todo "FileName"
    constant imgW : integer := bmp_dat.dimensions.width;
    constant imgH : integer := bmp_dat.dimensions.height;
    --

--    signal addr : UNSIGNED(ADDR_WIDTH-1 downto 0);
    signal addr : integer;

begin
    process (clk, reset_n)
    begin
        if (reset_n = '0') then
            dout <= (others => '0');
        elsif (clk'EVENT and clk = '1') then

--            if (row = imgRow0) and (col = imgCol0) then
            if (row < imgRow0) then
                addr <= 0;
            end if;

            if (row >= imgRow0) and (row < (imgRow0 + imgH)) and
               (col >= imgCol0) and (col < (imgCol0 + imgW)) then
                dout <= bmp_dat.pixel_data(addr);
                addr <= addr + 1;
            else
                dout <= (others => '0');
            end if;
        end if;
    end process;
end syn;
