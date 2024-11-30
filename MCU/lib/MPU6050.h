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


void MPU6050_Init(void);

void MPU6050_Read_Accel(MPU6050_ACCEL_t *Mpu_Accel);

void MPU6050_Read_Gyro(MPU6050_GYRO_t *Mpu_Gyro);

#endif
