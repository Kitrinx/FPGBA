library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;  

library MEM;

use work.pProc_bus_gba.all;
use work.pReg_gba_display.all;

entity gba_gpu_drawer is
   port 
   (
      clk100               : in  std_logic; 
      
      gb_bus               : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z', "ZZ", "ZZZZ", 'Z');                  
        
      pixel_out_addr       : out   integer range 0 to 38399;
      pixel_out_data       : out   std_logic_vector(14 downto 0);  
      pixel_out_we         : out   std_logic := '0';
                           
      linecounter          : in    unsigned(7 downto 0);
      drawline             : in    std_logic;
      refpoint_update      : in    std_logic;
      hblank_trigger       : in    std_logic;
      vblank_trigger       : in    std_logic;
      
      VRAM_Lo_addr         : in    integer range 0 to 16383;
      VRAM_Lo_datain       : in    std_logic_vector(31 downto 0);
      VRAM_Lo_dataout      : out   std_logic_vector(31 downto 0);
      VRAM_Lo_we           : in    std_logic_vector(3 downto 0);
      VRAM_Hi_addr         : in    integer range 0 to 8191;
      VRAM_Hi_datain       : in    std_logic_vector(31 downto 0);
      VRAM_Hi_dataout      : out   std_logic_vector(31 downto 0);
      VRAM_Hi_we           : in    std_logic_vector(3 downto 0);
                           
      OAMRAM_PROC_addr     : in    integer range 0 to 255;
      OAMRAM_PROC_datain   : in    std_logic_vector(31 downto 0);
      OAMRAM_PROC_dataout  : out   std_logic_vector(31 downto 0);
      OAMRAM_PROC_we       : in    std_logic_vector(3 downto 0);
                                    
      PALETTE_BG_addr      : in    integer range 0 to 128;
      PALETTE_BG_datain    : in    std_logic_vector(31 downto 0);
      PALETTE_BG_dataout   : out   std_logic_vector(31 downto 0);
      PALETTE_BG_we        : in    std_logic_vector(3 downto 0);
      PALETTE_OAM_addr     : in    integer range 0 to 128;
      PALETTE_OAM_datain   : in    std_logic_vector(31 downto 0);
      PALETTE_OAM_dataout  : out   std_logic_vector(31 downto 0);
      PALETTE_OAM_we       : in    std_logic_vector(3 downto 0)
   );
end entity;

