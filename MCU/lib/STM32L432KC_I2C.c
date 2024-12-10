/*
File: STM32L432KC_I2C
Author: Amy Liu
Email: amyliu01@g.hmc.edu
Date: 12/8/2024
Source code for I2C functions
*/
#include "STM32L432KC.h"
#include "STM32L432KC_I2C.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"

// Initializes the I2C peripheral
void initI2C() {
    // Step 1: Enable required clock domains
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;  // Enable GPIOB clock domain
    RCC->CR |= RCC_CR_HSION;              // Turn on HSI 16 MHz clock
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_I2C1SEL, 0b10);  // Set HSI16 as the clock for I2C
    RCC->APB1ENR1 |= RCC_APB1ENR1_I2C1EN; // Enable I2C1 clock

    // Step 2: Configure GPIO pins for I2C functionality
    pinMode(I2C_SCL, GPIO_ALT);  // Set SCL (PB6) to Alternate Function mode
    pinMode(I2C_SDA, GPIO_ALT);  // Set SDA (PB7) to Alternate Function mode

    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL6, 0b0100); // Set SCL (PB6) to AF4 for I2C
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL7, 0b0100); // Set SDA (PB7) to AF4 for I2C

    GPIOB->OSPEEDR |= GPIO_OSPEEDR_OSPEED3;  // Configure output speed to high
    GPIOB->OTYPER |= GPIO_OTYPER_OT6;        // Enable open-drain mode for SCL
    GPIOB->OTYPER |= GPIO_OTYPER_OT7;        // Enable open-drain mode for SDA

    // Step 3: Configure I2C-specific settings
    I2C1->CR1 &= ~I2C_CR1_ANFOFF;  // Enable analog noise filter
    I2C1->CR1 |= I2C_CR1_RXIE;     // Enable RX interrupt
    I2C1->CR1 |= I2C_CR1_TXIE;     // Enable TX interrupt
    I2C1->CR1 |= I2C_CR1_TCIE;     // Enable transfer-complete interrupt

    // Step 4: Set up timing registers for 400 kHz I2C High Speed Mode
    I2C1->TIMINGR = 0; // Clear TIMINGR
    I2C1->TIMINGR |= _VAL2FLD(I2C_TIMINGR_PRESC, 3);    // Prescaler
    I2C1->TIMINGR |= _VAL2FLD(I2C_TIMINGR_SCLDEL, 4);   // Data setup time
    I2C1->TIMINGR |= _VAL2FLD(I2C_TIMINGR_SDADEL, 2);   // Data hold time
    I2C1->TIMINGR |= _VAL2FLD(I2C_TIMINGR_SCLH, 0xF);   // High period
    I2C1->TIMINGR |= _VAL2FLD(I2C_TIMINGR_SCLL, 0x13);  // Low period

    // Step 5: Enable auto-end mode and the I2C peripheral
    I2C1->CR2 |= I2C_CR2_AUTOEND;  // Enable auto-end mode
    I2C1->CR1 |= I2C_CR1_PE;       // Enable I2C peripheral
}


// Configures I2C communication parameters
void ConfigureI2C(char address, char nbytes, uint16_t Read) {
    // Set 7-bit addressing mode using _VAL2FLD for clarity
    I2C1->CR2 &= ~I2C_CR2_ADD10;

    // Enable 7-bit header followed by r/w bit
    I2C1->CR2 |= _VAL2FLD(I2C_CR2_HEAD10R, 1);

    // Configure the slave address
    I2C1->CR2 &= ~I2C_CR2_SADD_Msk;               // Clear existing address
    I2C1->CR2 |= _VAL2FLD(I2C_CR2_SADD, address << 1); // Set new slave address

    // Configure transfer direction
    if (Read) {
        I2C1->CR2 |= I2C_CR2_RD_WRN;  // Set read operation
    } else {
        I2C1->CR2 &= ~I2C_CR2_RD_WRN; // Set write operation
    }

    // Set number of bytes to send/receive
    I2C1->CR2 &= ~I2C_CR2_NBYTES_Msk; // Clear NBYTES field
    I2C1->CR2 |= _VAL2FLD(I2C_CR2_NBYTES, nbytes); // Set NBYTES

    // Generate START condition
    I2C1->CR2 |= _VAL2FLD(I2C_CR2_START, 1);
}


// Sends data over I2C
void sendI2C(char address, char send[], char nbytes) {
    // Initialize communication for write operation
    ConfigureI2C(address, nbytes, 0);

    I2C1->ISR |= I2C_ISR_TXIS_Msk;

    // Transmit data byte-by-byte
    for (int i = 0; i < nbytes; i++) {
        // Wait until TXIS is set
        while (!(I2C1->ISR & I2C_ISR_TXIS));

        // Write data to TXDR
        *((volatile char *)(&I2C1->TXDR)) = send[i];
    }
}

// Reads data over I2C
void readI2C(char address, char nbytes, char *receive) {
    // Initialize communication for read operation
    ConfigureI2C(address, nbytes, 1);

    // Receive data byte-by-byte
    for (int i = 0; i < nbytes; i++) {
        // Wait until RXNE is set
        while (!(I2C1->ISR & I2C_ISR_RXNE));

        // Read data from RXDR
        receive[i] = (volatile char)I2C1->RXDR;
    }
}
