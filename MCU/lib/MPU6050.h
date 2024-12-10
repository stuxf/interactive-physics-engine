/*
File: MPU6050.h
Author: Amy Liu
Email: amyliu01@g.hmc.edu
Date: 12/8/2024
Header for MPU6050 functions
*/
#ifndef MPU6050_H
#define MPU6050_H

#include "STM32L432KC.h"
#include "STM32L432KC_I2C.h"

// MPU6050 Address
#define MPU6050_ADDR 0x68  // MPU6050 I2C address (7-bit)

// MPU6050 Register Definitions
#define REG_WHO_AM_I       0x75  // WHO_AM_I register
#define REG_PWR_MGMT_1     0x6B  // Power management register
#define REG_SMPLRT_DIV     0x19  // Sample rate divider
#define REG_ACCEL_CONFIG   0x1C  // Accelerometer configuration register
#define REG_GYRO_CONFIG    0x1B  // Gyroscope configuration register
#define REG_ACCEL_XOUT_H   0x3B  // Start of accelerometer data
#define REG_GYRO_XOUT_H    0x43  // Start of gyroscope data

// MPU6050 Accelerometer Data Structure
typedef struct {
    float Accel_X;  // X-axis acceleration in g
    float Accel_Y;  // Y-axis acceleration in g
    float Accel_Z;  // Z-axis acceleration in g
} MPU6050_ACCEL_t;

// MPU6050 Gyroscope Data Structure
typedef struct {
    float Gyro_X;   // X-axis angular velocity in degrees/second
    float Gyro_Y;   // Y-axis angular velocity in degrees/second
    float Gyro_Z;   // Z-axis angular velocity in degrees/second
} MPU6050_GYRO_t;

/* Initializes the MPU6050 sensor.
 * Configures the MPU6050 for basic operation by:
 *    -- Verifying the WHO_AM_I register to confirm the device presence.
 *    -- Waking up the device by clearing sleep mode in the power management register.
 *    -- Setting the sample rate to 1kHz.
 *    -- Configuring the accelerometer for a ±2g range.
 *    -- Configuring the gyroscope for a ±250°/s range.
 * Ensure the I2C peripheral is initialized and functional before calling this function. */
void MPU6050_Init(void);

/* Reads acceleration data from the MPU6050.
 *    -- Mpu_Accel: Pointer to an MPU6050_ACCEL_t structure to store the acceleration data.
 * This function reads raw accelerometer data for the X, Y, and Z axes, converts it into
 * values in 'g' (gravitational force), and stores them in the provided structure.
 *    -- Data is scaled using a conversion factor for a ±2g range (LSB sensitivity = 16384 LSB/g). */
void MPU6050_Read_Accel(MPU6050_ACCEL_t *Mpu_Accel);

/* Reads gyroscope data from the MPU6050.
 *    -- Mpu_Gyro: Pointer to an MPU6050_GYRO_t structure to store the gyroscope data.
 * This function reads raw gyroscope data for the X, Y, and Z axes, converts it into
 * values in degrees per second (°/s), and stores them in the provided structure.
 *    -- Data is scaled using a conversion factor for a ±250°/s range (LSB sensitivity = 131 LSB/°/s). */
void MPU6050_Read_Gyro(MPU6050_GYRO_t *Mpu_Gyro);


#endif
