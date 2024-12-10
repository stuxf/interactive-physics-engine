/*
File: main.c
Author: Amy Liu
Email: amyliu01@g.hmc.edu
Date: 12/8/2024
Purpose: Handles all logic to send IMU data to FPGA
*/

#include "STM32L432KC.h"
#include "MPU6050.h"
#include <math.h>
#include <stdio.h>

void mcu_to_fpga(int16_t angle_deg);

int main(void) {

    configureFlash(); // Configure Flash memory for current clock settings.
    configureClock(); // Set up the system clock.
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN; // Enable TIM2 clock.
    initTIM(TIM2); // Initialize TIM2 timer.
    initI2C(); // Initialize I2C bus.
    initSPI(1, 0, 0); // Initialize SPI with baud rate 1, CPOL=0, CPHA=0.

    uint8_t address = 0x68;  // Example I2C address
    uint8_t reg = 0x6B;      // Power Management Register
    uint8_t writeData = 0x00; // Data to write (e.g., wake up MPU6050)

    MPU6050_ACCEL_t accel_data;
  
    MPU6050_Init();

    while(1){

    MPU6050_Read_Accel(&accel_data);

    // Convert to raw integer data
        int16_t accel_x = (int16_t)(accel_data.Accel_X * 1000); // Convert to milli-g
        int16_t accel_y = (int16_t)(accel_data.Accel_Y * 1000);
        int16_t accel_z = (int16_t)(accel_data.Accel_Z * 1000);

    // Print accelerometer data for debugging
    printf("Accel X: %d, Y: %d, Z: %d\n", accel_x, accel_y, accel_z);

    double angle = atan2(accel_x,accel_y);
    double angle_deg1 = (angle * (180/M_PI));

    // map -180 to + 180 degree to 0 to 360 degree
    if (angle_deg1 < 0){
      angle_deg1+=360;
      }
    angle_deg1 = angle_deg1+(45/2);
    int16_t angle_deg  = (int16_t)angle_deg1 % 360;
    // Send data to FPGA via SPI
    mcu_to_fpga(angle_deg);
    printf("Current facing angle:..%hd", angle_deg);
    delay_millis(TIM2, 500);

}

}

void mcu_to_fpga(int16_t angle_deg) {
    // Set chip enable high
    digitalWrite(SPI_CE, 1);

    // Send accelerometer data (X, Y, Z)
    spiSendReceive((angle_deg >> 8) & 0xFF); // High byte of angle
    spiSendReceive(angle_deg & 0xFF);  

    // Set chip enable low
    digitalWrite(SPI_CE, 0);
}

//Addition debugging function for I2C communication

void testI2C_Write(uint8_t address, uint8_t reg, uint8_t data) {
    printf("Testing I2C Write...\n");
    printf("Writing to Device Address: 0x%X, Register: 0x%X, Data: 0x%X\n", address, reg, data);

    char payload[2] = {reg, data}; // Register address followed by data
    sendI2C(address, payload, 2);

    printf("Write operation completed successfully.\n");
}
void testI2C_Read(uint8_t address, uint8_t reg) {
    printf("Testing I2C Read...\n");
    printf("Reading from Device Address: 0x%X, Register: 0x%X\n", address, reg);

    char regAddress[1] = {reg};
    char readData[1] = {0};

    // First send the register address
    sendI2C(address, regAddress, 1);

    // Then read the data
    readI2C(address, 1, readData);

    printf("Read operation completed successfully. Data: 0x%X\n", readData[0]);
}
