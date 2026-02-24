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

  function to_idx(a : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(a));
  end function;

  constant SLV_X : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'X');
begin

  process(aclk)
    variable ia, ib  : integer;
    variable same_ab : boolean;
    variable old_a   : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable old_b   : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable out_a   : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable out_b   : std_logic_vector(DATA_WIDTH-1 downto 0);
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        read_a_data_o <= (others => '0');
        read_b_data_o <= (others => '0');
      else
        ia := to_idx(addr_a_i);
        ib := to_idx(addr_b_i);
        same_ab := (ia = ib);

        -- синхронное чтение: что было в RAM на этот такт
        old_a := ram(ia);
        old_b := ram(ib);

        out_a := old_a;
        out_b := old_b;

        -- WRITE_FIRST, при конфликте write/write на один адрес — приоритет B
        if (write_a_i = '1') and not (write_b_i = '1' and same_ab) then
          ram(ia) <= write_a_data_i;
          out_a   := write_a_data_i;
        end if;

        if (write_b_i = '1') then
          ram(ib) <= write_b_data_i;
          out_b   := write_b_data_i;
          if (write_a_i = '1') and same_ab then
            out_a := write_b_data_i;
          end if;
        end if;

        -- Коллизии как у сим-модели BRAM (X на выходах/памяти)
        -- synthesis translate_off
        if same_ab then
          if (write_a_i = '1' and write_b_i = '1') then
            -- как в unisim память (X), но выходы НЕ обязательно X
            ram(ia) <= SLV_X;
          
          elsif (write_a_i = '1' and write_b_i = '0') then
            out_b := SLV_X; -- A пишет, B читает тот же адрес
          
          elsif (write_a_i = '0' and write_b_i = '1') then
            out_a := SLV_X; -- B пишет, A читает тот же адрес
          end if;
        end if;
        -- synthesis translate_on
        read_a_data_o <= out_a;
        read_b_data_o <= out_b;
      end if;
    end if;
  end process;

end architecture;