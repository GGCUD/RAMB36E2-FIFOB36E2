library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fifo is
end entity;

architecture tb of tb_fifo is
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;
  constant DEPTH      : integer := 2**ADDR_WIDTH;

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';

  signal din     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal wr_en   : std_logic := '0';
  signal full    : std_logic;

  signal rd_en      : std_logic := '0';
  signal dout       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dout_valid : std_logic;
  signal empty      : std_logic;
  -- queury
  type q_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH downto 0);
  signal q_mem      : q_t := (others => (others => '0'))
  signal q_wr_ptr   : integer range 0 to DEPTH - 1 := 0;
  signal q_rd_ptr   : integer range 0 to DEPTH - 1 := 0;
  signal q_count    : integer range 0 to DEPTH := 0;

  signal cycle_cnt : integer := 0;

    procedure tick is
  begin
    wait until rising_edge(aclk);
    wait for 1 ns;
  end procedure;

begin

    aclk <= not aclk after 5 ns;

    u_dut : entity work.fifo(rtl)
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map(
            aclk => aclk,
            aresetn => aresetn,
            din => din,
            wr_en => wr_en,
            full => full,
            rd_en => rd_en,
            dout => dout,
            dout_valid => dout_valid,
            empty => empty
        );
    

    
end architecture;