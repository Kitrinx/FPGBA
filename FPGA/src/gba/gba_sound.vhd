library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gba.all;
use work.pReg_gba_sound.all;

entity gba_sound is
   port 
   (
      clk100              : in    std_logic;  
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z', "ZZ", "ZZZZ", 'Z');
      
      timer0_tick         : in    std_logic;
      timer1_tick         : in    std_logic;
      sound_dma_req       : out   std_logic_vector(1 downto 0);
      
      sound_out           : out   std_logic_vector(15 downto 0) := (others => '0');
      
      debug_fifocount     : out   integer
   );
end entity;

architecture arch of gba_sound is

   signal Sound_1_4_Master_Volume_RIGHT: std_logic_vector(SOUNDCNT_L_Sound_1_4_Master_Volume_RIGHT.upper downto SOUNDCNT_L_Sound_1_4_Master_Volume_RIGHT.lower) := (others => '0');
   signal Sound_1_4_Master_Volume_LEFT : std_logic_vector(SOUNDCNT_L_Sound_1_4_Master_Volume_LEFT .upper downto SOUNDCNT_L_Sound_1_4_Master_Volume_LEFT .lower) := (others => '0');
   signal Sound_1_Enable_Flags_RIGHT   : std_logic_vector(SOUNDCNT_L_Sound_1_Enable_Flags_RIGHT   .upper downto SOUNDCNT_L_Sound_1_Enable_Flags_RIGHT   .lower) := (others => '0');
   signal Sound_2_Enable_Flags_RIGHT   : std_logic_vector(SOUNDCNT_L_Sound_2_Enable_Flags_RIGHT   .upper downto SOUNDCNT_L_Sound_2_Enable_Flags_RIGHT   .lower) := (others => '0');
   signal Sound_3_Enable_Flags_RIGHT   : std_logic_vector(SOUNDCNT_L_Sound_3_Enable_Flags_RIGHT   .upper downto SOUNDCNT_L_Sound_3_Enable_Flags_RIGHT   .lower) := (others => '0');
   signal Sound_4_Enable_Flags_RIGHT   : std_logic_vector(SOUNDCNT_L_Sound_4_Enable_Flags_RIGHT   .upper downto SOUNDCNT_L_Sound_4_Enable_Flags_RIGHT   .lower) := (others => '0');
   signal Sound_1_Enable_Flags_LEFT    : std_logic_vector(SOUNDCNT_L_Sound_1_Enable_Flags_LEFT    .upper downto SOUNDCNT_L_Sound_1_Enable_Flags_LEFT    .lower) := (others => '0');
   signal Sound_2_Enable_Flags_LEFT    : std_logic_vector(SOUNDCNT_L_Sound_2_Enable_Flags_LEFT    .upper downto SOUNDCNT_L_Sound_2_Enable_Flags_LEFT    .lower) := (others => '0');
   signal Sound_3_Enable_Flags_LEFT    : std_logic_vector(SOUNDCNT_L_Sound_3_Enable_Flags_LEFT    .upper downto SOUNDCNT_L_Sound_3_Enable_Flags_LEFT    .lower) := (others => '0');
   signal Sound_4_Enable_Flags_LEFT    : std_logic_vector(SOUNDCNT_L_Sound_4_Enable_Flags_LEFT    .upper downto SOUNDCNT_L_Sound_4_Enable_Flags_LEFT    .lower) := (others => '0');
                                                                                                                
   signal Sound_1_4_Volume             : std_logic_vector(SOUNDCNT_H_Sound_1_4_Volume             .upper downto SOUNDCNT_H_Sound_1_4_Volume             .lower) := (others => '0');
   signal DMA_Sound_A_Volume           : std_logic_vector(SOUNDCNT_H_DMA_Sound_A_Volume           .upper downto SOUNDCNT_H_DMA_Sound_A_Volume           .lower) := (others => '0');
   signal DMA_Sound_B_Volume           : std_logic_vector(SOUNDCNT_H_DMA_Sound_B_Volume           .upper downto SOUNDCNT_H_DMA_Sound_B_Volume           .lower) := (others => '0');
   signal DMA_Sound_A_Enable_RIGHT     : std_logic_vector(SOUNDCNT_H_DMA_Sound_A_Enable_RIGHT     .upper downto SOUNDCNT_H_DMA_Sound_A_Enable_RIGHT     .lower) := (others => '0');
   signal DMA_Sound_A_Enable_LEFT      : std_logic_vector(SOUNDCNT_H_DMA_Sound_A_Enable_LEFT      .upper downto SOUNDCNT_H_DMA_Sound_A_Enable_LEFT      .lower) := (others => '0');
   signal DMA_Sound_A_Timer_Select     : std_logic_vector(SOUNDCNT_H_DMA_Sound_A_Timer_Select     .upper downto SOUNDCNT_H_DMA_Sound_A_Timer_Select     .lower) := (others => '0');
   signal DMA_Sound_A_Reset_FIFO       : std_logic_vector(SOUNDCNT_H_DMA_Sound_A_Reset_FIFO       .upper downto SOUNDCNT_H_DMA_Sound_A_Reset_FIFO       .lower) := (others => '0');
   signal DMA_Sound_B_Enable_RIGHT     : std_logic_vector(SOUNDCNT_H_DMA_Sound_B_Enable_RIGHT     .upper downto SOUNDCNT_H_DMA_Sound_B_Enable_RIGHT     .lower) := (others => '0');
   signal DMA_Sound_B_Enable_LEFT      : std_logic_vector(SOUNDCNT_H_DMA_Sound_B_Enable_LEFT      .upper downto SOUNDCNT_H_DMA_Sound_B_Enable_LEFT      .lower) := (others => '0');
   signal DMA_Sound_B_Timer_Select     : std_logic_vector(SOUNDCNT_H_DMA_Sound_B_Timer_Select     .upper downto SOUNDCNT_H_DMA_Sound_B_Timer_Select     .lower) := (others => '0');
   signal DMA_Sound_B_Reset_FIFO       : std_logic_vector(SOUNDCNT_H_DMA_Sound_B_Reset_FIFO       .upper downto SOUNDCNT_H_DMA_Sound_B_Reset_FIFO       .lower) := (others => '0');
                                                                                                                
   signal Sound_1_ON_flag              : std_logic_vector(SOUNDCNT_X_Sound_1_ON_flag              .upper downto SOUNDCNT_X_Sound_1_ON_flag              .lower) := (others => '0');
   signal Sound_2_ON_flag              : std_logic_vector(SOUNDCNT_X_Sound_2_ON_flag              .upper downto SOUNDCNT_X_Sound_2_ON_flag              .lower) := (others => '0');
   signal Sound_3_ON_flag              : std_logic_vector(SOUNDCNT_X_Sound_3_ON_flag              .upper downto SOUNDCNT_X_Sound_3_ON_flag              .lower) := (others => '0');
   signal Sound_4_ON_flag              : std_logic_vector(SOUNDCNT_X_Sound_4_ON_flag              .upper downto SOUNDCNT_X_Sound_4_ON_flag              .lower) := (others => '0');
   signal PSG_FIFO_Master_Enable       : std_logic_vector(SOUNDCNT_X_PSG_FIFO_Master_Enable       .upper downto SOUNDCNT_X_PSG_FIFO_Master_Enable       .lower) := (others => '0');
                                                                                                                    
   signal REG_SOUNDBIAS                : std_logic_vector(SOUNDBIAS                               .upper downto SOUNDBIAS                               .lower) := (others => '0');
               
   signal SOUNDCNT_H_DMA_written  : std_logic;

   signal new_cycles          : unsigned(7 downto 0) := (others => '0');
   signal new_cycles_slow     : unsigned(7 downto 0) := (others => '0');
   signal new_cycles_valid    : std_logic := '0';

   signal sound_out_ch1  : signed(15 downto 0);
   signal sound_out_ch2  : signed(15 downto 0);
   signal sound_out_ch3  : signed(15 downto 0);
   signal sound_out_ch4  : signed(15 downto 0);
   signal sound_out_dmaA : signed(15 downto 0);
   signal sound_out_dmaB : signed(15 downto 0);
   
   signal sound_on_ch1  : std_logic;
   signal sound_on_ch2  : std_logic;
   signal sound_on_ch3  : std_logic;
   signal sound_on_ch4  : std_logic;
   signal sound_on_dmaA : std_logic;
   signal sound_on_dmaB : std_logic;
   
   signal soundvol_leftright : integer range 0 to 15;
   
   signal soundmix1 : signed(15 downto 0) := (others => '0'); 
   signal soundmix2 : signed(15 downto 0) := (others => '0'); 
   signal soundmix3 : signed(15 downto 0) := (others => '0'); 
   signal soundmix4 : signed(15 downto 0) := (others => '0'); 
   signal soundmix5 : signed(15 downto 0) := (others => '0'); 
   signal soundmix6 : signed(15 downto 0) := (others => '0'); 
   signal soundmix7 : signed(15 downto 0) := (others => '0'); 
   
           
