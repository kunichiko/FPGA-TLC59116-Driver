LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;
	use work.I2C_pkg.all;
	use work.I2C_TLC59116_pkg.all;

entity I2C_SAMPLE is
generic(
    SCFREQ		:integer	:=48000		--kHz
);
port(
	pClk		:in std_logic;

	pI2Cscl		: inout std_logic;
    pI2Csda		: inout std_logic;

    -- switch
    pPsw		: in std_logic_vector(3 downto 0);

    -- reset sw
	rstn		:in std_logic
);
end I2C_SAMPLE;

architecture rtl of I2C_SAMPLE is

signal	sysclk	:std_logic;
signal	srstn	:std_logic;

signal ledmodes0 :led_mode_array(0 to 15);
signal ledmodes1 :led_mode_array(0 to 15);

--for I2C I/F
signal	SDAIN,SDAOUT	:std_logic;
signal	SCLIN,SCLOUT	:std_logic;
signal	I2CCLKEN	:std_logic;

signal	I2C_TXDAT	:std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--tx data in
signal	I2C_RXDAT	:std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--rx data out
signal	I2C_WRn		:std_logic;			    			--write
signal	I2C_RDn		:std_logic;				    		--read
signal	I2C_TXEMP	:std_logic;							--tx buffer empty
signal	I2C_RXED	:std_logic;							--rx buffered
signal	I2C_NOACK	:std_logic;							--no ack
signal	I2C_COLL	:std_logic;							--collision detect
signal	I2C_NX_READ	:std_logic;							--next data is read
signal	I2C_RESTART	:std_logic;							--make re-start condition
signal	I2C_START	:std_logic;							--make start condition
signal	I2C_FINISH	:std_logic;							--next data is final(make stop condition)
signal	I2C_F_FINISH :std_logic;						--next data is final(make stop condition)
signal	I2C_INIT	:std_logic;


constant NUM_DRIVERS: integer := 1;

signal	I2C_TXDAT_PXY	:i2cdat_array(NUM_DRIVERS-1 downto 0);		--tx data in
signal	I2C_RXDAT_PXY	:i2cdat_array(NUM_DRIVERS-1 downto 0);	--rx data out
signal	I2C_WRn_PXY		:std_logic_vector(NUM_DRIVERS-1 downto 0);						--write
signal	I2C_RDn_PXY		:std_logic_vector(NUM_DRIVERS-1 downto 0);						--read
signal	I2C_TXEMP_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--tx buffer empty
signal	I2C_RXED_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--rx buffered
signal	I2C_NOACK_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--no ack
signal	I2C_COLL_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--collision detect
signal	I2C_NX_READ_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--next data is read
signal	I2C_RESTART_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--make re-start condition
signal	I2C_START_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--make start condition
signal	I2C_FINISH_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);							--next data is final(make stop condition)
signal	I2C_F_FINISH_PXY :std_logic_vector(NUM_DRIVERS-1 downto 0);							--next data is final(make stop condition)
signal	I2C_INIT_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);

component I2CIF
port(
	DATIN	:in	    std_logic_vector(I2CDAT_WIDTH-1 downto 0);		--tx data in
	DATOUT	:out    std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--rx data out
	WRn		:in     std_logic;						--write
	RDn		:in     std_logic;						--read

	TXEMP	:out    std_logic;							--tx buffer empty
	RXED	:out    std_logic;							--rx buffered
	NOACK	:out    std_logic;							--no ack
	COLL	:out    std_logic;							--collision detect
	NX_READ	:in     std_logic;							--next data is read
	RESTART	:in     std_logic;							--make re-start condition
	START	:in     std_logic;							--make start condition
	FINISH	:in     std_logic;							--next data is final(make stop condition)
	F_FINISH :in    std_logic;							--next data is final(make stop condition)
	INIT	:in     std_logic;
	
--	INTn :out	std_logic;

	SDAIN   :in     std_logic;
	SDAOUT  :out    std_logic;
	SCLIN   :in     std_logic;
	SCLOUT  :out    std_logic;

	SFT 	:in		std_logic;
	clk	    :in		std_logic;
	rstn    :in     std_logic
);
end component;

