/*
 УПРАВЛЕНИЕ ГРОМКОСТЬЮ, ЧАСТОТОЙ И СДВИГОМ ПО ВРЕМЕНИ 
 11 БИТНОГО СИНУСОИДАЛЬНОГО КОДА БАРКЕРА + ЕСТЬ ВАРИАНТ ИМПУЛЬСНОГО 
 С ЗАДЕРЖКАМИ [...], [...] ИЛИ [...] периода ([...] периода постоян, далее периоды, когда сигнал в нуле)

Изначальный синус с частотой около 1кГц 
Двоичный код баркера с частотой 250Гц (т.е. 4 колебания синуса на бит Баркера)
----
ROM_out1: Выводит код 11 битный Баркера, заполненный синусоидами (без манипуляций с частотой на 1 бит 
баркера приходиться один период синусоиды). На фронте и спаде баркер-кода происходи сдвиг
фазы на 180 градусов. 
----
Есть варианты ROM_out1 (нужно раскомментировать), когда есть , когда после каждой секунды 
сигнал равен 0 на протяжении 1.5, 2 и 4 секунд (можно выбрать в первом в этой программе 
always-блоке)
----
ROM_out - это исходный синус из файла sine16by256.mif, записанный в ROM:
16битный синус на 2048 отсчётов, амплитуда намеренно уменьшена в 3 раза, чтобы была возможность
реализовать умножитель отсчётов
----

11битный Баркер-код (11100010010) посмотреть на осц-фе можно через GPIO: 
1ая левая сверху дата, 6ая сверху правая- земля 

Если держишь  key2 или key3 одну секунду, то частота увеличивается
на +-FREQ_STEP соответственно

key1 при нажатии увелчивает громкость (умножитель отсчётов):  1 нажатие - в 2 раза; 
2 нажатия - в 3 раза; 3 нажатия - в 1 раз

key0 - reset

sw0 -  при любом переключении - сдвиг фазы на 180*



(изначально период=слово, где слово - это бит баркера)

*/


module Top (

///
output reg barker11,

input[3:0] sw0,sw1,sw2,sw3,
///


	input clk  , 
	key0, // reset
	key2, // уменьшение частоты (+10)
	key3,  // увеличение частоты (-10)
	key1, // увеличение амплитуды: 1 нажатие - в 2 раза; 2 нажатия - в 3 раза; 3 нажатия - в 1 раз
	
	inout SDIN,
	output SCLK,USB_clk,BCLK,
	output reg DAC_LR_CLK,
	output DAC_DATA,
	output [2:0] ACK_LEDR,
	
	output test //test
);
///
parameter FREQ_STEP = 100; // шаг изменения частоты в увеличение и уменьшение по нажатию key3 и key2
wire pwm_out;
wire reset; assign reset = key0;
///





reg [3:0] counter; //selecting register address and its corresponding data
reg counting_state,ignition,read_enable; 	
reg [15:0] MUX_input;
reg [17:0] read_counter; //256 В том коде это step

///reg [3:0] ROM_output_mux_counter;
reg [4:0] ROM_output_mux_counter;
reg [4:0] DAC_LR_CLK_counter;
wire [15:0]ROM_out;
wire test1; //test
wire shim_clk;
wire shim_out; 
wire finish_flag;
wire increse, decrese; //Для манипуляции частотой
reg [17:0] step = 200;
reg  [1:0] key1_reg; initial key1_reg = 1; // 1 - в1 		2 - в2		3 - в3




///
wire [16:0]ROM_out1,ROM_out2;

assign DAC_DATA =  ROM_out2[15-ROM_output_mux_counter];


//просто синус
assign ROM_out2 = (ph==1) ? ROM_out*key1_reg : -(ROM_out*key1_reg) ; 


//assign ROM_out2 = (ph==1) ? ROM_out1 : -ROM_out1; //управление фазой посредством SW0 (переключение=смена фазы)


//Постоянный синусоидальный Баркер11-код
///assign ROM_out1 = (barker11==1) ? (ROM_out*key1_reg) : -(ROM_out*key1_reg); // изменение фазы на 180* по фронту и спаду 11битного кода баркера + увеличение громкости умножителем + cдвиг фазы на 180 по фронту key0

// 1секунда (около 4 периодов) синусоидального Баркер11-кода, 
// [1.5, 2 или 4] секунды - сигнала нет  (что выбрано ниже)
assign ROM_out1 = (vnol==0)	? ( (barker11==1) ? (ROM_out*key1_reg) : -(ROM_out*key1_reg) ) : 0;


