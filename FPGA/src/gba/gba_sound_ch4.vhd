library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegmap_gba.all;
use work.pProc_bus_gba.all;
use work.pReg_gba_sound.all;

entity gba_sound_ch4 is
   port 
   (
      clk100              : in    std_logic;  
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z', "ZZ", "ZZZZ", 'Z');
      
      new_cycles          : in    unsigned(7 downto 0);
      new_cycles_valid    : in    std_logic;
      
      sound_out           : out   signed(15 downto 0) := (others => '0');
      sound_on            : out   std_logic := '0'
   );
end entity;

architecture arch of gba_sound_ch4 is
   

   signal REG_Sound_length               : std_logic_vector(SOUND4CNT_L_Sound_length              .upper downto SOUND4CNT_L_Sound_length              .lower) := (others => '0');    
   signal REG_Envelope_Step_Time         : std_logic_vector(SOUND4CNT_L_Envelope_Step_Time        .upper downto SOUND4CNT_L_Envelope_Step_Time        .lower) := (others => '0');    
   signal REG_Envelope_Direction         : std_logic_vector(SOUND4CNT_L_Envelope_Direction        .upper downto SOUND4CNT_L_Envelope_Direction        .lower) := (others => '0');    
   signal REG_Initial_Volume_of_envelope : std_logic_vector(SOUND4CNT_L_Initial_Volume_of_envelope.upper downto SOUND4CNT_L_Initial_Volume_of_envelope.lower) := (others => '0');

   signal REG_Dividing_Ratio_of_Freq     : std_logic_vector(SOUND4CNT_H_Dividing_Ratio_of_Freq    .upper downto SOUND4CNT_H_Dividing_Ratio_of_Freq    .lower) := (others => '0');    
   signal REG_Counter_Step_Width         : std_logic_vector(SOUND4CNT_H_Counter_Step_Width        .upper downto SOUND4CNT_H_Counter_Step_Width        .lower) := (others => '0');    
   signal REG_Shift_Clock_Frequency      : std_logic_vector(SOUND4CNT_H_Shift_Clock_Frequency     .upper downto SOUND4CNT_H_Shift_Clock_Frequency     .lower) := (others => '0');    
   signal REG_Length_Flag                : std_logic_vector(SOUND4CNT_H_Length_Flag               .upper downto SOUND4CNT_H_Length_Flag               .lower) := (others => '0');    
   signal REG_Initial                    : std_logic_vector(SOUND4CNT_H_Initial                   .upper downto SOUND4CNT_H_Initial                   .lower) := (others => '0');    
                  
                 
   signal Sound_length_written               : std_logic;
   signal Envelope_Step_Time_written         : std_logic;
   signal Envelope_Direction_written         : std_logic;
   signal Initial_Volume_of_envelope_written : std_logic; 
          
   signal Dividing_Ratio_of_Freq_written     : std_logic;                                                                                                                                                      
   signal Counter_Step_Width_written         : std_logic;                                                                                                                                                      
   signal Shift_Clock_Frequency_written      : std_logic;                                                                                                                                                      
   signal Length_Flag_written                : std_logic;                                                                                                                                                      
   signal Initial_written                    : std_logic;                                                                                                                                                      
          
   signal length_left   : unsigned(6 downto 0) := (others => '0');
                        
   signal envelope_cnt  : unsigned(5 downto 0) := (others => '0');
   signal envelope_add  : unsigned(5 downto 0) := (others => '0');
                        
   signal volume        : integer range 0 to 15 := 0;
   signal wave_on       : std_logic := '0';      
                        
   signal divider_raw   : unsigned(23 downto 0) := (others => '0');
   signal freq_divider  : unsigned(23 downto 0) := (others => '0');
   signal length_on     : std_logic := '0';
   signal ch_on         : std_logic := '0';
   
   signal lfsr7bit      : std_logic := '0';
   signal lfsr          : std_logic_vector(14 downto 0) := (others => '0');
   
   signal soundcycles_freq     : unsigned(23 downto 0)  := (others => '0');
   signal soundcycles_envelope : unsigned(17 downto 0) := (others => '0');
   signal soundcycles_length   : unsigned(16 downto 0) := (others => '0');
   