component I2C_MUX is
generic(
    NUM_DRIVERS	:integer	:=2
);
port(
    -- I2C
    TXOUT		:out	std_logic_vector(7 downto 0);	--tx data in
    RXIN		:in		std_logic_vector(7 downto 0);	--rx data out
    WRn			:out	std_logic;						--write
    RDn			:out	std_logic;						--read
    
    TXEMP		:in		std_logic;						--tx buffer empty
    RXED		:in		std_logic;						--rx buffered
    NOACK		:in		std_logic;						--no ack
    COLL		:in		std_logic;						--collision detect
    NX_READ		:out	std_logic;						--next data is read
    RESTART		:out	std_logic;						--make re-start condition
    START		:out	std_logic;						--make start condition
    FINISH		:out	std_logic;						--next data is final(make stop condition)
    F_FINISH	 :out	std_logic;						--next data is final(make stop condition by force)
    INIT		:out	std_logic;
    
    -- for Driver
    DATIN_PXY   :in     i2cdat_array(NUM_DRIVERS-1 downto 0);		--tx data in
    DATOUT_PXY	:out    i2cdat_array(NUM_DRIVERS-1 downto 0);		--rx data out
    WRn_PXY		:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--write
    RDn_PXY		:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--read
    
    TXEMP_PXY   :out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--tx buffer empty
    RXED_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--rx buffered
    NOACK_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--no ack
    COLL_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--collision detect
    NX_READ_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is read
    RESTART_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--make re-start condition
    START_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--make start condition
    FINISH_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
    F_FINISH_PXY :in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
    INIT_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);
    
    clk			:in std_logic;
    rstn		:in std_logic
);
end component;

component I2C_TLC59116 is
port(
    -- I2C
    TXOUT		:out	std_logic_vector(7 downto 0);	--tx data in
    RXIN		:in		std_logic_vector(7 downto 0);	--rx data out
    WRn			:out	std_logic;						--write
    RDn			:out	std_logic;						--read
    
    TXEMP		:in		std_logic;						--tx buffer empty
    RXED		:in		std_logic;						--rx buffered
    NOACK		:in		std_logic;						--no ack
    COLL		:in		std_logic;						--collision detect
    NX_READ		:out	std_logic;						--next data is read
    RESTART		:out	std_logic;						--make re-start condition
    START		:out	std_logic;						--make start condition
    FINISH		:out	std_logic;						--next data is final(make stop condition)
    F_FINISH	:out	std_logic;						--next data is final(make stop condition by force)
    INIT		:out	std_logic;
    
    -- Ports
    LEDMODES    :in led_mode_array(0 to 15);

    clk			:in std_logic;
    rstn		:in std_logic
);
end component;

