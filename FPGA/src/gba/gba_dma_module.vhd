library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegmap_gba.all;
use work.pProc_bus_gba.all;

entity gba_dma_module is
   generic
   (
      index                        : integer range 0 to 3;
      has_DRQ                      : boolean;
      Reg_SAD                      : regmap_type;
      Reg_DAD                      : regmap_type;
      Reg_CNT_L                    : regmap_type;
      Reg_CNT_H_Dest_Addr_Control  : regmap_type;
      Reg_CNT_H_Source_Adr_Control : regmap_type;
      Reg_CNT_H_DMA_Repeat         : regmap_type;
      Reg_CNT_H_DMA_Transfer_Type  : regmap_type;
      Reg_CNT_H_Game_Pak_DRQ       : regmap_type;
      Reg_CNT_H_DMA_Start_Timing   : regmap_type;
      Reg_CNT_H_IRQ_on             : regmap_type;
      Reg_CNT_H_DMA_Enable         : regmap_type
   );
   port 
   (
      clk100              : in    std_logic;  
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z', "ZZ", "ZZZZ", 'Z');
      
      IRP_DMA             : out   std_logic := '0';
      
      dma_on              : out   std_logic := '0';
      allow_on            : in    std_logic;
      
      sound_dma_req       : in    std_logic;
      hblank_trigger      : in    std_logic;
      vblank_trigger      : in    std_logic;
      
      dma_new_cycles      : out   std_logic := '0'; 
      dma_first_cycles    : out   std_logic := '0';
      dma_dword_cycles    : out   std_logic := '0';
      dma_cycles_adrup    : out   std_logic_vector(3 downto 0) := (others => '0'); 
      
      dma_eepromcount     : out   unsigned(16 downto 0);
      
      dma_bus_Adr         : out   std_logic_vector(27 downto 0) := (others => '0'); 
      dma_bus_rnw         : out   std_logic := '0';
      dma_bus_ena         : out   std_logic := '0';
      dma_bus_acc         : out   std_logic_vector(1 downto 0) := (others => '0'); 
      dma_bus_dout        : out   std_logic_vector(31 downto 0) := (others => '0'); 
      dma_bus_din         : in    std_logic_vector(31 downto 0);
      dma_bus_done        : in    std_logic
   );
end entity;

