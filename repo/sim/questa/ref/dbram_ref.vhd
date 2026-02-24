library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity dbram_ref is
  generic (
    DATA_WIDTH : integer := 32;
    ADDR_WIDTH : integer := 10
  );
  port (
    aclk    : in  std_logic;
    aresetn : in  std_logic := '0';

    addr_a_i : in  std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    addr_b_i : in  std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

    write_a_i : in  std_logic := '0';
    write_b_i : in  std_logic := '0';

    read_a_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    read_b_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    write_a_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    write_b_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0')
  );
end entity;

architecture rtl of dbram_ref is
  -- Для 36-bit режима адрес примитива 15 бит: word addressing => младшие 5 бит = 0
  signal addr_a_15 : std_logic_vector(14 downto 0);
  signal addr_b_15 : std_logic_vector(14 downto 0);

  signal wea   : std_logic_vector(3 downto 0);
  signal webwe : std_logic_vector(7 downto 0);

  signal dina  : std_logic_vector(31 downto 0);
  signal dinb  : std_logic_vector(31 downto 0);
  signal douta : std_logic_vector(31 downto 0);
  signal doutb : std_logic_vector(31 downto 0);

  signal rst : std_logic;

  -- ZEROS
  constant Z1 : std_logic := '0';
  constant Z4 : std_logic_vector(3 downto 0)  := (others => '0');
  constant Z8 : std_logic_vector(7 downto 0)  := (others => '0');
  constant Z9 : std_logic_vector(8 downto 0)  := (others => '0');
  constant Z32: std_logic_vector(31 downto 0) := (others => '0');
begin
  -- Ограничимся конфигурацией тестового: 32 бит, 1024 слова (для 36-bit режима у RAMB36E2 это как раз ADDR_WIDTH=10)
  -- synthesis translate_off
  assert (DATA_WIDTH = 32) report "dbram_ref expects DATA_WIDTH=32" severity failure;
  assert (ADDR_WIDTH = 10) report "dbram_ref expects ADDR_WIDTH=10" severity failure;
  -- synthesis translate_on

  -- reset active HIGH
  rst <= '1' when aresetn = '0' else '0';

  addr_a_15 <= addr_a_i & "00000";
  addr_b_15 <= addr_b_i & "00000";

  wea   <= (others => write_a_i);
  webwe <= (others => write_b_i);

  dina <= write_a_data_i;
  dinb <= write_b_data_i;

  read_a_data_o <= douta;
  read_b_data_o <= doutb;

  RAMB36E2_inst : RAMB36E2
    generic map (
      -- Нам нужен общий такт
      CLOCK_DOMAINS       => "COMMON",

      -- Хотим видеть X на коллизиях
      SIM_COLLISION_CHECK => "GENERATE_X_ONLY",

      -- Без дополнительного выходного регистра (1 такт латентности чтения)
      DOA_REG => 0,
      DOB_REG => 0,

      -- Режим 36 бит (32 + parity), depth=1024 слов
      READ_WIDTH_A  => 36,
      READ_WIDTH_B  => 36,
      WRITE_WIDTH_A => 36,
      WRITE_WIDTH_B => 36,

      -- Поведение как “transparent / write-first”
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",

      -- defolt 
      CASCADE_ORDER_A => "NONE",
      CASCADE_ORDER_B => "NONE",
      ENADDRENA       => "FALSE",
      ENADDRENB       => "FALSE",
      EN_ECC_PIPE     => "FALSE",
      EN_ECC_READ     => "FALSE",
      EN_ECC_WRITE    => "FALSE",
      RDADDRCHANGEA   => "FALSE",
      RDADDRCHANGEB   => "FALSE",
      RSTREG_PRIORITY_A => "RSTREG",
      RSTREG_PRIORITY_B => "RSTREG",
      SLEEP_ASYNC     => "FALSE",
      INIT_FILE       => "NONE",
      INIT_A          => X"000000000",
      INIT_B          => X"000000000",
      SRVAL_A         => X"000000000",
      SRVAL_B         => X"000000000"
    )
    port map (
      -- Data outputs
      DOUTADOUT   => douta,
      DOUTBDOUT   => doutb,
      DOUTPADOUTP => open,
      DOUTPBDOUTP => open,

      -- Unused cascade/ECC outputs
      CASDOUTA      => open,
      CASDOUTB      => open,
      CASDOUTPA     => open,
      CASDOUTPB     => open,
      CASOUTDBITERR => open,
      CASOUTSBITERR => open,
      DBITERR       => open,
      ECCPARITY     => open,
      RDADDRECC     => open,
      SBITERR       => open,

      -- Tie-off cascade/ECC inputs
      CASDIMUXA       => Z1,
      CASDIMUXB       => Z1,
      CASDINA         => Z32,
      CASDINB         => Z32,
      CASDINPA        => Z4,
      CASDINPB        => Z4,
      CASDOMUXA       => Z1,
      CASDOMUXB       => Z1,
      CASDOMUXEN_A    => Z1,
      CASDOMUXEN_B    => Z1,
      CASINDBITERR    => Z1,
      CASINSBITERR    => Z1,
      CASOREGIMUXA    => Z1,
      CASOREGIMUXB    => Z1,
      CASOREGIMUXEN_A => Z1,
      CASOREGIMUXEN_B => Z1,
      ECCPIPECE       => Z1,
      INJECTDBITERR   => Z1,
      INJECTSBITERR   => Z1,

      -- Port A address/control
      ADDRARDADDR   => addr_a_15,
      ADDRENA       => Z1,
      CLKARDCLK     => aclk,
      ENARDEN       => '1',
      REGCEAREGCE   => '1',
      RSTRAMARSTRAM => rst,
      RSTREGARSTREG => rst,
      SLEEP         => '0',
      WEA           => wea,

      -- Port A data inputs
      DINADIN       => dina,
      DINPADINP     => Z4,

      -- Port B address/control
      ADDRBWRADDR => addr_b_15,
      ADDRENB     => Z1,
      CLKBWRCLK   => aclk,
      ENBWREN     => '1',
      REGCEB      => '1',
      RSTRAMB     => rst,
      RSTREGB     => rst,
      WEBWE       => webwe,

      -- Port B data inputs
      DINBDIN     => dinb,
      DINPBDINP   => Z4
    );

end architecture;