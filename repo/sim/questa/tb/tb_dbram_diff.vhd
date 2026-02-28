library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dbram_diff is
end entity;

architecture tb of tb_dbram_diff is
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;
  constant DEPTH      : integer := 2**ADDR_WIDTH;

  constant CYCLES : integer := 300; -- сколько тактов после directed

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';

  signal addr_a_i, addr_b_i : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal write_a_i, write_b_i : std_logic := '0';
  signal write_a_data_i, write_b_data_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  signal dut_ra, dut_rb : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ref_ra, ref_rb : std_logic_vector(DATA_WIDTH-1 downto 0);

  -- побитово
  function slv_eq(a,b : std_logic_vector) return boolean is
  begin
    if a'length /= b'length then return false; end if;
    for i in a'range loop
      if a(i) /= b(i) then return false; end if;
    end loop;
    return true;
  end function;

  function slv_to_hex(slv : std_logic_vector) return string is
    constant N : integer := (slv'length + 3) / 4;
    variable ext : std_logic_vector(N*4-1 downto 0) := (others => '0');
    variable res : string(1 to N);
    variable nib : std_logic_vector(3 downto 0);
    variable v   : integer;
    variable ok  : boolean;
  begin
    ext(slv'length-1 downto 0) := slv;

    for k in 0 to N-1 loop
      nib := ext((N-1-k)*4+3 downto (N-1-k)*4);
      ok := true;
      for i in 0 to 3 loop
        if not (nib(i) = '0' or nib(i) = '1') then ok := false; end if;
      end loop;
      if not ok then
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
    wait until falling_edge(aclk);
    wait for 0 ns;
  end procedure;

  procedure drive_phase is
  begin
    wait until rising_edge(aclk);
  end procedure;

begin
  aclk <= not aclk after 5 ns;

  -- DUT
  u_dut : entity work.dbram(rtl)
    generic map ( DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH )
    port map (
      aclk => aclk, aresetn => aresetn,
      addr_a_i => addr_a_i, addr_b_i => addr_b_i,
      write_a_i => write_a_i, write_b_i => write_b_i,
      read_a_data_o => dut_ra, read_b_data_o => dut_rb,
      write_a_data_i => write_a_data_i, write_b_data_i => write_b_data_i
    );

  -- REF
  u_ref : entity work.dbram_ref(rtl)
    generic map ( DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH )
    port map (
      aclk => aclk, aresetn => aresetn,
      addr_a_i => addr_a_i, addr_b_i => addr_b_i,
      write_a_i => write_a_i, write_b_i => write_b_i,
      read_a_data_o => ref_ra, read_b_data_o => ref_rb,
      write_a_data_i => write_a_data_i, write_b_data_i => write_b_data_i
    );

  -- stimulus
  stim : process
    variable i : integer;
    variable a_addr, b_addr : integer;
    variable seq : unsigned(DATA_WIDTH-1 downto 0) := x"00000001";
    constant delta : unsigned(DATA_WIDTH-1 downto 0) := x"9E3779B9";
  begin
    -- reset
    aresetn <= '0';
    write_a_i <= '0';
    write_b_i <= '0';
    addr_a_i <= (others => '0');
    addr_b_i <= (others => '0');
    write_a_data_i <= (others => '0');
    write_b_data_i <= (others => '0');

    for i in 0 to 4 loop
      tick;
    end loop;

    aresetn <= '1';
    tick;

    for i in 0 to 15 loop
      drive_phase;
      addr_a_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      write_a_data_i <= std_logic_vector(to_unsigned(16#1000# + i, DATA_WIDTH));
      write_a_i <= '1';

      addr_b_i <= std_logic_vector(to_unsigned((i+1) mod DEPTH, ADDR_WIDTH));
      write_b_i <= '0';
      write_b_data_i <= (others => '0');

      tick;

      write_a_i <= '0';
      tick;
    end loop;

    --оба читают
    for i in 0 to 15 loop
      drive_phase;
      addr_a_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      addr_b_i <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
      write_a_i <= '0';
      write_b_i <= '0';
      tick;
    end loop;

    --адреса и данные от счётчика i
    for i in 0 to CYCLES-1 loop
      drive_phase;
      a_addr := i mod DEPTH;
      b_addr := (i*3 + 7) mod DEPTH;

      -- write pattern
      if (i mod 4 = 0) then 
        write_a_i <= '1'; 
      else 
        write_a_i <=  '0';  
      end if;

      if (i mod 7 = 0) then
        write_b_i <= '1'; 
      else
        write_b_i <= '0';
      end if;

      -- избегает коллизии при записи
      --if (a_addr = b_addr) and ((i mod 4 = 0) or (i mod 7 = 0)) then
      --  b_addr := (b_addr + 1) mod DEPTH;
      --end if;

      addr_a_i <= std_logic_vector(to_unsigned(a_addr, ADDR_WIDTH));
      addr_b_i <= std_logic_vector(to_unsigned(b_addr, ADDR_WIDTH));

      seq := seq + delta;
      write_a_data_i <= std_logic_vector(seq);
      write_b_data_i <= std_logic_vector(not seq);

      tick;
    end loop;

    report "TB PASS" severity note;
    wait;
  end process;

  checker : process
    variable cyc : integer := 0;
  begin
    wait until rising_edge(aclk);
    wait for 1 ns;
    cyc := cyc + 1;

    if aresetn = '1' then
      assert slv_eq(dut_ra, ref_ra)
        report "Mismatch A @cycle=" & integer'image(cyc) &
               " addrA=" & slv_to_hex(addr_a_i) &
               " wea=" & std_logic'image(write_a_i) &
               " dinA=0x" & slv_to_hex(write_a_data_i) &
               " dut=0x" & slv_to_hex(dut_ra) &
               " ref=0x" & slv_to_hex(ref_ra)
        severity failure;

      assert slv_eq(dut_rb, ref_rb)
        report "Mismatch B @cycle=" & integer'image(cyc) &
               " addrB=" & slv_to_hex(addr_b_i) &
               " web=" & std_logic'image(write_b_i) &
               " dinB=0x" & slv_to_hex(write_b_data_i) &
               " dut=0x" & slv_to_hex(dut_rb) &
               " ref=0x" & slv_to_hex(ref_rb)
        severity failure;
    end if;
  end process;

end architecture;