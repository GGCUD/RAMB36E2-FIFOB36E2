--xpm_fifo_axis
--RAMB36E2

ENTITY fifo_axis IS
  GENERIC (
    TDATA_WIDTH    : INTEGER := 64;
    FIFO_DEPTH_LOG : INTEGER := 9
  );
  PORT (
    aclk    : IN STD_LOGIC;
    aresetn : IN STD_LOGIC := '0';

    rd_word_num : OUT STD_LOGIC_VECTOR(FIFO_DEPTH_LOG + 1 - 1 DOWNTO 0) := (OTHERS => '0');

    s_axis_tdata  : IN  STD_LOGIC_VECTOR(TDATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    s_axis_tvalid : IN  STD_LOGIC                                  := '0';
    s_axis_tready : OUT STD_LOGIC                                  := '0';

    m_axis_tdata  : OUT STD_LOGIC_VECTOR(TDATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    m_axis_tvalid : OUT STD_LOGIC                                  := '0';
    m_axis_tready : IN  STD_LOGIC                                  := '0'
  );
END ENTITY fifo_axis;

ENTITY dbram IS
  GENERIC (
    DATA_WIDTH : INTEGER := 32;
    ADDR_WIDTH : INTEGER := 10;
  );
  PORT (
    aclk    : IN STD_LOGIC;
    aresetn : IN STD_LOGIC := '0';

    addr_a_i : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    addr_b_i : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

    write_a_i : IN STD_LOGIC := '0';
    write_b_i : IN STD_LOGIC := '0';

    read_a_data_o : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    read_b_data_o : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

    write_a_data_i : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    write_b_data_i : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0')
  );
END ENTITY dbram;
