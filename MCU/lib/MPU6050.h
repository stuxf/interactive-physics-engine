#ifndef MPU6050_H
#define MPU6050_H

#include "STM32L432KC_I2C.h"
#include <stdint.h>

// MPU6050 I2C Address
#define MPU6050_ADDR 0x68

// MPU6050 Register Addresses
#define REG_WHO_AM_I       0x75
#define REG_PWR_MGMT_1     0x6B
#define REG_SMPLRT_DIV     0x19
#define REG_ACCEL_CONFIG   0x1C
#define REG_GYRO_CONFIG    0x1B
#define REG_ACCEL_XOUT_H   0x3B
#define REG_GYRO_XOUT_H    0x43

// MPU6050 Accelerometer Data Structure
typedef struct {
    float Accel_X;  // Acceleration in X-axis (g)
    float Accel_Y;  // Acceleration in Y-axis (g)
    float Accel_Z;  // Acceleration in Z-axis (g)
} MPU6050_ACCEL_t;

// MPU6050 Gyroscope Data Structure
typedef struct {
    float Gyro_X;  // Angular velocity in X-axis (°/s)
    float Gyro_Y;  // Angular velocity in Y-axis (°/s)
    float Gyro_Z;  // Angular velocity in Z-axis (°/s)
} MPU6050_GYRO_t;
void MPU_Init(void);
void MPU_Accel_Read(MPU6050_ACCEL_t *Mpu_Accel);
void MPU_Gyro_Read(MPU6050_GYRO_t *Mpu_Gyro);

#endif // MPU6050_H
