
#ifndef STM32L4_I2C_H
#define STM32L4_I2C_H

#include <stdint.h>
#include <stm32l432xx.h>

#define I2C_SCL PB6
#define I2C_SDA PB7
#define I2C_IRQ PB1

void initI2C(void);

void ConfigureI2C(char address, char nbyts, uint16_t Read);

void sendI2C(char address, char send[], char nbytes);

void readI2C(char address, char nbytes, char *reciev);


#endif