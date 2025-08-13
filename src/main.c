//////////////////////////////////////
////////// two shares, four bits /////
//////////////////////////////////////

#include "../common/stm32wrapper.h"
#include <stdio.h>
#include <stdlib.h>

/* Security parameter */
#define n 2
#define k 4
#define modQ 0x03

typedef unsigned char uint8;
typedef unsigned int uint32;


static int bigRow = n*k*(k+1)/2;
static int middleRow = k*(k+1)/2;



extern void GadgetA(uint32 table_Zij[n][n], uint32 shares_x[n], uint32 shares_y[n]);
extern void clear_regs(void);
extern void IPM0V1(uint32* a,uint32* b);


uint8 Logtable_16[16] = { 0, 15, 1, 4, 2, 8, 5, 10, 3, 14, 9, 7, 6, 13, 11, 12};  
uint8 Alogtable_16[16] = {1, 2, 4, 8, 3, 6, 12, 11, 5, 10, 7, 14, 15, 13, 9, 1};

uint8 genRandByte();
uint8 gfMul(uint8 a, uint8 b);
void xorVectors(uint32 * Sij, uint32 * Ri);
void encodeByte(uint8 val, uint8 * shares, uint8 * L);
uint8 decodeByte(uint8 shares0, uint8  shares1, uint8 * L);


uint8 genRandByte(){
    return rng_get_random_blocking() & 0xF;
}



uint8 gfMul(uint8 a, uint8 b)
{
    uint32_t t = 0;
    uint8 q;

    t = Logtable_16[a] + Logtable_16[b];

    q = t & 0xF;
    t = (t>>4);
    t = t + q;

    q = Alogtable_16[t];

    return q * ((a+0xF)>>4) * ((b+0xF)>>4);

}


void xorVectors(uint32 * Sij, uint32 * Ri){
    for (int i = 0; i < middleRow; ++i) {
        Sij[i] = Sij[i]^Ri[i];
    }
}


void encodeByte(uint8 val, uint8 * shares, uint8 * L){
    
    uint8 tmp = genRandByte();
    shares[1] = tmp;
    uint8 tmp2 = gfMul(L[1], tmp);
    shares[0] = val ^ tmp2;
}


uint8 decodeByte(uint8 shares0, uint8  shares1, uint8 * L){
    uint8 tmp;
    tmp = gfMul(L[1], shares1);
    uint8 pt_out = shares0 ^ tmp;
    return pt_out;
}
 

uint32 table_Zij[n][n];
int middleRoww = 10;
 

uint8  L[2];
uint32 * matrix_S_table[2][2];
uint32 * matrix_R_table[2];
uint32 * V_table[3];


int main() {

clock_setup();
gpio_setup();
usart_setup(115200);
flash_setup();

rng_enable();



    //////// Public L ////////
    L[0] = 1;
    L[1] = 6; // provides second order security


//// Construct the matrices V^p ////
uint32 qx = modQ;
uint32 vp_buffer[4][4];
uint32* vp;
for (int p = 1; p < k; p++) {
    vp = vp_buffer[p - 1];
    if (p > 1) {
        qx = gfMul(qx, 2);
    }
    for (int i = 0; i < k - p; i++) {
        vp[i] = qx;
    }
    V_table[p - 1] = vp;
}



  while(1){
        uint32 shares_x[2];
        uint32 shares_y[2];
        uint8 sharesx[2];
        uint8 sharesy[2];
        /// read shares x
        recv_USART_bytes(sharesx,n);
        
        /// read shares y
        recv_USART_bytes(sharesy,n);
        
        for(int i = 0; i<2; i++){
          shares_x[i] = sharesx[i];
        }

        for(int i = 0; i<2; i++){
          shares_y[i] = sharesy[i];
        }

        trigger_high(); 
        
        //// Compute s_i = (s0,...,sn−1) n-share IPMs of 0 ////
        uint8 S_table[bigRow][2];
        for (int i = 0; i < bigRow; i++) {
            uint32 shares_S0[1];
            uint32 shares_S1[1];
            IPM0V1(shares_S0,shares_S1);
            S_table[i][0] = shares_S0[0];
            S_table[i][1] = shares_S1[0];
        }

        //// Compute r_i = (r0,...,rn−1) n-share IPMs of 0 ////
        uint8 R_table[middleRow][2];
        for (int i = 0; i < middleRow; i++) {
            uint32 shares_R0[1];
            uint32 shares_R1[1];
            IPM0V1(shares_R0,shares_R1);
            R_table[i][0] = shares_R0[0];
            R_table[i][1] = shares_R1[0];
        }


        //// Construct matrices Si,j ////
        uint32 Sij_buffer[2][2][middleRow];
        uint32* Sij;
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n; ++j) {
                Sij = Sij_buffer[i][j];
                for (int l = 0; l < middleRow; ++l) {
                    Sij[l] = S_table[i * middleRow + l][j];
                }
                matrix_S_table[i][j] = Sij;
            }
        }

        //// Construct matrices Ri and update Si,0 ////
        uint32 Ri_buffer[2][middleRow];
        uint32* Ri;
        for (int i = 0; i < n; ++i) {
            Ri = Ri_buffer[i];
            for (int j = 0; j < middleRow; ++j) {
                Ri[j] = R_table[j][i];
            }
            matrix_R_table[i] = Ri;
            xorVectors(matrix_S_table[i][0], matrix_R_table[i]);
        }


        
        /// GadgetA
        GadgetA(table_Zij,shares_x,shares_y);
        
        // Compression 
        uint8 out[2];
        for (int i = 0; i < n; ++i) {
          uint8 pairOfShares[2];
          
          for (int j = 0; j < n; ++j) {
              pairOfShares[j] = table_Zij[i][j];
              clear_regs();
            }
            out[i] = decodeByte(pairOfShares[0],pairOfShares[1],L);
        }

    }
        
}
