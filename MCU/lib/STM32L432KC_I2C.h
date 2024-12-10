/*
File: STM32L432KC_I2C
Author: Amy Liu
Email: amyliu01@g.hmc.edu
Date: 12/8/2024
Header for I2C functions
*/

#ifndef STM32L4_I2C_H
#define STM32L4_I2C_H

#include <stdint.h>
#include <stm32l432xx.h>

#define I2C_SCL PB6
#define I2C_SDA PB7
#define I2C_IRQ PB1

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

/* Initializes the I2C peripheral and its basic configuration.
 * Sets up the clock and enables the I2C interface for communication.
 *    -- This function configures I2C in standard or fast mode based on pre-set settings.
 * Refer to the datasheet and reference manual for additional low-level details. */
void initI2C(void);

/* Configures the I2C communication parameters for a specific transfer.
 *    -- address: The 7-bit address of the I2C device.
 *    -- nbyts: The number of bytes to be transferred in the operation.
 *    -- Read: Determines the direction of data transfer (0 for write, 1 for read).
 * Configures the internal state of the I2C peripheral to manage the transfer based on these parameters. */
void ConfigureI2C(char address, char nbyts, uint16_t Read);

/* Sends data over the I2C bus to a specified device.
 *    -- address: The 7-bit address of the I2C device to send data to.
 *    -- send: A pointer to the buffer containing the data to be sent.
 *    -- nbytes: The number of bytes to send.
 * This function handles the I2C start condition, data transmission, and stop condition. */
void sendI2C(char address, char send[], char nbytes);

/* Reads data from a specified device over the I2C bus.
 *    -- address: The 7-bit address of the I2C device to read data from.
 *    -- nbytes: The number of bytes to read.
 *    -- reciev: A pointer to the buffer where the received data will be stored.
 * This function handles the I2C start condition, data reception, and stop condition. */
void readI2C(char address, char nbytes, char *reciev);



#endif