begin 

   iREG_Sound_length               : entity work.eProcReg_gba generic map ( SOUND4CNT_L_Sound_length               ) port map  (clk100, gb_bus, "000000"                       , REG_Sound_length               , Sound_length_written               );  
   iREG_Envelope_Step_Time         : entity work.eProcReg_gba generic map ( SOUND4CNT_L_Envelope_Step_Time         ) port map  (clk100, gb_bus, REG_Envelope_Step_Time         , REG_Envelope_Step_Time         , Envelope_Step_Time_written         );  
   iREG_Envelope_Direction         : entity work.eProcReg_gba generic map ( SOUND4CNT_L_Envelope_Direction         ) port map  (clk100, gb_bus, REG_Envelope_Direction         , REG_Envelope_Direction         , Envelope_Direction_written         );  
   iREG_Initial_Volume_of_envelope : entity work.eProcReg_gba generic map ( SOUND4CNT_L_Initial_Volume_of_envelope ) port map  (clk100, gb_bus, REG_Initial_Volume_of_envelope , REG_Initial_Volume_of_envelope , Initial_Volume_of_envelope_written ); 
                                                                                                                                                                        
   iREG_Dividing_Ratio_of_Freq     : entity work.eProcReg_gba generic map ( SOUND4CNT_H_Dividing_Ratio_of_Freq     ) port map  (clk100, gb_bus, REG_Dividing_Ratio_of_Freq     , REG_Dividing_Ratio_of_Freq     , Dividing_Ratio_of_Freq_written     );  
   iREG_Counter_Step_Width         : entity work.eProcReg_gba generic map ( SOUND4CNT_H_Counter_Step_Width         ) port map  (clk100, gb_bus, REG_Counter_Step_Width         , REG_Counter_Step_Width         , Counter_Step_Width_written         );  
   iREG_Shift_Clock_Frequency      : entity work.eProcReg_gba generic map ( SOUND4CNT_H_Shift_Clock_Frequency      ) port map  (clk100, gb_bus, REG_Shift_Clock_Frequency      , REG_Shift_Clock_Frequency      , Shift_Clock_Frequency_written      );  
   iREG_Length_Flag                : entity work.eProcReg_gba generic map ( SOUND4CNT_H_Length_Flag                ) port map  (clk100, gb_bus, REG_Length_Flag                , REG_Length_Flag                , Length_Flag_written                );  
   iREG_Initial                    : entity work.eProcReg_gba generic map ( SOUND4CNT_H_Initial                    ) port map  (clk100, gb_bus, "0"                            , REG_Initial                    , Initial_written                    );  
   
   iSOUND4CNT_LHighZero            : entity work.eProcReg_gba generic map ( SOUND4CNT_LHighZero                    ) port map  (clk100, gb_bus, x"0000");  
   iSOUND4CNT_HHighZero            : entity work.eProcReg_gba generic map ( SOUND4CNT_HHighZero                    ) port map  (clk100, gb_bus, x"0000");  
        
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         -- register write triggers
         if (Sound_length_written = '1') then
            length_left <= to_unsigned(64, 7) - unsigned(REG_Sound_length);
         end if;
         
         if (Initial_Volume_of_envelope_written = '1') then
            envelope_cnt <= (others => '0');
            envelope_add <= (others => '0');
            volume       <= to_integer(unsigned(REG_Initial_Volume_of_envelope));
         end if;
         
         if (Dividing_Ratio_of_Freq_written = '1') then
            case to_integer(unsigned(REG_Dividing_Ratio_of_Freq)) is
               when 0 => divider_raw <= to_unsigned(  8, divider_raw'length);
               when 1 => divider_raw <= to_unsigned( 16, divider_raw'length);
               when 2 => divider_raw <= to_unsigned( 32, divider_raw'length);
               when 3 => divider_raw <= to_unsigned( 48, divider_raw'length);
               when 4 => divider_raw <= to_unsigned( 64, divider_raw'length);
               when 5 => divider_raw <= to_unsigned( 80, divider_raw'length);
               when 6 => divider_raw <= to_unsigned( 96, divider_raw'length);
               when 7 => divider_raw <= to_unsigned(112, divider_raw'length);
               when others => null;
            end case;
            
            lfsr7bit <= REG_Counter_Step_Width(REG_Counter_Step_Width'left);
            
         end if;
         freq_divider <= divider_raw sll to_integer(unsigned(REG_Shift_Clock_Frequency));
         
         if (Initial_written = '1') then
            length_on <= REG_Length_Flag(REG_Length_Flag'left);
            if (REG_Initial = "1") then
               envelope_cnt <= (others => '0');
               envelope_add <= (others => '0');
               ch_on        <= '1';
               
               lfsr <= (others => '0');
               if (REG_Counter_Step_Width = "1") then
                  lfsr(6) <= '1';
               else
                  lfsr(14) <= '1';
               end if;
            end if;
         end if;
         
         -- cpu cycle trigger
         if (new_cycles_valid = '1') then
            soundcycles_freq     <= soundcycles_freq     + new_cycles;
            soundcycles_envelope <= soundcycles_envelope + new_cycles;
            soundcycles_length   <= soundcycles_length   + new_cycles;
         end if;
         
         -- freq / wavetable
         if (soundcycles_freq >= freq_divider) then
            soundcycles_freq <= soundcycles_freq - freq_divider;
            wave_on <= not lfsr(0);
            if (lfsr7bit = '1') then
               lfsr <= x"00" & (lfsr(1) xor lfsr(0)) & lfsr(6 downto 1);
            else
               lfsr <= (lfsr(1) xor lfsr(0)) & lfsr(14 downto 1);
            end if;
         end if;
         
         -- envelope
         if (soundcycles_envelope >= 65536) then -- 64 Hz
            soundcycles_envelope <= soundcycles_envelope - 65536;
            if (REG_Envelope_Step_Time /= "000") then
               envelope_cnt <= envelope_cnt + 1;
            end if;
         end if;
         
         if (REG_Envelope_Step_Time /= "000") then
            if (envelope_cnt >= unsigned(REG_Envelope_Step_Time)) then
               envelope_cnt <= (others => '0');
               if (envelope_add < 15) then
                  envelope_add <= envelope_add + 1;
               end if;
            end if;
            
            if (REG_Envelope_Direction = "0") then -- decrease
               if (unsigned(REG_Initial_Volume_of_envelope) >= envelope_add) then
                  volume <= to_integer(unsigned(REG_Initial_Volume_of_envelope)) - to_integer(envelope_add);
               else
                  volume <= 0;
               end if;
            else
               if (unsigned(REG_Initial_Volume_of_envelope) + envelope_add <= 15) then
                  volume <= to_integer(unsigned(REG_Initial_Volume_of_envelope)) + to_integer(envelope_add);
               else
                  volume <= 15;
               end if;
            end if;
         end if;
      
         -- length
         if (soundcycles_length >= 16384) then -- 256 Hz
            soundcycles_length <= soundcycles_length - 16384;
            if (length_left > 0 and length_on = '1') then
               length_left <= length_left - 1;
               if (length_left = 1) then
                  ch_on <= '0';
               end if;
            end if;
         end if;
        
         -- sound out
         if (ch_on = '1') then
            if (wave_on = '1') then
               sound_out <= to_signed(128 * volume, 16);
            else
               sound_out <= to_signed(-128 * volume, 16);
            end if;
         else
            sound_out <= (others => '0');
         end if;
      
         sound_on <= ch_on;
      
      end if;
   end process;
  

end architecture;





