-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Lucie Svobodova, xsvobo1x
--
library ieee;
use ieee.std_logic_1164.all;
-------------------------------------------------
-- vstupni a vystupni porty
entity UART_FSM is
port(
    CLK         : in std_logic;                     -- hodinovy signal
    RST         : in std_logic;                     -- reset
    DIN         : in std_logic;                     -- data in
    CLK_CNT     : in std_logic_vector(4 downto 0);  -- citac hodinovych signalu
    BIT_CNT     : in std_logic_vector(3 downto 0);  -- citac bitu (pouzit pri DATA_READ)
    STOP_BIT_EN : in std_logic;                     -- detekce prijeti stop bitu (1 = je nastaven)
    
    STOP_BIT_W  : out std_logic;                    -- indikace, ze cekame na stop bit
    CLK_CNT_EN  : out std_logic;                    -- indikace, ze je aktivovan citac hodinoveho signalu
    DREAD       : out std_logic;                    -- indikace, ze je aktivovan rezim ctení dat
    DVALID      : out std_logic                     -- indikace, ze ma byt zapsat DOUT_VLD
    );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
type state_t is (WAIT_FOR_START, WAIT_FOR_FIRST, DATA_READ, WAIT_FOR_STOP, DATA_VALID);
signal pstate : state_t;  -- soucasny stav (present state)
signal nstate : state_t;  -- nasledujici stav

begin
  -- Present State Register
  pstate_reg: process(RST, CLK)
  begin
      if (RST = '1') then
          pstate <= WAIT_FOR_START;
      elsif (CLK'event) and (CLK = '1') then
          pstate <= nstate;
      end if;
  end process; -- pstate_logic
  
  -- Next State Logic
  nstate_logic: process (pstate, DIN, CLK_CNT, BIT_CNT, STOP_BIT_EN)
  begin
      case pstate is
          -- zacatek prenosu je zahajen nastavenim DIN na log.0 
          when WAIT_FOR_START =>  if (DIN = '0') then
                                      nstate <= WAIT_FOR_FIRST;
                                  end if;                       
          -- cekame, nez je prenesen start bit a nez se dostaneme do poloviny prvniho bitu
          when WAIT_FOR_FIRST =>  if (CLK_CNT = "10100") then
                                      nstate <= DATA_READ;
                                 end if;
          -- data jsou ctena do doby, nez je nacteno 8 bitu - citac BIT_CNT                        
          when DATA_READ      =>  if (BIT_CNT = "1000") then
                                      nstate <= WAIT_FOR_STOP;
                                  end if;                
          -- po nacteni 8 bitu se pocka na nactení stop bitu                           
          when WAIT_FOR_STOP  =>  if (STOP_BIT_EN = '1') then
                                      nstate <= DATA_VALID;
                                  end if;
          -- po prijetí stop bitu je na dobu jednoho hodinoveho taktu nastaven vystup DOUT_VLD
          -- po jednom hodinovém taktu se vracime do stavu WAIT_FOR_FIRST  
          when DATA_VALID     =>  nstate <= WAIT_FOR_START;
          when others         =>  nstate <= WAIT_FOR_FIRST;
      end case;
  end process; -- nstate_logic 
  
  -- Output Logic - nastaveni vystupu
  output_logic: process(pstate)
  begin
      case pstate is
          when WAIT_FOR_START =>
              DREAD <= '0';
              CLK_CNT_EN <= '0';
              STOP_BIT_W <= '0';
              DVALID <= '0';
              
          when WAIT_FOR_FIRST =>
              DREAD <= '0';
              CLK_CNT_EN <= '1';  -- indikace pracujiciho citace hodinoveho signalu
              STOP_BIT_W <= '0';
              DVALID <= '0';
                    
          when DATA_READ =>
              DREAD <= '1';       -- indikace cteni dat
              CLK_CNT_EN <= '1';  -- indikace pracujiciho citace hodinoveho signalu
              STOP_BIT_W <= '0';
              DVALID <= '0';
                      
          when WAIT_FOR_STOP =>
              DREAD <= '0';
              CLK_CNT_EN <= '0';
              STOP_BIT_W <= '1';  -- indikace cekani na stop bit
              DVALID <= '0';
              
          when DATA_VALID =>
              DREAD <= '0';
              CLK_CNT_EN <= '0';
              STOP_BIT_W <= '0';
              DVALID <= '1';      -- indikace, ze ma byt na vystup poslan DOUT_VLD='1'
              
          when others =>
              DREAD <= '0';
              CLK_CNT_EN <= '0';
              STOP_BIT_W <= '0';
              DVALID <= '0';
      end case;
  end process; -- output_logic
  
end behavioral;
