module shim (in0,in1,clk,out,test); //два входа на 
	input[3:0] in0, in1;
	input clk;

	output out;
	output reg test;
	wire [5:0] in0_0;
	wire [5:0] in1_0;
	assign in0_0 = in0*4;
	assign in1_0 = in1*4;
	reg out;
	
	reg[6:0] counter;

	always@(posedge clk)
	begin
	
		
		if((counter<=in0_0) && in0!=4'b0000)
			begin
				out <= 1'b0;
			end
			
		else if(((counter-in0_0)<=in1_0) && in1!=4'b0000)
			begin
				out <= 1'b1;
			end
		/*else 
			begin
			counter<=7'b0000000;
			test<=1'b1;
			end*/
			//test<=1'b0;
		counter<=(counter>in0_0+in1_0)?(counter<=0):(counter+1'b1);
	end
	/*always@(posedge clk)
	begin
		if (counter > in0_0+in1_0) counter <= 7'b0000000;
		else counter<=counter+1'b1;
	end*/

endmodule 
