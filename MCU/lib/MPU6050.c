/*
File: MPU6050.c
Author: Amy Liu
Email: amyliu01@g.hmc.edu
Date: 12/8/2024
Source code for MPU6050 functions
*/
#include "STM32L432KC.h"
#include "STM32L432KC_I2C.h"

#define MPU6050_ADDR 0x68  // MPU6050 I2C address
#define REG_WHO_AM_I 0x75  // WHO_AM_I register
#define REG_PWR_MGMT_1 0x6B // Power management register
#define REG_SMPLRT_DIV 0x19 // Sample rate divider
#define REG_ACCEL_CONFIG 0x1C // Accelerometer config
#define REG_GYRO_CONFIG 0x1B  // Gyroscope config
#define REG_ACCEL_XOUT_H 0x3B // Accelerometer data start
#define REG_GYRO_XOUT_H 0x43  // Gyroscope data start

typedef struct {
    float Accel_X;
    float Accel_Y;
    float Accel_Z;
} MPU6050_ACCEL_t;

typedef struct {
    float Gyro_X;
    float Gyro_Y;
    float Gyro_Z;
} MPU6050_GYRO_t;

void MPU6050_Init(void) {
    printf("Initializing MPU6050...\n");

    char check;
    char data[2];

    // Read WHO_AM_I register
    readI2C(MPU6050_ADDR, 1, &check);
    printf("WHO_AM_I Register: 0x%X\n", check);

    if (check == 0x68) {
        printf("MPU6050 detected successfully.\n");

        // Wake up the MPU6050
        data[0] = REG_PWR_MGMT_1;
        data[1] = 0x00;  // Clear sleep mode
        sendI2C(MPU6050_ADDR, data, 2);
        printf("MPU6050: Wake-up complete.\n");

        // Set sample rate to 1kHz
        data[0] = REG_SMPLRT_DIV;
        data[1] = 0x07;
        sendI2C(MPU6050_ADDR, data, 2);
        printf("MPU6050: Sample rate set to 1kHz.\n");

        // Configure accelerometer to ±2g
        data[0] = REG_ACCEL_CONFIG;
        data[1] = 0x00;
        sendI2C(MPU6050_ADDR, data, 2);
        printf("MPU6050: Accelerometer configured to ±2g.\n");

        // Configure gyroscope to ±250°/s
        data[0] = REG_GYRO_CONFIG;
        data[1] = 0x00;
        sendI2C(MPU6050_ADDR, data, 2);
        printf("MPU6050: Gyroscope configured to ±250°/s.\n");

    } else {
        printf("Error: MPU6050 not detected. WHO_AM_I=0x%X\n", check);
    }
}
void MPU6050_Read_Accel(MPU6050_ACCEL_t *Mpu_Accel) {
    char read_data[6];

    printf("Reading accelerometer data...\n");

    // Read 6 bytes starting from REG_ACCEL_XOUT_H
    sendI2C(MPU6050_ADDR, (char[]){REG_ACCEL_XOUT_H}, 1); // Set the starting register
    readI2C(MPU6050_ADDR, 6, read_data);

    // Combine high and low bytes for each axis
    int16_t accel_x_raw = (int16_t)(read_data[0] << 8 | read_data[1]);
    int16_t accel_y_raw = (int16_t)(read_data[2] << 8 | read_data[3]);
    int16_t accel_z_raw = (int16_t)(read_data[4] << 8 | read_data[5]);

    // Convert to g
    Mpu_Accel->Accel_X = accel_x_raw / 16384.0;
    Mpu_Accel->Accel_Y = accel_y_raw / 16384.0;
    Mpu_Accel->Accel_Z = accel_z_raw / 16384.0;

  //  printf("Accelerometer Data: X=%.2fg, Y=%.2fg, Z=%.2fg\n",
        //   Mpu_Accel->Accel_X, Mpu_Accel->Accel_Y, Mpu_Accel->Accel_Z);
}
void MPU6050_Read_Gyro(MPU6050_GYRO_t *Mpu_Gyro) {
    char read_data[6];

    printf("Reading gyroscope data...\n");

    // Read 6 bytes starting from REG_GYRO_XOUT_H
    sendI2C(MPU6050_ADDR, (char[]){REG_GYRO_XOUT_H}, 1); // Set the starting register
    readI2C(MPU6050_ADDR, 6, read_data);

    // Combine high and low bytes for each axis
    int16_t gyro_x_raw = (int16_t)(read_data[0] << 8 | read_data[1]);
    int16_t gyro_y_raw = (int16_t)(read_data[2] << 8 | read_data[3]);
    int16_t gyro_z_raw = (int16_t)(read_data[4] << 8 | read_data[5]);

    // Convert to degrees/second
    Mpu_Gyro->Gyro_X = gyro_x_raw / 131.0;
    Mpu_Gyro->Gyro_Y = gyro_y_raw / 131.0;
    Mpu_Gyro->Gyro_Z = gyro_z_raw / 131.0;

//    printf("Gyroscope Data: X=%.2f°/s, Y=%.2f°/s, Z=%.2f°/s\n",
       //    Mpu_Gyro->Gyro_X, Mpu_Gyro->Gyro_Y, Mpu_Gyro->Gyro_Z);
}
