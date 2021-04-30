-- uart.vhd: UART controller - receiving part
-- Author(s): Lucie Svobodová, xsvobo1x
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-------------------------------------------------
entity UART_RX is
port(	
  CLK: 	    in std_logic;
	RST: 	    in std_logic;
	DIN: 	    in std_logic;
	DOUT: 	    out std_logic_vector(7 downto 0);
	DOUT_VLD: 	out std_logic
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
signal clk_cnt    : std_logic_vector(4 downto 0);   -- citac hodinovych signalu
signal bit_cnt    : std_logic_vector(3 downto 0);   -- citac bitu (pouzity pri DATA_READ)
signal clk_cnt_en : std_logic;                      -- indikace, zda je aktivovan citac hodinoveho signalu
signal dread      : std_logic;                      -- indikace, zda je aktivovan rezim cteni dat
signal stop_bit_w : std_logic;                      -- indikace, ze cekame na stop bit
signal stop_bit_en: std_logic;                      -- indikace, ze byl stop bit detekovan
signal dvalid     : std_logic;                      -- indikace, ze dvalid ma byt nastaven
signal rst_syn0 : std_logic;                -- vystup z D klopneho obvodu po prvni urovni synchronizace signalu RST
signal rst_syn : std_logic;                 -- vystup z D klopneho obvodu po druhe urovni synchronizace signalu RST
signal din_syn0 : std_logic;                -- vystup z D klopneho obvodu po prvni urovni synchronizace signalu DIN
signal din_syn : std_logic;                 -- vystup z D klopneho obvodu po druhe urovni synchronizace signalu DIN

begin
    
    -- synchronizace vstupu RST pomoci klopnych obvodu typu D (zde pouzity 2)
    -- prvni klopny obvod typu D - vystupem je signal rst_syn0
    RST_SYNCHRO_0:  process(CLK) begin
                        if rising_edge(CLK) then
                            rst_syn0 <= RST;
                        end if;
                    end process;   
    -- druhy klopny obvod typu D - vystupem je rst_syn, ktery je take vstupem do FSM
    RST_SYNCHRO:    process(CLK) begin
                        if rising_edge(CLK) then
                            rst_syn <= rst_syn0;
                        end if;
                    end process;
                    
    -- synchronizace vstupu DIN pomoci klopnych obvodu typu D (zde pouzity 2)
    -- prvni klopny obvod typu D - vystupem je signal din_syn0
    DIN_SYNCHRO_0:  process(CLK) begin
                        if rising_edge(CLK) then
                            din_syn0 <= DIN;
                        end if;
                    end process;
     -- druhy klopny obvod typu D - vystupem je din_syn, ktery je take vstupem do FSM
    DIN_SYNCHRO:    process(CLK) begin
                        if rising_edge(CLK) then
                            din_syn <= din_syn0;
                        end if;
                    end process;
                    
    -- namapovani signalu na porty FSM
    FSM: entity work.UART_FSM(behavioral)
    port map  (
        CLK           => CLK,              -- hodinovy signal
        RST           => rst_syn,          -- synchronizovany signal reset
        DIN           => din_syn,          -- synchronizovany signal data in
        CLK_CNT       => clk_cnt,          -- citac hodinovych signalu
        BIT_CNT       => bit_cnt,          -- citac bitu (pouzit pri DATA_READ)
        STOP_BIT_EN   => stop_bit_en,      -- signalizace, zda byl stop bit detekovan
        
        STOP_BIT_W    => stop_bit_w,       -- indikace, ze se ceka na stop bit
        CLK_CNT_EN    => clk_cnt_en,       -- indikace, zda je aktivovan citac hodinoveho signálu
        DREAD         => dread,            -- indikace, zda je aktivovan rezim cteni dat
        DVALID        => dvalid            -- indikace, zda ma byt zapsan DOUT_VLD
    );
    
    process (CLK) begin
        if (CLK'event) and (CLK = '1') then
            -- pokud neni dread aktivovan, pocitadlo bitu je vynulovano
            if (dread = '0') then
                bit_cnt <= "0000";
            end if;
            -- pokud je aktivovan citac hodinoveho signalu, bude inkrementovan
            if (clk_cnt_en = '1') then
                clk_cnt <= clk_cnt + 1;
            else
                clk_cnt <= "00000";
            end if;
            
            -- pokud jsme ve stavu cteni dat
            if (dread = '1') then
                if (clk_cnt (4) = '1') then
                    DOUT(to_integer(unsigned(bit_cnt))) <= din_syn;
                    bit_cnt <= bit_cnt + 1;
                    clk_cnt <= "00000";
                end if;
            end if;  
            
            -- pokud cekame na stop bit, cekame, nez DIN vysle log.1
            if (stop_bit_w = '1') then
                if (din_syn = '1') then
                    stop_bit_en <= '1';
                else
                    stop_bit_en <= '0';
                end if;
            end if;
            
            -- pokud jsme ve stavu DATA_VALID, vysleme DOUT_VLD
            if (dvalid = '1') then
                DOUT_VLD <= '1';
            else
                DOUT_VLD <= '0';
            end if;
        end if;
    end process;
end behavioral;
