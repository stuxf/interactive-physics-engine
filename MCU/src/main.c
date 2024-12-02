#include "libraries/MPU6050.h"
#include "libraries/STM32L432KC_I2C.h"
#include "libraries/STM32L432KC.h"
#include <stdio.h>
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
void mcu_to_fpga(int16_t accel_x, int16_t accel_y, int16_t accel_z);

/*
int main(void) {
    configureFlash();
    configureClock();

    initI2C(); // Initialize I2C peripheral

    uint8_t address = 0x68;  // Example I2C address
    uint8_t reg = 0x6B;      // Power Management Register
    uint8_t writeData = 0x00; // Data to write (e.g., wake up MPU6050)

    // Test I2C Write
    testI2C_Write(address, reg, writeData);

    // Test I2C Read
    testI2C_Read(address, reg);

    while (1);
}
*/

int main(void) {

    configureFlash();
    configureClock();
     RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;
  initTIM(TIM2);
    initI2C();
    initSPI(1, 0, 0);

    uint8_t address = 0x68;  // Example I2C address
    uint8_t reg = 0x6B;      // Power Management Register
    uint8_t writeData = 0x00; // Data to write (e.g., wake up MPU6050)

    // Test I2C Write
    testI2C_Write(address, reg, writeData);

    // Test I2C Read
    testI2C_Read(address, reg);
    MPU6050_ACCEL_t accel_data;
    MPU6050_GYRO_t gyro_data;

    MPU6050_Init();


    while(1){
    MPU6050_Read_Accel(&accel_data);
    printf("Accel X: %.2fg, Y: %.2fg, Z: %.2fg\n", accel_data.Accel_X, accel_data.Accel_Y, accel_data.Accel_Z);

    MPU6050_Read_Gyro(&gyro_data);
    printf("Gyro X: %.2fdeg/s, Y: %.2fdeg/s, Z: %.2fdeg/s\n", gyro_data.Gyro_X, gyro_data.Gyro_Y, gyro_data.Gyro_Z);
    // Convert to raw integer data
        int16_t accel_x = (int16_t)(accel_data.Accel_X * 1000); // Convert to milli-g
        int16_t accel_y = (int16_t)(accel_data.Accel_Y * 1000);
        int16_t accel_z = (int16_t)(accel_data.Accel_Z * 1000);

        // Print accelerometer data for debugging
    printf("Accel X: %d, Y: %d, Z: %d\n", accel_x, accel_y, accel_z);

        // Send data to FPGA via SPI
    mcu_to_fpga(accel_x, accel_y, accel_z);
    delay_millis(TIM2, 1000);

    //delay_millis(TIM2,100); // Delay 1 second between prints
}

}


// Function to send accelerometer data to FPGA
void mcu_to_fpga(int16_t accel_x, int16_t accel_y, int16_t accel_z) {
    // Set chip enable high
    digitalWrite(SPI_CE, 1);

    // Send accelerometer data (X, Y, Z)
    spiSendReceive((accel_x >> 8) & 0xFF); // High byte of X
    spiSendReceive(accel_x & 0xFF);        // Low byte of X
    spiSendReceive((accel_y >> 8) & 0xFF); // High byte of Y
    spiSendReceive(accel_y & 0xFF);        // Low byte of Y
   spiSendReceive((accel_z >> 8) & 0xFF); // High byte of Z
    spiSendReceive(accel_z & 0xFF);        // Low byte of Z

    // Set chip enable low
    digitalWrite(SPI_CE, 0);
}
