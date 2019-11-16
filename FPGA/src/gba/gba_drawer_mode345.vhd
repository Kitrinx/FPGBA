library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

entity gba_drawer_mode345 is
   port 
   (
      clk100               : in  std_logic;                     
      BG_Mode              : in  std_logic_vector(2 downto 0);
                           
      drawline             : in  std_logic;
      busy                 : out std_logic := '0';
      
      second_frame         : in  std_logic;
      refX                 : in  signed(27 downto 0);
      refY                 : in  signed(27 downto 0);
      dx                   : in  signed(15 downto 0);
      dy                   : in  signed(15 downto 0);
      
      pixel_we             : out std_logic := '0';
      pixeldata            : out std_logic_vector(15 downto 0) := (others => '0');
      pixel_x              : out integer range 0 to 239;

      PALETTE_Drawer_addr  : out integer range 0 to 127;
      PALETTE_Drawer_data  : in  std_logic_vector(31 downto 0);
      PALETTE_Drawer_valid : in  std_logic;
      
      VRAM_Drawer_addr_Lo  : out integer range 0 to 16383;
      VRAM_Drawer_addr_Hi  : out integer range 0 to 8191;
      VRAM_Drawer_data_Lo  : in  std_logic_vector(31 downto 0);
      VRAM_Drawer_data_Hi  : in  std_logic_vector(31 downto 0);
      VRAM_Drawer_valid_Lo : in  std_logic;
      VRAM_Drawer_valid_Hi : in  std_logic
      
   );
end entity;

architecture arch of gba_drawer_mode345 is
   
   type tFetchState is
   (
      IDLE,
      STARTREAD,
      WAITREAD,
      FETCHDONE
   );
   signal vramfetch    : tFetchState := IDLE;
   signal palettefetch : tFetchState := IDLE;
   
   type tDrawState is
   (
      NEXTPIXEL,
      READPALETTE
   );
   signal DrawState : tDrawState := NEXTPIXEL;
  
   signal x_cnt            : integer range 0 to 239;
   signal realX            : signed(27 downto 0);
   signal realY            : signed(27 downto 0);
   signal xxx              : signed(19 downto 0);
   signal yyy              : signed(19 downto 0);
   
   signal VRAM_byteaddr    : unsigned(16 downto 0); 
   signal vram_readwait    : integer range 0 to 2;
   signal vram_data        : std_logic_vector(15 downto 0);
   signal vram_data_ack    : std_logic := '0';
   signal x_cnt_save       : integer range 0 to 239;
   
   signal PALETTE_byteaddr : unsigned(8 downto 0); 
   signal palette_readwait : integer range 0 to 2;
   signal palette_data     : std_logic_vector(15 downto 0);
   signal palette_data_req : std_logic := '0';
   signal palette_data_ack : std_logic := '0';
   