architecture arch of gba_dma_module is

   signal SAD                      : std_logic_vector(Reg_SAD                     .upper downto Reg_SAD                     .lower) := (others => '0');
   signal DAD                      : std_logic_vector(Reg_DAD                     .upper downto Reg_DAD                     .lower) := (others => '0');
   signal CNT_L                    : std_logic_vector(Reg_CNT_L                   .upper downto Reg_CNT_L                   .lower) := (others => '0');
   signal CNT_H_Dest_Addr_Control  : std_logic_vector(Reg_CNT_H_Dest_Addr_Control .upper downto Reg_CNT_H_Dest_Addr_Control .lower) := (others => '0');
   signal CNT_H_Source_Adr_Control : std_logic_vector(Reg_CNT_H_Source_Adr_Control.upper downto Reg_CNT_H_Source_Adr_Control.lower) := (others => '0');
   signal CNT_H_DMA_Repeat         : std_logic_vector(Reg_CNT_H_DMA_Repeat        .upper downto Reg_CNT_H_DMA_Repeat        .lower) := (others => '0');
   signal CNT_H_DMA_Transfer_Type  : std_logic_vector(Reg_CNT_H_DMA_Transfer_Type .upper downto Reg_CNT_H_DMA_Transfer_Type .lower) := (others => '0');
   signal CNT_H_Game_Pak_DRQ       : std_logic_vector(Reg_CNT_H_Game_Pak_DRQ      .upper downto Reg_CNT_H_Game_Pak_DRQ      .lower) := (others => '0');
   signal CNT_H_DMA_Start_Timing   : std_logic_vector(Reg_CNT_H_DMA_Start_Timing  .upper downto Reg_CNT_H_DMA_Start_Timing  .lower) := (others => '0');
   signal CNT_H_IRQ_on             : std_logic_vector(Reg_CNT_H_IRQ_on            .upper downto Reg_CNT_H_IRQ_on            .lower) := (others => '0');
   signal CNT_H_DMA_Enable         : std_logic_vector(Reg_CNT_H_DMA_Enable        .upper downto Reg_CNT_H_DMA_Enable        .lower) := (others => '0');

   signal SAD_written                        : std_logic;                                                                                                                                                      
   signal DAD_written                        : std_logic;                                                                                                                                                      
   signal CNT_L_written                      : std_logic;                                                                                                                                                                                                                                                                                                           
   signal CNT_H_Dest_Addr_Control_written    : std_logic;                                                                                                                                                      
   signal CNT_H_Source_Adr_Control_written   : std_logic;                                                                                                                                                      
   signal CNT_H_DMA_Repeat_written           : std_logic;                                                                                                                                                      
   signal CNT_H_DMA_Transfer_Type_written    : std_logic;                                                                                                                                                      
   signal CNT_H_Game_Pak_DRQ_written         : std_logic;                                                                                                                                                      
   signal CNT_H_DMA_Start_Timing_written     : std_logic;                                                                                                                                                      
   signal CNT_H_IRQ_on_written               : std_logic;                                                                                                                                                      
   signal CNT_H_DMA_Enable_written           : std_logic;   

   signal Enable  : std_logic_vector(0 downto 0) := "0";
   signal running : std_logic := '0';
   signal waiting : std_logic := '0';
   signal first   : std_logic := '0';
   
   signal dest_Addr_Control  : integer range 0 to 3;
   signal source_Adr_Control : integer range 0 to 3;
   signal Start_Timing       : integer range 0 to 3;
   signal Repeat             : std_logic;
   signal Transfer_Type_DW   : std_logic;
   signal iRQ_on             : std_logic;

   signal addr_source        : unsigned(27 downto 0);
   signal addr_target        : unsigned(27 downto 0);
   signal count              : unsigned(16 downto 0);
   signal fullcount          : unsigned(16 downto 0);
   
   signal last_dma_value     : std_logic_vector(31 downto 0) := (others => '0');

   type tstate is
   (
      IDLE,
      READING,
      WRITING
   );
   signal state : tstate := IDLE;

