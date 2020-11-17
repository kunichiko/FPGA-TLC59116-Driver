LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;
	use work.I2C_pkg.all;
	use work.I2C_TLC59116_pkg.all;

entity I2C_SAMPLE_RTC is
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
end I2C_SAMPLE_RTC;

architecture rtl of I2C_SAMPLE_RTC is

-- global signals
signal	sysclk	:std_logic;
signal	srstn	:std_logic;

--for I2C I/F
signal	SDAIN,SDAOUT    :std_logic;
signal	SCLIN,SCLOUT    :std_logic;
signal	I2CCLKEN	    :std_logic;

signal	I2C_TXDAT	    :std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--tx data in
signal	I2C_RXDAT	    :std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--rx data out
signal	I2C_WRn		    :std_logic;			    			        --write
signal	I2C_RDn		    :std_logic;				    		        --read
signal	I2C_TXEMP	    :std_logic;							        --tx buffer empty
signal	I2C_RXED	    :std_logic;							        --rx buffered
signal	I2C_NOACK	    :std_logic;							        --no ack
signal	I2C_COLL	    :std_logic;							        --collision detect
signal	I2C_NX_READ	    :std_logic;							        --next data is read
signal	I2C_RESTART	    :std_logic;							        --make re-start condition
signal	I2C_START	    :std_logic;							        --make start condition
signal	I2C_FINISH	    :std_logic;							        --next data is final(make stop condition)
signal	I2C_F_FINISH    :std_logic;				    		        --next data is final(make stop condition)
signal	I2C_INIT	    :std_logic;

component I2CIF
port(
	DATIN	:in	    std_logic_vector(I2CDAT_WIDTH-1 downto 0);		--tx data in
	DATOUT	:out    std_logic_vector(I2CDAT_WIDTH-1 downto 0);	    --rx data out
	WRn		:in     std_logic;						    --write
	RDn		:in     std_logic;						    --read

	TXEMP	:out    std_logic;							--tx buffer empty
	RXED	:out    std_logic;							--rx buffered
	NOACK	:out    std_logic;							--no ack
	COLL	:out    std_logic;							--collision detect
	NX_READ	:in     std_logic;							--next data is read
	RESTART	:in     std_logic;							--make re-start condition
	START	:in     std_logic;							--make start condition
	FINISH	:in     std_logic;							--next data is final(make stop condition)
	F_FINISH:in     std_logic;							--next data is final(make stop condition)
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

component I2Crtc is
    port(
        TXOUT		:out	std_logic_vector(7 downto 0);		--tx data in
        RXIN		:in		std_logic_vector(7 downto 0);	--rx data out
        WRn			:out	std_logic;						--write
        RDn			:out	std_logic;						--read
    
        TXEMP		:in		std_logic;							--tx buffer empty
        RXED		:in		std_logic;							--rx buffered
        NOACK		:in		std_logic;							--no ack
        COLL		:in		std_logic;							--collision detect
        NX_READ		:out	std_logic;							--next data is read
        RESTART		:out	std_logic;							--make re-start condition
        START		:out	std_logic;							--make start condition
        FINISH		:out	std_logic;							--next data is final(make stop condition)
        F_FINISH	:out	std_logic;							--next data is final(make stop condition)
        INIT		:out	std_logic;
    
        YEHID		:out std_logic_vector(3 downto 0);
        YELID		:out std_logic_vector(3 downto 0);
        MONID		:out std_logic_vector(3 downto 0);
        DAYHID		:out std_logic_vector(1 downto 0);
        DAYLID		:out std_logic_vector(3 downto 0);
        WDAYID		:out std_logic_vector(2 downto 0);
        HORHID		:out std_logic_vector(1 downto 0);
        HORLID		:out std_logic_vector(3 downto 0);
        MINHID		:out std_logic_vector(2 downto 0);
        MINLID		:out std_logic_vector(3 downto 0);
        SECHID		:out std_logic_vector(2 downto 0);
        SECLID		:out std_logic_vector(3 downto 0);
        RTCINI		:out std_logic;
        
        YEHWD		:in std_logic_vector(3 downto 0);
        YELWD		:in std_logic_vector(3 downto 0);
        MONWD		:in std_logic_vector(3 downto 0);
        DAYHWD		:in std_logic_vector(1 downto 0);
        DAYLWD		:in std_logic_vector(3 downto 0);
        WDAYWD		:in std_logic_vector(2 downto 0);
        HORHWD		:in std_logic_vector(1 downto 0);
        HORLWD		:in std_logic_vector(3 downto 0);
        MINHWD		:in std_logic_vector(2 downto 0);
        MINLWD		:in std_logic_vector(3 downto 0);
        SECHWD		:in std_logic_vector(2 downto 0);
        SECLWD		:in std_logic_vector(3 downto 0);
        RTCWR		:in std_logic;
        
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
-- RTC driver
--
rtc	:I2Crtc port map(
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

    YEHID		=>open,
    YELID		=>open,
    MONID		=>open,
    DAYHID		=>open,
    DAYLID		=>open,
    WDAYID		=>open,
    HORHID		=>open,
    HORLID		=>open,
    MINHID		=>open,
    MINLID		=>open,
    SECHID		=>open,
    SECLID		=>open,
    RTCINI		=>open,
    
    YEHWD		=>(others=>'0'),
    YELWD		=>(others=>'0'),
    MONWD		=>(others=>'0'),
    DAYHWD		=>(others=>'0'),
    DAYLWD		=>(others=>'0'),
    WDAYWD		=>(others=>'0'),
    HORHWD		=>(others=>'0'),
    HORLWD		=>(others=>'0'),
    MINHWD		=>(others=>'0'),
    MINLWD		=>(others=>'0'),
    SECHWD		=>(others=>'0'),
    SECLWD		=>(others=>'0'),
    RTCWR		=>'0',
    
    clk			=>sysclk,
    rstn		=>srstn
);

end rtl;