begin 

   VRAM_Drawer_addr_Lo <= to_integer(VRAM_byteaddr(15 downto 2));
   VRAM_Drawer_addr_Hi <= to_integer(VRAM_byteaddr(14 downto 2));
   
   PALETTE_Drawer_addr <= to_integer(PALETTE_byteaddr(8 downto 2));
   
   xxx <= realX(27 downto 8);
   yyy <= realY(27 downto 8);
   
   -- vramfetch
   process (clk100)
    variable byteaddr : integer;
   begin
      if rising_edge(clk100) then
      
         case (vramfetch) is
         
            when IDLE =>
               if (drawline = '1') then
                  busy      <= '1';
                  vramfetch <= STARTREAD;
                  realX     <= refX;
                  realY     <= refY;
                  x_cnt     <= 0;
               elsif (DrawState = NEXTPIXEL and palettefetch = IDLE) then
                  busy      <= '0';
               end if;
               
            when STARTREAD => 
               if    (BG_Mode = "011") then byteaddr := to_integer(unsigned(yyy * 480 + (xxx * 2)));
               elsif (BG_Mode = "100") then byteaddr := to_integer(unsigned(yyy * 240 + xxx));
               else                         byteaddr := to_integer(unsigned(yyy * 320 + (xxx * 2))); 
               end if;
               
               if (second_frame = '1' and BG_Mode /= "011") then
                  byteaddr := byteaddr + 16#A000#;
               end if;
               
               VRAM_byteaddr <= to_unsigned(byteaddr, VRAM_byteaddr'length);
               
               if ((BG_Mode  = "101" and (xxx >= 0 and yyy >= 0 and xxx < 160 and yyy < 128)) or
                   (BG_Mode /= "101" and (xxx >= 0 and yyy >= 0 and xxx < 240 and yyy < 160))) then
                  vramfetch     <= WAITREAD;
                  vram_readwait <= 2;
               else
                  if (x_cnt < 239) then
                     x_cnt     <= x_cnt + 1;
                  else
                     vramfetch <= IDLE;
                  end if;
                  realX <= realX + dx;
                  realY <= realy + dy;
               end if;
            
            when WAITREAD =>
               if (vram_readwait > 0) then
                  vram_readwait <= vram_readwait - 1;
               else
                  if (VRAM_byteaddr(16) = '1' and VRAM_Drawer_valid_Hi = '1') then
                     if (VRAM_byteaddr(1) = '1') then
                        vram_data <= VRAM_Drawer_data_Hi(31 downto 16);
                     else
                        vram_data <= VRAM_Drawer_data_Hi(15 downto 0);
                     end if;
                     vramfetch  <= FETCHDONE;
                  elsif (VRAM_byteaddr(16) = '0' and VRAM_Drawer_valid_Lo = '1') then
                     if (VRAM_byteaddr(1) = '1') then
                        vram_data <= VRAM_Drawer_data_Lo(31 downto 16);
                     else
                        vram_data <= VRAM_Drawer_data_Lo(15 downto 0);
                     end if;
                     vramfetch  <= FETCHDONE; 
                  end if;
               end if;
            
            when FETCHDONE =>
               if (vram_data_ack = '1') then
                  if (x_cnt < 239) then
                     vramfetch <= STARTREAD;
                     x_cnt     <= x_cnt + 1;
                  else
                     vramfetch <= IDLE;
                  end if;
                  realX <= realX + dx;
                  realY <= realy + dy;
               end if;
         
         end case;
      
      end if;
   end process;
   
   -- palette
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         case (palettefetch) is
         
            when IDLE =>
               if (palette_data_req = '1') then
                  palettefetch <= STARTREAD;
               end if;
               
            when STARTREAD => 
               palettefetch     <= WAITREAD;
               palette_readwait <= 2;
            
            when WAITREAD =>
               if (palette_readwait > 0) then
                  palette_readwait <= palette_readwait - 1;
               elsif (PALETTE_Drawer_valid = '1') then
                  if (PALETTE_byteaddr(1) = '1') then
                     palette_data <= PALETTE_Drawer_data(31 downto 16);
                  else
                     palette_data <= PALETTE_Drawer_data(15 downto 0);
                  end if;
                  palettefetch  <= FETCHDONE;
               end if;
            
            when FETCHDONE =>
               if (palette_data_ack = '1') then
                     palettefetch <= IDLE;
               end if;
         
         end case;
      
      end if;
   end process;
   
   
   -- draw
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         vram_data_ack    <= '0';
         palette_data_req <= '0';
         palette_data_ack <= '0';
         
         pixel_we <= '0';
      
         case (DrawState) is
         
            when NEXTPIXEL =>
               if (vramfetch = FETCHDONE and vram_data_ack = '0') then
                  vram_data_ack <= '1';
                  x_cnt_save    <= x_cnt;
                  if (BG_Mode = "100") then
                     palette_data_req <= '1';
                     DrawState        <= READPALETTE; 
                     if (VRAM_byteaddr(0) = '1') then
                        PALETTE_byteaddr <= unsigned(vram_data(15 downto 8)) & '0';
                     else
                        PALETTE_byteaddr <= unsigned(vram_data(7 downto 0)) & '0';
                     end if;
                  else
                     pixel_we      <= '1';
                     pixeldata     <= '0' & vram_data(14 downto 0);
                     pixel_x       <= x_cnt;
                  end if;
               end if;
               
            when READPALETTE => 
               if (palettefetch = FETCHDONE) then
                  palette_data_ack <= '1';
                  DrawState        <= NEXTPIXEL;
                  pixel_we         <= '1';
                  pixeldata        <= '0' & palette_data(14 downto 0);
                  pixel_x          <= x_cnt_save;
               end if;

         end case;
      
      end if;
   end process;


end architecture;