begin 

   iSound_1_4_Master_Volume_RIGHT : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_1_4_Master_Volume_RIGHT ) port map  (clk100, gb_bus, Sound_1_4_Master_Volume_RIGHT , Sound_1_4_Master_Volume_RIGHT );  
   iSound_1_4_Master_Volume_LEFT  : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_1_4_Master_Volume_LEFT  ) port map  (clk100, gb_bus, Sound_1_4_Master_Volume_LEFT  , Sound_1_4_Master_Volume_LEFT  );  
   iSound_1_Enable_Flags_RIGHT    : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_1_Enable_Flags_RIGHT    ) port map  (clk100, gb_bus, Sound_1_Enable_Flags_RIGHT    , Sound_1_Enable_Flags_RIGHT    );  
   iSound_2_Enable_Flags_RIGHT    : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_2_Enable_Flags_RIGHT    ) port map  (clk100, gb_bus, Sound_2_Enable_Flags_RIGHT    , Sound_2_Enable_Flags_RIGHT    );  
   iSound_3_Enable_Flags_RIGHT    : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_3_Enable_Flags_RIGHT    ) port map  (clk100, gb_bus, Sound_3_Enable_Flags_RIGHT    , Sound_3_Enable_Flags_RIGHT    );  
   iSound_4_Enable_Flags_RIGHT    : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_4_Enable_Flags_RIGHT    ) port map  (clk100, gb_bus, Sound_4_Enable_Flags_RIGHT    , Sound_4_Enable_Flags_RIGHT    );  
   iSound_1_Enable_Flags_LEFT     : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_1_Enable_Flags_LEFT     ) port map  (clk100, gb_bus, Sound_1_Enable_Flags_LEFT     , Sound_1_Enable_Flags_LEFT     );  
   iSound_2_Enable_Flags_LEFT     : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_2_Enable_Flags_LEFT     ) port map  (clk100, gb_bus, Sound_2_Enable_Flags_LEFT     , Sound_2_Enable_Flags_LEFT     );  
   iSound_3_Enable_Flags_LEFT     : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_3_Enable_Flags_LEFT     ) port map  (clk100, gb_bus, Sound_3_Enable_Flags_LEFT     , Sound_3_Enable_Flags_LEFT     );  
   iSound_4_Enable_Flags_LEFT     : entity work.eProcReg_gba generic map ( SOUNDCNT_L_Sound_4_Enable_Flags_LEFT     ) port map  (clk100, gb_bus, Sound_4_Enable_Flags_LEFT     , Sound_4_Enable_Flags_LEFT     );  
                                                                                                                                                                                                         
   iSound_1_4_Volume              : entity work.eProcReg_gba generic map ( SOUNDCNT_H_Sound_1_4_Volume              ) port map  (clk100, gb_bus, Sound_1_4_Volume              , Sound_1_4_Volume              );  
   iDMA_Sound_A_Volume            : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_A_Volume            ) port map  (clk100, gb_bus, DMA_Sound_A_Volume            , DMA_Sound_A_Volume            );  
   iDMA_Sound_B_Volume            : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_B_Volume            ) port map  (clk100, gb_bus, DMA_Sound_B_Volume            , DMA_Sound_B_Volume            );  
   iDMA_Sound_A_Enable_RIGHT      : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_A_Enable_RIGHT      ) port map  (clk100, gb_bus, DMA_Sound_A_Enable_RIGHT      , DMA_Sound_A_Enable_RIGHT      , SOUNDCNT_H_DMA_written);  
   iDMA_Sound_A_Enable_LEFT       : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_A_Enable_LEFT       ) port map  (clk100, gb_bus, DMA_Sound_A_Enable_LEFT       , DMA_Sound_A_Enable_LEFT       );  
   iDMA_Sound_A_Timer_Select      : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_A_Timer_Select      ) port map  (clk100, gb_bus, DMA_Sound_A_Timer_Select      , DMA_Sound_A_Timer_Select      );  
   iDMA_Sound_A_Reset_FIFO        : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_A_Reset_FIFO        ) port map  (clk100, gb_bus, "0"                           , DMA_Sound_A_Reset_FIFO        );  
   iDMA_Sound_B_Enable_RIGHT      : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_B_Enable_RIGHT      ) port map  (clk100, gb_bus, DMA_Sound_B_Enable_RIGHT      , DMA_Sound_B_Enable_RIGHT      );  
   iDMA_Sound_B_Enable_LEFT       : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_B_Enable_LEFT       ) port map  (clk100, gb_bus, DMA_Sound_B_Enable_LEFT       , DMA_Sound_B_Enable_LEFT       );  
   iDMA_Sound_B_Timer_Select      : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_B_Timer_Select      ) port map  (clk100, gb_bus, DMA_Sound_B_Timer_Select      , DMA_Sound_B_Timer_Select      );  
   iDMA_Sound_B_Reset_FIFO        : entity work.eProcReg_gba generic map ( SOUNDCNT_H_DMA_Sound_B_Reset_FIFO        ) port map  (clk100, gb_bus, "0"                           , DMA_Sound_B_Reset_FIFO        );  
                                                                                                                                                                                                         
   iSound_1_ON_flag               : entity work.eProcReg_gba generic map ( SOUNDCNT_X_Sound_1_ON_flag               ) port map  (clk100, gb_bus, Sound_1_ON_flag);  
   iSound_2_ON_flag               : entity work.eProcReg_gba generic map ( SOUNDCNT_X_Sound_2_ON_flag               ) port map  (clk100, gb_bus, Sound_2_ON_flag);  
   iSound_3_ON_flag               : entity work.eProcReg_gba generic map ( SOUNDCNT_X_Sound_3_ON_flag               ) port map  (clk100, gb_bus, Sound_3_ON_flag);  
   iSound_4_ON_flag               : entity work.eProcReg_gba generic map ( SOUNDCNT_X_Sound_4_ON_flag               ) port map  (clk100, gb_bus, Sound_4_ON_flag);  
   iPSG_FIFO_Master_Enable        : entity work.eProcReg_gba generic map ( SOUNDCNT_X_PSG_FIFO_Master_Enable        ) port map  (clk100, gb_bus, PSG_FIFO_Master_Enable        , PSG_FIFO_Master_Enable        );  
                                                        
   iREG_SOUNDBIAS                 : entity work.eProcReg_gba generic map ( SOUNDBIAS                                ) port map  (clk100, gb_bus, REG_SOUNDBIAS                 , REG_SOUNDBIAS                 );  
                                                        
   iSOUNDCNT_XHighZero            : entity work.eProcReg_gba generic map ( SOUNDCNT_XHighZero                       ) port map  (clk100, gb_bus, x"0000");  
   iSOUNDBIAS_HighZero            : entity work.eProcReg_gba generic map ( SOUNDBIAS_HighZero                       ) port map  (clk100, gb_bus, x"0000");  


   Sound_1_ON_flag(Sound_1_ON_flag'right) <= '1' when sound_on_ch1 = '1' and (Sound_1_Enable_Flags_LEFT = "1" or Sound_1_Enable_Flags_RIGHT = "1") else '0';
   Sound_2_ON_flag(Sound_2_ON_flag'right) <= '1' when sound_on_ch2 = '1' and (Sound_2_Enable_Flags_LEFT = "1" or Sound_2_Enable_Flags_RIGHT = "1") else '0';
   Sound_3_ON_flag(Sound_3_ON_flag'right) <= '1' when sound_on_ch3 = '1' and (Sound_3_Enable_Flags_LEFT = "1" or Sound_3_Enable_Flags_RIGHT = "1") else '0';
   Sound_4_ON_flag(Sound_4_ON_flag'right) <= '1' when sound_on_ch4 = '1' and (Sound_4_Enable_Flags_LEFT = "1" or Sound_4_Enable_Flags_RIGHT = "1") else '0';
    
   igba_sound_ch1 : entity work.gba_sound_ch1
   generic map
   (
      has_sweep                      => true,
      Reg_Number_of_sweep_shift      => SOUND1CNT_L_Number_of_sweep_shift    ,
      Reg_Sweep_Frequency_Direction  => SOUND1CNT_L_Sweep_Frequency_Direction,
      Reg_Sweep_Time                 => SOUND1CNT_L_Sweep_Time               ,
      Reg_Sound_length               => SOUND1CNT_H_Sound_length              ,
      Reg_Wave_Pattern_Duty          => SOUND1CNT_H_Wave_Pattern_Duty         ,
      Reg_Envelope_Step_Time         => SOUND1CNT_H_Envelope_Step_Time        ,
      Reg_Envelope_Direction         => SOUND1CNT_H_Envelope_Direction        ,
      Reg_Initial_Volume_of_envelope => SOUND1CNT_H_Initial_Volume_of_envelope,
      Reg_Frequency                  => SOUND1CNT_X_Frequency  ,
      Reg_Length_Flag                => SOUND1CNT_X_Length_Flag,
      Reg_Initial                    => SOUND1CNT_X_Initial    ,
      Reg_HighZero                   => SOUND1CNT_XHighZero
   )
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch1,
      sound_on         => sound_on_ch1 
   );
   
   igba_sound_ch2 : entity work.gba_sound_ch1
   generic map
   (
      has_sweep                      => false,
      Reg_Number_of_sweep_shift      => SOUND1CNT_L_Number_of_sweep_shift    ,  -- unused
      Reg_Sweep_Frequency_Direction  => SOUND1CNT_L_Sweep_Frequency_Direction,  -- unused
      Reg_Sweep_Time                 => SOUND1CNT_L_Sweep_Time               ,  -- unused
      Reg_Sound_length               => SOUND2CNT_L_Sound_length              ,
      Reg_Wave_Pattern_Duty          => SOUND2CNT_L_Wave_Pattern_Duty         ,
      Reg_Envelope_Step_Time         => SOUND2CNT_L_Envelope_Step_Time        ,
      Reg_Envelope_Direction         => SOUND2CNT_L_Envelope_Direction        ,
      Reg_Initial_Volume_of_envelope => SOUND2CNT_L_Initial_Volume_of_envelope,
      Reg_Frequency                  => SOUND2CNT_H_Frequency  ,
      Reg_Length_Flag                => SOUND2CNT_H_Length_Flag,
      Reg_Initial                    => SOUND2CNT_H_Initial    ,
      Reg_HighZero                   => SOUND2CNT_HHighZero
   )
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch2,
      sound_on         => sound_on_ch2 
   );
   
   igba_sound_ch3 : entity work.gba_sound_ch3
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch3,
      sound_on         => sound_on_ch3 
   );
   
   igba_sound_ch4 : entity work.gba_sound_ch4
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch4,
      sound_on         => sound_on_ch4 
   );
   
   igba_sound_dmaA : entity work.gba_sound_dma
   generic map
   (
      REG_FIFO            => FIFO_A
   )
   port map
   (
      clk100              => clk100,
      gb_bus              => gb_bus,
                           
      settings_new        => SOUNDCNT_H_DMA_written,
      Enable_RIGHT        => DMA_Sound_A_Enable_RIGHT(DMA_Sound_A_Enable_RIGHT'left),
      Enable_LEFT         => DMA_Sound_A_Enable_LEFT(DMA_Sound_A_Enable_LEFT'left), 
      Timer_Select        => DMA_Sound_A_Timer_Select(DMA_Sound_A_Timer_Select'left),
      Reset_FIFO          => DMA_Sound_A_Reset_FIFO(DMA_Sound_A_Reset_FIFO'left),  
      volume_high         => DMA_Sound_A_Volume(DMA_Sound_A_Volume'left),  
      
      timer0_tick         => timer0_tick,
      timer1_tick         => timer1_tick,
      dma_req             => sound_dma_req(0),
                           
      sound_out           => sound_out_dmaA,
      sound_on            => sound_on_dmaA,
      
      debug_fifocount     => debug_fifocount
   );
   
   igba_sound_dmaB : entity work.gba_sound_dma
   generic map
   (
      REG_FIFO            => FIFO_B
   )
   port map
   (
      clk100              => clk100,
      gb_bus              => gb_bus,
                           
      settings_new        => SOUNDCNT_H_DMA_written,
      Enable_RIGHT        => DMA_Sound_B_Enable_RIGHT(DMA_Sound_B_Enable_RIGHT'left),
      Enable_LEFT         => DMA_Sound_B_Enable_LEFT(DMA_Sound_B_Enable_LEFT'left), 
      Timer_Select        => DMA_Sound_B_Timer_Select(DMA_Sound_B_Timer_Select'left),
      Reset_FIFO          => DMA_Sound_B_Reset_FIFO(DMA_Sound_B_Reset_FIFO'left),  
      volume_high         => DMA_Sound_B_Volume(DMA_Sound_B_Volume'left),
                           
      timer0_tick         => timer0_tick,
      timer1_tick         => timer1_tick,
      dma_req             => sound_dma_req(1),
                           
      sound_out           => sound_out_dmaB,
      sound_on            => sound_on_dmaB,
      
      debug_fifocount     => open
   );
   
   new_cycles <= x"04";
   
   -- todo: stereo
   -- todo : volume_left/right
   process (clk100)
   begin
      if rising_edge(clk100) then
         
         -- generate exact timing, cannot use gameboy time
         new_cycles_valid <= '0';
                
         if (new_cycles_slow < 99) then
            new_cycles_slow <= new_cycles_slow + 1;
         else
            new_cycles_slow  <= (others => '0');
            new_cycles_valid <= '1';
         end if;
         
         -- sound channel mixing
         if (sound_on_ch1 = '1' and (Sound_1_Enable_Flags_LEFT = "1" or Sound_1_Enable_Flags_RIGHT = "1")) then
            soundmix1 <= sound_out_ch1;
         else
            soundmix1 <= (others => '0');
         end if;
         
         if (sound_on_ch2 = '1' and (Sound_2_Enable_Flags_LEFT = "1" or Sound_2_Enable_Flags_RIGHT = "1")) then
            soundmix2 <= soundmix1 + sound_out_ch2;
         else
            soundmix2 <= soundmix1;
         end if;
         
         if (sound_on_ch3 = '1' and (Sound_3_Enable_Flags_LEFT = "1" or Sound_3_Enable_Flags_RIGHT = "1")) then
            soundmix3 <= soundmix2 + sound_out_ch3;
         else
            soundmix3 <= soundmix2;
         end if;
         
         if (sound_on_ch4 = '1' and (Sound_4_Enable_Flags_LEFT = "1" or Sound_4_Enable_Flags_RIGHT = "1")) then
            soundmix4 <= soundmix3 + sound_out_ch4;
         else
            soundmix4 <= soundmix3;
         end if;
         
         soundvol_leftright <= to_integer(unsigned(Sound_1_4_Master_Volume_LEFT)) + to_integer(unsigned(Sound_1_4_Master_Volume_RIGHT));
         
         case (to_integer(unsigned(Sound_1_4_Volume))) is
             when 0     => soundmix5 <= resize((soundmix4 * soundvol_leftright) / 64, 16);
             when 1     => soundmix5 <= resize((soundmix4 * soundvol_leftright) / 32, 16);
             when 2     => soundmix5 <= resize((soundmix4 * soundvol_leftright) / 16, 16);
             when 3     => soundmix5 <= (others => '0'); -- +3 is not allowed
             when others => null;
         end case;

         if (sound_on_dmaA = '1') then
            soundmix6 <= soundmix5 + sound_out_dmaA;
         else
            soundmix6 <= soundmix5;
         end if;
         
         if (sound_on_dmaB = '1') then
            soundmix7 <= soundmix6 + sound_out_dmaB;
         else
            soundmix7 <= soundmix6;
         end if;
         
         if (PSG_FIFO_Master_Enable = "1") then -- should usually reset all sound registers
            sound_out <= std_logic_vector(soundmix7);
         else
            sound_out <= (others => '0');
         end if;
      
      end if;
   end process;
    
end architecture;


 
 