begin 

   gDRQ : if has_DRQ = true generate
   begin
      iCNT_H_Game_Pak_DRQ       : entity work.eProcReg_gba generic map ( Reg_CNT_H_Game_Pak_DRQ       ) port map  (clk100, gb_bus, CNT_H_Game_Pak_DRQ       , CNT_H_Game_Pak_DRQ       , CNT_H_Game_Pak_DRQ_written       );  
   end generate;
   
   iSAD                      : entity work.eProcReg_gba generic map ( Reg_SAD                      ) port map  (clk100, gb_bus, x"00000000"              , SAD                      , SAD_written                      );  
   iDAD                      : entity work.eProcReg_gba generic map ( Reg_DAD                      ) port map  (clk100, gb_bus, x"00000000"              , DAD                      , DAD_written                      );  
   iCNT_L                    : entity work.eProcReg_gba generic map ( Reg_CNT_L                    ) port map  (clk100, gb_bus, x"0000"                  , CNT_L                    , CNT_L_written                    );   
   iCNT_H_Dest_Addr_Control  : entity work.eProcReg_gba generic map ( Reg_CNT_H_Dest_Addr_Control  ) port map  (clk100, gb_bus, CNT_H_Dest_Addr_Control  , CNT_H_Dest_Addr_Control  , CNT_H_Dest_Addr_Control_written  );  
   iCNT_H_Source_Adr_Control : entity work.eProcReg_gba generic map ( Reg_CNT_H_Source_Adr_Control ) port map  (clk100, gb_bus, CNT_H_Source_Adr_Control , CNT_H_Source_Adr_Control , CNT_H_Source_Adr_Control_written );  
   iCNT_H_DMA_Repeat         : entity work.eProcReg_gba generic map ( Reg_CNT_H_DMA_Repeat         ) port map  (clk100, gb_bus, CNT_H_DMA_Repeat         , CNT_H_DMA_Repeat         , CNT_H_DMA_Repeat_written         );  
   iCNT_H_DMA_Transfer_Type  : entity work.eProcReg_gba generic map ( Reg_CNT_H_DMA_Transfer_Type  ) port map  (clk100, gb_bus, CNT_H_DMA_Transfer_Type  , CNT_H_DMA_Transfer_Type  , CNT_H_DMA_Transfer_Type_written  );  
   iCNT_H_DMA_Start_Timing   : entity work.eProcReg_gba generic map ( Reg_CNT_H_DMA_Start_Timing   ) port map  (clk100, gb_bus, CNT_H_DMA_Start_Timing   , CNT_H_DMA_Start_Timing   , CNT_H_DMA_Start_Timing_written   );  
   iCNT_H_IRQ_on             : entity work.eProcReg_gba generic map ( Reg_CNT_H_IRQ_on             ) port map  (clk100, gb_bus, CNT_H_IRQ_on             , CNT_H_IRQ_on             , CNT_H_IRQ_on_written             );  
   iCNT_H_DMA_Enable         : entity work.eProcReg_gba generic map ( Reg_CNT_H_DMA_Enable         ) port map  (clk100, gb_bus, Enable                   , CNT_H_DMA_Enable         , CNT_H_DMA_Enable_written         );  
   
   dma_eepromcount <= fullcount;
   
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         IRP_DMA       <= '0';
         
         dma_bus_ena <= '0';
         
         dma_new_cycles   <= '0';
         dma_first_cycles <= '0';
         dma_dword_cycles <= '0';
         dma_cycles_adrup <= (others => '0');
      
         -- dma init
         if (CNT_H_DMA_Enable_written= '1') then
         
            Enable <= CNT_H_DMA_Enable;
            
            if (CNT_H_DMA_Enable = "0") then
               running <= '0';
               waiting <= '0';
               dma_on  <= '0';
            end if;
         
            if (Enable = "0" and CNT_H_DMA_Enable = "1") then
               
               -- drq not implemented! Reg_CNT_H_Game_Pak_DRQ
               
               dest_Addr_Control  <= to_integer(unsigned(CNT_H_Dest_Addr_Control));
               source_Adr_Control <= to_integer(unsigned(CNT_H_Source_Adr_Control));
               Start_Timing       <= to_integer(unsigned(CNT_H_DMA_Start_Timing));
               Repeat             <= CNT_H_DMA_Repeat(CNT_H_DMA_Repeat'left);
               Transfer_Type_DW   <= CNT_H_DMA_Transfer_Type(CNT_H_DMA_Transfer_Type'left);
               iRQ_on             <= CNT_H_IRQ_on(CNT_H_IRQ_on'left);

               addr_source <= unsigned(SAD(27 downto 0));
               addr_target <= unsigned(DAD(27 downto 0));

               case (index) is
                  when 0 => addr_source(27) <= '0'; addr_target(27) <= '0';
                  when 1 =>                         addr_target(27) <= '0';
                  when 2 =>                         addr_target(27) <= '0';
                  when 3 => null;
               end case;
                  
               if (index = 3) then
                  if (CNT_L(15 downto 0) = (15 downto 0 => '0')) then
                     count <= '1' & x"0000";
                  else
                     count <= '0' & unsigned(CNT_L(15 downto 0));
                  end if;  
               else
                  if (CNT_L(13 downto 0) = (13 downto 0 => '0')) then
                     count <= '0' & x"4000";
                  else
                     count <= "000" & unsigned(CNT_L(13 downto 0));
                  end if;  
               end if;

               waiting <= '1';
               
               if (CNT_H_DMA_Start_Timing = "11" and (index = 1 or index = 2)) then
                  count             <= to_unsigned(4, 17);
                  dest_Addr_Control <= 3;
               end if;
         
            end if;
         
         end if;
        
         -- dma checkrun
         if (Enable = "1") then 
            if (waiting = '1') then
               if (Start_Timing = 0 or 
               (Start_Timing = 1 and vblank_trigger = '1') or 
               (Start_Timing = 2 and hblank_trigger = '1') or 
               (Start_Timing = 3 and sound_dma_req = '1')) then
                  dma_on     <= '1';
                  running    <= '1';
                  waiting    <= '0';
                  first      <= '1';
                  fullcount  <= count;
               end if ;
            end if;
            --if (DMAs[index].dMA_Start_Timing = 3 and index = 3) -- video dma not implemented"
   
   
            -- dma work
            if (running = '1') then
               
               case state is
               
                  when IDLE =>
                     if (allow_on = '1') then
                        state <= READING;
                        --if (unsigned(addr_source) > unsigned(x"2000000")) then required to read 0 for bios?
                        dma_bus_rnw <= '1';
                        dma_bus_ena <= '1';
                        if (Transfer_Type_DW = '1') then
                           dma_bus_Adr <= std_logic_vector(addr_source(27 downto 2)) & "00";
                           dma_bus_acc <= ACCESS_32BIT;
                        else
                           dma_bus_Adr <= std_logic_vector(addr_source(27 downto 1)) & "0";
                           dma_bus_acc <= ACCESS_16BIT;
                        end if;  
                        -- timing
                        count <= count - 1;
                        first <= '0';
                        dma_new_cycles   <= '1';
                        dma_first_cycles <= first;
                        dma_dword_cycles <= Transfer_Type_DW;
                        dma_cycles_adrup <= std_logic_vector(addr_source(27 downto 24));   
                     end if;
                  
                  when READING =>
                     if (dma_bus_done = '1') then
                        state <= WRITING;
                        dma_bus_rnw  <= '0';
                        dma_bus_ena  <= '1';
                        dma_bus_Adr  <= std_logic_vector(addr_target);
                        
                        if (addr_source >= 16#2000000#) then
                           dma_bus_dout   <= dma_bus_din;
                           last_dma_value <= dma_bus_din;
                        else
                           dma_bus_dout <= last_dma_value;
                        end if;
                        
                        -- next settings
                        if (Transfer_Type_DW = '1') then
                           if (source_Adr_Control = 0 or source_Adr_Control = 3) then 
                              addr_source <= addr_source + 4; 
                           elsif (source_Adr_Control = 1) then
                              addr_source <= addr_source - 4;
                           end if;

                           if (dest_Addr_Control = 0 or (dest_Addr_Control = 3 and Start_Timing /= 3)) then
                              addr_target <= addr_target + 4;
                           elsif (dest_Addr_Control = 1) then
                              addr_target <= addr_target - 4;
                           end if;
                        else
                           if (source_Adr_Control = 0 or source_Adr_Control = 3) then 
                              addr_source <= addr_source + 2; 
                           elsif (source_Adr_Control = 1) then
                              addr_source <= addr_source - 2;
                           end if;

                           if (dest_Addr_Control = 0 or (dest_Addr_Control = 3 and Start_Timing /= 3)) then
                              addr_target <= addr_target + 2;
                           elsif (dest_Addr_Control = 1) then
                              addr_target <= addr_target - 2;
                           end if;
                        end if;
                        -- timing
                        dma_new_cycles   <= '1';
                        dma_first_cycles <= first;
                        dma_dword_cycles <= Transfer_Type_DW;
                        dma_cycles_adrup <= std_logic_vector(addr_target(27 downto 24));
                     end if;
                     
                  
                  when WRITING =>
                     if (dma_bus_done = '1') then
                        state <= IDLE;
                        if (count = 0) then
                           running <= '0';
                           dma_on  <= '0';

                           IRP_DMA <= iRQ_on;

                           if (Repeat = '1' and Start_Timing /= 0) then
                              waiting <= '1';
                              if (Start_Timing = 3 and (index = 1 or index = 2)) then
                                  count <= to_unsigned(4, 17);
                              else
                                 
                                 if (index = 3) then
                                    if (CNT_L(15 downto 0) = (15 downto 0 => '0')) then
                                       count <= '1' & x"0000";
                                    else
                                       count <= '0' & unsigned(CNT_L(15 downto 0));
                                    end if;  
                                 else
                                    if (CNT_L(13 downto 0) = (13 downto 0 => '0')) then
                                       count <= '0' & x"4000";
                                    else
                                       count <= "000" & unsigned(CNT_L(13 downto 0));
                                    end if;  
                                 end if;
                                 
                                 if (dest_Addr_Control = 3) then
                                    addr_target <= unsigned(DAD(27 downto 0));
                                    if (index < 3) then
                                       addr_target(27) <= '0';
                                    end if;
                                 end if;
                              end if;
                           else
                              Enable <= "0";
                           end if;
                        end if;
                     end if;
                     
                  
                  
               end case;
               
            
            end if;
         end if;
      
      end if;
   end process;
  

end architecture;


