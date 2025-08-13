/////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// code bit t-SNI Gadget for k = 4 and n = 2 //////////////////
/////////////////////////////////////////////////////////////////////////////////////////
                        

.syntax unified
.thumb

.text


.global clear_regs
.type clear_regs, %function
.align 4
clear_regs:
    
    push {r14}

    mov r0, 0
    mov r1, 0
    mov r2, 0
    mov r3, 0

    pop {pc}


.align 4
.global   vectorToUint_asm
.type   vectorToUint_asm, %function;

vectorToUint_asm:
    
    push {r4-r11,r14}
    
    mov r10, #0 // counter i loop
    mov r5, #0 // val

initC0_i_vec:

    
    
    mov r2, 0 

    lsl r11, r10, #2
    add r11, r11, r1
    ldr r2, [r0, r11] // vect[i]
    lsl r2, r2, r10 // t = vect[i] << (k-1-i);
    eor r5, r5, r2 // val = val ^ t;
    

    // LOOP ITERATION initC0_i_vec
    add r10, r10, #1
    cmp r10, 4 // if i < k
    blt initC0_i_vec

    mov r0, r5
    mov r5, 0 

    pop {r4-r11,r14}
    bx lr


.align 4
.global   elementWiseMult_asm
.type   elementWiseMult_asm, %function;
// r0 = C_table[q]
// r1 = V_table[q-1]
// r2 = k-q == row
elementWiseMult_asm:
    
    push {r4-r11,r14}
    sub sp, sp, #(4 * 10)
    
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]

    // double loop
    mov r10, #0 // COUNTER i loop
    str r10, [sp, #16]
    mov r11, #0 // COUNTER j loop
    str r11, [sp, #20]

initC0_i_elemWise:

    ldr r11, [sp, #20] // reset counter j
    mov r11, #0
    str r11, [sp, #20] 

initC0_j_elemWise: 
    
    
    ldr r1, [sp, #4] // i
    ldr r10, [sp, #16] // i
    lsl r10, r10, #2  
    ldr r11, [sp, #20] // j
    lsl r12, r11, #2
    ldr r0, [sp, #0]
    ldr r4, [r0, r10] // Cq[i] == ith row of Cq

    mov r5, 0 
    
    ldr r5, [r4, r12] // a = Cq[i][j]

    ldr r0, [r1, r10]  // V_table[q-1][i] == ith row of V_table[q-1]
    mov r1, #3 // k-1
    sub r1, r1, r11 // (k-1)-j
    bl getbit_asm // b

    mov r1, 0 

    and r0, r5, r0
    str r0, [r4, r12] // Cq[i][j] = a & b
    ldr r0, [sp, #4]  
    
    mov r0, 0 


    // LOOP ITERATION initC0_j_elemWise
    ldr r11, [sp, #20] // counter j
    add r11, r11, #1
    str r11, [sp, #20] 
    cmp r11, #4 // if i < K
    blt initC0_j_elemWise


    // LOOP ITERATION initC0_i_elemWise
    ldr r10, [sp, #16] // counter i
    add r10, r10, #1
    str r10, [sp, #16] 
    cmp r10, r2 // if i < row
    blt initC0_i_elemWise

    add sp, sp, #(4* 10)
    pop {r4-r11,r14}
    bx lr



.align 4
.global   addRowToMatrix_asm
.type   addRowToMatrix_asm, %function;
// r0 = C_table[q]
// r1 = counter
// r2 = bit
addRowToMatrix_asm:
    
    push {r4-r11}
    
    mov r4, #0 // i loop

    lsl r1, r1, #2
    add r0, r0, r1
    ldr r0, [r0]  // Cq[counter]


loop_addRowMat:
    
    // CODE START   
    mov r3, #0
    lsl r5, r4, #2 // i
    str r3 , [r0, r5] // clear Cq[counter][i]
    str r2 , [r0, r5] // Cq[counter][i] = bit
    // LOOP ITERATION loop_addRowMat    
    add r4, r4, #1
    cmp r4, 4 // i<k
    blt loop_addRowMat

    pop {r4-r11}
    bx lr




.align 4
.global   getbit_asm
.type   getbit_asm, %function;
// r0 = x
// r1 = index
getbit_asm:
    and r0, r0, 0xFF
    lsr r0, r0, r1
    and r0, r0, 0x01

    bx lr



.align 4
.global   getIndex
.type   getIndex, %function;
// return i(4*n)+j
// r0 = i
// r1 = j
getIndex:
    push {r4,r5}
    lsl r1, r1, #2 // r1 = 4*j
    mov r4, #0 // index loop
    mov r5, #0 
    cmp r0, r4
    ble endf

loopIndex:
    add r5, r5, #8
    // LOOP ITERATION loopGBj
    add r4, r4, #1
    cmp r4, r0
    blt loopIndex

endf:
    add r0, r5, r1
    pop {r4,r5}
    bx lr

 


.align 4
.global   GadgetA
.type   GadgetA, %function;
// r0 = outputShares --> [sp, #0]
// r1 = sharesX --> [sp, #4]
// r2 = sharesY --> [sp, #8]



GadgetA:
    
    push {r4-r11,r14}

        
    sub sp, sp, #(4 * 5)
    // store pointers parameters in stack
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]
    
        
    // LOOP GADGET 2 ITERATION
    mov r10, #0 // COUNTER i loop
    str r10, [sp, #12]
    mov r11, #0 // COUNTER j loop
    str r11, [sp, #16]


   // r10 = i
   // r11 = j
loopGBi:
    ldr r11, [sp, #16] // counter j
    mov r11, #0
    str r11, [sp, #16] 

loopGBj:
    

    ldr r0, [sp, #12] // counter i
    ldr r1, [sp, #16] // counter j
    ldr r5, =matrix_S_table
    bl getIndex
    ldr r2, [r5, r0] // matrix_S_table[i][j] = Sij

    ldr r0, [sp, #4] // shares_x ptr
    ldr r1, [sp, #8] // shares_y ptr

    lsl r8, r10, #2 
    ldr r0, [r0, r8] // get sharesX[i]
    ldr r8, =L 

    lsl r8, r11, #2
    ldr r1, [r1, r8] // get sharesY[j]
    ldr r8, =L 

    
    bl GadgetB //GadgetB(x_i,  y_j, Sij)
   

    // store output share
    mov r9, r0
    ldr r0, [sp, #12] // counter i
    ldr r1, [sp, #16] // counter j
    ldr r8, [sp, #0] // outpushare ptr
    bl getIndex 
    add r8, r8, r0
    str r9, [r8]


    // LOOP ITERATION loopGBj
    ldr r11, [sp, #16] // counter j
    add r11, r11, #1
    str r11, [sp, #16] 
    cmp r11, 2
    blt loopGBj


    // LOOP ITERATION loopGBi
    ldr r10, [sp, #12] // counter i
    add r10, r10, #1
    str r10, [sp, #12] 
    cmp r10, 2
    blt loopGBi

    ldr r0, [sp, #0]
    add sp, sp, #(4 * 5)
    pop {r4-r11,r14}
    bx lr



.align 4
.global   GadgetB
.type   GadgetB, %function;
// r0 = x
// r1 = y
// r2 = Sij
//GadgetB(uint32  x, uint32  y, uint32  * Sij){

GadgetB:
  

    push {r4-r11,r14}
    sub sp, sp, #(4 * 60)

    // store pointers parameters in stack
    //str r0, [sp, #0]    // x
    //str r1, [sp, #4]    // y
    str r2, [sp, #8]    // Sij
    //ldr r2, =Ctilde

    mov r3, r0 // x_i
    mov r4, r1 // y_j

///////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// fill C0 with cross products /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////
    

    //#################  Get x[0]  #################
    mov r0, r3
    mov r1, #0 
    bl getbit_asm
    mov r5, r0

    //#################  Get x[1]  #################
    mov r0, r3
    mov r1, #1
    bl getbit_asm
    mov r6, r0

    //#################  Get x[2]  #################
    mov r0, r3
    mov r1, #2
    bl getbit_asm
    mov r7, r0

    //#################  Get x[3]  #################
    mov r0, r3
    mov r1, #3
    bl getbit_asm
    mov r8, r0


    //#################  Get y[0]  #################
    mov r0, r4
    mov r1, #0 
    bl getbit_asm
    mov r9, r0

    //#################  Get y[1]  #################
    mov r0, r4
    mov r1, #1
    bl getbit_asm
    mov r10, r0

    //#################  Get y[2]  #################
    mov r0, r4
    mov r1, #2
    bl getbit_asm
    mov r11, r0

    //#################  Get y[3]  #################
    mov r0, r4
    mov r1, #3
    bl getbit_asm
    mov r12, r0


    ///////// Compute binary cross products and store /////////
    mov r1, #0


    /////////////////// Row 0 ///////////////////

    ////// x[0]y[3] //////
    and r1, r5, r12 
    lsl r1, r1, 3
    
    ////// x[0]y[2] //////
    and r0, r5, r11 
    lsl r0, r0, 2
    eor r1, r1, r0

    ////// x[0]y[1] //////
    and r0, r5, r10 
    lsl r0, r0, 1
    eor r1, r1, r0

    ////// x[0]y[0] //////
    and r0, r5, r9 
    eor r1, r1, r0

    str r1, [sp, 12]
    mov r1, #0 

    
    /////////////////// Row 1 ///////////////////
    ////// x[1]y[2] //////
    and r1, r6, r11 
    lsl r1, r1, 3
    
    ////// x[1]y[1] //////
    and r0, r6, r10 
    lsl r0, r0, 2
    eor r1, r1, r0


    ////// x[1]y[0] //////
    and r0, r6, r9 
    lsl r0, r0, 1
    eor r1, r1, r0

    str r1, [sp, #16]
    mov r1, #0 

    /////////////////// Row 4 mod Q_0 ///////////////////

    ////// x[1]y[3] % MOD Q_0 //////
    and r0, r6, r12 
    lsl r1, r0, 1
    eor r1, r1, r0

    str r1, [sp, #28]
    mov r1, #0 


    /////////////////// Row 2 ///////////////////
    ////// x[2]y[1] //////
    and r1, r7, r10 
    lsl r1, r1, 3
    

    ////// x[2]y[0] //////
    and r0, r7, r9 
    lsl r0, r0, 2
    eor r1,r1, r0
    
    str r1, [sp, #20]
    mov r1, #0 

    /////////////////// Row 5 MOD Q_0 ///////////////////

    ////// x[2]y[2] MOD Q_0 //////
    and r0, r7, r11 
    lsl r1, r0, 1
    eor r1, r1, r0

    str r1, [sp, #32]
    mov r1, #0 

    /////////////////// Row 7 MOD Q_1 ///////////////////
    ////// x[2]y[3] MOD Q_1 //////
    and r0, r7, r12 
    lsl r1, r0, 1
    eor r1, r1, r0
    lsl r1, r1, 1

    str r1, [sp, #40]
    mov r1, #0 


    /////////////////// Row 3 ///////////////////
    ////// x[3]y[0] //////
    and r1, r8, r9
    lsl r1, r1, 3 

    str r1, [sp, #24]
    mov r1, #0 



    /////////////////// Row 6 MOD Q_0 ///////////////////
    ////// x[3]y[1] mod Q_0 //////
    and r0, r8, r10 
    lsl r1, r0, 1
    eor r1, r1, r0

    str r1, [sp, #36]
    mov r1, #0 


    /////////////////// Row 8 MOD Q_1 ///////////////////
    ////// x[3]y[2] mod Q_1 //////
    and r0, r8, r11
    lsl r1, r0, 1
    eor r1, r1, r0
    lsl r1, r1, 1

    str r1, [sp, #44]
    mov r1, #0 


    /////////////////// Row 9 MOD Q_2 ///////////////////
    ////// x[3]y[3] mod Q_2 //////
    and r0, r8, r12
    lsl r1, r0, 1
    eor r1, r1, r0
    lsl r1, r1, 2

    str r1, [sp, #48]
    mov r1, #0 



//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// mask Ctilde with Sij ////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    ldr r3, [sp, #8] // Sij

    // double loop
    mov r10, #0 // COUNTER i loop
    mov r0, 0 // output

initC0_i_mask:
    
    mov r6, #0
    mov r1, #0
    mov r5, #0

    lsl r4, r10, #2
    ldr r6, [r3, r4] // Sij[i]
    add r7, r4, 12
    ldr r1, [sp, r7] // Ctilde[i] in SP
    eor r5, r6, r1
    //////// Compress ////////
    eor r0, r0, r5

    

    // LOOP ITERATION initC0_i_mask
    add r10, r10, #1
    cmp r10, 10 
    blt initC0_i_mask


    
    ///// clear RF /////
    mov r1, #0
    mov r2, #0
    //ldr r2, =Ctilde   // Ctilde ptr
    mov r3, #0
    mov r4, #0
    mov r5, #0
    mov r6, #0
    mov r7, #0
    mov r8, #0
    mov r9, #0
    mov r10, #0
    mov r11, #0
    mov r12, #0

    
    add sp, sp, #(4 * 60)
    pop {r4-r11,r14}
    bx lr



.align 4
.global   IPM0V1
.type   IPM0V1, %function;
// r0 = s0 pt
// r1 = s0 pt

IPM0V1:    
    push {r4-r11,r14}
    mov r4, r0
    mov r5, r1

    bl rng_get_random_blocking
    mov r10, r0 // 32 bit randomness
    mov r0, r4 // place back s0 pt
    mov r1, r5 // place back s1 pt
    
    lsr r12, r10, 8
    and r12, r12, #0xF // z_1
    mov r14, r12

    // c1
    lsr r2, r12, 1 // c1
    and r6, r2, 0x1 // a0 = c1
    and r7, r2, 0x1 // b0 = c1


    // b1
    lsr r3, r12, 2 
    and r3, r3, 0x1 // b1
    eor r6, r3, r6 // a0 = c1 + b1
    mov r8, r3 // c0 = b1
    mov r9, r3 // d0 = b1


    // a1
    lsr r4, r12, 3 
    and r4, r4, 0x1 // a1
    eor r7, r4, r7 // b0 = c1 + a1
    eor r9, r4, r9 // d0 = b1 + a1

    // d1
    and r5, r12, 0x1 // d1
    eor r7, r5, r7 // b0 = c1 + a1 + d1
    eor r8, r5, r8 // c0 = b1 + d1

    lsl r11, r6, 3 // a0 placed
    lsl r7, r7, 2 // b0 placed
    eor r11, r11, r7
    lsl r8, r8, 1 // c0 placed
    eor r11, r11, r8
    eor r11, r11, r9 // d0 placed


    lsr r12, r10, 4
    and r12, r12, #0xF // y_1
    eor r14, r14, r12

    // c1
    lsr r2, r12, 1 // c1
    and r6, r2, 0x1 // a0 = c1
    and r7, r2, 0x1 // b0 = c1


    // b1
    lsr r3, r12, 2 
    and r3, r3, 0x1 // b1
    eor r6, r3, r6 // a0 = c1 + b1
    mov r8, r3 // c0 = b1
    mov r9, r3 // d0 = b1


    // a1
    lsr r4, r12, 3 
    and r4, r4, 0x1 // a1
    eor r7, r4, r7 // b0 = c1 + a1
    eor r9, r4, r9 // d0 = b1 + a1

    // d1
    and r5, r12, 0x1 // d1
    eor r7, r5, r7 // b0 = c1 + a1 + d1
    eor r8, r5, r8 // c0 = b1 + d1

    lsl r6, r6, 3 // a0 placed
    lsl r7, r7, 2 // b0 placed
    eor r6, r6, r7
    lsl r8, r8, 1 // c0 placed
    eor r6, r6, r8
    eor r6, r6, r9 // d0 placed

    eor r11, r11, r6 // sum shares 0

    str r11, [r0] // store result share 0
    str r14, [r1] // store result share 1

    pop {r4-r11,r14}
    bx lr