// ДЛЯ ВЫБОРА ВРЕМЕНИ, КОГДА СИГНАЛ В НУЛЕ: РАСКОММЕНТИРОВАТЬ НУЖНОЕ, ЗАКОМЕНТИРОВАТЬ НЕНУЖНОЕ
// vnol==1 по прошествии 1 секунды, далее по прошествии [] ==0 
reg [27:0]sek;  initial sek =0;
reg vnol; initial vnol = 0;
always @ (posedge clk)
begin
	
	//  СИГНАЛ В НУЛЕ 2 периода от 1кГц
	//* 
	if (sek==150000)
	begin
		vnol <= 0;
		sek <= 0;
	end 
	//*/
	
	//  СИГНАЛ В НУЛЕ  100 периода от 1кГц
 	/*
	if (sek==5200000)
	begin
		vnol <= 0;
		sek <= 0;
	end 
	*/
	
	
	 /* 
	/// СИГНАЛ В НУЛЕ  10 периода от 1кГц
	if (sek==700000)
	begin
		vnol <= 0;
		sek <= 0;
	end
	 */
	
	else
	  // 1 периода прошло
	begin
		if (sek==50000)
			vnol <= 1;		
		sek <= sek + 1;
	end
	
		
end

///




// УПРАВЛЕНИЕ ГРОМКОСТЬЮ
// настройка key1_reg с тремя состояниями для увеличения громкости
always@ (posedge ~key1)
begin

	if (key1_reg==1)
		key1_reg <= 2;
	else
	if (key1_reg==2)
		key1_reg <= 3;
	else 
	if (key1_reg==3)
		key1_reg <= 1;
	
end










////////////////////////////////////////////////////////////////////////////////
assign test=test1; //test
//============================================
//Instantiation section
I2C_Protocol I2C(
	
	.clk(clk),
	.reset(reset),
	.ignition(ignition),
	.MUX_input(MUX_input),
	.ACK(ACK_LEDR),
	.SDIN(SDIN),
	.finish_flag(finish_flag),
	.SCLK(SCLK)
);


USB_Clock_PLL	USB_Clock_PLL_inst (
	.inclk0 ( clk ),
	.c0 ( USB_clk ),
	.c1 ( BCLK )
	);

	sine16by256_ROM	sine16by256_inst (
	.address ( read_counter ),
	.clock ( clk ),
	.rden ( read_enable ),
	.q ( ROM_out )
	);
	
	
	/*
	Five_Centimeters_Per_Second_ROM	Five_Centimeters_Per_Second_ROM_inst (
	.address ( read_counter ),
	.clock ( clk ),
	.rden ( read_enable ),
	.q ( ROM_out )
	);
	*/
	
/*	
PLL_SHIM PLL_SHIM_inst (
	.inclk0 (clk),
	.c0 (shim_clk)
);*/
//манипулируем частотой

//Если держишь  key2 или key3 одну секунду, то частота увеличивается на +-FREQ_STEP соответственно
button_to_1pulse inst1
(
.clk50(clk),
.button(key2),
.button_debounced_pulse(increse)
);

button_to_1pulse inst2
(
.clk50(clk),
.button(key3),
.button_debounced_pulse(decrese)
);

/*
shim sh
(
.clk(shim_clk),
.in0(tau0),
.in1(tau1),
.out(shim_out),
.test(test1) //test
);*/

///
/*
PWM pwm1 
(
	.clk(clk4Hz),
	.sw0(sw0),sw1(sw1),sw2(sw2),sw3(sw3),
	.out(pwm_out)
);*/
///

//============================================

//УПРАВЛЕНИЕ ФАЗОЙ (при нажатии key0 сдвиг на 180)
reg ph; initial ph = 1;
always@(posedge clk)
	if (sw0[0]==1)
		ph <= 0;
	else 
		ph <= 1;


//УПРАВЛЕНИЕ ДЛИТЕЛЬНОСТЬЮ
/*
reg [25:0] T; initial cnt1=0;
reg en_t; initial en_t=0;
always@(posedge clk)
begin
	
	if ( (T+1)*read_counter > 50000000 && (T-1)*read_counter < 50000000  )
		en_t<=1;
	else
		T<=T+1;
		
if (en_t==1)
begin
	if (pwm_out==1)
		if (ROM_out1<0) 
			ph1<=ph1*(-1); // если был в минусе- стал в плюсе
		else
			
		
		
end				
			
	


end
*/




//УПРАВЛЕНИЕ ЧАСТОТОЙ  

// Для подключение модуля button_to_1pulse, где по 1 секунде держать надо 
always@(posedge clk)
begin
		if(increse) 	step  <= step + FREQ_STEP;
		else if (decrese) 	step  <= step - FREQ_STEP;

end


always @(posedge DAC_LR_CLK)
	begin
	if(read_enable) 
		begin
			read_counter <= read_counter + step;
		
		if (read_counter == 214198) read_counter <= 0;
		end
	end
//============================================
// ROM output mux
always @(posedge BCLK) 
	begin
	if(read_enable)
		begin
		
		
			ROM_output_mux_counter <= ROM_output_mux_counter + 1;
		
		
		if (DAC_LR_CLK_counter == 31) DAC_LR_CLK <= 1;
		else DAC_LR_CLK <= 0;
		end
	end
