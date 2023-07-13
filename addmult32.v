`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2023 09:07:54 AM
// Design Name: 
// Module Name: addmult32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module addmult32(
    input CLK,
    input [31:0] A,
    input [31:0] B,
    output [31:0] OUT,
    input OPCODE
    );
    
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2
   
   // DSP1
   // A[16:0] x B[16:0]
   // A[16:0] + B[16:0] 
   // Multiply is set to 17 bit to utilize PCOUT cascade 17-shift
   // 32 bit add can be implemented with one dsp, but since we have 2 cascaded anyway
   // splitting it into two saves input MUX LUTs
   // Fill C upper bits with inverse of A to cascade carry to next dsp slice

    wire [29:0] DSP1_A;
    wire [29:0] DSP1_ACOUT;
    wire [17:0] DSP1_B;
    wire [47:0] DSP1_C;
    
    wire [47:0] DSP1_P;
    wire [47:0] DSP1_PCOUT;
    wire DSP1_CARRYCASCOUT;
    
    wire [8:0] DSP1_OPMODE;
    
    assign DSP1_A = {13'b0, A[16:0]};
    assign DSP1_B = {1'b0, B[16:0]};
    assign DSP1_C = {13'b0, A[16:0]};
    
    assign DSP1_OPMODE = OPCODE ? 9'b000000101 : 9'b000110011;
    

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
      .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
      .RND(48'h000000000000),            // Rounding Constant
      .USE_MULT("DYNAMIC"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
      .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
      .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
      // Pattern Detector Attributes: Pattern Detection Configuration
      .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
      .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
      .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
      .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
      .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
      .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
      .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
      .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
      .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
      .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
      .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
      .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
      .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
      .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
      .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
      .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
      .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(0),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(0),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(0),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(0),                     // Pipeline stages for OPMODE (0-1)
      .PREG(0)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_1 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP1_ACOUT),                 // 30-bit output: A port cascade
      .BCOUT(),                 // 18-bit output: B cascade
      .CARRYCASCOUT(DSP1_CARRYCASCOUT),          // 1-bit output: Cascade carry
      .MULTSIGNOUT(),           // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP1_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP1_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(30'b0),                     // 30-bit input: A cascade data
      .BCIN(18'b0),                     // 18-bit input: B cascade
      .CARRYCASCIN(1'b0),       // 1-bit input: Cascade carry
      .MULTSIGNIN(1'b0),         // 1-bit input: Multiplier sign cascade
      .PCIN(48'b0),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(4'b0),               // 4-bit input: ALU control
      .CARRYINSEL(3'b0),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(5'b0),                 // 5-bit input: INMODE control
      .OPMODE(DSP1_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP1_A),                           // 30-bit input: A data
      .B(DSP1_B),                           // 18-bit input: B data
      .C(DSP1_C),                           // 48-bit input: C data
      .CARRYIN(1'b0),               // 1-bit input: Carry-in
      .D(27'b0),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b1),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b1),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b1),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b1),             // 1-bit input: Clock enable for INMODEREG
      .CEM(1'b1),                       // 1-bit input: Clock enable for MREG
      .CEP(1'b1),                       // 1-bit input: Clock enable for PREG
      .RSTA(1'b1),                     // 1-bit input: Reset for AREG
      .RSTALLCARRYIN(1'b1),   // 1-bit input: Reset for CARRYINREG
      .RSTALUMODE(1'b1),         // 1-bit input: Reset for ALUMODEREG
      .RSTB(1'b1),                     // 1-bit input: Reset for BREG
      .RSTC(1'b1),                     // 1-bit input: Reset for CREG
      .RSTCTRL(1'b1),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
      .RSTD(1'b1),                     // 1-bit input: Reset for DREG and ADREG
      .RSTINMODE(1'b1),           // 1-bit input: Reset for INMODEREG
      .RSTM(1'b1),                     // 1-bit input: Reset for MREG
      .RSTP(1'b1)                      // 1-bit input: Reset for PREG
   );
    
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2
   
   // DSP2
   // A[16:0] x B[16:0] + A[16:0] x B[31:17]
   // (A[16:0] + B[16:0] carry) + A[31:17] + B[31:17]
   // Use DSP1 PCOUT and CARRYCASCOUT for MUL and ADD respectively
   
    wire [17:0] DSP2_B;
    wire [47:0] DSP2_C;
    
    wire [47:0] DSP2_P;
    
    wire [8:0] DSP2_OPMODE;
    wire [2:0] DSP2_CARRYINSEL;
    
    wire DSP2_CARRYIN;
    
    assign DSP2_B = {3'b0, B[31:17]};
    assign DSP2_C = {33'h7fffffff, A[31:17]};
    
    assign DSP2_OPMODE = OPCODE ? 9'b001010101 : 9'b000110011;
    assign DSP2_CARRYINSEL = OPCODE ? 3'b010 : 3'b000;
    
    assign DSP2_CARRYIN = DSP1_P[17];
  

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("CASCADE"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
      .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
      .RND(48'h000000000000),            // Rounding Constant
      .USE_MULT("DYNAMIC"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
      .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
      .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
      // Pattern Detector Attributes: Pattern Detection Configuration
      .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
      .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
      .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
      .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
      .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
      .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
      .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
      .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
      .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
      .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
      .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
      .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
      .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
      .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
      .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
      .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
      .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(0),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(0),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(0),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(0),                     // Pipeline stages for OPMODE (0-1)
      .PREG(0)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_2 (
      // Cascade outputs: Cascade Ports
      .ACOUT(),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP2_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(DSP1_ACOUT),                     // 30-bit input: A cascade data
      .BCIN(18'b0),                     // 18-bit input: B cascade
      .CARRYCASCIN(1'b0),       // 1-bit input: Cascade carry
      .MULTSIGNIN(1'b0),         // 1-bit input: Multiplier sign cascade
      .PCIN(DSP1_PCOUT),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(4'b0),               // 4-bit input: ALU control
      .CARRYINSEL(DSP2_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(5'b0),                 // 5-bit input: INMODE control
      .OPMODE(DSP2_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(30'b0),                           // 30-bit input: A data
      .B(DSP2_B),                           // 18-bit input: B data
      .C(DSP2_C),                           // 48-bit input: C data
      .CARRYIN(DSP2_CARRYIN),               // 1-bit input: Carry-in
      .D(27'b0),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b1),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b1),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b1),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b1),             // 1-bit input: Clock enable for INMODEREG
      .CEM(1'b1),                       // 1-bit input: Clock enable for MREG
      .CEP(1'b1),                       // 1-bit input: Clock enable for PREG
      .RSTA(1'b0),                     // 1-bit input: Reset for AREG
      .RSTALLCARRYIN(1'b0),   // 1-bit input: Reset for CARRYINREG
      .RSTALUMODE(1'b0),         // 1-bit input: Reset for ALUMODEREG
      .RSTB(1'b0),                     // 1-bit input: Reset for BREG
      .RSTC(1'b0),                     // 1-bit input: Reset for CREG
      .RSTCTRL(1'b0),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
      .RSTD(1'b0),                     // 1-bit input: Reset for DREG and ADREG
      .RSTINMODE(1'b0),           // 1-bit input: Reset for INMODEREG
      .RSTM(1'b0),                     // 1-bit input: Reset for MREG
      .RSTP(1'b0)                      // 1-bit input: Reset for PREG
   );
   
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2
   
   // DSP3
   // A[31:17] x B[16:0]
   
    wire [29:0] DSP3_A;
    wire [17:0] DSP3_B;
    
    wire [47:0] DSP3_P;
    
    wire [8:0] DSP3_OPMODE;
    
    assign DSP3_A = {13'b0, A[31:17]};
    assign DSP3_B = {1'b0, B[16:0]};
    
    assign DSP3_OPMODE = OPCODE ? 9'b000000101 : 9'b000000000;
   
   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
      .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
      .RND(48'h000000000000),            // Rounding Constant
      .USE_MULT("MULTIPLY"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
      .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
      .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
      // Pattern Detector Attributes: Pattern Detection Configuration
      .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
      .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
      .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
      .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
      .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
      .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
      .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
      .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
      .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
      .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
      .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
      .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
      .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
      .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
      .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
      .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
      .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(0),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(0),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(0),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(0),                     // Pipeline stages for OPMODE (0-1)
      .PREG(0)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_3 (
      // Cascade outputs: Cascade Ports
      .ACOUT(),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP3_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(30'b0),                     // 30-bit input: A cascade data
      .BCIN(18'b0),                     // 18-bit input: B cascade
      .CARRYCASCIN(1'b0),       // 1-bit input: Cascade carry
      .MULTSIGNIN(1'b0),         // 1-bit input: Multiplier sign cascade
      .PCIN(48'b0),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(4'b0),               // 4-bit input: ALU control
      .CARRYINSEL(3'b0),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(5'b0),                 // 5-bit input: INMODE control
      .OPMODE(DSP3_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP3_A),                           // 30-bit input: A data
      .B(DSP3_B),                           // 18-bit input: B data
      .C(48'b0),                           // 48-bit input: C data
      .CARRYIN(1'b0),               // 1-bit input: Carry-in
      .D(27'b0),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b1),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b1),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b1),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b1),             // 1-bit input: Clock enable for INMODEREG
      .CEM(1'b1),                       // 1-bit input: Clock enable for MREG
      .CEP(1'b1),                       // 1-bit input: Clock enable for PREG
      .RSTA(1'b0),                     // 1-bit input: Reset for AREG
      .RSTALLCARRYIN(1'b0),   // 1-bit input: Reset for CARRYINREG
      .RSTALUMODE(1'b0),         // 1-bit input: Reset for ALUMODEREG
      .RSTB(1'b0),                     // 1-bit input: Reset for BREG
      .RSTC(1'b0),                     // 1-bit input: Reset for CREG
      .RSTCTRL(1'b0),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
      .RSTD(1'b0),                     // 1-bit input: Reset for DREG and ADREG
      .RSTINMODE(1'b0),           // 1-bit input: Reset for INMODEREG
      .RSTM(1'b0),                     // 1-bit input: Reset for MREG
      .RSTP(1'b0)                      // 1-bit input: Reset for PREG
   );
   
    wire [31:0] RESULT1;
    wire [14:0] RESULT2;
   
    assign RESULT1 = {DSP2_P[14:0], DSP1_P[16:0]};
    assign RESULT2 = DSP3_P[14:0];
    
   // Add two mult products with 2 CLBs
   
    wire [7:0] CO;
    wire [14:0] S;
    wire [7:0] O1;
    wire [7:0] O2;
    
    assign S = RESULT1[31:17] ^ RESULT2[14:0];
   
   // CARRY8: Fast Carry Logic with Look Ahead
   //         Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   CARRY8 #(
      .CARRY_TYPE("SINGLE_CY8")  // 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
   )
   CARRY8_1 (
      .CO(CO),         // 8-bit output: Carry-out
      .O(O1),           // 8-bit output: Carry chain XOR data out
      .CI(1'b0),         // 1-bit input: Lower Carry-In
      .CI_TOP(1'b0), // 1-bit input: Upper Carry-In
      .DI({RESULT1[23:17], 1'b0}),         // 8-bit input: Carry-MUX data in
      .S({S[6:0], DSP1_P[16]})            // 8-bit input: Carry-mux select
   );
   
   // CARRY8: Fast Carry Logic with Look Ahead
   //         Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   CARRY8 #(
      .CARRY_TYPE("SINGLE_CY8")  // 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
   )
   CARRY8_2 (
      .CO(),         // 8-bit output: Carry-out
      .O(O2),           // 8-bit output: Carry chain XOR data out
      .CI(CO[7]),         // 1-bit input: Lower Carry-In
      .CI_TOP(1'b0), // 1-bit input: Upper Carry-In
      .DI({RESULT1[31:24]}),         // 8-bit input: Carry-MUX data in
      .S(S[14:7])            // 8-bit input: Carry-mux select
   );
   
    assign OUT = {O2, O1[7:1], RESULT1[16:0]};
   
endmodule
