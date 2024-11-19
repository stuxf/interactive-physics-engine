
#include "STM32L432KC_I2C.h"
#include <stdio.h>

#define MPU6050_I2C_ADDR 0x68

void init_I2C(void) {
    printf("Initializing I2C...\n");

    // Enable GPIOA clock for PA5 (SDA) and PA6 (SCL)
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    // Configure PA5 and PA6 as alternate function (AF4 for I2C)
    GPIOA->MODER &= ~(_VAL2FLD(GPIO_MODER_MODE5, 0b11) | _VAL2FLD(GPIO_MODER_MODE6, 0b11));
    GPIOA->MODER |= (_VAL2FLD(GPIO_MODER_MODE5, 0b10) | _VAL2FLD(GPIO_MODER_MODE6, 0b10));

    GPIOA->OTYPER |= (GPIO_OTYPER_OT5 | GPIO_OTYPER_OT6); // Open-drain
    GPIOA->OSPEEDR |= (_VAL2FLD(GPIO_OSPEEDR_OSPEED5, 0b11) | _VAL2FLD(GPIO_OSPEEDR_OSPEED6, 0b11)); // High speed
    GPIOA->PUPDR &= ~(_VAL2FLD(GPIO_PUPDR_PUPD5, 0b11) | _VAL2FLD(GPIO_PUPDR_PUPD6, 0b11)); // No pull-up/pull-down

    GPIOA->AFR[0] |= (_VAL2FLD(GPIO_AFRL_AFSEL5, 4) | _VAL2FLD(GPIO_AFRL_AFSEL6, 4)); // Set AF4 for I2C1

    // Enable I2C1 clock
    RCC->APB1ENR1 |= RCC_APB1ENR1_I2C1EN;

    // Disable I2C1 during configuration
    I2C1->CR1 &= ~I2C_CR1_PE;

    // Configure timing for 400 kHz with 16 MHz HSI
    I2C1->TIMINGR = (_VAL2FLD(I2C_TIMINGR_PRESC, 0) |  // Prescaler = 0
                     _VAL2FLD(I2C_TIMINGR_SCLL, 0x9) | // SCL low period
                     _VAL2FLD(I2C_TIMINGR_SCLH, 0x3) | // SCL high period
                     _VAL2FLD(I2C_TIMINGR_SDADEL, 0x2) | // Data setup time
                     _VAL2FLD(I2C_TIMINGR_SCLDEL, 0x4)); // Data hold time

    // Enable peripheral
    I2C1->CR1 |= I2C_CR1_PE;

    // Enable auto end mode
    I2C1->CR2 |= I2C_CR2_AUTOEND;

    printf("I2C initialized successfully.\n");
}

void I2C_Write(uint8_t addr, uint8_t reg, uint8_t data) {
    printf("I2C Write: Addr=0x%X, Reg=0x%X, Data=0x%X\n", addr, reg, data);

    // Wait until I2C is ready
    while (I2C1->CR2 & I2C_CR2_START);

    // Clear NACK flag
    I2C1->ICR |= I2C_ICR_NACKCF;

    // Configure transfer for writing 2 bytes
    I2C1->CR2 = (_VAL2FLD(I2C_CR2_SADD, addr << 1) |  // Address
                 _VAL2FLD(I2C_CR2_NBYTES, 2) |        // 2 bytes: Register + Data
                 _VAL2FLD(I2C_CR2_RD_WRN, 0) |        // Write
                 I2C_CR2_START);                      // Start condition

    // Wait for TXIS flag
    while (!(I2C1->ISR & I2C_ISR_TXIS)) {
        if (I2C1->ISR & I2C_ISR_NACKF) {
            printf("Error: NACK received during write.\n");
            I2C1->ICR |= I2C_ICR_NACKCF;
            return;
        }
    }

    // Send register address
    I2C1->TXDR = reg;

    // Wait for TXIS flag
    while (!(I2C1->ISR & I2C_ISR_TXIS));

    // Send data
    I2C1->TXDR = data;

    // Wait for transfer to complete
    while (!(I2C1->ISR & I2C_ISR_TC));

    printf("I2C Write Complete.\n");
}

uint8_t I2C_Read(uint8_t addr, uint8_t reg) {
    printf("I2C Read: Addr=0x%X, Reg=0x%X\n", addr, reg);

    // Write the register address
    while (I2C1->CR2 & I2C_CR2_START);

    I2C1->ICR |= I2C_ICR_NACKCF; // Clear NACK flag

    I2C1->CR2 = (_VAL2FLD(I2C_CR2_SADD, addr << 1) |  // Address
                 _VAL2FLD(I2C_CR2_NBYTES, 1) |        // 1 byte: Register
                 _VAL2FLD(I2C_CR2_RD_WRN, 0) |        // Write
                 I2C_CR2_START);                      // Start condition

    // Wait for TXIS flag
    while (!(I2C1->ISR & I2C_ISR_TXIS));

    // Send register address
    I2C1->TXDR = reg;

    // Wait for transfer complete
    while (!(I2C1->ISR & I2C_ISR_TC));

    // Configure for reading 1 byte
    I2C1->CR2 = (_VAL2FLD(I2C_CR2_SADD, addr << 1) |  // Address
                 _VAL2FLD(I2C_CR2_NBYTES, 1) |        // 1 byte
                 _VAL2FLD(I2C_CR2_RD_WRN, 1) |        // Read
                 I2C_CR2_START);                      // Start condition

    // Wait for RXNE flag
    while (!(I2C1->ISR & I2C_ISR_RXNE));

    // Read data
    uint8_t data = I2C1->RXDR;

    printf("I2C Read Complete: Data=0x%X\n", data);
    return data;
}

void I2C_Scan(void) {
    printf("Scanning I2C bus...\n");
    for (uint8_t addr = 1; addr < 128; addr++) {
        while (I2C1->CR2 & I2C_CR2_START);
        I2C1->ICR |= I2C_ICR_NACKCF;

        I2C1->CR2 = (_VAL2FLD(I2C_CR2_SADD, addr << 1) | _VAL2FLD(I2C_CR2_NBYTES, 0) | I2C_CR2_START);
        while (!(I2C1->ISR & (I2C_ISR_TC | I2C_ISR_NACKF)));

        if (!(I2C1->ISR & I2C_ISR_NACKF)) {
            printf("Device found at 0x%X\n", addr);
        }
        I2C1->ICR |= I2C_ICR_NACKCF; // Clear NACK flag
    }
}
