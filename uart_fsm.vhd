-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Lucie Svobodová¡, xsvobo1x
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
    
    STOP_BIT_W  : out std_logic;                    -- signalizace, ze cekame na stop bit
    CLK_CNT_EN  : out std_logic;                    -- signalizace, ze je aktivovan citac hodinoveho signalu
    DREAD       : out std_logic;                    -- signalizace, ze je aktivovan rezim ctení dat
    DVALID      : out std_logic
    );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
type state_t is (WAIT_FOR_START, WAIT_FOR_FIRST, DATA_READ, WAIT_FOR_STOP, DATA_VALID);
signal state : state_t := WAIT_FOR_START;
begin
  
    -- pokud jsme ve stavu READ_DATA, nastavime vystupni signal DREAD na 1
  DREAD <= '1' when  state = DATA_READ else '0';
  
  
  -- pokud jsme ve stavu WAIT_FOR_FIRST nebo DATA_READ, vyuzivame clock counter
  CLK_CNT_EN <= '1' when state = WAIT_FOR_FIRST or state = DATA_READ else '0';
  
  DVALID <= '1' when state = DATA_VALID else '0';
  
  process (CLK) begin
    if rising_edge(CLK) then
            
        -- pokud je nastaven vstup RST na log.1, zaciname cekat na START_BIT
        if RST = '1' then
            state <= WAIT_FOR_START;
        -- pokud RST neni nastaven na log.1, prenos uz zacal
        else
            case state is
                -- zacatek prenosu je zahajen nastavenim DIN na log.1 
                when WAIT_FOR_START =>  
                                        if DIN = '0' then
                                            state <= WAIT_FOR_FIRST;
                                        end if;
                -- po 24 hodinových signalech od prvni detekce start bitu se prepne do stavu cteni dat                       
                when WAIT_FOR_FIRST =>  if CLK_CNT = "11000" then
                                            state <= DATA_READ;
                                        end if;
                -- data jsou ctena do doby, nez je nacteno 8 bitu - citac BIT_CNT                        
                when DATA_READ      =>  if BIT_CNT = "1000" then
                                            state <= WAIT_FOR_STOP;
                                            STOP_BIT_W <= '1';
                                        end if;
                -- po nacteni 8 bitu se pocka na nactení stop bitu                           
                when WAIT_FOR_STOP =>   if STOP_BIT_EN = '1' then
                                            STOP_BIT_W <= '0';
                                            state <= DATA_VALID;
                                        end if;
                -- po prijetí stop bitu je na dobu jednoho hodinoveho taktu nastaven vystup DOUT_VLD
                -- po jednom hodinovém taktu se vracime do stavu WAIT_FOR_FIRST  
                when DATA_VALID     =>  state <= WAIT_FOR_START;
                          
                when others         =>  null;
            end case;
        end if;
    end if;
end process;
end behavioral;
