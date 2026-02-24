library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dbram_diff is
end entity;

architecture tb of tb_dbram_diff is
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';

  signal addr_a_i, addr_b_i : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal write_a_i, write_b_i : std_logic := '0';
  signal write_a_data_i, write_b_data_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  signal dut_ra, dut_rb : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ref_ra, ref_rb : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal lfsr : std_logic_vector(31 downto 0) := x"1ACEB00C";

  function slv_eq(a,b : std_logic_vector) return boolean is
  begin
    if a'length /= b'length then return false; end if;
    for i in a'range loop
      if a(i) /= b(i) then return false; end if;
    end loop;
    return true;
  end function;

  function nibble_has_only_01(n : std_logic_vector(3 downto 0)) return boolean is
  begin
    for i in 0 to 3 loop
      if not (n(i) = '0' or n(i) = '1') then
        return false;
      end if;
    end loop;
    return true;
  end function;

  function slv_to_hex(slv : std_logic_vector) return string is
    constant N : integer := (slv'length + 3) / 4;
    variable ext : std_logic_vector(N*4-1 downto 0) := (others => '0');
    variable res : string(1 to N);
    variable nib : std_logic_vector(3 downto 0);
    variable v   : integer;
  begin
    -- предполагаем стандартный downto-вектор
    ext(slv'length-1 downto 0) := slv;

    for k in 0 to N-1 loop
      nib := ext((N-1-k)*4+3 downto (N-1-k)*4);

      if not nibble_has_only_01(nib) then
        res(k+1) := 'X';
      else
        v := to_integer(unsigned(nib));
        if v < 10 then
          res(k+1) := character'val(character'pos('0') + v);
        else
          res(k+1) := character'val(character'pos('A') + (v-10));
        end if;
      end if;
    end loop;

    return res;
  end function;

  procedure tick is
  begin
    wait until rising_edge(aclk);
    wait for 1 ns;
  end procedure;

begin
  aclk <= not aclk after 5 ns;

  u_dut : entity work.dbram(rtl)
    generic map ( DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH )
    port map (
      aclk => aclk, aresetn => aresetn,
      addr_a_i => addr_a_i, addr_b_i => addr_b_i,
      write_a_i => write_a_i, write_b_i => write_b_i,
      read_a_data_o => dut_ra, read_b_data_o => dut_rb,
      write_a_data_i => write_a_data_i, write_b_data_i => write_b_data_i
    );

  u_ref : entity work.dbram_ref(rtl)
    generic map ( DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH )
    port map (
      aclk => aclk, aresetn => aresetn,
      addr_a_i => addr_a_i, addr_b_i => addr_b_i,
      write_a_i => write_a_i, write_b_i => write_b_i,
      read_a_data_o => ref_ra, read_b_data_o => ref_rb,
      write_a_data_i => write_a_data_i, write_b_data_i => write_b_data_i
    );

  stim : process
    variable i : integer;
  begin
    aresetn <= '0';
    write_a_i <= '0'; write_b_i <= '0';
    addr_a_i <= (others => '0'); addr_b_i <= (others => '0');
    write_a_data_i <= (others => '0'); write_b_data_i <= (others => '0');

    for i in 0 to 4 loop
      tick;
    end loop;

    aresetn <= '1';
    tick;

    -- Directed 1
    for i in 0 to 7 loop
      addr_a_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      write_a_data_i <= std_logic_vector(to_unsigned(16#1000# + i, DATA_WIDTH));
      write_a_i <= '1';

      addr_b_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      write_b_i <= '0';
      tick;
      write_a_i <= '0';
    end loop;

    for i in 0 to 7 loop
      addr_a_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      addr_b_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      write_a_i <= '0';
      write_b_i <= '0';
      tick;
    end loop;

    -- Directed 2: A write, B read same addr => B may be X
    addr_a_i <= std_logic_vector(to_unsigned(5, ADDR_WIDTH));
    addr_b_i <= std_logic_vector(to_unsigned(5, ADDR_WIDTH));
    write_a_data_i <= x"AAAA5555";
    write_a_i <= '1';
    write_b_i <= '0';
    tick;
    write_a_i <= '0';

    -- Directed 3: both write same addr => X
    addr_a_i <= std_logic_vector(to_unsigned(9, ADDR_WIDTH));
    addr_b_i <= std_logic_vector(to_unsigned(9, ADDR_WIDTH));
    write_a_data_i <= x"11111111";
    write_b_data_i <= x"22222222";
    write_a_i <= '1';
    write_b_i <= '1';
    tick;
    write_a_i <= '0';
    write_b_i <= '0';

    -- Random: 500 cycles
    for i in 0 to 499 loop
      lfsr <= lfsr(30 downto 0) & (lfsr(31) xor lfsr(21) xor lfsr(1) xor lfsr(0));

      addr_a_i <= lfsr(ADDR_WIDTH-1 downto 0);
      addr_b_i <= lfsr(2*ADDR_WIDTH-1 downto ADDR_WIDTH);

      write_a_data_i <= lfsr;
      write_b_data_i <= not lfsr;

      write_a_i <= lfsr(3);
      write_b_i <= lfsr(7);

      tick;
    end loop;

    --report "TB PASS";
    --assert false report "DONE" severity failure;
    report "DONE" severity note;
    wait;
  end process;

  checker : process
  begin
    wait until rising_edge(aclk);
    wait for 1 ns;

    if aresetn = '1' then
      assert slv_eq(dut_ra, ref_ra)
        report "Mismatch A: DUT=0x" & slv_to_hex(dut_ra) & " REF=0x" & slv_to_hex(ref_ra)
        severity failure;

      assert slv_eq(dut_rb, ref_rb)
        report "Mismatch B: DUT=0x" & slv_to_hex(dut_rb) & " REF=0x" & slv_to_hex(ref_rb)
        severity failure;
    end if;
  end process;

end architecture;