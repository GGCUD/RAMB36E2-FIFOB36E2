library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
  generic (
    DATA_WIDTH : integer := 32;
    ADDR_WIDTH : integer := 10   -- depth = 2**ADDR_WIDTH
  );
  port (
    aclk    : in  std_logic;
    aresetn : in  std_logic := '0';

    din     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    wr_en   : in  std_logic := '0';
    full    : out std_logic := '0';

    rd_en      : in  std_logic := '0';
    dout       : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    dout_valid : out std_logic := '0';
    empty      : out std_logic := '1'
  );
end entity;

architecture rtl of fifo is
  constant DEPTH   : integer := 2**ADDR_WIDTH;
  constant DEPTH_U : unsigned(ADDR_WIDTH downto 0) := to_unsigned(DEPTH, ADDR_WIDTH+1);

  signal wr_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal count  : unsigned(ADDR_WIDTH downto 0)   := (others => '0'); -- 0..DEPTH

  signal full_s  : std_logic;
  signal empty_s : std_logic;

  signal wr_hs : std_logic;
  signal rd_hs : std_logic;
  signal rd_hs_d : std_logic := '0';

  -- dbram signals
  signal addr_a_i, addr_b_i : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_a_i, write_b_i : std_logic;
  signal write_a_data_i, write_b_data_i : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_a_data_o, read_b_data_o   : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal dout_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin
  empty_s <= '1' when count = 0       else '0';
  full_s  <= '1' when count = DEPTH_U else '0';

  empty <= empty_s;
  full  <= full_s;

  wr_hs <= '1' when (wr_en = '1' and full_s  = '0') else '0';
  rd_hs <= '1' when (rd_en = '1' and empty_s = '0') else '0';

  addr_a_i <= std_logic_vector(wr_ptr);
  addr_b_i <= std_logic_vector(rd_ptr);

  write_a_i      <= wr_hs;
  write_a_data_i <= din;

  write_b_i      <= '0';
  write_b_data_i <= (others => '0');

  u_mem : entity work.dbram(rtl)
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      aclk => aclk,
      aresetn => aresetn,

      addr_a_i => addr_a_i,
      addr_b_i => addr_b_i,

      write_a_i => write_a_i,
      write_b_i => write_b_i,

      read_a_data_o => read_a_data_o,
      read_b_data_o => read_b_data_o,

      write_a_data_i => write_a_data_i,
      write_b_data_i => write_b_data_i
    );

  -- align dout with dout_valid
  dout <= dout_reg;

  process(aclk)
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
        count  <= (others => '0');

        rd_hs_d    <= '0';
        dout_valid <= '0';
        dout_reg   <= (others => '0');
      else
        rd_hs_d    <= rd_hs;
        dout_valid <= rd_hs_d;

        if rd_hs_d = '1' then
            dout_reg <= read_b_data_o;
        end if;

        -- pointers
        if wr_hs = '1' then
            wr_ptr <= wr_ptr + 1;
        end if;

        if rd_hs = '1' then
            rd_ptr <= rd_ptr + 1;
        end if;

        -- count update
        if wr_hs = '1' then
            if rd_hs = '0' then
                count <= count + 1;
            end if;
        else
            if rd_hs = '1' then
                count <= count - 1;
            end if;
        end if;
      end if;
    end if;
  end process;

end architecture;