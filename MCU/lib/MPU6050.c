#include "MPU6050.h"
#include <stdio.h>

void MPU_Init(void) {
    printf("Initializing MPU6050...\n");

    // Check WHO_AM_I register
    uint8_t check = I2C_Read(MPU6050_ADDR, REG_WHO_AM_I);
    printf("WHO_AM_I Register: 0x%X\n", check);

    if (check == 0x68) {
        printf("MPU6050 detected successfully.\n");

        // Wake up the MPU6050
        I2C_Write(MPU6050_ADDR, REG_PWR_MGMT_1, 0x00); // Clear sleep mode
        printf("MPU6050: Wake-up complete.\n");

        // Set sample rate to 1kHz
        I2C_Write(MPU6050_ADDR, REG_SMPLRT_DIV, 0x07);
        printf("MPU6050: Sample rate set to 1kHz.\n");

        // Configure accelerometer to ±2g
        I2C_Write(MPU6050_ADDR, REG_ACCEL_CONFIG, 0x00);
        printf("MPU6050: Accelerometer configured to ±2g.\n");

        // Configure gyroscope to ±250°/s
        I2C_Write(MPU6050_ADDR, REG_GYRO_CONFIG, 0x00);
        printf("MPU6050: Gyroscope configured to ±250°/s.\n");

    } else {
        printf("Error: MPU6050 not detected. WHO_AM_I=0x%X\n", check);
    }
}

void MPU_Accel_Read(MPU6050_ACCEL_t *Mpu_Accel) {
    uint8_t read_data[6];

    printf("Reading accelerometer data...\n");
    for (int i = 0; i < 6; i++) {
        read_data[i] = I2C_Read(MPU6050_ADDR, REG_ACCEL_XOUT_H + i);
    }

    // Combine high and low bytes for each axis
    int16_t accel_x_raw = (int16_t)(read_data[0] << 8 | read_data[1]);
    int16_t accel_y_raw = (int16_t)(read_data[2] << 8 | read_data[3]);
    int16_t accel_z_raw = (int16_t)(read_data[4] << 8 | read_data[5]);

    // Convert to g
    Mpu_Accel->Accel_X = accel_x_raw / 16384.0;
    Mpu_Accel->Accel_Y = accel_y_raw / 16384.0;
    Mpu_Accel->Accel_Z = accel_z_raw / 16384.0;

    printf("Accelerometer Data: X=%.2fg, Y=%.2fg, Z=%.2fg\n",
           Mpu_Accel->Accel_X, Mpu_Accel->Accel_Y, Mpu_Accel->Accel_Z);
}

void MPU_Gyro_Read(MPU6050_GYRO_t *Mpu_Gyro) {
    uint8_t read_data[6];

    printf("Reading gyroscope data...\n");
    for (int i = 0; i < 6; i++) {
        read_data[i] = I2C_Read(MPU6050_ADDR, REG_GYRO_XOUT_H + i);
    }

    // Combine high and low bytes for each axis
    int16_t gyro_x_raw = (int16_t)(read_data[0] << 8 | read_data[1]);
    int16_t gyro_y_raw = (int16_t)(read_data[2] << 8 | read_data[3]);
    int16_t gyro_z_raw = (int16_t)(read_data[4] << 8 | read_data[5]);

    // Convert to degrees per second
    Mpu_Gyro->Gyro_X = gyro_x_raw / 131.0;
    Mpu_Gyro->Gyro_Y = gyro_y_raw / 131.0;
    Mpu_Gyro->Gyro_Z = gyro_z_raw / 131.0;

    printf("Gyroscope Data: X=%.2f°/s, Y=%.2f°/s, Z=%.2f°/s\n",
           Mpu_Gyro->Gyro_X, Mpu_Gyro->Gyro_Y, Mpu_Gyro->Gyro_Z);
}
