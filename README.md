# FPGA-TLC59116-Driver

TLC59116というI2Cでコントロール可能なLEDドライバをFGPAから操作するためのモジュールです。

I2C IF部分はプー氏作成のI2CIF.vhdを使っていて、それに接続できる形で I2C_TLC59116.vhd を作っています。

また、I2CIF.vhdを他のモジュールと共用して１つのI2Cバスライン上にある複数のI2Cデバイスをコントロールできるようにするために、I2Cバスマルチプレクサも作成しました(I2C_MUX.vhd, I2C_MUX_PROXY.vhd)。

I2Cバスマルチプレクサの動作の詳細は architecture.pptx をご覧ください。

# Memo

TLC59116の動作確認のためにラズパイからI2CでTLC59116を制御した時のコマンドを覚書として残しておきます。

● i2c-toolsのインストール
> sudo apt-get install i2c-tools

● i2cバスデバイス検出
> i2cdetect -y 1

値の書き込みは i2cset を使います。

- 第一引数: I2Cデバイスアドレス=0x60
- 第二引数: レジスタ番号
- 第三引数: 書き込む値

● R00h (MODE1) のOSCを 0にしてオシレータ起動
> sudo i2cset -y 1 0x60 0x00 0x01

● R01h (MODE2) のDMBLNKを 1にして点滅モード
> sudo i2cset -y 1 0x60 0x01 0x20

● R02h〜04h でRGB各色の輝度を設定
> sudo i2cset -y 1 0x60 0x02 0xc0

● R12h (GRPPWM) で点滅のデューティー比を 50%に
> sudo i2cset -y 1 0x60 0x12 0x80

● R13h (GRPFREQ) で点滅サイクルを1秒(24Hzなので0x18)に
> sudo i2cset -y 1 0x60 0x13 0x18

● R14h (LEDOUT0) でLED0,1,2のモードを11に
> sudo i2cset -y 1 0x60 0x14 0x3f

これで好きな色で点滅が始まる。

なお、この状態でLED0,1,2のモードを変えれば点灯・消灯も可能(色も維持される)

● R14h (LEDOUT0) でLED0,1,2のモードを10にして点灯(0x2aは "00-10-10-10")
> sudo i2cset -y 1 0x60 0x14 0x2a

● R14h (LEDOUT0) でLED0,1,2のモードを00にして点灯
> sudo i2cset -y 1 0x60 0x14 0x00