always @(posedge BCLK)
	begin
	if(read_enable)
		begin
		DAC_LR_CLK_counter <= DAC_LR_CLK_counter + 1;
		end
	end
//============================================
// generate 6 configuration pulses 
always @(posedge clk)
	begin
	if(!reset) 
		begin
		counting_state <= 0;
		read_enable <= 0;
		end
	else
		begin
		case(counting_state)
		0:
			begin
			ignition <= 1;
			read_enable <= 0;
			///if(counter == 8) counting_state <= 1; //was 8
			
			///
			if(counter == 9) counting_state <= 1; // выполняет (1-counter) действий
			///
			
			end
		1:
			begin
			read_enable <= 1;
			ignition <= 0;
			
			end
		endcase
		end
	end
//============================================
// this counter is used to switch between registers
always @(posedge SCLK)
	begin
		case(counter) //MUX_input[15:9] register address, MUX_input[8:0] register data
		1: MUX_input <= 16'h1201; // activate interface
		
		
		
		//1: MUX_input <= 16'h0470; // left headphone out =1110000
		2: MUX_input <= (16'b0000010001111000) ;///+ vol_val);
		
		
		3: MUX_input <= 16'h0C00; // power down control
		
		
		
		4: MUX_input <= 16'h0812; // analog audio path control 	выход с ЦАП
		///3:MUX_input <= 16'b0000100000100111;							выход с MicIn
		
		
		5: MUX_input <= 16'h0A00; // digital audio path control
		6: MUX_input <= 16'h102F; // sampling control
		7: MUX_input <= 16'h0E23; // digital audio interface format
		
		
		
		///8: MUX_input <= 16'h0670; // right headphone out       =1110000
		//	7'b010111 = -74Дб  звука нет
		8: MUX_input <= (16'b0000011001111000 );///+ vol_val); было 1100000
 		
		

		
		//9: begin MUX_input <= (16'b000001000111100); ///MUX_input <= (16'b0000010001111100); //+ vol_val);	///

			//end
			
		endcase		
	
		
		
	end
always @(posedge finish_flag)
		counter <= counter + 1; 

	
	
///
///////////////////////////////////////////////////////////////////////////////////////	
///

/* 
синус 1кГц => частоту баркера сделаем 250 Гц, т.е.  4 периодида на бит баркера
*/

/* 11100010010  генерация повторяющегося 11-битного кода Баркера с частотой в 250Гц .
 
*/

// формируем частоту clk_250Hz
reg clk250Hz; 
reg [23:0]count_b; initial count_b=0;
always@ (posedge clk)
begin
	
	if (count_b==100000) // Хочу сделать 4 периода синуса на бит => т.к. count_b==6250000 это 4ГЦ, а надо (для 1000 Гц синуса) 250, то делим	6250000 на 62.5 = 100000			//12500000) если 125000000 то 500мс на бит, а при 650000- нужные 250мс на бит (см фото). Интересно почему так
	begin
		clk250Hz <= ~clk250Hz;
		count_b <= 0;
	end
	else
		count_b <= count_b + 1;

end

reg [3:0] a; initial a = 1; // счётчик битов от страшего к младшему от 1 до 11 (для того, чтобы формировать бит=импульс нужной чатсоты)
always@ (posedge clk250Hz )
begin

	 if (a==1) 
	 begin
		barker11 <= 1; 
		a <= 2;
	 end
	 
	 else
	 
	 if (a==2) 
	 begin
		barker11 <= 1; 
		a <= 3;
	 end
	 
	 else
	 
	 if (a==3) 
	 begin
		barker11 <= 1; 
		a <= 4;
	 end
	 
	 else
	 
	 if (a==4) 
	 begin
		barker11 <= 0; 
		a <= 5;
	 end
	 
	 else
	 
	 if (a==5) 
	 begin
		barker11 <= 0; 
		a <= 6;
	 end
		
	 else
	 
	 if (a==6) 
	 begin
		barker11 <= 0; 
		a <= 7;
	 end
		
	 else
	 
	 if (a==7) 
	 begin
		barker11 <= 1; 
		a <= 8;
	 end
		
	 else
	 
	 if (a==8) 
	 begin
		barker11 <= 0; 
		a <= 9;
	 end
		
	 else
	 
	 if (a==9) 
	 begin
		barker11 <= 0; 
		a <= 10;
	 end
		
	 else
	 
	 if (a==10) 
	 begin
		barker11 <= 1; 
		a <= 11;
	 end
		
	 else
	 
	 if (a==11) 
	 begin
		barker11 <= 0; 
		a <= 1;
	 end

end

///
///////////////////////////////////////////////////////////////////////////////////////
///	
	
	
	
	


endmodule 