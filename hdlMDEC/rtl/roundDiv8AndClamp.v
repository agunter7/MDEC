//
// => Add 0.5 to 4 bit fixed point  (add +4)
// => Round and perform signed by 8 (add +7 if negative, >> 3)
// => Perform Clamp in -2048..+2047 Range
// => Round toward ZERO for the closest EVEN integer, EXCEPT -1.
//
module roundDiv8AndClamp(
	input  signed [23:0] valueIn,
	output signed [11:0] valueOut
);

	//--------------------------------------------------------------------------------------------
	// (value+4)/8 as signed value.
	// Step 1 : Add 4
	// Step 2 : Add 7 if number is negative (rounding toward zero => signed division by 8)
	//  => Before unsigned division by 8 (shift 3), make sure that -1/-2/-3/-4/-5/-6/-7 return 0. (worked for SIGNED VALUES)
	//--------------------------------------------------------------------------------------------
	// Merged into a single addition operation gives :
	wire  [3:0] rndPartAndDiv8  = valueIn[23] ? 4'b1011 : 4'b0111; // Add 11 (7+4) if negative, or add 4 if positive.
	wire [23:0] outCalcRoundDiv = valueIn + { 20'b0 , rndPartAndDiv8};

	// [23:Sign][22:15 Overflow][14:3 Value][2:0 Not necessary (div 8)]
	
	//--------------------------------------------------------------------------------------------
	// Signed saturated arithmetic. 12 bit. (-2048..+2047)
	//--------------------------------------------------------------------------------------------
	// Remove 3 bit ( div 8 unsigned ), then clamp.
	wire isNZero= |outCalcRoundDiv[22:15];
	wire isOne  = &outCalcRoundDiv[22:15];
	wire orSt   = (!outCalcRoundDiv[23]) & (isNZero);							// [+ Value] and has non zero                    -> OR  1
	wire andSt  = ((outCalcRoundDiv[23]) & ( isOne)) | (!outCalcRoundDiv[23]);	// [- Value] and has all one   or positive value -> AND 1 
	wire [11:0] clippedOutCalc = (outCalcRoundDiv[14:3] | {12{orSt}}) & {12{andSt}};

	//--------------------------------------------------------------------------------------------
	// round toward closest to zero EVEN number for positive and negative value, except -1.
	//--------------------------------------------------------------------------------------------
	wire isMinus1	= &clippedOutCalc; 						// [1 if value is -1]
	wire isOdd      =  clippedOutCalc[0]  & (!isMinus1);	// If ODD and not minus ONE.
	wire posV       = !clippedOutCalc[11] & isOdd;			// Fill with ONE for Positive ODD value.

	assign valueOut = clippedOutCalc + { {11{posV}} , isOdd };	// Add +1 if negative, -1 if positive for VALID numbers.

endmodule