component SFTCLK
generic(
	SYS_CLK	:integer	:=20000;
	OUT_CLK	:integer	:=1600;
	selWIDTH :integer	:=2
);
port(
	sel		:in std_logic_vector(selWIDTH-1 downto 0);
	SFT		:out std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

begin

I2C	:I2CIF port map(
    DATIN	=>I2C_TXDAT,
    DATOUT	=>I2C_RXDAT,
    WRn		=>I2C_WRn,
    RDn		=>I2C_RDn,

    TXEMP	=>I2C_TXEMP,
    RXED	=>I2C_RXED,
    NOACK	=>I2C_NOACK,
    COLL	=>I2C_COLL,
    NX_READ	=>I2C_NX_READ,
    RESTART	=>I2C_RESTART,
    START	=>I2C_START,
    FINISH	=>I2C_FINISH,
    F_FINISH=>I2C_F_FINISH,
    INIT	=>I2C_INIT,
    

    SDAIN 	=>SDAIN,
    SDAOUT	=>SDAOUT,
    SCLIN	=>SCLIN,
    SCLOUT	=>SCLOUT,

    SFT		=>I2CCLKEN,
    clk		=>sysclk,
    rstn 	=>srstn
);

I2CMUX :I2C_MUX generic map(NUM_DRIVERS=>NUM_DRIVERS) port map(
    -- I2C
    TXOUT   => I2C_TXDAT,
    RXIN    => I2C_RXDAT,
    WRn     => I2C_WRn,
    RDn     => I2C_RDn,
    
    TXEMP   => I2C_TXEMP,
    RXED	=> I2C_RXED,
    NOACK	=> I2C_NOACK,
    COLL	=> I2C_COLL,
    NX_READ	=> I2C_NX_READ,
    RESTART	=> I2C_RESTART,
    START	=> I2C_START,
    FINISH	=> I2C_FINISH,
    F_FINISH=> I2C_F_FINISH,
    INIT	=> I2C_INIT,
    
    -- for Driver
    DATIN_PXY   => I2C_TXDAT_PXY,
    DATOUT_PXY	=> I2C_RXDAT_PXY,
    WRn_PXY		=> I2C_WRn_PXY,
    RDn_PXY		=> I2C_WRn_PXY,
    
    TXEMP_PXY   => I2C_TXEMP_PXY,
    RXED_PXY	=> I2C_RXED_PXY,
    NOACK_PXY	=> I2C_NOACK_PXY,
    COLL_PXY	=> I2C_COLL_PXY,
    NX_READ_PXY	=> I2C_NX_READ_PXY,
    RESTART_PXY	=> I2C_RESTART_PXY,
    START_PXY	=> I2C_START_PXY,
    FINISH_PXY	=> I2C_FINISH_PXY,
    F_FINISH_PXY => I2C_F_FINISH_PXY,
    INIT_PXY	=> I2C_INIT_PXY,
    
    clk			=> sysclk,
    rstn		=> srstn
);

-- System signals
sysclk <= pClk;
srstn  <= rstn;

-- I2C signals
pI2CSCL <= '0' when SCLOUT='0' else 'Z';
pI2CSDA <= '0' when SDAOUT='0' else 'Z';
process(sysclk,srstn)begin
    if(srstn='0')then
        SCLIN<='1';
        SDAIN<='1';
    elsif(sysclk' event and sysclk='1')then
        SCLIN<=pI2CSCL;
        SDAIN<=pI2CSDA;
    end if;
end process;

i2cclk :SFTCLK
generic map(SCFREQ,800,1)
port map(
    SEL => "0",
    SFT =>I2CCLKEN,
    CLK =>sysclk,
    RSTN => srstn
);

--
-- LED driver 
--

tlc59116_0 :I2C_TLC59116 port map(
    -- I2C I/F
    TXOUT	=>I2C_TXDAT_PXY(0),
    RXIN	=>I2C_RXDAT_PXY(0),
    WRn		=>I2C_WRn_PXY(0),
    RDn		=>I2C_RDn_PXY(0),

    TXEMP	=>I2C_TXEMP_PXY(0),
    RXED	=>I2C_RXED_PXY(0),
    NOACK	=>I2C_NOACK_PXY(0),
    COLL	=>I2C_COLL_PXY(0),
    NX_READ	=>I2C_NX_READ_PXY(0),
    RESTART	=>I2C_RESTART_PXY(0),
    START	=>I2C_START_PXY(0),
    FINISH	=>I2C_FINISH_PXY(0),
    F_FINISH=>I2C_F_FINISH_PXY(0),
    INIT	=>I2C_INIT_PXY(0),

    -- LED Control Ports
    LEDMODES => ledmodes0,

    clk		=>sysclk,
    rstn	=>srstn
);

-- tlc59116_1 :I2C_TLC59116 port map(
--     -- I2C I/F
--     TXOUT	=>I2C_TXDAT_PXY(1),
--     RXIN	=>I2C_RXDAT_PXY(1),
--     WRn		=>I2C_WRn_PXY(1),
--     RDn		=>I2C_RDn_PXY(1),

--     TXEMP	=>I2C_TXEMP_PXY(1),
--     RXED	=>I2C_RXED_PXY(1),
--     NOACK	=>I2C_NOACK_PXY(1),
--     COLL	=>I2C_COLL_PXY(1),
--     NX_READ	=>I2C_NX_READ_PXY(1),
--     RESTART	=>I2C_RESTART_PXY(1),
--     START	=>I2C_START_PXY(1),
--     FINISH	=>I2C_FINISH_PXY(1),
--     F_FINISH=>I2C_F_FINISH_PXY(1),
--     INIT	=>I2C_INIT_PXY(1),

--     -- LED Control Ports
--     LEDMODES => ledmodes1,

--     clk		=>sysclk,
--     rstn	=>srstn
-- );

process(sysclk,srstn)begin
    if(srstn='0')then
        ledmodes0<=(others => "00");
        ledmodes1<=(others => "00");
    elsif(sysclk' event and sysclk='1')then
        ledmodes0<=(others => "00");
        ledmodes1<=(others => "00");
        if(pPsw(0)='0')then
            ledmodes0(0)<="10";
        end if;
        if(pPsw(1)='0')then
            ledmodes0(1)<="10";
        end if;
        if(pPsw(2)='0')then
            ledmodes1(0)<="11";
        end if;
        if(pPsw(3)='0')then
            ledmodes1(0)<="11";
        end if;
    end if;
end process;

end rtl;