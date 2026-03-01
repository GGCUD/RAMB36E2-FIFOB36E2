library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fifo is
end entity;

architecture tb of tb_fifo is
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';

  signal din     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal wr_en   : std_logic := '0';
  signal full    : std_logic;

  signal rd_en      : std_logic := '0';
  signal dout       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dout_valid : std_logic;
  signal empty      : std_logic;

  signal cycle_cnt : integer := 0;

  procedure tick is
  begin
    wait until rising_edge(aclk);
    wait for 1 ns;
  end procedure;

begin
  -- clock 100 MHz
  aclk <= not aclk after 5 ns;

  -- DUT
  u_dut : entity work.fifo(rtl)
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
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

  -- cycle counter
  process(aclk)
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        cycle_cnt <= 0;
      else
        cycle_cnt <= cycle_cnt + 1;
      end if;
    end if;
  end process;

  stim : process
    variable i : integer;
    variable exp : std_logic_vector(DATA_WIDTH-1 downto 0);
  begin
    -- reset
    aresetn <= '0';
    din <= (others => '0');
    wr_en <= '0';
    rd_en <= '0';

    for i in 0 to 4 loop
      tick;
    end loop;

    aresetn <= '1';
    tick;

    assert empty = '1' report "After reset: empty must be 1" severity failure;
    for i in 0 to 15 loop
      assert full = '0' report "Unexpected FULL during initial writes" severity failure;

      din <= std_logic_vector(to_unsigned(16#1000# + i, DATA_WIDTH));
      wr_en <= '1';
      tick;

      wr_en <= '0';
      tick;
    end loop;

    assert empty = '0' report "After writes: empty must be 0" severity failure;

    for i in 0 to 15 loop
      exp := std_logic_vector(to_unsigned(16#1000# + i, DATA_WIDTH));

      -- request read
      assert empty = '0' report "Unexpected EMPTY before read @i=" & integer'image(i) severity failure;
      rd_en <= '1';
      tick;

      -- response cycle
      rd_en <= '0';
      tick;

      assert dout_valid = '1'
        report "Expected dout_valid=1 @cycle=" & integer'image(cycle_cnt) & " i=" & integer'image(i)
        severity failure;

      assert dout = exp
        report "DATA mismatch @cycle=" & integer'image(cycle_cnt) &
               " i=" & integer'image(i) &
               " dout=" & integer'image(to_integer(unsigned(dout))) &
               " exp="  & integer'image(to_integer(unsigned(exp)))
        severity failure;
    end loop;

    assert empty = '1' report "After reads: empty must be 1" severity failure;

    report "TB PASS" severity note;
    wait;
  end process;

end architecture;