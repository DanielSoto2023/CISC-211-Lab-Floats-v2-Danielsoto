/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Daniel Soto"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    MOV R5, 0
    LDR R4, =f0
    STR R5,[R4]
    LDR R4, =sb0
    STR R5,[R4]
    LDR R4,=storedExp0
    STR R5,[R4]
    LDR R4,=realExp0
    STR R5,[R4]
    LDR R4,=mant0
    STR R5,[R4]
    
    MOV R5, 0
    LDR R4, =f1
    STR R5,[R4]
    LDR R4, =sb1
    STR R5,[R4]
    LDR R4,=storedExp1
    STR R5,[R4]
    LDR R4,=realExp1
    STR R5,[R4]
    LDR R4,=mant1
    STR R5,[R4]
    
    MOV R5, 0
    LDR R4, =fMax
    STR R5,[R4]
    LDR R4, =sbMax
    STR R5,[R4]
    LDR R4,=storedExpMax
    STR R5,[R4]
    LDR R4,=realExpMax
    STR R5,[R4]
    LDR R4,=mantMax
    STR R5,[R4]
    POP {R4-R11,LR}
    BX LR
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    LDR R4,[r0]
    LSR R4,31
    STR R4,[r1]
    POP {R4-R11,LR}
    BX LR
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    LDR r0,[r0]
    LDR R4,=0x7F800000
    AND R0,R0,R4
    LSR R0,23
    MOV R4, 0
    CMP R0, R4
    BEQ subnormal /*checks for subnormal so -126 not -127*/
    BAL normal
    subnormal:
    SUB r1,r0,126
    BAL endExponent
    normal:
    SUB r1,r0,127
    BAL endExponent
    endExponent:
    POP {R4-R11,LR}
    BX LR
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    LDR r0,[r0]
    LDR R3, =0x007FFFFF
    AND R0,R0,R3
    MOV R1,R0
    LDR R3, =0x00800000 /*adds implied bit*/
    ORR R1,R1,R3 
    POP {R4-R11,LR}
    BX LR
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    LDR r0,[r0]
    LDR R4,=0x00000000
    CMP r0,r4
    BEQ isZero
    LDR R4,=0x80000000
    CMP r0,r4
    BEQ negativeZero
    MOV r0,0
    BAL asmIsZeroEnd
    negativeZero:
    MOV r0,-1
    BAL asmIsZeroEnd
    isZero:
    MOV r0,1
    BAL asmIsZeroEnd
    asmIsZeroEnd:
    POP {R4-R11,LR}
    BX LR
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {R4-R11,LR}
    LDR R0,[R0]
    LDR R4,=0x7F800000
    LDR R5,=0xFF800000
    CMP r0,r4
    BEQ posInf
    CMP r0,r5
    BEQ negInf
    MOV r0,0
    BAL endInf
    posInf:
    MOV r0,1
    BAL endInf
    negInf:
    MOV r0,-1
    BAL endInf
    endInf:
    POP {R4-R11,LR}
    BX LR
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    PUSH {R4-R11,LR}
    MOV R4,R0
    MOV R5,R1 /*R4 and R5 will keep the variables as R0-R3 are not perserved through func calls*/
    BL initVariables
    
    LDR R6,=f0
    STR R4,[r6]
    LDR R6,=f1
    STR R5,[R6]
    
    LDR r0,=f0 /*Self Explainatory, Get sign bit*/
    LDR R1,=sb0
    BL getSignBit
    
    LDR r0,=f1
    LDR R1,=sb1
    BL getSignBit
    
    LDR r0,=f0 /*Get and Store exponent result*/
    BL getExponent
    LDR r4, =storedExp0
    LDR r5, =realExp0
    STR r0,[r4]
    STR r1,[r5]
    
    LDR r0,=f1
    BL getExponent
    LDR r4, =storedExp1
    LDR r5, =realExp1
    STR r0,[r4]
    STR r1,[r5]
    
    LDR r0,=f0 /*Mantissa, r0 is returned w/o implied, r1 with*/
    BL getMantissa
    MOV r4,r0
    MOV r5,r1
    MOV r6,0
    LDR R7,=storedExp0
    LDR r7,[r7]
    CMP r6,r7
    BEQ realSubnormalf0
    LDR r6,=255
    CMP r6,r7
    BEQ realSubnormalf0
    LDR R8,=mant0
    STR r5,[r8]
    BAL pastSubf0
    
    realSubnormalf0:
    LDR r8,=mant0
    STR r4, [r8]
   
    pastSubf0:
    LDR r0,=f1 /*Mantissa, r0 is returned w/o implied, r1 with*/
    BL getMantissa
    MOV r4,r0
    MOV r5,r1
    MOV r6,0
    LDR R7,=storedExp1
    LDR r7,[r7]
    CMP r6,r7
    BEQ realSubnormalf1
    LDR r6,=255
    CMP r6,r7
    BEQ realSubnormalf1
    LDR R8,=mant1
    STR r5,[r8]
    BAL pastSubf1
    
    realSubnormalf1:
    LDR r8,=mant1
    STR r4, [r8]
    
    pastSubf1:
    
    LDR r0,=f0 /*check inf cases*/
    BL asmIsInf
    LDR r1,=1
    LDR r2,=-1
    CMP R1,R0
    BEQ f0Max
    CMP R2,r0
    BEQ f1Max
    
    LDR r0,=f1
    BL asmIsInf
    LDR r1,=1
    LDR r2,=-1
    CMP R1,R0
    BEQ f1Max
    CMP R2,r0
    BEQ f0Max
    
    LDR r0,=sb0 /*Check sign bit*/
    LDR r1,=sb1
    LDR r0,[r0]
    LDR r1,[r1]
    
    CMP r0,r1
    BNE diffSignBit /*Diff sign bit positive one is fMax*/
    LDR r2,=1 
    CMP r0,r2 /*r0 and r1 are equal at this point.*/
    BEQ negativeCase
    
    positiveCase: /*Redundant label just to make it look like negative case*/
    LDR r0,=realExp0
    LDR r1,=realExp1
    LDR r0,[r0]
    LDR r1,[r1]
    CMP r0,r1
    BNE diffPosExp
    
    LDR r0,=mant0
    LDR r1,=mant1
    LDR r0,[r0]
    LDR r1,[r1]
    CMP r0,r1
    BNE diffPosMant
    BAL f0Max /*IF for some reason they are equal then f0Max*/
    
    negativeCase: /*The less negative number is larger*/
    LDR r0,=realExp0
    LDR r1,=realExp1
    LDR r0,[r0]
    LDR r1,[r1]
    CMP r0,r1
    BNE diffNegExp
    
    LDR r0,=mant0
    LDR r1,=mant1
    LDR r0,[r0]
    LDR r1,[r1]
    CMP r0,r1
    BNE diffNegMant
    BAL f0Max /*IF for some reason they are equal then f0Max*/
    
    diffNegMant: /*Buncha Compares to see if F0 or F1 is greater*/
    CMP r0,r1
    BGT f1Max
    BAL f0Max
    
    diffNegExp:
    CMP r0,r1
    BGT f1Max
    BAL f0Max
    
    diffPosMant:
    CMP r0,r1
    BGT f0Max
    BAL f1Max
    
    diffPosExp:
    CMP r0,r1
    BGT f0Max /*test*/
    BAL f1Max
    
    diffSignBit:
    CMP r0,r1
    BLT f0Max /*0 is positive, 1 is negative therefore Less than*/
    BAL f1Max
    
    f0Max: /*Storing stuff in the max mem locations*/
    LDR r0,=f0
    LDR r0,[r0]
    LDR r1,=fMax
    STR r0,[r1]
    
    LDR r0,=sb0
    LDR r0,[r0]
    LDR r1,=sbMax
    STR r0,[r1]
    
    LDR r0,=storedExp0
    LDR r0,[r0]
    LDR r1,=storedExpMax
    STR r0,[r1]
    
    LDR r0,=realExp0
    LDR r0,[r0]
    LDR r1,=realExpMax
    STR r0,[r1]
    
    LDR r0,=mant0
    LDR r0,[r0]
    LDR r1,=mantMax
    STR r0,[r1]
    
    LDR r0,=fMax
    BAL done
    
    f1Max:
    LDR r0,=f1
    LDR r0,[r0]
    LDR r1,=fMax
    STR r0,[r1]
    
    LDR r0,=sb1
    LDR r0,[r0]
    LDR r1,=sbMax
    STR r0,[r1]
    
    LDR r0,=storedExp1
    LDR r0,[r0]
    LDR r1,=storedExpMax
    STR r0,[r1]
    
    LDR r0,=realExp1
    LDR r0,[r0]
    LDR r1,=realExpMax
    STR r0,[r1]
    
    LDR r0,=mant1
    LDR r0,[r0]
    LDR r1,=mantMax
    STR r0,[r1]
    
    LDR r0,=fMax
    BAL done
    
    
    
    done:
    POP {R4-R11,LR}
    BX LR    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



