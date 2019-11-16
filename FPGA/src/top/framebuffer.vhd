library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;  
use STD.textio.all; 

entity framebuffer is
   generic
   (
      SCALE : integer := 1
   );
   port 
   (
      clk100               : in  std_logic; 
      
      pixel_out_addr       : in  integer range 0 to 38399;
      pixel_out_data       : in  std_logic_vector(14 downto 0);  
      pixel_out_we         : in  std_logic;
      
      clkvga               : in  std_logic;
      oCoord_X             : in  integer range -1023 to 2047;
      oCoord_Y             : in  integer range -1023 to 2047;
      gameboy_graphic      : out std_logic_vector(14 downto 0);
      gpu_out_active       : out std_logic := '0'                  
   );
end entity;

architecture arch of framebuffer is
   
   -- vga readout
   signal oCoord_X_1     : integer range -1023 to 2047;
   signal oCoord_Y_1     : integer range -1023 to 2047;
   signal oCoord_active  : std_logic := '0';
   
   signal readout_addr        : integer range 0 to 38399 := 0; 
   signal readout_addr_ystart : integer range 0 to 38400 := 0; 
   signal readout_slow_x      : integer range 0 to 4     := 0; 
   signal readout_slow_y      : integer range 0 to 4     := 0; 
   signal readout_buffer      : std_logic_vector(14 downto 0) := (others => '0');
   
   type tPixelArray is array(0 to 38399) of std_logic_vector(14 downto 0);
   signal PixelArray : tPixelArray := (others => (others => '0'));
   
   -- affine + mosaik
    signal ref2_x : signed(27 downto 0) := (others => '0'); 
    signal ref2_y : signed(27 downto 0) := (others => '0'); 
    signal ref3_x : signed(27 downto 0) := (others => '0'); 
    signal ref3_y : signed(27 downto 0) := (others => '0'); 
    
    signal mosaik_bg0_vcnt : integer range 0 to 15;
    signal mosaik_bg1_vcnt : integer range 0 to 15;
    signal mosaik_bg2_vcnt : integer range 0 to 15;
    signal mosaik_bg3_vcnt : integer range 0 to 15;
   
begin 

   process (clkvga)
   begin
      if rising_edge(clkvga) then
      
         oCoord_X_1 <= oCoord_X;
         oCoord_Y_1 <= oCoord_Y;
      
         if (oCoord_X >= 0 and oCoord_X < (240 * SCALE) and oCoord_Y >= 0 and oCoord_Y < (160 * SCALE)) then
            oCoord_active <= '1';
            if (readout_slow_x < (SCALE - 1)) then
               readout_slow_x <= readout_slow_x + 1;
            else
               if (readout_addr < 38399) then
                  readout_addr <= readout_addr + 1;
               end if;
               readout_slow_x <= 0;
            end if;
         else
            oCoord_active <= '0';
            if (oCoord_X = (240 * SCALE) and oCoord_Y >= 0 and oCoord_Y < (160 * SCALE)) then
               if (readout_slow_y < (SCALE - 1)) then
                  readout_slow_y <= readout_slow_y + 1;
                  readout_addr   <= readout_addr_ystart;
               else
                  readout_slow_y      <= 0;
                  readout_addr_ystart <= readout_addr_ystart + 240;
               end if;
            end if;
         end if;
         
         if (oCoord_X = 0 and oCoord_Y = -1) then
            readout_addr        <= 0;
            readout_addr_ystart <= 0;
            readout_slow_x      <= 0;
            readout_slow_y      <= 0;
         end if;
         
         readout_buffer  <= PixelArray(readout_addr);
         gameboy_graphic <= readout_buffer;

         gpu_out_active <= oCoord_active;
      
      end if;
   end process;
   
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         if (pixel_out_we = '1') then
            PixelArray(pixel_out_addr) <= pixel_out_data;
         end if;
      
      end if;
   end process;
   

-- synthesis translate_off
   
   goutput : if 1 = 1 generate
   begin
   
      process
      
         file outfile: text;
         variable f_status: FILE_OPEN_STATUS;
         variable line_out : line;
         variable color : unsigned(31 downto 0);
         variable linecounter_int : integer;
         
      begin
   
         file_open(f_status, outfile, "gra_gba_out.gra", write_mode);
         file_close(outfile);
         
         file_open(f_status, outfile, "gra_gba_out.gra", append_mode);
         write(line_out, string'("480#320")); 
         writeline(outfile, line_out);
         
         while (true) loop
            wait until ((pixel_out_addr mod 240) = 239) and pixel_out_we = '1';
            linecounter_int := pixel_out_addr / 240;

            wait for 100 ns;

            for x in 0 to 239 loop
               color := x"0000" & "0" & unsigned(PixelArray(linecounter_int * 240 + x));
               color := x"00" & unsigned(color(14 downto 10)) & "000" & unsigned(color(9 downto 5)) & "000" & unsigned(color(4 downto 0)) & "000";
            
               for doublex in 0 to 1 loop
                  for doubley in 0 to 1 loop
                     write(line_out, to_integer(color));
                     write(line_out, string'("#"));
                     write(line_out, x * 2 + doublex);
                     write(line_out, string'("#")); 
                     write(line_out, linecounter_int * 2 + doubley);
                     writeline(outfile, line_out);
                  end loop;
               end loop;

            end loop;
            
            file_close(outfile);
            file_open(f_status, outfile, "gra_gba_out.gra", append_mode);
            
         end loop;
         
      end process;
   
   end generate goutput;
   
-- synthesis translate_on

end architecture;





