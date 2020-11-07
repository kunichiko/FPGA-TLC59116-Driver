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

signal ledmodes :led_mode_array(0 to 15);

--for I2C I/F
signal	SDAIN,SDAOUT	:std_logic;
signal	SCLIN,SCLOUT	:std_logic;
signal	I2CCLKEN	:std_logic;
signal	I2C_TXDAT	:std_logic_vector(7 downto 0);		--tx data in
signal	I2C_RXDAT	:std_logic_vector(7 downto 0);	--rx data out
signal	I2C_WRn		:std_logic;						--write
signal	I2C_RDn		:std_logic;						--read
signal	I2C_TXEMP	:std_logic;							--tx buffer empty
signal	I2C_RXED	:std_logic;							--rx buffered
signal	I2C_NOACK	:std_logic;							--no ack
signal	I2C_COLL	:std_logic;							--collision detect
signal	I2C_NX_READ	:std_logic;							--next data is read
signal	I2C_RESTART	:std_logic;							--make re-start condition
signal	I2C_START	:std_logic;							--make start condition
signal	I2C_FINISH	:std_logic;							--next data is final(make stop condition)
signal	I2C_F_FINISH :std_logic;							--next data is final(make stop condition)
signal	I2C_INIT	:std_logic;

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

tlc59116 :I2C_TLC59116 port map(
    -- I2C I/F
    TXOUT	=>I2C_TXDAT,
    RXIN	=>I2C_RXDAT,
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

    -- LED Control Ports
    LEDMODES => ledmodes,

    clk		=>sysclk,
    rstn	=>srstn
);

process(sysclk,srstn)begin
    if(srstn='0')then
        ledmodes<=(others => "00");
    elsif(sysclk' event and sysclk='1')then
        ledmodes<=(others => "00");
        if(pPsw(0)='0')then
            ledmodes(0)<="10";
        end if;
        if(pPsw(1)='0')then
            ledmodes(1)<="10";
        end if;
        if(pPsw(2)='0')then
            ledmodes(2)<="10";
        end if;
        if(pPsw(3)='0')then
            ledmodes(3)<="10";
        end if;
    end if;
end process;

end rtl;