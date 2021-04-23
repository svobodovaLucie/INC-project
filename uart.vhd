-- uart.vhd: UART controller - receiving part
-- Author(s): Lucie Svobodová¡, xsvobo1x
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
signal clk_cnt_en : std_logic;                      -- signalizace, zda je aktivovan citac hodinoveho signalu
signal dread      : std_logic;                      -- signalizace, zda je aktivovan rezim cteni dat
signal D_VLD      : std_logic;                      -- signalizace, zda je nastaven DOUT_VLD
signal stop_bit_w : std_logic;                      -- signalizace, ze cekame na stop bit
signal stop_bit_en: std_logic;
signal dvalid     : std_logic;

begin
    FSM: entity work.UART_FSM(behavioral)
    port map  (
        CLK           => CLK,              -- hodinovy signal
        RST           => RST,              -- reset
        DIN           => DIN,              -- data in
        CLK_CNT       => clk_cnt,          -- citac hodinovych signalu
        BIT_CNT       => bit_cnt,          -- citac bitu (pouzit pri DATA_READ)
        STOP_BIT_EN   => stop_bit_en,      -- signalizace, zda je stop bit prijat
        
        STOP_BIT_W    => stop_bit_w,       -- signalizace, ze cekame na stop bit
        CLK_CNT_EN    => clk_cnt_en,       -- signalizace, zda je aktivovan citac hodinoveho signálu
        DREAD         => dread,             -- signalizace, zda je aktivovan rezim cteni dat
        DVALID        => dvalid
    );
    
    process (CLK) begin
        if rising_edge(CLK) then
              if dread = '0' then
                  bit_cnt <= "0000";
              end if;
    
            -- pokud je aktivovan citac hodinoveho signalu, inkrementujeme ho
            if clk_cnt_en = '1' then
                clk_cnt <= clk_cnt + 1;
            else 
                clk_cnt <= "00000";
            end if;
            
            -- pokud jsme ve stavu cteni dat
            if dread = '1' then
                -- pokud je clk_cnt > 15, vynulujeme jej a zapiseme nactený bit na DOUT
                if bit_cnt(3) = '1' then
                    clk_cnt <= "00000";
                    --DOUT(to_integer(unsigned(bit_cnt))) <= DIN;
                    --bit_cnt <= bit_cnt + 1;
                else 
                  if clk_cnt(4) = '1' then
                  --if clk_cnt = "010000" then
                    clk_cnt <= "00000";
                    DOUT(to_integer(unsigned(bit_cnt))) <= DIN;   -- zapis nacteneho bitu na vystup
                    bit_cnt <= bit_cnt + 1;
                  end if;
              end if;
            end if;
            
            -- pokud cekame na stop bit, cekame, nez DIN vysle log.1
            if stop_bit_w = '1' then
                -- pokud DIN vyslala 1, tedy stop bit, muzeme se prepnout do dalsiho stavu
                if DIN = '1' then
                    stop_bit_en <= '1';
                else
                    stop_bit_en <= '0';
                end if;
            end if;
            
            if dvalid = '1' then
                DOUT_VLD <= '1';
            else
                DOUT_VLD <= '0';
            end if;
        end if;
    end process;
end behavioral;
