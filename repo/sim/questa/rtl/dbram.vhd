library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dbram is
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

architecture rtl of dbram is
  constant DEPTH : integer := 2**ADDR_WIDTH;

  type ram_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ram : ram_t := (others => (others => '0'));

  attribute ram_style : string;
  attribute ram_style of ram : signal is "block";
  signal ram_data_a, ram_data_b : std_logic_vector(DATA_WIDTH-1 downto 0);
begin


  process(aclk)
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        ram_data_a <= (others => '0');
        ram_data_b <= (others => '0');
      else
        -- Port A
        if write_a_i = '1' then
          ram(to_integer(unsigned(addr_a_i))) <= write_a_data_i;
          ram_data_a <= write_a_data_i;  -- WRITE_FIRST
        else
          ram_data_a <= ram(to_integer(unsigned(addr_a_i)));
        end if;

        -- Port B
        if write_b_i = '1' then
          ram(to_integer(unsigned(addr_b_i))) <= write_b_data_i;
          ram_data_b <= write_b_data_i;  -- WRITE_FIRST
        else
          ram_data_b <= ram(to_integer(unsigned(addr_b_i)));
        end if;
      end if;
    end if;
  end process;
  
  read_a_data_o <= ram_data_a;
  read_b_data_o <= ram_data_b;

end architecture;