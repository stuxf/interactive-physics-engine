#include "lib/STM32L432KC.h"
#include "lib/MPU6050.h"

int main(void) {
    // System Initialization
    configureFlash();
    configureClock();

    // Initialize I2C for MPU6050
    init_I2C();

    // Initialize TIM2 for delay
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;  // Enable TIM2 clock
    initTIM(TIM2);
    I2C_Scan();
  uint8_t who_am_i = I2C_Read(MPU6050_ADDR, 0x75);
  printf("WHO_AM_I: 0x%X\n", who_am_i);

    // Initialize MPU6050
    MPU_Init();

    // Structures to hold sensor data
    MPU6050_ACCEL_t accel_data;
    MPU6050_GYRO_t gyro_data;

    printf("Starting MPU6050 data acquisition...\n");

    while (1) {
        // Read accelerometer data
        MPU_Accel_Read(&accel_data);

        // Read gyroscope data
        MPU_Gyro_Read(&gyro_data);

        // Delay to avoid overwhelming the terminal
        delay_millis(TIM2, 500);
    }

    return 0;
}