architecture arch of gba_gpu_drawer is
   
   signal BG_Mode                           : std_logic_vector(DISPCNT_BG_Mode              .upper downto DISPCNT_BG_Mode              .lower) := (others => '0');
   signal REG_DISPCNT_Reserved_CGB_Mode     : std_logic_vector(DISPCNT_Reserved_CGB_Mode    .upper downto DISPCNT_Reserved_CGB_Mode    .lower) := (others => '0');
   signal REG_DISPCNT_Display_Frame_Select  : std_logic_vector(DISPCNT_Display_Frame_Select .upper downto DISPCNT_Display_Frame_Select .lower) := (others => '0');
   signal REG_DISPCNT_H_Blank_IntervalFree  : std_logic_vector(DISPCNT_H_Blank_IntervalFree .upper downto DISPCNT_H_Blank_IntervalFree .lower) := (others => '0');
   signal REG_DISPCNT_OBJ_Char_VRAM_Map     : std_logic_vector(DISPCNT_OBJ_Char_VRAM_Map    .upper downto DISPCNT_OBJ_Char_VRAM_Map    .lower) := (others => '0');
   signal Forced_Blank                      : std_logic_vector(DISPCNT_Forced_Blank         .upper downto DISPCNT_Forced_Blank         .lower) := (others => '0');
   signal Screen_Display_BG0                : std_logic_vector(DISPCNT_Screen_Display_BG0   .upper downto DISPCNT_Screen_Display_BG0   .lower) := (others => '0');
   signal Screen_Display_BG1                : std_logic_vector(DISPCNT_Screen_Display_BG1   .upper downto DISPCNT_Screen_Display_BG1   .lower) := (others => '0');
   signal Screen_Display_BG2                : std_logic_vector(DISPCNT_Screen_Display_BG2   .upper downto DISPCNT_Screen_Display_BG2   .lower) := (others => '0');
   signal Screen_Display_BG3                : std_logic_vector(DISPCNT_Screen_Display_BG3   .upper downto DISPCNT_Screen_Display_BG3   .lower) := (others => '0');
   signal Screen_Display_OBJ                : std_logic_vector(DISPCNT_Screen_Display_OBJ   .upper downto DISPCNT_Screen_Display_OBJ   .lower) := (others => '0');
   signal REG_DISPCNT_Window_0_Display_Flag : std_logic_vector(DISPCNT_Window_0_Display_Flag.upper downto DISPCNT_Window_0_Display_Flag.lower) := (others => '0');
   signal REG_DISPCNT_Window_1_Display_Flag : std_logic_vector(DISPCNT_Window_1_Display_Flag.upper downto DISPCNT_Window_1_Display_Flag.lower) := (others => '0');
   signal REG_DISPCNT_OBJ_Wnd_Display_Flag  : std_logic_vector(DISPCNT_OBJ_Wnd_Display_Flag .upper downto DISPCNT_OBJ_Wnd_Display_Flag .lower) := (others => '0');
   signal REG_GREENSWAP                     : std_logic_vector(GREENSWAP                    .upper downto GREENSWAP                    .lower) := (others => '0');

   signal REG_BG0CNT_BG_Priority            : std_logic_vector(BG0CNT_BG_Priority           .upper downto BG0CNT_BG_Priority           .lower) := (others => '0');
   signal REG_BG0CNT_Character_Base_Block   : std_logic_vector(BG0CNT_Character_Base_Block  .upper downto BG0CNT_Character_Base_Block  .lower) := (others => '0');
   signal REG_BG0CNT_UNUSED_4_5             : std_logic_vector(BG0CNT_UNUSED_4_5            .upper downto BG0CNT_UNUSED_4_5            .lower) := (others => '0');
   signal REG_BG0CNT_Mosaic                 : std_logic_vector(BG0CNT_Mosaic                .upper downto BG0CNT_Mosaic                .lower) := (others => '0');
   signal REG_BG0CNT_Colors_Palettes        : std_logic_vector(BG0CNT_Colors_Palettes       .upper downto BG0CNT_Colors_Palettes       .lower) := (others => '0');
   signal REG_BG0CNT_Screen_Base_Block      : std_logic_vector(BG0CNT_Screen_Base_Block     .upper downto BG0CNT_Screen_Base_Block     .lower) := (others => '0');
   signal REG_BG0CNT_Screen_Size            : std_logic_vector(BG0CNT_Screen_Size           .upper downto BG0CNT_Screen_Size           .lower) := (others => '0');
                                                                             
   signal REG_BG1CNT_BG_Priority            : std_logic_vector(BG1CNT_BG_Priority           .upper downto BG1CNT_BG_Priority           .lower) := (others => '0');
   signal REG_BG1CNT_Character_Base_Block   : std_logic_vector(BG1CNT_Character_Base_Block  .upper downto BG1CNT_Character_Base_Block  .lower) := (others => '0');
   signal REG_BG1CNT_UNUSED_4_5             : std_logic_vector(BG1CNT_UNUSED_4_5            .upper downto BG1CNT_UNUSED_4_5            .lower) := (others => '0');
   signal REG_BG1CNT_Mosaic                 : std_logic_vector(BG1CNT_Mosaic                .upper downto BG1CNT_Mosaic                .lower) := (others => '0');
   signal REG_BG1CNT_Colors_Palettes        : std_logic_vector(BG1CNT_Colors_Palettes       .upper downto BG1CNT_Colors_Palettes       .lower) := (others => '0');
   signal REG_BG1CNT_Screen_Base_Block      : std_logic_vector(BG1CNT_Screen_Base_Block     .upper downto BG1CNT_Screen_Base_Block     .lower) := (others => '0');
   signal REG_BG1CNT_Screen_Size            : std_logic_vector(BG1CNT_Screen_Size           .upper downto BG1CNT_Screen_Size           .lower) := (others => '0');
                                                                             
   signal REG_BG2CNT_BG_Priority            : std_logic_vector(BG2CNT_BG_Priority           .upper downto BG2CNT_BG_Priority           .lower) := (others => '0');
   signal REG_BG2CNT_Character_Base_Block   : std_logic_vector(BG2CNT_Character_Base_Block  .upper downto BG2CNT_Character_Base_Block  .lower) := (others => '0');
   signal REG_BG2CNT_UNUSED_4_5             : std_logic_vector(BG2CNT_UNUSED_4_5            .upper downto BG2CNT_UNUSED_4_5            .lower) := (others => '0');
   signal REG_BG2CNT_Mosaic                 : std_logic_vector(BG2CNT_Mosaic                .upper downto BG2CNT_Mosaic                .lower) := (others => '0');
   signal REG_BG2CNT_Colors_Palettes        : std_logic_vector(BG2CNT_Colors_Palettes       .upper downto BG2CNT_Colors_Palettes       .lower) := (others => '0');
   signal REG_BG2CNT_Screen_Base_Block      : std_logic_vector(BG2CNT_Screen_Base_Block     .upper downto BG2CNT_Screen_Base_Block     .lower) := (others => '0');
   signal REG_BG2CNT_Display_Area_Overflow  : std_logic_vector(BG2CNT_Display_Area_Overflow .upper downto BG2CNT_Display_Area_Overflow .lower) := (others => '0');
   signal REG_BG2CNT_Screen_Size            : std_logic_vector(BG2CNT_Screen_Size           .upper downto BG2CNT_Screen_Size           .lower) := (others => '0');
                                                                             
   signal REG_BG3CNT_BG_Priority            : std_logic_vector(BG3CNT_BG_Priority           .upper downto BG3CNT_BG_Priority           .lower) := (others => '0');
   signal REG_BG3CNT_Character_Base_Block   : std_logic_vector(BG3CNT_Character_Base_Block  .upper downto BG3CNT_Character_Base_Block  .lower) := (others => '0');
   signal REG_BG3CNT_UNUSED_4_5             : std_logic_vector(BG3CNT_UNUSED_4_5            .upper downto BG3CNT_UNUSED_4_5            .lower) := (others => '0');
   signal REG_BG3CNT_Mosaic                 : std_logic_vector(BG3CNT_Mosaic                .upper downto BG3CNT_Mosaic                .lower) := (others => '0');
   signal REG_BG3CNT_Colors_Palettes        : std_logic_vector(BG3CNT_Colors_Palettes       .upper downto BG3CNT_Colors_Palettes       .lower) := (others => '0');
   signal REG_BG3CNT_Screen_Base_Block      : std_logic_vector(BG3CNT_Screen_Base_Block     .upper downto BG3CNT_Screen_Base_Block     .lower) := (others => '0');
   signal REG_BG3CNT_Display_Area_Overflow  : std_logic_vector(BG3CNT_Display_Area_Overflow .upper downto BG3CNT_Display_Area_Overflow .lower) := (others => '0');
   signal REG_BG3CNT_Screen_Size            : std_logic_vector(BG3CNT_Screen_Size           .upper downto BG3CNT_Screen_Size           .lower) := (others => '0');
                                                                             
   signal REG_BG0HOFS                       : std_logic_vector(BG0HOFS                      .upper downto BG0HOFS                      .lower) := (others => '0');
   signal REG_BG0VOFS                       : std_logic_vector(BG0VOFS                      .upper downto BG0VOFS                      .lower) := (others => '0');
   signal REG_BG1HOFS                       : std_logic_vector(BG1HOFS                      .upper downto BG1HOFS                      .lower) := (others => '0');
   signal REG_BG1VOFS                       : std_logic_vector(BG1VOFS                      .upper downto BG1VOFS                      .lower) := (others => '0');
   signal REG_BG2HOFS                       : std_logic_vector(BG2HOFS                      .upper downto BG2HOFS                      .lower) := (others => '0');
   signal REG_BG2VOFS                       : std_logic_vector(BG2VOFS                      .upper downto BG2VOFS                      .lower) := (others => '0');
   signal REG_BG3HOFS                       : std_logic_vector(BG3HOFS                      .upper downto BG3HOFS                      .lower) := (others => '0');
   signal REG_BG3VOFS                       : std_logic_vector(BG3VOFS                      .upper downto BG3VOFS                      .lower) := (others => '0');
                                                                             
   signal REG_BG2RotScaleParDX              : std_logic_vector(BG2RotScaleParDX             .upper downto BG2RotScaleParDX             .lower) := (others => '0');
   signal REG_BG2RotScaleParDMX             : std_logic_vector(BG2RotScaleParDMX            .upper downto BG2RotScaleParDMX            .lower) := (others => '0');
   signal REG_BG2RotScaleParDY              : std_logic_vector(BG2RotScaleParDY             .upper downto BG2RotScaleParDY             .lower) := (others => '0');
   signal REG_BG2RotScaleParDMY             : std_logic_vector(BG2RotScaleParDMY            .upper downto BG2RotScaleParDMY            .lower) := (others => '0');
   signal REG_BG2RefX                       : std_logic_vector(BG2RefX                      .upper downto BG2RefX                      .lower) := (others => '0');
   signal REG_BG2RefY                       : std_logic_vector(BG2RefY                      .upper downto BG2RefY                      .lower) := (others => '0');
                                                                             
   signal REG_BG3RotScaleParDX              : std_logic_vector(BG3RotScaleParDX             .upper downto BG3RotScaleParDX             .lower) := (others => '0');
   signal REG_BG3RotScaleParDMX             : std_logic_vector(BG3RotScaleParDMX            .upper downto BG3RotScaleParDMX            .lower) := (others => '0');
   signal REG_BG3RotScaleParDY              : std_logic_vector(BG3RotScaleParDY             .upper downto BG3RotScaleParDY             .lower) := (others => '0');
   signal REG_BG3RotScaleParDMY             : std_logic_vector(BG3RotScaleParDMY            .upper downto BG3RotScaleParDMY            .lower) := (others => '0');
   signal REG_BG3RefX                       : std_logic_vector(BG3RefX                      .upper downto BG3RefX                      .lower) := (others => '0');
   signal REG_BG3RefY                       : std_logic_vector(BG3RefY                      .upper downto BG3RefY                      .lower) := (others => '0');
                                                                             
   signal REG_WIN0H_X2                      : std_logic_vector(WIN0H_X2                     .upper downto WIN0H_X2                     .lower) := (others => '0');
   signal REG_WIN0H_X1                      : std_logic_vector(WIN0H_X1                     .upper downto WIN0H_X1                     .lower) := (others => '0');
                                                                             
   signal REG_WIN1H_X2                      : std_logic_vector(WIN1H_X2                     .upper downto WIN1H_X2                     .lower) := (others => '0');
   signal REG_WIN1H_X1                      : std_logic_vector(WIN1H_X1                     .upper downto WIN1H_X1                     .lower) := (others => '0');
                                                                             
   signal REG_WIN0V_Y2                      : std_logic_vector(WIN0V_Y2                     .upper downto WIN0V_Y2                     .lower) := (others => '0');
   signal REG_WIN0V_Y1                      : std_logic_vector(WIN0V_Y1                     .upper downto WIN0V_Y1                     .lower) := (others => '0');
                                                                             
   signal REG_WIN1V_Y2                      : std_logic_vector(WIN1V_Y2                     .upper downto WIN1V_Y2                     .lower) := (others => '0');
   signal REG_WIN1V_Y1                      : std_logic_vector(WIN1V_Y1                     .upper downto WIN1V_Y1                     .lower) := (others => '0');
                                                                             
   signal REG_WININ_Window_0_BG0_Enable     : std_logic_vector(WININ_Window_0_BG0_Enable    .upper downto WININ_Window_0_BG0_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_0_BG1_Enable     : std_logic_vector(WININ_Window_0_BG1_Enable    .upper downto WININ_Window_0_BG1_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_0_BG2_Enable     : std_logic_vector(WININ_Window_0_BG2_Enable    .upper downto WININ_Window_0_BG2_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_0_BG3_Enable     : std_logic_vector(WININ_Window_0_BG3_Enable    .upper downto WININ_Window_0_BG3_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_0_OBJ_Enable     : std_logic_vector(WININ_Window_0_OBJ_Enable    .upper downto WININ_Window_0_OBJ_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_0_Special_Effect : std_logic_vector(WININ_Window_0_Special_Effect.upper downto WININ_Window_0_Special_Effect.lower) := (others => '0');
   signal REG_WININ_Window_1_BG0_Enable     : std_logic_vector(WININ_Window_1_BG0_Enable    .upper downto WININ_Window_1_BG0_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_1_BG1_Enable     : std_logic_vector(WININ_Window_1_BG1_Enable    .upper downto WININ_Window_1_BG1_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_1_BG2_Enable     : std_logic_vector(WININ_Window_1_BG2_Enable    .upper downto WININ_Window_1_BG2_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_1_BG3_Enable     : std_logic_vector(WININ_Window_1_BG3_Enable    .upper downto WININ_Window_1_BG3_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_1_OBJ_Enable     : std_logic_vector(WININ_Window_1_OBJ_Enable    .upper downto WININ_Window_1_OBJ_Enable    .lower) := (others => '0');
   signal REG_WININ_Window_1_Special_Effect : std_logic_vector(WININ_Window_1_Special_Effect.upper downto WININ_Window_1_Special_Effect.lower) := (others => '0');
                                                                             
   signal REG_WINOUT_Outside_BG0_Enable     : std_logic_vector(WINOUT_Outside_BG0_Enable    .upper downto WINOUT_Outside_BG0_Enable    .lower) := (others => '0');
   signal REG_WINOUT_Outside_BG1_Enable     : std_logic_vector(WINOUT_Outside_BG1_Enable    .upper downto WINOUT_Outside_BG1_Enable    .lower) := (others => '0');
   signal REG_WINOUT_Outside_BG2_Enable     : std_logic_vector(WINOUT_Outside_BG2_Enable    .upper downto WINOUT_Outside_BG2_Enable    .lower) := (others => '0');
   signal REG_WINOUT_Outside_BG3_Enable     : std_logic_vector(WINOUT_Outside_BG3_Enable    .upper downto WINOUT_Outside_BG3_Enable    .lower) := (others => '0');
   signal REG_WINOUT_Outside_OBJ_Enable     : std_logic_vector(WINOUT_Outside_OBJ_Enable    .upper downto WINOUT_Outside_OBJ_Enable    .lower) := (others => '0');
   signal REG_WINOUT_Outside_Special_Effect : std_logic_vector(WINOUT_Outside_Special_Effect.upper downto WINOUT_Outside_Special_Effect.lower) := (others => '0');
   signal REG_WINOUT_Objwnd_BG0_Enable      : std_logic_vector(WINOUT_Objwnd_BG0_Enable     .upper downto WINOUT_Objwnd_BG0_Enable     .lower) := (others => '0');
   signal REG_WINOUT_Objwnd_BG1_Enable      : std_logic_vector(WINOUT_Objwnd_BG1_Enable     .upper downto WINOUT_Objwnd_BG1_Enable     .lower) := (others => '0');
   signal REG_WINOUT_Objwnd_BG2_Enable      : std_logic_vector(WINOUT_Objwnd_BG2_Enable     .upper downto WINOUT_Objwnd_BG2_Enable     .lower) := (others => '0');
   signal REG_WINOUT_Objwnd_BG3_Enable      : std_logic_vector(WINOUT_Objwnd_BG3_Enable     .upper downto WINOUT_Objwnd_BG3_Enable     .lower) := (others => '0');
   signal REG_WINOUT_Objwnd_OBJ_Enable      : std_logic_vector(WINOUT_Objwnd_OBJ_Enable     .upper downto WINOUT_Objwnd_OBJ_Enable     .lower) := (others => '0');
   signal REG_WINOUT_Objwnd_Special_Effect  : std_logic_vector(WINOUT_Objwnd_Special_Effect .upper downto WINOUT_Objwnd_Special_Effect .lower) := (others => '0');
                                                                             
   signal REG_MOSAIC_BG_Mosaic_H_Size       : std_logic_vector(MOSAIC_BG_Mosaic_H_Size      .upper downto MOSAIC_BG_Mosaic_H_Size      .lower) := (others => '0');
   signal REG_MOSAIC_BG_Mosaic_V_Size       : std_logic_vector(MOSAIC_BG_Mosaic_V_Size      .upper downto MOSAIC_BG_Mosaic_V_Size      .lower) := (others => '0');
   signal REG_MOSAIC_OBJ_Mosaic_H_Size      : std_logic_vector(MOSAIC_OBJ_Mosaic_H_Size     .upper downto MOSAIC_OBJ_Mosaic_H_Size     .lower) := (others => '0');
   signal REG_MOSAIC_OBJ_Mosaic_V_Size      : std_logic_vector(MOSAIC_OBJ_Mosaic_V_Size     .upper downto MOSAIC_OBJ_Mosaic_V_Size     .lower) := (others => '0');
                                                                             
   signal REG_BLDCNT_BG0_1st_Target_Pixel   : std_logic_vector(BLDCNT_BG0_1st_Target_Pixel  .upper downto BLDCNT_BG0_1st_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG1_1st_Target_Pixel   : std_logic_vector(BLDCNT_BG1_1st_Target_Pixel  .upper downto BLDCNT_BG1_1st_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG2_1st_Target_Pixel   : std_logic_vector(BLDCNT_BG2_1st_Target_Pixel  .upper downto BLDCNT_BG2_1st_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG3_1st_Target_Pixel   : std_logic_vector(BLDCNT_BG3_1st_Target_Pixel  .upper downto BLDCNT_BG3_1st_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_OBJ_1st_Target_Pixel   : std_logic_vector(BLDCNT_OBJ_1st_Target_Pixel  .upper downto BLDCNT_OBJ_1st_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BD_1st_Target_Pixel    : std_logic_vector(BLDCNT_BD_1st_Target_Pixel   .upper downto BLDCNT_BD_1st_Target_Pixel   .lower) := (others => '0');
   signal REG_BLDCNT_Color_Special_Effect   : std_logic_vector(BLDCNT_Color_Special_Effect  .upper downto BLDCNT_Color_Special_Effect  .lower) := (others => '0');
   signal REG_BLDCNT_BG0_2nd_Target_Pixel   : std_logic_vector(BLDCNT_BG0_2nd_Target_Pixel  .upper downto BLDCNT_BG0_2nd_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG1_2nd_Target_Pixel   : std_logic_vector(BLDCNT_BG1_2nd_Target_Pixel  .upper downto BLDCNT_BG1_2nd_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG2_2nd_Target_Pixel   : std_logic_vector(BLDCNT_BG2_2nd_Target_Pixel  .upper downto BLDCNT_BG2_2nd_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BG3_2nd_Target_Pixel   : std_logic_vector(BLDCNT_BG3_2nd_Target_Pixel  .upper downto BLDCNT_BG3_2nd_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_OBJ_2nd_Target_Pixel   : std_logic_vector(BLDCNT_OBJ_2nd_Target_Pixel  .upper downto BLDCNT_OBJ_2nd_Target_Pixel  .lower) := (others => '0');
   signal REG_BLDCNT_BD_2nd_Target_Pixel    : std_logic_vector(BLDCNT_BD_2nd_Target_Pixel   .upper downto BLDCNT_BD_2nd_Target_Pixel   .lower) := (others => '0');
                                                                             
   signal REG_BLDALPHA_EVA_Coefficient      : std_logic_vector(BLDALPHA_EVA_Coefficient     .upper downto BLDALPHA_EVA_Coefficient     .lower) := (others => '0');
   signal REG_BLDALPHA_EVB_Coefficient      : std_logic_vector(BLDALPHA_EVB_Coefficient     .upper downto BLDALPHA_EVB_Coefficient     .lower) := (others => '0');
                                                                             
   signal REG_BLDY                          : std_logic_vector(BLDY                         .upper downto BLDY                         .lower) := (others => '0');

   
   signal ref2_x_written : std_logic;
   signal ref2_y_written : std_logic;
   signal ref3_x_written : std_logic;
   signal ref3_y_written : std_logic;
   
   signal enables_wnd0   : std_logic_vector(5 downto 0);
   signal enables_wnd1   : std_logic_vector(5 downto 0);
   signal enables_wndobj : std_logic_vector(5 downto 0);
   signal enables_wndout : std_logic_vector(5 downto 0);
   
   -- ram wiring
   signal OAMRAM_Drawer_addr       : integer range 0 to 255;
   signal OAMRAM_Drawer_data       : std_logic_vector(31 downto 0);
   signal PALETTE_OAM_Drawer_addr  : integer range 0 to 127;
   signal PALETTE_OAM_Drawer_data  : std_logic_vector(31 downto 0);
   
   signal PALETTE_BG_Drawer_addr   : integer range 0 to 127;
   signal PALETTE_BG_Drawer_addr0  : integer range 0 to 127;
   signal PALETTE_BG_Drawer_addr1  : integer range 0 to 127;
   signal PALETTE_BG_Drawer_addr2  : integer range 0 to 127;
   signal PALETTE_BG_Drawer_addr3  : integer range 0 to 127;
   signal PALETTE_BG_Drawer_data   : std_logic_vector(31 downto 0);
   signal PALETTE_BG_Drawer_valid  : std_logic_vector(3 downto 0) := (others => '0');
   signal PALETTE_BG_Drawer_cnt    : unsigned(1 downto 0) := (others => '0');
   
   signal VRAM_Drawer_addr_Lo  : integer range 0 to 16383;
   signal VRAM_Drawer_addr_Hi  : integer range 0 to 8191;
   signal VRAM_Drawer_addr0    : integer range 0 to 16383;
   signal VRAM_Drawer_addr1    : integer range 0 to 16383;
   signal VRAM_Drawer_addr2    : integer range 0 to 16383;
   signal VRAM_Drawer_addr3    : integer range 0 to 16383;
   signal VRAM_Drawer_data_Lo  : std_logic_vector(31 downto 0);
   signal VRAM_Drawer_data_Hi  : std_logic_vector(31 downto 0);
   signal VRAM_Drawer_valid_Lo : std_logic_vector(3 downto 0) := (others => '0');
   signal VRAM_Drawer_valid_Hi : std_logic_vector(1 downto 0) := (others => '0');
   signal VRAM_Drawer_cnt_Lo   : unsigned(1 downto 0) := (others => '0');
   signal VRAM_Drawer_cnt_Hi   : std_logic := '0';
   
   -- background multiplexing
   signal drawline_mode0_0 : std_logic;
   signal drawline_mode0_1 : std_logic;
   signal drawline_mode0_2 : std_logic;
   signal drawline_mode0_3 : std_logic;
   signal drawline_mode2_2 : std_logic;
   signal drawline_mode2_3 : std_logic;
   signal drawline_mode345 : std_logic;
   signal drawline_obj     : std_logic;
   
   signal pixel_we_mode0_0 : std_logic;
   signal pixel_we_mode0_1 : std_logic;
   signal pixel_we_mode0_2 : std_logic;
   signal pixel_we_mode0_3 : std_logic;
   signal pixel_we_mode2_2 : std_logic;
   signal pixel_we_mode2_3 : std_logic;
   signal pixel_we_mode345 : std_logic;
   signal pixel_we_modeobj : std_logic;
   signal pixel_we_bg0     : std_logic;
   signal pixel_we_bg1     : std_logic;
   signal pixel_we_bg2     : std_logic;
   signal pixel_we_bg3     : std_logic;
   signal pixel_we_obj     : std_logic;
   
   signal pixeldata_mode0_0 : std_logic_vector(15 downto 0);
   signal pixeldata_mode0_1 : std_logic_vector(15 downto 0);
   signal pixeldata_mode0_2 : std_logic_vector(15 downto 0);
   signal pixeldata_mode0_3 : std_logic_vector(15 downto 0);
   signal pixeldata_mode2_2 : std_logic_vector(15 downto 0);
   signal pixeldata_mode2_3 : std_logic_vector(15 downto 0);
   signal pixeldata_mode345 : std_logic_vector(15 downto 0);
   signal pixeldata_modeobj : std_logic_vector(18 downto 0);
   signal pixeldata_bg0     : std_logic_vector(15 downto 0);
   signal pixeldata_bg1     : std_logic_vector(15 downto 0);
   signal pixeldata_bg2     : std_logic_vector(15 downto 0);
   signal pixeldata_bg3     : std_logic_vector(15 downto 0);
   signal pixeldata_obj     : std_logic_vector(18 downto 0);
   
   signal pixel_x_mode0_0 : integer range 0 to 239;
   signal pixel_x_mode0_1 : integer range 0 to 239;
   signal pixel_x_mode0_2 : integer range 0 to 239;
   signal pixel_x_mode0_3 : integer range 0 to 239;
   signal pixel_x_mode2_2 : integer range 0 to 239;
   signal pixel_x_mode2_3 : integer range 0 to 239;
   signal pixel_x_mode345 : integer range 0 to 239;
   signal pixel_x_modeobj : integer range 0 to 239;
   signal pixel_x_bg0     : integer range 0 to 239;
   signal pixel_x_bg1     : integer range 0 to 239;
   signal pixel_x_bg2     : integer range 0 to 239;
   signal pixel_x_bg3     : integer range 0 to 239;
   signal pixel_x_obj     : integer range 0 to 239;
   
   signal pixel_objwnd    : std_logic;

   signal PALETTE_Drawer_addr_mode0_0 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode0_1 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode0_2 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode0_3 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode2_2 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode2_3 : integer range 0 to 127;
   signal PALETTE_Drawer_addr_mode345 : integer range 0 to 127;
   
   signal VRAM_Drawer_addr_mode0_0 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_mode0_1 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_mode0_2 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_mode0_3 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_mode2_2 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_mode2_3 : integer range 0 to 16383;
   signal VRAM_Drawer_addr_345_Lo  : integer range 0 to 16383;
   signal VRAM_Drawer_addr_345_Hi  : integer range 0 to 8191;
   signal VRAM_Drawer_addrobj      : integer range 0 to 8191;
   
   signal busy_mode0_0 : std_logic;
   signal busy_mode0_1 : std_logic;
   signal busy_mode0_2 : std_logic;
   signal busy_mode0_3 : std_logic;
   signal busy_mode2_2 : std_logic;
   signal busy_mode2_3 : std_logic;
   signal busy_mode345 : std_logic;
   signal busy_modeobj : std_logic;
   signal busy_any     : std_logic;
   
   signal draw_allmod   : std_logic_vector(7 downto 0);
   signal busy_allmod   : std_logic_vector(7 downto 0);
   
   -- linebuffers
   signal clear_enable          : std_logic := '0';
   signal clear_addr            : integer range 0 to 239;
   signal clear_trigger         : std_logic := '0';
   signal clear_trigger_1       : std_logic := '0';
   
   signal linecounter_int       : integer range 0 to 159;
   signal linebuffer_addr       : integer range 0 to 239;
   signal linebuffer_addr_1     : integer range 0 to 239;
   
   signal linebuffer_bg0_data   : std_logic_vector(15 downto 0);
   signal linebuffer_bg1_data   : std_logic_vector(15 downto 0);
   signal linebuffer_bg2_data   : std_logic_vector(15 downto 0);
   signal linebuffer_bg3_data   : std_logic_vector(15 downto 0);
   signal linebuffer_obj_data   : std_logic_vector(18 downto 0);
   
   signal linebuffer_objwindow  : std_logic_vector(0 to 239) := (others => '0');
                                
   -- merge_pixel
   signal pixeldata_back        : std_logic_vector(15 downto 0) := (others => '0');
   signal allow_start           : std_logic := '1';
   signal merge_line            : std_logic := '0';
   signal merge_enable          : std_logic := '0';
   signal merge_enable_1        : std_logic := '0';
   signal merge_pixeldata_out   : std_logic_vector(15 downto 0);
   signal merge_pixel_x         : integer range 0 to 239;
   signal merge_pixel_y         : integer range 0 to 159;
   signal merge_pixel_we        : std_logic := '0';
   signal objwindow_merge_in    : std_logic := '0';
   
   signal pixelout_addr         : integer range 0 to 38399;
   signal merge_pixel_we_1      : std_logic := '0';
   signal merge_pixeldata_out_1 : std_logic_vector(15 downto 0);
   
   signal lineUpToDate          : std_logic_vector(0 to 159) := (others => '0');
   signal linesDrawn            : integer range 0 to 160 := 0;
   signal nextLineDrawn         : std_logic := '0';
   signal nextLineCounter       : integer range 0 to 159 := 0;
   
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
   
   iREG_DISPCNT_BG_Mode               : entity work.eProcReg_gba generic map (DISPCNT_BG_Mode              ) port map  (clk100, gb_bus, BG_Mode                           , BG_Mode               ); 
   iREG_DISPCNT_Reserved_CGB_Mode     : entity work.eProcReg_gba generic map (DISPCNT_Reserved_CGB_Mode    ) port map  (clk100, gb_bus, REG_DISPCNT_Reserved_CGB_Mode     , REG_DISPCNT_Reserved_CGB_Mode     ); 
   iREG_DISPCNT_Display_Frame_Select  : entity work.eProcReg_gba generic map (DISPCNT_Display_Frame_Select ) port map  (clk100, gb_bus, REG_DISPCNT_Display_Frame_Select  , REG_DISPCNT_Display_Frame_Select  ); 
   iREG_DISPCNT_H_Blank_IntervalFree  : entity work.eProcReg_gba generic map (DISPCNT_H_Blank_IntervalFree ) port map  (clk100, gb_bus, REG_DISPCNT_H_Blank_IntervalFree  , REG_DISPCNT_H_Blank_IntervalFree  ); 
   iREG_DISPCNT_OBJ_Char_VRAM_Map     : entity work.eProcReg_gba generic map (DISPCNT_OBJ_Char_VRAM_Map    ) port map  (clk100, gb_bus, REG_DISPCNT_OBJ_Char_VRAM_Map     , REG_DISPCNT_OBJ_Char_VRAM_Map     ); 
   iREG_DISPCNT_Forced_Blank          : entity work.eProcReg_gba generic map (DISPCNT_Forced_Blank         ) port map  (clk100, gb_bus, Forced_Blank                      , Forced_Blank                      ); 
   iREG_DISPCNT_Screen_Display_BG0    : entity work.eProcReg_gba generic map (DISPCNT_Screen_Display_BG0   ) port map  (clk100, gb_bus, Screen_Display_BG0                , Screen_Display_BG0                ); 
   iREG_DISPCNT_Screen_Display_BG1    : entity work.eProcReg_gba generic map (DISPCNT_Screen_Display_BG1   ) port map  (clk100, gb_bus, Screen_Display_BG1                , Screen_Display_BG1                ); 
   iREG_DISPCNT_Screen_Display_BG2    : entity work.eProcReg_gba generic map (DISPCNT_Screen_Display_BG2   ) port map  (clk100, gb_bus, Screen_Display_BG2                , Screen_Display_BG2                ); 
   iREG_DISPCNT_Screen_Display_BG3    : entity work.eProcReg_gba generic map (DISPCNT_Screen_Display_BG3   ) port map  (clk100, gb_bus, Screen_Display_BG3                , Screen_Display_BG3                ); 
   iREG_DISPCNT_Screen_Display_OBJ    : entity work.eProcReg_gba generic map (DISPCNT_Screen_Display_OBJ   ) port map  (clk100, gb_bus, Screen_Display_OBJ                , Screen_Display_OBJ                ); 
   iREG_DISPCNT_Window_0_Display_Flag : entity work.eProcReg_gba generic map (DISPCNT_Window_0_Display_Flag) port map  (clk100, gb_bus, REG_DISPCNT_Window_0_Display_Flag , REG_DISPCNT_Window_0_Display_Flag ); 
   iREG_DISPCNT_Window_1_Display_Flag : entity work.eProcReg_gba generic map (DISPCNT_Window_1_Display_Flag) port map  (clk100, gb_bus, REG_DISPCNT_Window_1_Display_Flag , REG_DISPCNT_Window_1_Display_Flag ); 
   iREG_DISPCNT_OBJ_Wnd_Display_Flag  : entity work.eProcReg_gba generic map (DISPCNT_OBJ_Wnd_Display_Flag ) port map  (clk100, gb_bus, REG_DISPCNT_OBJ_Wnd_Display_Flag  , REG_DISPCNT_OBJ_Wnd_Display_Flag  ); 
   iREG_GREENSWAP                     : entity work.eProcReg_gba generic map (GREENSWAP                    ) port map  (clk100, gb_bus, REG_GREENSWAP                     , REG_GREENSWAP                     ); 

   
   iREG_BG0CNT_BG_Priority              : entity work.eProcReg_gba generic map (BG0CNT_BG_Priority           ) port map  (clk100, gb_bus, REG_BG0CNT_BG_Priority            , REG_BG0CNT_BG_Priority            ); 
   iREG_BG0CNT_Character_Base_Block     : entity work.eProcReg_gba generic map (BG0CNT_Character_Base_Block  ) port map  (clk100, gb_bus, REG_BG0CNT_Character_Base_Block   , REG_BG0CNT_Character_Base_Block   ); 
   iREG_BG0CNT_UNUSED_4_5               : entity work.eProcReg_gba generic map (BG0CNT_UNUSED_4_5            ) port map  (clk100, gb_bus, REG_BG0CNT_UNUSED_4_5             , REG_BG0CNT_UNUSED_4_5             ); 
   iREG_BG0CNT_Mosaic                   : entity work.eProcReg_gba generic map (BG0CNT_Mosaic                ) port map  (clk100, gb_bus, REG_BG0CNT_Mosaic                 , REG_BG0CNT_Mosaic                 ); 
   iREG_BG0CNT_Colors_Palettes          : entity work.eProcReg_gba generic map (BG0CNT_Colors_Palettes       ) port map  (clk100, gb_bus, REG_BG0CNT_Colors_Palettes        , REG_BG0CNT_Colors_Palettes        ); 
   iREG_BG0CNT_Screen_Base_Block        : entity work.eProcReg_gba generic map (BG0CNT_Screen_Base_Block     ) port map  (clk100, gb_bus, REG_BG0CNT_Screen_Base_Block      , REG_BG0CNT_Screen_Base_Block      ); 
   iREG_BG0CNT_Screen_Size              : entity work.eProcReg_gba generic map (BG0CNT_Screen_Size           ) port map  (clk100, gb_bus, REG_BG0CNT_Screen_Size            , REG_BG0CNT_Screen_Size            ); 
                                                                                                                                                                                                               
   iREG_BG1CNT_BG_Priority              : entity work.eProcReg_gba generic map (BG1CNT_BG_Priority           ) port map  (clk100, gb_bus, REG_BG1CNT_BG_Priority            , REG_BG1CNT_BG_Priority            ); 
   iREG_BG1CNT_Character_Base_Block     : entity work.eProcReg_gba generic map (BG1CNT_Character_Base_Block  ) port map  (clk100, gb_bus, REG_BG1CNT_Character_Base_Block   , REG_BG1CNT_Character_Base_Block   ); 
   iREG_BG1CNT_UNUSED_4_5               : entity work.eProcReg_gba generic map (BG1CNT_UNUSED_4_5            ) port map  (clk100, gb_bus, REG_BG1CNT_UNUSED_4_5             , REG_BG1CNT_UNUSED_4_5             ); 
   iREG_BG1CNT_Mosaic                   : entity work.eProcReg_gba generic map (BG1CNT_Mosaic                ) port map  (clk100, gb_bus, REG_BG1CNT_Mosaic                 , REG_BG1CNT_Mosaic                 ); 
   iREG_BG1CNT_Colors_Palettes          : entity work.eProcReg_gba generic map (BG1CNT_Colors_Palettes       ) port map  (clk100, gb_bus, REG_BG1CNT_Colors_Palettes        , REG_BG1CNT_Colors_Palettes        ); 
   iREG_BG1CNT_Screen_Base_Block        : entity work.eProcReg_gba generic map (BG1CNT_Screen_Base_Block     ) port map  (clk100, gb_bus, REG_BG1CNT_Screen_Base_Block      , REG_BG1CNT_Screen_Base_Block      ); 
   iREG_BG1CNT_Screen_Size              : entity work.eProcReg_gba generic map (BG1CNT_Screen_Size           ) port map  (clk100, gb_bus, REG_BG1CNT_Screen_Size            , REG_BG1CNT_Screen_Size            ); 
                                                                                                                                                                                                               
   iREG_BG2CNT_BG_Priority              : entity work.eProcReg_gba generic map (BG2CNT_BG_Priority           ) port map  (clk100, gb_bus, REG_BG2CNT_BG_Priority            , REG_BG2CNT_BG_Priority            ); 
   iREG_BG2CNT_Character_Base_Block     : entity work.eProcReg_gba generic map (BG2CNT_Character_Base_Block  ) port map  (clk100, gb_bus, REG_BG2CNT_Character_Base_Block   , REG_BG2CNT_Character_Base_Block   ); 
   iREG_BG2CNT_UNUSED_4_5               : entity work.eProcReg_gba generic map (BG2CNT_UNUSED_4_5            ) port map  (clk100, gb_bus, REG_BG2CNT_UNUSED_4_5             , REG_BG2CNT_UNUSED_4_5             ); 
   iREG_BG2CNT_Mosaic                   : entity work.eProcReg_gba generic map (BG2CNT_Mosaic                ) port map  (clk100, gb_bus, REG_BG2CNT_Mosaic                 , REG_BG2CNT_Mosaic                 ); 
   iREG_BG2CNT_Colors_Palettes          : entity work.eProcReg_gba generic map (BG2CNT_Colors_Palettes       ) port map  (clk100, gb_bus, REG_BG2CNT_Colors_Palettes        , REG_BG2CNT_Colors_Palettes        ); 
   iREG_BG2CNT_Screen_Base_Block        : entity work.eProcReg_gba generic map (BG2CNT_Screen_Base_Block     ) port map  (clk100, gb_bus, REG_BG2CNT_Screen_Base_Block      , REG_BG2CNT_Screen_Base_Block      ); 
   iREG_BG2CNT_Display_Area_Overflow    : entity work.eProcReg_gba generic map (BG2CNT_Display_Area_Overflow ) port map  (clk100, gb_bus, REG_BG2CNT_Display_Area_Overflow  , REG_BG2CNT_Display_Area_Overflow  ); 
   iREG_BG2CNT_Screen_Size              : entity work.eProcReg_gba generic map (BG2CNT_Screen_Size           ) port map  (clk100, gb_bus, REG_BG2CNT_Screen_Size            , REG_BG2CNT_Screen_Size            ); 
                                                                                                                                                                                                               
   iREG_BG3CNT_BG_Priority              : entity work.eProcReg_gba generic map (BG3CNT_BG_Priority           ) port map  (clk100, gb_bus, REG_BG3CNT_BG_Priority            , REG_BG3CNT_BG_Priority            ); 
   iREG_BG3CNT_Character_Base_Block     : entity work.eProcReg_gba generic map (BG3CNT_Character_Base_Block  ) port map  (clk100, gb_bus, REG_BG3CNT_Character_Base_Block   , REG_BG3CNT_Character_Base_Block   ); 
   iREG_BG3CNT_UNUSED_4_5               : entity work.eProcReg_gba generic map (BG3CNT_UNUSED_4_5            ) port map  (clk100, gb_bus, REG_BG3CNT_UNUSED_4_5             , REG_BG3CNT_UNUSED_4_5             ); 
   iREG_BG3CNT_Mosaic                   : entity work.eProcReg_gba generic map (BG3CNT_Mosaic                ) port map  (clk100, gb_bus, REG_BG3CNT_Mosaic                 , REG_BG3CNT_Mosaic                 ); 
   iREG_BG3CNT_Colors_Palettes          : entity work.eProcReg_gba generic map (BG3CNT_Colors_Palettes       ) port map  (clk100, gb_bus, REG_BG3CNT_Colors_Palettes        , REG_BG3CNT_Colors_Palettes        ); 
   iREG_BG3CNT_Screen_Base_Block        : entity work.eProcReg_gba generic map (BG3CNT_Screen_Base_Block     ) port map  (clk100, gb_bus, REG_BG3CNT_Screen_Base_Block      , REG_BG3CNT_Screen_Base_Block      ); 
   iREG_BG3CNT_Display_Area_Overflow    : entity work.eProcReg_gba generic map (BG3CNT_Display_Area_Overflow ) port map  (clk100, gb_bus, REG_BG3CNT_Display_Area_Overflow  , REG_BG3CNT_Display_Area_Overflow  ); 
   iREG_BG3CNT_Screen_Size              : entity work.eProcReg_gba generic map (BG3CNT_Screen_Size           ) port map  (clk100, gb_bus, REG_BG3CNT_Screen_Size            , REG_BG3CNT_Screen_Size            ); 
                                                                                                                                                                                                               
   iREG_BG0HOFS                         : entity work.eProcReg_gba generic map (BG0HOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG0HOFS                       ); 
   iREG_BG0VOFS                         : entity work.eProcReg_gba generic map (BG0VOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG0VOFS                       ); 
   iREG_BG1HOFS                         : entity work.eProcReg_gba generic map (BG1HOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG1HOFS                       ); 
   iREG_BG1VOFS                         : entity work.eProcReg_gba generic map (BG1VOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG1VOFS                       ); 
   iREG_BG2HOFS                         : entity work.eProcReg_gba generic map (BG2HOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2HOFS                       ); 
   iREG_BG2VOFS                         : entity work.eProcReg_gba generic map (BG2VOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2VOFS                       ); 
   iREG_BG3HOFS                         : entity work.eProcReg_gba generic map (BG3HOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3HOFS                       ); 
   iREG_BG3VOFS                         : entity work.eProcReg_gba generic map (BG3VOFS                      ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3VOFS                       ); 
                                                                                                                                                                                                               
   iREG_BG2RotScaleParDX                : entity work.eProcReg_gba generic map (BG2RotScaleParDX             ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2RotScaleParDX              ); 
   iREG_BG2RotScaleParDMX               : entity work.eProcReg_gba generic map (BG2RotScaleParDMX            ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2RotScaleParDMX             ); 
   iREG_BG2RotScaleParDY                : entity work.eProcReg_gba generic map (BG2RotScaleParDY             ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2RotScaleParDY              ); 
   iREG_BG2RotScaleParDMY               : entity work.eProcReg_gba generic map (BG2RotScaleParDMY            ) port map  (clk100, gb_bus, x"0000"                           , REG_BG2RotScaleParDMY             ); 
   iREG_BG2RefX                         : entity work.eProcReg_gba generic map (BG2RefX                      ) port map  (clk100, gb_bus, x"0000000"                        , REG_BG2RefX                       , ref2_x_written); 
   iREG_BG2RefY                         : entity work.eProcReg_gba generic map (BG2RefY                      ) port map  (clk100, gb_bus, x"0000000"                        , REG_BG2RefY                       , ref2_y_written); 
                                                                                                                                                                                                               
   iREG_BG3RotScaleParDX                : entity work.eProcReg_gba generic map (BG3RotScaleParDX             ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3RotScaleParDX              ); 
   iREG_BG3RotScaleParDMX               : entity work.eProcReg_gba generic map (BG3RotScaleParDMX            ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3RotScaleParDMX             ); 
   iREG_BG3RotScaleParDY                : entity work.eProcReg_gba generic map (BG3RotScaleParDY             ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3RotScaleParDY              ); 
   iREG_BG3RotScaleParDMY               : entity work.eProcReg_gba generic map (BG3RotScaleParDMY            ) port map  (clk100, gb_bus, x"0000"                           , REG_BG3RotScaleParDMY             ); 
   iREG_BG3RefX                         : entity work.eProcReg_gba generic map (BG3RefX                      ) port map  (clk100, gb_bus, x"0000000"                        , REG_BG3RefX                       , ref3_x_written); 
   iREG_BG3RefY                         : entity work.eProcReg_gba generic map (BG3RefY                      ) port map  (clk100, gb_bus, x"0000000"                        , REG_BG3RefY                       , ref3_y_written); 
                                                                                                                                                                                                               
   iREG_WIN0H_X2                        : entity work.eProcReg_gba generic map (WIN0H_X2                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN0H_X2                      ); 
   iREG_WIN0H_X1                        : entity work.eProcReg_gba generic map (WIN0H_X1                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN0H_X1                      ); 
                                                                                                                                                                                                    
   iREG_WIN1H_X2                        : entity work.eProcReg_gba generic map (WIN1H_X2                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN1H_X2                      ); 
   iREG_WIN1H_X1                        : entity work.eProcReg_gba generic map (WIN1H_X1                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN1H_X1                      ); 
                                                                                                                                                                                                       
   iREG_WIN0V_Y2                        : entity work.eProcReg_gba generic map (WIN0V_Y2                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN0V_Y2                      ); 
   iREG_WIN0V_Y1                        : entity work.eProcReg_gba generic map (WIN0V_Y1                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN0V_Y1                      ); 
                                                                                                                                                                                                       
   iREG_WIN1V_Y2                        : entity work.eProcReg_gba generic map (WIN1V_Y2                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN1V_Y2                      ); 
   iREG_WIN1V_Y1                        : entity work.eProcReg_gba generic map (WIN1V_Y1                     ) port map  (clk100, gb_bus, x"00"                             , REG_WIN1V_Y1                      ); 
                                                                                                                                                                                                               
   iREG_WININ_Window_0_BG0_Enable       : entity work.eProcReg_gba generic map (WININ_Window_0_BG0_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_0_BG0_Enable     , REG_WININ_Window_0_BG0_Enable     ); 
   iREG_WININ_Window_0_BG1_Enable       : entity work.eProcReg_gba generic map (WININ_Window_0_BG1_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_0_BG1_Enable     , REG_WININ_Window_0_BG1_Enable     ); 
   iREG_WININ_Window_0_BG2_Enable       : entity work.eProcReg_gba generic map (WININ_Window_0_BG2_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_0_BG2_Enable     , REG_WININ_Window_0_BG2_Enable     ); 
   iREG_WININ_Window_0_BG3_Enable       : entity work.eProcReg_gba generic map (WININ_Window_0_BG3_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_0_BG3_Enable     , REG_WININ_Window_0_BG3_Enable     ); 
   iREG_WININ_Window_0_OBJ_Enable       : entity work.eProcReg_gba generic map (WININ_Window_0_OBJ_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_0_OBJ_Enable     , REG_WININ_Window_0_OBJ_Enable     ); 
   iREG_WININ_Window_0_Special_Effect   : entity work.eProcReg_gba generic map (WININ_Window_0_Special_Effect) port map  (clk100, gb_bus, REG_WININ_Window_0_Special_Effect , REG_WININ_Window_0_Special_Effect ); 
   iREG_WININ_Window_1_BG0_Enable       : entity work.eProcReg_gba generic map (WININ_Window_1_BG0_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_1_BG0_Enable     , REG_WININ_Window_1_BG0_Enable     ); 
   iREG_WININ_Window_1_BG1_Enable       : entity work.eProcReg_gba generic map (WININ_Window_1_BG1_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_1_BG1_Enable     , REG_WININ_Window_1_BG1_Enable     ); 
   iREG_WININ_Window_1_BG2_Enable       : entity work.eProcReg_gba generic map (WININ_Window_1_BG2_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_1_BG2_Enable     , REG_WININ_Window_1_BG2_Enable     ); 
   iREG_WININ_Window_1_BG3_Enable       : entity work.eProcReg_gba generic map (WININ_Window_1_BG3_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_1_BG3_Enable     , REG_WININ_Window_1_BG3_Enable     ); 
   iREG_WININ_Window_1_OBJ_Enable       : entity work.eProcReg_gba generic map (WININ_Window_1_OBJ_Enable    ) port map  (clk100, gb_bus, REG_WININ_Window_1_OBJ_Enable     , REG_WININ_Window_1_OBJ_Enable     ); 
   iREG_WININ_Window_1_Special_Effect   : entity work.eProcReg_gba generic map (WININ_Window_1_Special_Effect) port map  (clk100, gb_bus, REG_WININ_Window_1_Special_Effect , REG_WININ_Window_1_Special_Effect ); 
                                                                                                                                                                                                               
   iREG_WINOUT_Outside_BG0_Enable       : entity work.eProcReg_gba generic map (WINOUT_Outside_BG0_Enable    ) port map  (clk100, gb_bus, REG_WINOUT_Outside_BG0_Enable     , REG_WINOUT_Outside_BG0_Enable     ); 
   iREG_WINOUT_Outside_BG1_Enable       : entity work.eProcReg_gba generic map (WINOUT_Outside_BG1_Enable    ) port map  (clk100, gb_bus, REG_WINOUT_Outside_BG1_Enable     , REG_WINOUT_Outside_BG1_Enable     ); 
   iREG_WINOUT_Outside_BG2_Enable       : entity work.eProcReg_gba generic map (WINOUT_Outside_BG2_Enable    ) port map  (clk100, gb_bus, REG_WINOUT_Outside_BG2_Enable     , REG_WINOUT_Outside_BG2_Enable     ); 
   iREG_WINOUT_Outside_BG3_Enable       : entity work.eProcReg_gba generic map (WINOUT_Outside_BG3_Enable    ) port map  (clk100, gb_bus, REG_WINOUT_Outside_BG3_Enable     , REG_WINOUT_Outside_BG3_Enable     ); 
   iREG_WINOUT_Outside_OBJ_Enable       : entity work.eProcReg_gba generic map (WINOUT_Outside_OBJ_Enable    ) port map  (clk100, gb_bus, REG_WINOUT_Outside_OBJ_Enable     , REG_WINOUT_Outside_OBJ_Enable     ); 
   iREG_WINOUT_Outside_Special_Effect   : entity work.eProcReg_gba generic map (WINOUT_Outside_Special_Effect) port map  (clk100, gb_bus, REG_WINOUT_Outside_Special_Effect , REG_WINOUT_Outside_Special_Effect ); 
   iREG_WINOUT_Objwnd_BG0_Enable        : entity work.eProcReg_gba generic map (WINOUT_Objwnd_BG0_Enable     ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_BG0_Enable      , REG_WINOUT_Objwnd_BG0_Enable      ); 
   iREG_WINOUT_Objwnd_BG1_Enable        : entity work.eProcReg_gba generic map (WINOUT_Objwnd_BG1_Enable     ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_BG1_Enable      , REG_WINOUT_Objwnd_BG1_Enable      ); 
   iREG_WINOUT_Objwnd_BG2_Enable        : entity work.eProcReg_gba generic map (WINOUT_Objwnd_BG2_Enable     ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_BG2_Enable      , REG_WINOUT_Objwnd_BG2_Enable      ); 
   iREG_WINOUT_Objwnd_BG3_Enable        : entity work.eProcReg_gba generic map (WINOUT_Objwnd_BG3_Enable     ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_BG3_Enable      , REG_WINOUT_Objwnd_BG3_Enable      ); 
   iREG_WINOUT_Objwnd_OBJ_Enable        : entity work.eProcReg_gba generic map (WINOUT_Objwnd_OBJ_Enable     ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_OBJ_Enable      , REG_WINOUT_Objwnd_OBJ_Enable      ); 
   iREG_WINOUT_Objwnd_Special_Effect    : entity work.eProcReg_gba generic map (WINOUT_Objwnd_Special_Effect ) port map  (clk100, gb_bus, REG_WINOUT_Objwnd_Special_Effect  , REG_WINOUT_Objwnd_Special_Effect  ); 
                                                                                                                                                                                                               
   iREG_MOSAIC_BG_Mosaic_H_Size         : entity work.eProcReg_gba generic map (MOSAIC_BG_Mosaic_H_Size      ) port map  (clk100, gb_bus, x"0"                              , REG_MOSAIC_BG_Mosaic_H_Size       ); 
   iREG_MOSAIC_BG_Mosaic_V_Size         : entity work.eProcReg_gba generic map (MOSAIC_BG_Mosaic_V_Size      ) port map  (clk100, gb_bus, x"0"                              , REG_MOSAIC_BG_Mosaic_V_Size       ); 
   iREG_MOSAIC_OBJ_Mosaic_H_Size        : entity work.eProcReg_gba generic map (MOSAIC_OBJ_Mosaic_H_Size     ) port map  (clk100, gb_bus, x"0"                              , REG_MOSAIC_OBJ_Mosaic_H_Size      ); 
   iREG_MOSAIC_OBJ_Mosaic_V_Size        : entity work.eProcReg_gba generic map (MOSAIC_OBJ_Mosaic_V_Size     ) port map  (clk100, gb_bus, x"0"                              , REG_MOSAIC_OBJ_Mosaic_V_Size      ); 
                                                                                                                                                                                                               
   iREG_BLDCNT_BG0_1st_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG0_1st_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG0_1st_Target_Pixel   , REG_BLDCNT_BG0_1st_Target_Pixel   ); 
   iREG_BLDCNT_BG1_1st_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG1_1st_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG1_1st_Target_Pixel   , REG_BLDCNT_BG1_1st_Target_Pixel   ); 
   iREG_BLDCNT_BG2_1st_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG2_1st_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG2_1st_Target_Pixel   , REG_BLDCNT_BG2_1st_Target_Pixel   ); 
   iREG_BLDCNT_BG3_1st_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG3_1st_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG3_1st_Target_Pixel   , REG_BLDCNT_BG3_1st_Target_Pixel   ); 
   iREG_BLDCNT_OBJ_1st_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_OBJ_1st_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_OBJ_1st_Target_Pixel   , REG_BLDCNT_OBJ_1st_Target_Pixel   ); 
   iREG_BLDCNT_BD_1st_Target_Pixel      : entity work.eProcReg_gba generic map (BLDCNT_BD_1st_Target_Pixel   ) port map  (clk100, gb_bus, REG_BLDCNT_BD_1st_Target_Pixel    , REG_BLDCNT_BD_1st_Target_Pixel    ); 
   iREG_BLDCNT_Color_Special_Effect     : entity work.eProcReg_gba generic map (BLDCNT_Color_Special_Effect  ) port map  (clk100, gb_bus, REG_BLDCNT_Color_Special_Effect   , REG_BLDCNT_Color_Special_Effect   ); 
   iREG_BLDCNT_BG0_2nd_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG0_2nd_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG0_2nd_Target_Pixel   , REG_BLDCNT_BG0_2nd_Target_Pixel   ); 
   iREG_BLDCNT_BG1_2nd_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG1_2nd_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG1_2nd_Target_Pixel   , REG_BLDCNT_BG1_2nd_Target_Pixel   ); 
   iREG_BLDCNT_BG2_2nd_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG2_2nd_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG2_2nd_Target_Pixel   , REG_BLDCNT_BG2_2nd_Target_Pixel   ); 
   iREG_BLDCNT_BG3_2nd_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_BG3_2nd_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_BG3_2nd_Target_Pixel   , REG_BLDCNT_BG3_2nd_Target_Pixel   ); 
   iREG_BLDCNT_OBJ_2nd_Target_Pixel     : entity work.eProcReg_gba generic map (BLDCNT_OBJ_2nd_Target_Pixel  ) port map  (clk100, gb_bus, REG_BLDCNT_OBJ_2nd_Target_Pixel   , REG_BLDCNT_OBJ_2nd_Target_Pixel   ); 
   iREG_BLDCNT_BD_2nd_Target_Pixel      : entity work.eProcReg_gba generic map (BLDCNT_BD_2nd_Target_Pixel   ) port map  (clk100, gb_bus, REG_BLDCNT_BD_2nd_Target_Pixel    , REG_BLDCNT_BD_2nd_Target_Pixel    ); 
                                                                                                                                                                                                               
   iREG_BLDALPHA_EVA_Coefficient        : entity work.eProcReg_gba generic map (BLDALPHA_EVA_Coefficient     ) port map  (clk100, gb_bus, REG_BLDALPHA_EVA_Coefficient      , REG_BLDALPHA_EVA_Coefficient      ); 
   iREG_BLDALPHA_EVB_Coefficient        : entity work.eProcReg_gba generic map (BLDALPHA_EVB_Coefficient     ) port map  (clk100, gb_bus, REG_BLDALPHA_EVB_Coefficient      , REG_BLDALPHA_EVB_Coefficient      ); 
                                                                                                                                                                                                               
   iREG_BLDY                            : entity work.eProcReg_gba generic map (BLDY                         ) port map  (clk100, gb_bus, "00000"                           , REG_BLDY                          ); 

   gvram_lo : for i in 0 to 3 generate
      signal ram_dout_single1 : std_logic_vector(7 downto 0);
      signal ram_dout_single2 : std_logic_vector(7 downto 0);
      signal ram_din_single  : std_logic_vector(7 downto 0);
   begin
      
      ibyteram: entity MEM.SyncRamDual
      generic map
      (
         DATA_WIDTH => 8,
         ADDR_WIDTH => 14
      )
      port map
      (
         clk        => clk100,
         
         addr_a     => VRAM_Lo_addr,
         datain_a   => ram_din_single,
         dataout_a  => ram_dout_single1,
         we_a       => VRAM_Lo_we(i),
         re_a       => '1',
                  
         addr_b     => VRAM_Drawer_addr_Lo,
         datain_b   => x"00",
         dataout_b  => ram_dout_single2,
         we_b       => '0',
         re_b       => '1'
      );
      
      ram_din_single <= VRAM_Lo_datain(((i+1) * 8) - 1 downto (i * 8));
      VRAM_Lo_dataout(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single1;
      VRAM_Drawer_data_Lo(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single2;
   end generate; 

   gvram_hi : for i in 0 to 3 generate
      signal ram_dout_single1 : std_logic_vector(7 downto 0);
      signal ram_dout_single2 : std_logic_vector(7 downto 0);
      signal ram_din_single  : std_logic_vector(7 downto 0);
   begin
      
      ibyteram: entity MEM.SyncRamDual
      generic map
      (
         DATA_WIDTH => 8,
         ADDR_WIDTH => 13
      )
      port map
      (
         clk        => clk100,
         
         addr_a     => VRAM_Hi_addr,
         datain_a   => ram_din_single,
         dataout_a  => ram_dout_single1,
         we_a       => VRAM_Hi_we(i),
         re_a       => '1',
                  
         addr_b     => VRAM_Drawer_addr_Hi,
         datain_b   => x"00",
         dataout_b  => ram_dout_single2,
         we_b       => '0',
         re_b       => '1'
      );
      
      ram_din_single <= VRAM_Hi_datain(((i+1) * 8) - 1 downto (i * 8));
      VRAM_Hi_dataout(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single1;
      VRAM_Drawer_data_Hi(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single2;
   end generate;   
               
   goamram : for i in 0 to 3 generate
      signal ram_dout_single1 : std_logic_vector(7 downto 0);
      signal ram_dout_single2 : std_logic_vector(7 downto 0);
      signal ram_din_single  : std_logic_vector(7 downto 0);
   begin
      
      ibyteram: entity MEM.SyncRamDualNotPow2
      generic map
      (
         DATA_WIDTH => 8,
         DATA_COUNT => 256
      )
      port map
      (
         clk        => clk100,
         
         addr_a     => OAMRAM_PROC_addr,
         datain_a   => ram_din_single,
         dataout_a  => ram_dout_single1,
         we_a       => OAMRAM_PROC_we(i),
         re_a       => '1',
                  
         addr_b     => OAMRAM_Drawer_addr,
         datain_b   => x"00",
         dataout_b  => ram_dout_single2,
         we_b       => '0',
         re_b       => '1'
      );
      
      ram_din_single <= OAMRAM_PROC_datain(((i+1) * 8) - 1 downto (i * 8));
      OAMRAM_PROC_dataout(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single1;
      OAMRAM_Drawer_data(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single2;
   end generate;  
    
   gpaletteram_bg : for i in 0 to 3 generate
      signal ram_dout_single1 : std_logic_vector(7 downto 0);
      signal ram_dout_single2 : std_logic_vector(7 downto 0);
      signal ram_din_single  : std_logic_vector(7 downto 0);
   begin
      
      ibyteram: entity MEM.SyncRamDualNotPow2
      generic map
      (
         DATA_WIDTH => 8,
         DATA_COUNT => 128
      )
      port map
      (
         clk        => clk100,
         
         addr_a     => PALETTE_BG_addr,
         datain_a   => ram_din_single,
         dataout_a  => ram_dout_single1,
         we_a       => PALETTE_BG_we(i),
         re_a       => '1',
                  
         addr_b     => PALETTE_BG_Drawer_addr,
         datain_b   => x"00",
         dataout_b  => ram_dout_single2,
         we_b       => '0',
         re_b       => '1'
      );
      
      ram_din_single <= PALETTE_BG_datain(((i+1) * 8) - 1 downto (i * 8));
      PALETTE_BG_dataout(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single1;
      PALETTE_BG_Drawer_data(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single2;
   end generate;  
   
   gpaletteram_oam : for i in 0 to 3 generate
      signal ram_dout_single1 : std_logic_vector(7 downto 0);
      signal ram_dout_single2 : std_logic_vector(7 downto 0);
      signal ram_din_single  : std_logic_vector(7 downto 0);
   begin
      
      ibyteram: entity MEM.SyncRamDualNotPow2
      generic map
      (
         DATA_WIDTH => 8,
         DATA_COUNT => 128
      )
      port map
      (
         clk        => clk100,
         
         addr_a     => PALETTE_OAM_addr,
         datain_a   => ram_din_single,
         dataout_a  => ram_dout_single1,
         we_a       => PALETTE_OAM_we(i),
         re_a       => '1',
                  
         addr_b     => PALETTE_OAM_Drawer_addr,
         datain_b   => x"00",
         dataout_b  => ram_dout_single2,
         we_b       => '0',
         re_b       => '1'
      );
      
      ram_din_single <= PALETTE_OAM_datain(((i+1) * 8) - 1 downto (i * 8));
      PALETTE_OAM_dataout(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single1;
      PALETTE_OAM_Drawer_data(((i+1) * 8) - 1 downto (i * 8)) <= ram_dout_single2; 
   end generate; 
   
   igba_drawer_mode0_0 : entity work.gba_drawer_mode0
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode0_0,
      busy                 => busy_mode0_0,
      ypos                 => linecounter,
      mapbase              => unsigned(REG_BG0CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG0CNT_Character_Base_Block),
      hicolor              => REG_BG0CNT_Colors_Palettes(REG_BG0CNT_Colors_Palettes'left),
      screensize           => unsigned(REG_BG0CNT_Screen_Size),
      scrollX              => unsigned(REG_BG0HOFS(8 downto 0)),
      scrollY              => unsigned(REG_BG0VOFS(24 downto 16)),
      pixel_we             => pixel_we_mode0_0,
      pixeldata            => pixeldata_mode0_0,
      pixel_x              => pixel_x_mode0_0,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode0_0,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(0),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode0_0,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(0)
   );
   
  igba_drawer_mode0_1 : entity work.gba_drawer_mode0
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode0_1,
      busy                 => busy_mode0_1,
      ypos                 => linecounter,
      mapbase              => unsigned(REG_BG1CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG1CNT_Character_Base_Block),
      hicolor              => REG_BG1CNT_Colors_Palettes(REG_BG1CNT_Colors_Palettes'left),
      screensize           => unsigned(REG_BG1CNT_Screen_Size),
      scrollX              => unsigned(REG_BG1HOFS(8 downto 0)),
      scrollY              => unsigned(REG_BG1VOFS(24 downto 16)),
      pixel_we             => pixel_we_mode0_1,
      pixeldata            => pixeldata_mode0_1,
      pixel_x              => pixel_x_mode0_1,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode0_1,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(1),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode0_1,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(1)
   );
   
   igba_drawer_mode0_2 : entity work.gba_drawer_mode0
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode0_2,
      busy                 => busy_mode0_2,
      ypos                 => linecounter,
      mapbase              => unsigned(REG_BG2CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG2CNT_Character_Base_Block),
      hicolor              => REG_BG2CNT_Colors_Palettes(REG_BG2CNT_Colors_Palettes'left),
      screensize           => unsigned(REG_BG2CNT_Screen_Size),
      scrollX              => unsigned(REG_BG2HOFS(8 downto 0)),
      scrollY              => unsigned(REG_BG2VOFS(24 downto 16)),
      pixel_we             => pixel_we_mode0_2,
      pixeldata            => pixeldata_mode0_2,
      pixel_x              => pixel_x_mode0_2,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode0_2,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(2),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode0_2,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(2)
   );
   
   igba_drawer_mode0_3 : entity work.gba_drawer_mode0
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode0_3,
      busy                 => busy_mode0_3,
      ypos                 => linecounter,
      mapbase              => unsigned(REG_BG3CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG3CNT_Character_Base_Block),
      hicolor              => REG_BG3CNT_Colors_Palettes(REG_BG3CNT_Colors_Palettes'left),
      screensize           => unsigned(REG_BG3CNT_Screen_Size),
      scrollX              => unsigned(REG_BG3HOFS(8 downto 0)),
      scrollY              => unsigned(REG_BG3VOFS(24 downto 16)),
      pixel_we             => pixel_we_mode0_3,
      pixeldata            => pixeldata_mode0_3,
      pixel_x              => pixel_x_mode0_3,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode0_3,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(3),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode0_3,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(3)
   );
    
   igba_drawer_mode2_2 : entity work.gba_drawer_mode2
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode2_2,
      busy                 => busy_mode2_2,
      mapbase              => unsigned(REG_BG2CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG2CNT_Character_Base_Block),
      screensize           => unsigned(REG_BG2CNT_Screen_Size),
      wrapping             => REG_BG2CNT_Display_Area_Overflow(REG_BG2CNT_Display_Area_Overflow'left),
      refX                 => ref2_x,
      refY                 => ref2_y,
      dx                   => signed(REG_BG2RotScaleParDX),
      dy                   => signed(REG_BG2RotScaleParDY),  
      pixel_we             => pixel_we_mode2_2,
      pixeldata            => pixeldata_mode2_2,
      pixel_x              => pixel_x_mode2_2,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode2_2,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(2),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode2_2,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(2)
   );
   
   igba_drawer_mode2_3 : entity work.gba_drawer_mode2
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode2_3,
      busy                 => busy_mode2_3,
      mapbase              => unsigned(REG_BG3CNT_Screen_Base_Block),
      tilebase             => unsigned(REG_BG3CNT_Character_Base_Block),
      screensize           => unsigned(REG_BG3CNT_Screen_Size),
      wrapping             => REG_BG3CNT_Display_Area_Overflow(REG_BG3CNT_Display_Area_Overflow'left),
      refX                 => ref3_x,
      refY                 => ref3_y,
      dx                   => signed(REG_BG3RotScaleParDX),
      dy                   => signed(REG_BG3RotScaleParDY),  
      pixel_we             => pixel_we_mode2_3,
      pixeldata            => pixeldata_mode2_3,
      pixel_x              => pixel_x_mode2_3,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode2_3,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(3),
      VRAM_Drawer_addr     => VRAM_Drawer_addr_mode2_3,
      VRAM_Drawer_data     => VRAM_Drawer_data_Lo,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Lo(3)
   );
   
   igba_drawer_mode345 : entity work.gba_drawer_mode345
   port map
   (
      clk100               => clk100,
      drawline             => drawline_mode345,
      busy                 => busy_mode345,
      BG_Mode              => BG_Mode,
      second_frame         => REG_DISPCNT_Display_Frame_Select(REG_DISPCNT_Display_Frame_Select'left),
      refX                 => ref2_x,
      refY                 => ref2_y,
      dx                   => signed(REG_BG2RotScaleParDX),
      dy                   => signed(REG_BG2RotScaleParDY),  
      pixel_we             => pixel_we_mode345,
      pixeldata            => pixeldata_mode345,
      pixel_x              => pixel_x_mode345,
      PALETTE_Drawer_addr  => PALETTE_Drawer_addr_mode345,
      PALETTE_Drawer_data  => PALETTE_BG_Drawer_data,
      PALETTE_Drawer_valid => PALETTE_BG_Drawer_valid(2),
      VRAM_Drawer_addr_Lo  => VRAM_Drawer_addr_345_Lo,
      VRAM_Drawer_addr_Hi  => VRAM_Drawer_addr_345_Hi,
      VRAM_Drawer_data_Lo  => VRAM_Drawer_data_Lo,
      VRAM_Drawer_data_Hi  => VRAM_Drawer_data_Hi,
      VRAM_Drawer_valid_Lo => VRAM_Drawer_valid_Lo(2),
      VRAM_Drawer_valid_Hi => VRAM_Drawer_valid_Hi(0)
   );
   
   igba_drawer_obj : entity work.gba_drawer_obj
   port map
   (
      clk100               => clk100,
      
      hblank               => hblank_trigger,
      busy                 => busy_modeobj,
      
      drawline             => drawline_obj,
      ypos                 => linecounter_int,
      
      one_dim_mapping      => REG_DISPCNT_OBJ_Char_VRAM_Map(REG_DISPCNT_OBJ_Char_VRAM_Map'left),
      mosaic_h             => unsigned(REG_MOSAIC_OBJ_Mosaic_H_Size),
      mosaic_v             => unsigned(REG_MOSAIC_OBJ_Mosaic_V_Size),
      
      pixel_we             => pixel_we_modeobj,
      pixeldata            => pixeldata_modeobj,
      pixel_x              => pixel_x_modeobj,
      pixel_objwnd         => pixel_objwnd,
      
      OAMRAM_Drawer_addr   => OAMRAM_Drawer_addr,
      OAMRAM_Drawer_data   => OAMRAM_Drawer_data,
      
      PALETTE_Drawer_addr  => PALETTE_OAM_Drawer_addr,
      PALETTE_Drawer_data  => PALETTE_OAM_Drawer_data,
      
      VRAM_Drawer_addr     => VRAM_Drawer_addrobj,
      VRAM_Drawer_data     => VRAM_Drawer_data_Hi,
      VRAM_Drawer_valid    => VRAM_Drawer_valid_Hi(1)
   );
   
   
   -- todo: for backgrounds: if (!mosaic_on || mosaik_bg0_vcnt == 0)
   drawline_mode0_0 <= Screen_Display_BG0(Screen_Display_BG0'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "000" or BG_Mode = "001" else '0';
   drawline_mode0_1 <= Screen_Display_BG1(Screen_Display_BG1'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "000" or BG_Mode = "001" else '0';
   drawline_mode0_2 <= Screen_Display_BG2(Screen_Display_BG2'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "000" else '0';
   drawline_mode0_3 <= Screen_Display_BG3(Screen_Display_BG3'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "000" else '0';
   drawline_mode2_2 <= Screen_Display_BG2(Screen_Display_BG2'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "001" or BG_Mode = "010" else '0';
   drawline_mode2_3 <= Screen_Display_BG3(Screen_Display_BG3'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "010" else '0';
   drawline_mode345 <= Screen_Display_BG2(Screen_Display_BG2'left) and drawline and allow_start and (not nextLineDrawn) when BG_Mode = "011" or BG_Mode = "100" or BG_Mode = "101" else '0';
   drawline_obj     <= Screen_Display_OBJ(Screen_Display_OBJ'left) and drawline and allow_start and (not nextLineDrawn);

   PALETTE_BG_Drawer_addr0 <= PALETTE_Drawer_addr_mode0_0;
   PALETTE_BG_Drawer_addr1 <= PALETTE_Drawer_addr_mode0_1;
   PALETTE_BG_Drawer_addr2 <= PALETTE_Drawer_addr_mode0_2 when BG_Mode = "000" else PALETTE_Drawer_addr_mode2_2 when BG_Mode = "001" or BG_Mode = "010" else PALETTE_Drawer_addr_mode345;
   PALETTE_BG_Drawer_addr3 <= PALETTE_Drawer_addr_mode0_3 when BG_Mode = "000" else PALETTE_Drawer_addr_mode2_3;

   VRAM_Drawer_addr0 <= VRAM_Drawer_addr_mode0_0;
   VRAM_Drawer_addr1 <= VRAM_Drawer_addr_mode0_1;
   VRAM_Drawer_addr2 <= VRAM_Drawer_addr_mode0_2 when BG_Mode = "000" else VRAM_Drawer_addr_mode2_2 when BG_Mode = "001" or BG_Mode = "010" else VRAM_Drawer_addr_345_Lo;
   VRAM_Drawer_addr3 <= VRAM_Drawer_addr_mode0_3 when BG_Mode = "000" else VRAM_Drawer_addr_mode2_3;
   
   draw_allmod(0) <= drawline_mode0_0;
   draw_allmod(1) <= drawline_mode0_1;
   draw_allmod(2) <= drawline_mode0_2;
   draw_allmod(3) <= drawline_mode0_3;
   draw_allmod(4) <= drawline_mode2_2;
   draw_allmod(5) <= drawline_mode2_3;
   draw_allmod(6) <= drawline_mode345;
   draw_allmod(7) <= drawline_obj    ;

   busy_allmod(0) <= busy_mode0_0;
   busy_allmod(1) <= busy_mode0_1;
   busy_allmod(2) <= busy_mode0_2;
   busy_allmod(3) <= busy_mode0_3;
   busy_allmod(4) <= busy_mode2_2;
   busy_allmod(5) <= busy_mode2_3;
   busy_allmod(6) <= busy_mode345;
   busy_allmod(7) <= busy_modeobj;
   
   -- memory mapping
   process (clk100)
   begin
      if rising_edge(clk100) then

         if (PALETTE_BG_addr = 0 and PALETTE_BG_we(1) = '1') then
            pixeldata_back <= PALETTE_BG_datain(15 downto 0);
         end if;
      
         PALETTE_BG_Drawer_cnt <= PALETTE_BG_Drawer_cnt + 1;
         case (to_integer(PALETTE_BG_Drawer_cnt)) is
            when 0 => PALETTE_BG_Drawer_addr <= PALETTE_BG_Drawer_addr0; PALETTE_BG_Drawer_valid <= "1000";
            when 1 => PALETTE_BG_Drawer_addr <= PALETTE_BG_Drawer_addr1; PALETTE_BG_Drawer_valid <= "0001";
            when 2 => PALETTE_BG_Drawer_addr <= PALETTE_BG_Drawer_addr2; PALETTE_BG_Drawer_valid <= "0010";
            when 3 => PALETTE_BG_Drawer_addr <= PALETTE_BG_Drawer_addr3; PALETTE_BG_Drawer_valid <= "0100";
            when others => null;
         end case;
         
         VRAM_Drawer_cnt_Lo <= VRAM_Drawer_cnt_Lo + 1;
         case (to_integer(VRAM_Drawer_cnt_Lo)) is
            when 0 => VRAM_Drawer_addr_Lo <= VRAM_Drawer_addr0; VRAM_Drawer_valid_Lo <= "1000";
            when 1 => VRAM_Drawer_addr_Lo <= VRAM_Drawer_addr1; VRAM_Drawer_valid_Lo <= "0001";
            when 2 => VRAM_Drawer_addr_Lo <= VRAM_Drawer_addr2; VRAM_Drawer_valid_Lo <= "0010";
            when 3 => VRAM_Drawer_addr_Lo <= VRAM_Drawer_addr3; VRAM_Drawer_valid_Lo <= "0100";
            when others => null;
         end case;
         
         VRAM_Drawer_cnt_Hi <= not VRAM_Drawer_cnt_Hi;
         case (VRAM_Drawer_cnt_Hi) is
            when '0' => VRAM_Drawer_addr_Hi <= VRAM_Drawer_addr_345_Hi; VRAM_Drawer_valid_Hi <= "10";
            when '1' => VRAM_Drawer_addr_Hi <= VRAM_Drawer_addrobj;     VRAM_Drawer_valid_Hi <= "01";
            when others => null;
         end case;
         
         busy_any <= busy_mode0_0 or busy_mode0_1 or busy_mode0_2 or busy_mode0_3 or busy_mode2_2 or busy_mode2_3 or busy_mode345 or busy_modeobj;
         
         -- wait with delete for 2 clock cycles
         clear_trigger_1 <= clear_trigger;
         if (clear_trigger_1 = '1') then 
            clear_addr    <= 0;
            clear_enable  <= '1';
         end if;
         
         if (clear_enable = '1') then
            if (clear_addr < 239) then
               clear_addr <= clear_addr + 1;
            else
               clear_enable     <= '0';
            end if;
            
            pixel_we_bg0 <= '1';
            pixel_we_bg1 <= '1';
            pixel_we_bg2 <= '1';
            pixel_we_bg3 <= '1';
            pixel_we_obj <= '1';
            
            pixeldata_bg0 <= x"8000";
            pixeldata_bg1 <= x"8000";
            pixeldata_bg2 <= x"8000";
            pixeldata_bg3 <= x"8000";
            pixeldata_obj <= "000" & x"8000";
         
            pixel_x_bg0 <= clear_addr;
            pixel_x_bg1 <= clear_addr;
            pixel_x_bg2 <= clear_addr;
            pixel_x_bg3 <= clear_addr;
            pixel_x_obj <= clear_addr;
         
         else         
         
            pixel_we_bg0 <= pixel_we_mode0_0;
            pixel_we_bg1 <= pixel_we_mode0_1;
            pixel_we_obj <= pixel_we_modeobj;
            
            pixeldata_bg0 <= pixeldata_mode0_0;
            pixeldata_bg1 <= pixeldata_mode0_1;
            pixeldata_obj <= pixeldata_modeobj;
            
            pixel_x_bg0 <= pixel_x_mode0_0;
            pixel_x_bg1 <= pixel_x_mode0_1;
            pixel_x_obj <= pixel_x_modeobj;
         
            if (BG_Mode = "000") then
               pixel_we_bg2  <= pixel_we_mode0_2;
               pixeldata_bg2 <= pixeldata_mode0_2;
               pixel_x_bg2   <= pixel_x_mode0_2;
            elsif (BG_Mode = "001" or BG_Mode = "010") then
               pixel_we_bg2  <= pixel_we_mode2_2;
               pixeldata_bg2 <= pixeldata_mode2_2;
               pixel_x_bg2   <= pixel_x_mode2_2;
            else
               pixel_we_bg2  <= pixel_we_mode345;
               pixeldata_bg2 <= pixeldata_mode345;
               pixel_x_bg2   <= pixel_x_mode345;
            end if;
            
            if (BG_Mode = "000") then
               pixel_we_bg3  <= pixel_we_mode0_3; 
               pixeldata_bg3 <= pixeldata_mode0_3;
               pixel_x_bg3   <= pixel_x_mode0_3;
            else 
               pixel_we_bg3   <= pixel_we_mode2_3;
               pixeldata_bg3 <= pixeldata_mode2_3;
               pixel_x_bg3   <= pixel_x_mode2_3;
            end if;
            
         end if;

      end if;
   end process;
   
   -- line buffers
   ilinebuffer_bg0: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 16,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100,
      
      addr_a     => pixel_x_bg0,
      datain_a   => pixeldata_bg0,
      dataout_a  => open,
      we_a       => pixel_we_bg0,
      re_a       => '0',
               
      addr_b     => linebuffer_addr,
      datain_b   => x"0000",
      dataout_b  => linebuffer_bg0_data,
      we_b       => '0',
      re_b       => '1'
   );
   ilinebuffer_bg1: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 16,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100,
      
      addr_a     => pixel_x_bg1,
      datain_a   => pixeldata_bg1,
      dataout_a  => open,
      we_a       => pixel_we_bg1,
      re_a       => '0',
               
      addr_b     => linebuffer_addr,
      datain_b   => x"0000",
      dataout_b  => linebuffer_bg1_data,
      we_b       => '0',
      re_b       => '1'
   );
   ilinebuffer_bg2: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 16,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100,
      
      addr_a     => pixel_x_bg2,
      datain_a   => pixeldata_bg2,
      dataout_a  => open,
      we_a       => pixel_we_bg2,
      re_a       => '0',
               
      addr_b     => linebuffer_addr,
      datain_b   => x"0000",
      dataout_b  => linebuffer_bg2_data,
      we_b       => '0',
      re_b       => '1'
   );
   ilinebuffer_bg3: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 16,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100,
      
      addr_a     => pixel_x_bg3,
      datain_a   => pixeldata_bg3,
      dataout_a  => open,
      we_a       => pixel_we_bg3,
      re_a       => '0',
               
      addr_b     => linebuffer_addr,
      datain_b   => x"0000",
      dataout_b  => linebuffer_bg3_data,
      we_b       => '0',
      re_b       => '1'
   );
   ilinebuffer_obj: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 19,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100,
      
      addr_a     => pixel_x_obj,
      datain_a   => pixeldata_obj,
      dataout_a  => open,
      we_a       => pixel_we_obj,
      re_a       => '0',
               
      addr_b     => linebuffer_addr,
      datain_b   => (18 downto 0 => '0'),
      dataout_b  => linebuffer_obj_data,
      we_b       => '0',
      re_b       => '1'
   );
   
   -- line buffer readout
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         if (pixel_objwnd = '1') then
            linebuffer_objwindow(pixel_x_obj) <= '1';
         end if;
         
         nextLineDrawn <= lineUpToDate(nextLineCounter);

         if (vblank_trigger = '1') then
            if (linesDrawn = 160) then
               lineUpToDate <= (others => '0');
            else
            end if;
            nextLineCounter <= 0;
            linesDrawn      <= 0;
         elsif (drawline = '1' and nextLineCounter < 159) then
            nextLineCounter <= nextLineCounter + 1;
         end if;  

         if (drawline = '1' and nextLineDrawn = '1') then
            linesDrawn <= linesDrawn + 1;
         end if;
         
         if (drawline = '1' and busy_allmod = x"00" and allow_start = '1' and nextLineDrawn = '0') then
            linebuffer_addr      <= 0;
            merge_enable         <= '0';
            linecounter_int      <= to_integer(linecounter);
            linebuffer_objwindow <= (others => '0');
            allow_start          <= '0';
            linesDrawn           <= linesDrawn + 1;
            lineUpToDate(nextLineCounter) <= '1';
            
            merge_line <= '0';
            if (draw_allmod /= x"00") then
               merge_line <= '1';
            else
               allow_start <= '1';
            end if;
         end if;
            
         clear_trigger <= '0';
         if (merge_line = '1' and busy_allmod = x"00") then 
            linebuffer_addr  <= 0;
            merge_enable     <= '1';
            merge_line       <= '0';
            clear_trigger    <= '1';
         end if;
         
         if (merge_enable = '1') then
            if (linebuffer_addr < 239) then
               linebuffer_addr <= linebuffer_addr + 1;
            else
               merge_enable     <= '0';
               allow_start      <= '1';
            end if;
         end if;
      
         linebuffer_addr_1 <= linebuffer_addr;
         merge_enable_1 <= merge_enable;
         
         objwindow_merge_in <= linebuffer_objwindow(linebuffer_addr);
      
         pixelout_addr         <= merge_pixel_x + merge_pixel_y * 240;
         merge_pixel_we_1      <= merge_pixel_we;
         
         if (Forced_Blank = "1") then
            merge_pixeldata_out_1 <= x"7FFF";
         else
            merge_pixeldata_out_1 <= '0' & merge_pixeldata_out(4 downto 0) & merge_pixeldata_out(9 downto 5) & merge_pixeldata_out(14 downto 10);
         end if;
      
      end if;
   end process;
   
   pixel_out_addr <= pixelout_addr;
   pixel_out_data <= merge_pixeldata_out_1(14 downto 0);
   pixel_out_we   <= merge_pixel_we_1;
   
   enables_wnd0   <= REG_WININ_Window_0_Special_Effect & REG_WININ_Window_0_OBJ_Enable & REG_WININ_Window_0_BG3_Enable & REG_WININ_Window_0_BG2_Enable & REG_WININ_Window_0_BG1_Enable & REG_WININ_Window_0_BG0_Enable;
   enables_wnd1   <= REG_WININ_Window_1_Special_Effect & REG_WININ_Window_1_OBJ_Enable & REG_WININ_Window_1_BG3_Enable & REG_WININ_Window_1_BG2_Enable & REG_WININ_Window_1_BG1_Enable & REG_WININ_Window_1_BG0_Enable;
   enables_wndobj <= REG_WINOUT_Objwnd_Special_Effect & REG_WINOUT_Objwnd_OBJ_Enable & REG_WINOUT_Objwnd_BG3_Enable & REG_WINOUT_Objwnd_BG2_Enable & REG_WINOUT_Objwnd_BG1_Enable & REG_WINOUT_Objwnd_BG0_Enable;
   enables_wndout <= REG_WINOUT_Outside_Special_Effect & REG_WINOUT_Outside_OBJ_Enable & REG_WINOUT_Outside_BG3_Enable & REG_WINOUT_Outside_BG2_Enable & REG_WINOUT_Outside_BG1_Enable & REG_WINOUT_Outside_BG0_Enable;
   
   igba_drawer_merge : entity work.gba_drawer_merge
   port map
   (
      clk100               => clk100,                
                           
      enable               => merge_enable_1,                     
      xpos                 => linebuffer_addr_1,
      ypos                 => linecounter_int,
      
      BG0_on               => Screen_Display_BG0(Screen_Display_BG0'left),
      BG1_on               => Screen_Display_BG1(Screen_Display_BG1'left),
      WND0_on              => REG_DISPCNT_Window_0_Display_Flag(REG_DISPCNT_Window_0_Display_Flag'left),
      WND1_on              => REG_DISPCNT_Window_1_Display_Flag(REG_DISPCNT_Window_1_Display_Flag'left),
      WNDOBJ_on            => REG_DISPCNT_OBJ_Wnd_Display_Flag(REG_DISPCNT_OBJ_Wnd_Display_Flag'left),
                           
      WND0_X1              => unsigned(REG_WIN0H_X1),
      WND0_X2              => unsigned(REG_WIN0H_X2),
      WND0_Y1              => unsigned(REG_WIN0V_Y1),
      WND0_Y2              => unsigned(REG_WIN0V_Y2),
      WND1_X1              => unsigned(REG_WIN1H_X1),
      WND1_X2              => unsigned(REG_WIN1H_X2),
      WND1_Y1              => unsigned(REG_WIN1V_Y1),
      WND1_Y2              => unsigned(REG_WIN1V_Y2),
                           
      enables_wnd0         => enables_wnd0,  
      enables_wnd1         => enables_wnd1,  
      enables_wndobj       => enables_wndobj,
      enables_wndout       => enables_wndout,
                            
      special_effect_in    => unsigned(REG_BLDCNT_Color_Special_Effect),
      effect_1st_bg0       => REG_BLDCNT_BG0_1st_Target_Pixel(REG_BLDCNT_BG0_1st_Target_Pixel'left),
      effect_1st_bg1       => REG_BLDCNT_BG1_1st_Target_Pixel(REG_BLDCNT_BG1_1st_Target_Pixel'left),
      effect_1st_bg2       => REG_BLDCNT_BG2_1st_Target_Pixel(REG_BLDCNT_BG2_1st_Target_Pixel'left),
      effect_1st_bg3       => REG_BLDCNT_BG3_1st_Target_Pixel(REG_BLDCNT_BG3_1st_Target_Pixel'left),
      effect_1st_obj       => REG_BLDCNT_OBJ_1st_Target_Pixel(REG_BLDCNT_OBJ_1st_Target_Pixel'left),
      effect_1st_BD        => REG_BLDCNT_BD_1st_Target_Pixel(REG_BLDCNT_BD_1st_Target_Pixel'left),
      effect_2nd_bg0       => REG_BLDCNT_BG0_2nd_Target_Pixel(REG_BLDCNT_BG0_2nd_Target_Pixel'left),
      effect_2nd_bg1       => REG_BLDCNT_BG1_2nd_Target_Pixel(REG_BLDCNT_BG1_2nd_Target_Pixel'left),
      effect_2nd_bg2       => REG_BLDCNT_BG2_2nd_Target_Pixel(REG_BLDCNT_BG2_2nd_Target_Pixel'left),
      effect_2nd_bg3       => REG_BLDCNT_BG3_2nd_Target_Pixel(REG_BLDCNT_BG3_2nd_Target_Pixel'left),
      effect_2nd_obj       => REG_BLDCNT_OBJ_2nd_Target_Pixel(REG_BLDCNT_OBJ_2nd_Target_Pixel'left),
      effect_2nd_BD        => REG_BLDCNT_BD_2nd_Target_Pixel(REG_BLDCNT_BD_2nd_Target_Pixel'left),
                            
      Prio_BG0             => unsigned(REG_BG0CNT_BG_Priority),
      Prio_BG1             => unsigned(REG_BG1CNT_BG_Priority),
      Prio_BG2             => unsigned(REG_BG2CNT_BG_Priority),
      Prio_BG3             => unsigned(REG_BG3CNT_BG_Priority),
                            
      EVA                  => unsigned(REG_BLDALPHA_EVA_Coefficient),
      EVB                  => unsigned(REG_BLDALPHA_EVB_Coefficient),
      BLDY                 => unsigned(REG_BLDY),
                           
      pixeldata_bg0        => linebuffer_bg0_data,
      pixeldata_bg1        => linebuffer_bg1_data,
      pixeldata_bg2        => linebuffer_bg2_data,
      pixeldata_bg3        => linebuffer_bg3_data,
      pixeldata_obj        => linebuffer_obj_data,
      pixeldata_back       => pixeldata_back,
      objwindow_in         => objwindow_merge_in,
                           
      pixeldata_out        => merge_pixeldata_out,
      pixel_x              => merge_pixel_x,      
      pixel_y              => merge_pixel_y,      
      pixel_we             => merge_pixel_we     
   );
   
   -- affine + mosaik
   process (clk100)
   begin
      if rising_edge(clk100) then

         if (refpoint_update = '1' or ref2_x_written = '1') then ref2_x <= signed(REG_BG2RefX); end if;
         if (refpoint_update = '1' or ref2_y_written = '1') then ref2_y <= signed(REG_BG2RefY); end if;
         if (refpoint_update = '1' or ref3_x_written = '1') then ref3_x <= signed(REG_BG3RefX); end if;
         if (refpoint_update = '1' or ref3_y_written = '1') then ref3_y <= signed(REG_BG3RefY); end if;

         if (hblank_trigger = '1') then
            if (BG_Mode /= "000" and Screen_Display_BG2 = "1") then
               ref2_x <= ref2_x + signed(REG_BG2RotScaleParDMX);
               ref2_y <= ref2_y + signed(REG_BG2RotScaleParDMY);
            end if;
            if (BG_Mode = "010" and Screen_Display_BG3 = "1") then
               ref3_x <= ref3_x + signed(REG_BG3RotScaleParDMX);
               ref3_y <= ref3_y + signed(REG_BG3RotScaleParDMY);
            end if;
         end if;
         
         if (drawline = '1' and linecounter = 0) then
            mosaik_bg0_vcnt <= 0;
            mosaik_bg1_vcnt <= 0;
            mosaik_bg2_vcnt <= 0;
            mosaik_bg3_vcnt <= 0;
         end if;

      end if;
   end process;

end architecture;





