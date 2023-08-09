`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: PolyArch
// Engineer: Maxim Zhulin
// 
// Create Date: 07/13/2023 05:32:38 PM
// Design Name: 
// Module Name: addmult64
// Project Name: Overgen
// Target Devices: 
// Tool Versions: 
// Description: Fused DSP 64 bit Multiply/Add/Logic Unit 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module addmult64(
    input [63:0] A,
    input [63:0] B,
    output reg [63:0] O,
    input [5:0] OPCODE,
    output IREADY,
    input IVALID,
    input OREADY,
    output OVALID,
    input CLK
    );
    
    // OPCODES
    // [5:4] 00=>16 10=>32 11=>64
    // [3:0] 0000=>ADD 0001 =>MUL
    
    // A        B        C        D
    // DSP1 L1
    // [25:0]   [16:0]                  (64 MUL)
    // [25:0]   [16:0]                  (32 MUL)
    // [15:0]   [15:0]                  (16 MUL)
    // [15:0]   [15:0]                  (16 ADD)
    // [31:0]   [31:0]                  (32 ADD)
    
    // DSP2 L2
    // [25:0]   [33:17]                 (64 MUL)
    // [25:0]   [31:17]                 (32 MUL)
    
    // DSP3 L3
    // [25:0]   [50:34]                 (64 MUL)
    // [31:27]  [4:0]                   (32 MUL)
    
    // DSP4 L1 
    // [51:26]  [16:0]                  (64 MUL)
    // [57:32]  [48:32]                 (32 MUL)
    // [31:16]  [31:16]                 (16 MUL)
    // [31:16]  [31:16]                 (16 ADD)
    
    // DSP5 L2
    // [51:26]  [33:17]                 (64 MUL)
    // [57:32]  [63:49]                 (32 MUL)
    
    // DSP6 L3
    // [51:26]  [50:34]                 (64 MUL)
    // [63:58]  [36:32]                 (32 MUL)
    
    // DSP7 L1 
    // [63:52]  [16:0]                  (64 MUL)
    // [47:32]  [47:32]                 (16 MUL)
    // [47:32]  [47:32]                 (16 ADD)
    // [63:32]  [63:32]                 (32 ADD)
    
    // DSP8 L1
    // [25:0]   [63:51]                 (64 MUL)
    // [63:48]  [63:48]                 (16 MUL)
    // [63:48]  [63:48]                 (16 ADD)
 

   // DSP1
   
   // inputs
   reg [29:0] DSP1_A;
   reg [17:0] DSP1_B;
   reg [47:0] DSP1_C;
   wire [26:0] DSP1_D;
   wire [47:0] DSP1_PCIN;
   
   wire [4:0] DSP1_INMODE;
   wire [8:0] DSP1_OPMODE;
   wire [3:0] DSP1_ALUMODE;
   wire [2:0] DSP1_CARRYINSEL;
   
   wire DSP1_CARRYIN;
   
   // outputs
   wire [29:0] DSP1_ACOUT;
   wire [47:0] DSP1_P;
   wire [47:0] DSP1_PCOUT;   
   
   // input multiplex
   always @ (*) begin
    case (OPCODE)
      6'b100000:  
        begin
          DSP1_A = {14'b0, A[31:2]};
          DSP1_B = {16'b0, A[1:0]};
          DSP1_C = {16'b0, B};
        end
      default:    
        begin
          DSP1_A = {4'b0, A[25:0]};
          DSP1_B = {1'b0, B[16:0]};
          DSP1_C = 48'b0;
        end
     endcase 
   end
      
   assign DSP1_D = 27'b0;
   assign DSP1_PCIN = 48'b0;
   
   assign DSP1_INMODE = 5'b0;
   assign DSP1_OPMODE = 9'b000000101;
   assign DSP1_ALUMODE = 4'b0;
   assign DSP1_CARRYINSEL = 3'b0;
   
   assign DSP1_CARRYIN = 1'b0;
  
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

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
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP1 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP1_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
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
      .ACIN(),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP1_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP1_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP1_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP1_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP1_A),                           // 30-bit input: A data
      .B(DSP1_B),                           // 18-bit input: B data
      .C(DSP1_C),                           // 48-bit input: C data
      .CARRYIN(DSP1_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP1_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b0),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b0),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP1
   
   
   // DSP2
   // A input always comes from DSP1, of the same form, use DSP1_ACOUT
   
   // inputs
   wire [29:0] DSP2_ACIN;
   wire [17:0] DSP2_B;
   wire [47:0] DSP2_C;
   wire [26:0] DSP2_D;
   wire [47:0] DSP2_PCIN;
   
   wire [4:0] DSP2_INMODE;
   wire [8:0] DSP2_OPMODE;
   wire [3:0] DSP2_ALUMODE;
   wire [2:0] DSP2_CARRYINSEL;
   
   wire DSP2_CARRYIN;
   
   // outputs
   wire [29:0] DSP2_ACOUT;
   wire [47:0] DSP2_P;
   wire [47:0] DSP2_PCOUT;
   
   // assignment
   assign DSP2_ACIN = DSP1_ACOUT;
   assign DSP2_B = {1'b0, B[33:17]};
   assign DSP2_C = 48'b0;
   assign DSP2_D = 27'b0;
   assign DSP2_PCIN = DSP1_PCOUT;
   
   assign DSP2_INMODE = 5'b0;
   assign DSP2_OPMODE = 9'b001010101;
   assign DSP2_ALUMODE = 4'b0;
   assign DSP2_CARRYINSEL = 3'b0;
   
   assign DSP2_CARRYIN = 1'b0;
   
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("CASCADE"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
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
      .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(1),                          // Pipeline stages for A (0-2)
      .BCASCREG(1),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(1),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP2 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP2_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP2_PCOUT),                   // 48-bit output: Cascade output
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
      .ACIN(DSP2_ACIN),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(DSP2_PCIN),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP2_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP2_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP2_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP2_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(),                           // 30-bit input: A data
      .B(DSP2_B),                           // 18-bit input: B data
      .C(DSP2_C),                           // 48-bit input: C data
      .CARRYIN(DSP2_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP2_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP2
   
   
   // DSP3
   // A input always comes from DSP2, of the same form, use DSP2_ACOUT
   
   // inputs
   wire [29:0] DSP3_ACIN;
   wire [17:0] DSP3_B;
   wire [47:0] DSP3_C;
   wire [26:0] DSP3_D;
   wire [47:0] DSP3_PCIN;
   
   wire [4:0] DSP3_INMODE;
   wire [8:0] DSP3_OPMODE;
   wire [3:0] DSP3_ALUMODE;
   wire [2:0] DSP3_CARRYINSEL;
   
   wire DSP3_CARRYIN;
   
   // outputs
   wire [47:0] DSP3_P;
   wire [47:0] DSP3_PCOUT;
   
   // assignment
   assign DSP3_ACIN = DSP2_ACOUT;
   assign DSP3_B = {1'b0, B[50:34]};
   assign DSP3_C = {18'b0, DSP7_P[12:0], 17'b0};
   assign DSP3_D = 27'b0;
   assign DSP3_PCIN = DSP2_PCOUT;
   
   assign DSP3_INMODE = 5'b0;
   assign DSP3_OPMODE = 9'b111010101;
   assign DSP3_ALUMODE = 4'b0;
   assign DSP3_CARRYINSEL = 3'b0;
   
   assign DSP3_CARRYIN = 1'b0;
   
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("CASCADE"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
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
      .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(1),                          // Pipeline stages for A (0-2)
      .BCASCREG(2),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(2),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(1),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP3 (
      // Cascade outputs: Cascade Ports
      .ACOUT(),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP3_PCOUT),                   // 48-bit output: Cascade output
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
      .ACIN(DSP3_ACIN),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(DSP3_PCIN),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP3_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP3_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP3_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP3_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(),                           // 30-bit input: A data
      .B(DSP3_B),                           // 18-bit input: B data
      .C(DSP3_C),                           // 48-bit input: C data
      .CARRYIN(DSP3_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP3_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP3
   
   
   // DSP4
   
   // inputs
   reg [29:0] DSP4_A;
   reg [17:0] DSP4_B;
   reg [47:0] DSP4_C;
   wire [26:0] DSP4_D;
   wire [47:0] DSP4_PCIN;
   
   wire [4:0] DSP4_INMODE;
   wire [8:0] DSP4_OPMODE;
   wire [3:0] DSP4_ALUMODE;
   wire [2:0] DSP4_CARRYINSEL;
   
   wire DSP4_CARRYIN;
   
   // outputs
   wire [29:0] DSP4_ACOUT;
   wire [47:0] DSP4_P;
   wire [47:0] DSP4_PCOUT;
   
   // input multiplex
   always @ (*) begin
    case (OPCODE[5:4])
      6'b11:  
        begin
          DSP4_A = {3'b0, A[51:26]};
          DSP4_B = {1'b0, B[16:0]};
          DSP4_C = 48'b0;
        end
      6'b00:    
        begin
          DSP4_A = {11'b0, A[31:16]};
          DSP4_B = {2'b0, B[31:16]};
          DSP4_C = 48'b0;
        end
      default:    
        begin
          DSP4_A = {11'b0, A[31:16]};
          DSP4_B = {2'b0, B[31:16]};
          DSP4_C = 48'b0;
        end
     endcase 
   end
   
   assign DSP4_D = 27'b0;
   assign DSP4_PCIN = 48'b0;
   
   assign DSP4_INMODE = 5'b0;
   assign DSP4_OPMODE = 9'b000000101;
   assign DSP4_ALUMODE = 4'b0;
   assign DSP4_CARRYINSEL = 3'b0;
   
   assign DSP4_CARRYIN = 1'b0;
  
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

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
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP4 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP4_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP4_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP4_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP4_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP4_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP4_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP4_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP4_A),                           // 30-bit input: A data
      .B(DSP4_B),                           // 18-bit input: B data
      .C(DSP4_C),                           // 48-bit input: C data
      .CARRYIN(DSP4_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP4_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b0),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b0),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP4
   
   
   // DSP5
   // A input always comes from DSP4, of the same form, use DSP4_ACOUT
   
   // inputs
   wire [29:0] DSP5_ACIN;
   wire [17:0] DSP5_B;
   wire [47:0] DSP5_C;
   wire [26:0] DSP5_D;
   wire [47:0] DSP5_PCIN;
   
   wire [4:0] DSP5_INMODE;
   wire [8:0] DSP5_OPMODE;
   wire [3:0] DSP5_ALUMODE;
   wire [2:0] DSP5_CARRYINSEL;
   
   wire DSP5_CARRYIN;
   
   // outputs
   wire [29:0] DSP5_ACOUT;
   wire [47:0] DSP5_P;
   wire [47:0] DSP5_PCOUT;
   
   wire DSP5_CARRYCASCOUT;
   
   // assignment
   assign DSP5_ACIN = DSP4_ACOUT;
   assign DSP5_B = {1'b0, B[33:17]};
   assign DSP5_C = {43'b0, DSP8_P[11:0], 9'b0};
   assign DSP5_D = 27'b0;
   assign DSP5_PCIN = DSP4_PCOUT;
   
   assign DSP5_INMODE = 5'b0;
   assign DSP5_OPMODE = 9'b111010101;
   assign DSP5_ALUMODE = 4'b0;
   assign DSP5_CARRYINSEL = 3'b0;
   
   assign DSP5_CARRYIN = 1'b0;
   
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("CASCADE"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
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
      .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(1),                          // Pipeline stages for A (0-2)
      .BCASCREG(1),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(1),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP5 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP5_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(DSP5_CARRYCASCOUT),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP5_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP5_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(DSP5_ACIN),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(DSP5_PCIN),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP5_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP5_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP5_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP5_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(),                           // 30-bit input: A data
      .B(DSP5_B),                           // 18-bit input: B data
      .C(DSP5_C),                           // 48-bit input: C data
      .CARRYIN(DSP5_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP5_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP5
   
   
   // DSP6
   // A input always comes from DSP5, of the same form, use DSP5_ACOUT
   
   // inputs
   wire [29:0] DSP6_ACIN;
   wire [17:0] DSP6_B;
   wire [47:0] DSP6_C;
   wire [26:0] DSP6_D;
   wire [47:0] DSP6_PCIN;
   
   wire [4:0] DSP6_INMODE;
   wire [8:0] DSP6_OPMODE;
   wire [3:0] DSP6_ALUMODE;
   wire [2:0] DSP6_CARRYINSEL;
   
   wire DSP6_CARRYIN;
   
   // outputs
   wire [47:0] DSP6_P;
   wire [47:0] DSP6_PCOUT;
   
   // assignment
   assign DSP6_ACIN = DSP5_ACOUT;
   assign DSP6_B = {1'b0, B[50:34]};
   assign DSP6_C = 48'b0;
   assign DSP6_D = 27'b0;
   assign DSP6_PCIN = DSP5_PCOUT;
   
   assign DSP6_INMODE = 5'b0;
   assign DSP6_OPMODE = 9'b001010101;
   assign DSP6_ALUMODE = 4'b0;
   assign DSP6_CARRYINSEL = 3'b0;
   
   assign DSP6_CARRYIN = 1'b0;
   assign DSP6_CARRYCASCIN = DSP5_CARRYCASCOUT;
   
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

   DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("CASCADE"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
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
      .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(1),                          // Pipeline stages for A (0-2)
      .BCASCREG(2),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(2),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(1),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP6 (
      // Cascade outputs: Cascade Ports
      .ACOUT(),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP6_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP6_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(DSP6_ACIN),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(DSP6_CARRYCASCIN),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(DSP6_PCIN),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP6_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP6_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP6_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP6_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(),                           // 30-bit input: A data
      .B(DSP6_B),                           // 18-bit input: B data
      .C(DSP6_C),                           // 48-bit input: C data
      .CARRYIN(DSP6_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP6_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP6
   
   
   // DSP7
   
   // inputs
   reg [29:0] DSP7_A;
   reg [17:0] DSP7_B;
   reg [47:0] DSP7_C;
   wire [26:0] DSP7_D;
   wire [47:0] DSP7_PCIN;
   
   wire [4:0] DSP7_INMODE;
   wire [8:0] DSP7_OPMODE;
   wire [3:0] DSP7_ALUMODE;
   wire [2:0] DSP7_CARRYINSEL;
   
   wire DSP7_CARRYIN;
   
   // outputs
   wire [29:0] DSP7_ACOUT;
   wire [47:0] DSP7_P;
   wire [47:0] DSP7_PCOUT;
   
   // input multiplex
   always @ (*) begin
    case (OPCODE[5:4])
      6'b11:  
        begin
          DSP7_A = {4'b0, A[25:0]};
          DSP7_B = {5'b0, B[63:51]};
          DSP7_C = 48'b0;
        end
      6'b00:    
        begin
          DSP7_A = {11'b0, A[47:32]};
          DSP7_B = {2'b0, B[47:32]};
          DSP7_C = 48'b0;
        end
      default:    
        begin
          DSP7_A = {11'b0, A[47:32]};
          DSP7_B = {2'b0, B[47:32]};
          DSP7_C = 48'b0;
        end
    endcase 
   end
   
   // assignment  
   assign DSP7_D = 27'b0;
   assign DSP7_PCIN = 48'b0;
   
   assign DSP7_INMODE = 5'b0;
   assign DSP7_OPMODE = 9'b000000101;
   assign DSP7_ALUMODE = 4'b0;
   assign DSP7_CARRYINSEL = 3'b0;
   
   assign DSP7_CARRYIN = 1'b0;
  
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

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
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP7 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP7_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP7_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP7_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP7_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP7_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP7_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP7_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP7_A),                           // 30-bit input: A data
      .B(DSP7_B),                           // 18-bit input: B data
      .C(DSP7_C),                           // 48-bit input: C data
      .CARRYIN(DSP7_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP7_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b0),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b0),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP7
   
   
   // DSP8 
   // [25:0]   [63:51]                 (64 MUL)
   // [63:48]  [63:48]                 (16 MUL)
   // [63:48]  [63:48]                 (16 ADD)
   
   // inputs
   reg [29:0] DSP8_A;
   reg [17:0] DSP8_B;
   reg [47:0] DSP8_C;
   wire [26:0] DSP8_D;
   wire [47:0] DSP8_PCIN;
   
   wire [4:0] DSP8_INMODE;
   wire [8:0] DSP8_OPMODE;
   wire [3:0] DSP8_ALUMODE;
   wire [2:0] DSP8_CARRYINSEL;
   
   wire DSP8_CARRYIN;
   
   // outputs
   wire [29:0] DSP8_ACOUT;
   wire [47:0] DSP8_P;
   wire [47:0] DSP8_PCOUT;
   
   // input multiplex
   
   // assignment
   
   always @ (*) begin
    case (OPCODE[5:4])
      6'b11:  
        begin
          DSP8_A = {4'b0, A[63:52]};
          DSP8_B = {1'b0, B[16:0]};
          DSP8_C = 48'b0;
        end
      6'b00:    
        begin
          DSP8_A = {11'b0, A[63:48]};
          DSP8_B = {2'b0, B[63:48]};
          DSP8_C = 48'b0;
        end
      default:    
        begin
          DSP8_A = {11'b0, A[63:48]};
          DSP8_B = {2'b0, B[63:48]};
          DSP8_C = 48'b0;
        end
    endcase 
   end

   assign DSP8_D = 27'b0;
   assign DSP8_PCIN = 48'b0;
   
   assign DSP8_INMODE = 5'b0;
   assign DSP8_OPMODE = 9'b000000101;
   assign DSP8_ALUMODE = 4'b0;
   assign DSP8_CARRYINSEL = 3'b0;
   
   assign DSP8_CARRYIN = 1'b0;
  
   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.2

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
      .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(0),                          // Pipeline stages for A (0-2)
      .BCASCREG(0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(1),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
      .PREG(1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_DSP8 (
      // Cascade outputs: Cascade Ports
      .ACOUT(DSP8_ACOUT),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(DSP8_PCOUT),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(DSP8_P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(),                     // 30-bit input: A cascade data
      .BCIN(),                     // 18-bit input: B cascade
      .CARRYCASCIN(),       // 1-bit input: Cascade carry
      .MULTSIGNIN(),         // 1-bit input: Multiplier sign cascade
      .PCIN(),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(DSP8_ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(DSP8_CARRYINSEL),         // 3-bit input: Carry select
      .CLK(CLK),                       // 1-bit input: Clock
      .INMODE(DSP8_INMODE),                 // 5-bit input: INMODE control
      .OPMODE(DSP8_OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(DSP8_A),                           // 30-bit input: A data
      .B(DSP8_B),                           // 18-bit input: B data
      .C(DSP8_C),                           // 48-bit input: C data
      .CARRYIN(DSP8_CARRYIN),               // 1-bit input: Carry-in
      .D(DSP8_D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(1'b0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b0),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(1'b0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(1'b0),                     // 1-bit input: Clock enable for 1st stage BREG
      .CEB2(1'b0),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(1'b0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(1'b0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(1'b0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(1'b0),             // 1-bit input: Clock enable for INMODEREG
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

   // End of DSP48E2_inst instantiation
   // End DSP8
   
   // Pipeline registers
   
   reg [47:0] DSP1_P1, DSP1_P2, DSP2_P1, DSP4_P1, DSP4_P2, DSP5_P1;
   
   always @ (posedge CLK) begin
    DSP1_P1 <= DSP1_P;
    DSP1_P2 <= DSP1_P1;
    DSP2_P1 <= DSP2_P;
    DSP4_P1 <= DSP4_P;
    DSP4_P2 <= DSP4_P1;
    DSP5_P1 <= DSP5_P;
  end
   
   // Output assignment
   
   wire [63:0] M64_0, M64_1, M64_2, M64_3, M64;
   wire [31:0] M32_0_0, M32_0_1, M32_1_0, M32_1_1, M32_0, M32_1;
   
   assign M64_0 = {DSP3_P[29:0], DSP2_P1[16:0], DSP1_P2[16:0]};
   assign M64_1 = {DSP6_P[3:0], DSP5_P1[16:0], DSP4_P2[16:0], 26'b0};
   assign M64 = M64_0 + M64_1;
   
   assign M32_0_0 = {DSP2_P[14:0], DSP1_P[16:0]};
   assign M32_0_1 = {DSP7_P[5:0], 26'b0};
   assign M32_0 = M32_0_0 + M32_0_1;
   
   always @ (*) begin
    case (OPCODE[5:4])
      6'b11: O = M64;
      6'b00: 
        begin
          O[15:0] = DSP1_P[15:0];
          O[31:16] = DSP4_P[15:0];
          O[47:32] = DSP7_P[15:0];
          O[63:48] = DSP8_P[15:0];
        end
      default: 
        begin
          O[15:0] = DSP1_P[15:0];
          O[31:16] = DSP4_P[15:0];
          O[47:32] = DSP7_P[15:0];
          O[63:48] = DSP8_P[15:0];
        end
    endcase
   end
  
endmodule
  