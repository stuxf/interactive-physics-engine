#ifndef STM32L432KC_I2C_H
#define STM32L432KC_I2C_H

#include <stdint.h>
#include <stdbool.h>
#include "stm32l432xx.h"

// Pin configuration
#define I2C_SCL_PIN        GPIO_PIN_6    // PA6
#define I2C_SDA_PIN        GPIO_PIN_5    // PA5
#define I2C_SCL_PORT       GPIOA
#define I2C_SDA_PORT       GPIOA
#define I2C_AF             4             // Alternate Function for I2C (AF4)

// I2C clock speed configuration (400 kHz)
#define I2C_SPEED          400000        // 400 kHz
#define I2C_TIMINGR_VALUE  ((_VAL2FLD(I2C_TIMINGR_PRESC, 0)) | \
                            (_VAL2FLD(I2C_TIMINGR_SCLL, 0x9)) | \
                            (_VAL2FLD(I2C_TIMINGR_SCLH, 0x3)) | \
                            (_VAL2FLD(I2C_TIMINGR_SDADEL, 0x2)) | \
                            (_VAL2FLD(I2C_TIMINGR_SCLDEL, 0x4)))

void init_I2C(void);
void I2C_Write(uint8_t addr, uint8_t reg, uint8_t data);
uint8_t I2C_Read(uint8_t addr, uint8_t reg);
void I2C_Scan(void);
#endif // STM32L432KC_I2C_H
