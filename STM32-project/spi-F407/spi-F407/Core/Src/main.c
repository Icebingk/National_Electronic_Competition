/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
SPI_HandleTypeDef hspi3;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_SPI3_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
/* SPI?????? */
#define SPI_TIMEOUT 1000

/* spi??????????*/
#define SPI_FPGA_CS_PORT  GPIOA
#define SPI_FPGA_CS_PIN   GPIO_PIN_4

/* ???????? */
#define SPI_FPGA_CS_LOW()  HAL_GPIO_WritePin(SPI_FPGA_CS_PORT, SPI_FPGA_CS_PIN, GPIO_PIN_RESET)
#define SPI_FPGA_CS_HIGH() HAL_GPIO_WritePin(SPI_FPGA_CS_PORT, SPI_FPGA_CS_PIN, GPIO_PIN_SET)

int state_flag=0;//???????¦Ë

/**
  * @brief  ???????????????????????????
  * @param  byte:??????????
  * @retval ???????????
  */
uint8_t SPI_FPGA_SendByte(uint8_t byte)
{
    uint8_t rxData = 0;

    /* ??????????CS */
    SPI_FPGA_CS_LOW();

    if (HAL_SPI_TransmitReceive(&hspi3, &byte, &rxData, 1, SPI_TIMEOUT) != HAL_OK)
    {
        Error_Handler();  // ???????
    }

    /* ????????????CS */
    SPI_FPGA_CS_HIGH();
    return rxData;
}

/**
  * @brief  ?????????????(??????????????)
  * @retval ???????????
  */
uint8_t SPI_FPGA_ReadByte(void)
{
    return SPI_FPGA_SendByte(0xFF);  // 0xFF????????????????
}

/**
  * @brief  ??????????????????
  * @param  txData: ????????????????
  * @param  rxData: ????????????????
  * @param  size: ???????
  * @retval ??
  */
void SPI_FPGA_TransmitReceive(uint8_t *txData, uint8_t *rxData, uint16_t size)
{
    /* ????CS */
    SPI_FPGA_CS_LOW();

    if (HAL_SPI_TransmitReceive(&hspi3, txData, rxData, size, SPI_TIMEOUT) != HAL_OK)
    {
        Error_Handler();
    }

    /* ????CS */
    SPI_FPGA_CS_HIGH();
}


/**
  * @brief  ???????(????)
  * @param  nCount: ???????
  * @retval ??
  */
void Delay(__IO uint32_t nCount)
{
    while(nCount--);
}

/**
  * @brief  SPI ????????(??????)
  * @param  txData: ????????????
  * @param  size: ?????????????
  */
void SPI_FPGA_Transmit(uint8_t *txData, uint16_t size)
{
	    /* ????CS */
    SPI_FPGA_CS_LOW();
	
    if (HAL_SPI_Transmit(&hspi3, txData, size, SPI_TIMEOUT) != HAL_OK)
    {
        Error_Handler(); // 
    }
		
		    /* ????CS */
    SPI_FPGA_CS_HIGH();
}

/**
  * @brief  SPI ????????(?????)
  * @param  rxData: ????????????
  * @param  size: ?????????????
  */
void SPI_FPGA_Receive(uint8_t *rxData, uint16_t size)
{
	    /* ????CS */
    SPI_FPGA_CS_LOW();
	
    if (HAL_SPI_Receive(&hspi3, rxData, size, SPI_TIMEOUT) != HAL_OK)
    {
        Error_Handler(); // 
    }
		
		    /* ????CS */
    SPI_FPGA_CS_HIGH();
}


/**
  * @brief  ????????
  * @param  
  * @param  
  */
void Update_State_Flag(void)
{
    // ??? PA10, PA11, PA12 ??
    int pa10 = HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_10);
    int pa11 = HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_11);
    int pa12 = HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_12);

    // ????state_flag
    state_flag = (pa10 << 2) | (pa11 << 1) | pa12;
}


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_SPI3_Init();
  /* USER CODE BEGIN 2 */
 // uint8_t txByte = 0x55;
//  uint8_t rxByte = 0;
  uint8_t txData[12] = {0xAA, 0x2B, 0x3C, 0x4D, 0x5E, 0x6F, 0x7A, 0x8B, 0x9C, 0xAD, 0xBE, 0xCF};
  uint8_t rxData[12] = {0x12, 0x2E, 0x3C, 0x4E, 0x2A, 0x3E, 0x4D, 0x5E, 0x6F, 0x9E, 0x1D, 0x8E};
//	uint8_t rxBuffer[1];
  //uint8_t rxBuffer[5] = {0};
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
   Update_State_Flag();
		
	  switch (state_flag)
    {
        case 1: // ??????????
            SPI_FPGA_SendByte(txData[0]);
            break;

        case 2: // ??????????
            rxData[0] = SPI_FPGA_ReadByte();
            break;

        case 3: // ????????10?????
            SPI_FPGA_Transmit(txData, 5);
            break;

        case 4: // ????????10?????
            SPI_FPGA_Receive(rxData, 10);
            break;

        case 5: // ?????????????10?????
            SPI_FPGA_TransmitReceive(txData, rxData, 10);
            break;

        case 6: // ????????12 ?????,???????5???????????????
            SPI_FPGA_CS_LOW();
            HAL_SPI_Transmit(&hspi3, txData, 5, SPI_TIMEOUT);
            SPI_FPGA_CS_HIGH(); // 
            HAL_Delay(1); // ???
            HAL_SPI_Transmit(&hspi3, txData + 5, 5, SPI_TIMEOUT);
           // ???????10???????????????
            SPI_FPGA_CS_LOW();
            HAL_SPI_Transmit(&hspi3, txData + 10, 2, SPI_TIMEOUT);
            SPI_FPGA_CS_HIGH();
            break;

        case 7: // ????????12 ?????,???????5???????????????
            SPI_FPGA_CS_LOW();
            HAL_SPI_Receive(&hspi3, rxData, 5, SPI_TIMEOUT);
            SPI_FPGA_CS_HIGH(); // 
            HAL_SPI_Receive(&hspi3, rxData + 5, 5, SPI_TIMEOUT);
           // ???????10???????????????
            SPI_FPGA_CS_LOW();
            HAL_SPI_Receive(&hspi3, rxData + 10, 2, SPI_TIMEOUT);
            SPI_FPGA_CS_HIGH();
            break;
 
        default:
            break;
    }
		HAL_Delay(2000);
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief SPI3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_SPI3_Init(void)
{

  /* USER CODE BEGIN SPI3_Init 0 */

  /* USER CODE END SPI3_Init 0 */

  /* USER CODE BEGIN SPI3_Init 1 */

  /* USER CODE END SPI3_Init 1 */
  /* SPI3 parameter configuration*/
  hspi3.Instance = SPI3;
  hspi3.Init.Mode = SPI_MODE_MASTER;
  hspi3.Init.Direction = SPI_DIRECTION_2LINES;
  hspi3.Init.DataSize = SPI_DATASIZE_16BIT;
  hspi3.Init.CLKPolarity = SPI_POLARITY_LOW;
  hspi3.Init.CLKPhase = SPI_PHASE_1EDGE;
  hspi3.Init.NSS = SPI_NSS_SOFT;
  hspi3.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_8;
  hspi3.Init.FirstBit = SPI_FIRSTBIT_MSB;
  hspi3.Init.TIMode = SPI_TIMODE_DISABLE;
  hspi3.Init.CRCCalculation = SPI_CRCCALCULATION_ENABLE;
  hspi3.Init.CRCPolynomial = 10;
  if (HAL_SPI_Init(&hspi3) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN SPI3_Init 2 */

  /* USER CODE END SPI3_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();

/* USER CODE BEGIN MX_GPIO_Init_2 */

GPIO_InitTypeDef GPIO_InitStruct = {0};

__HAL_RCC_GPIOA_CLK_ENABLE();
/* ????CS ???????? */
GPIO_InitStruct.Pin = SPI_FPGA_CS_PIN;
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
HAL_GPIO_Init(SPI_FPGA_CS_PORT, &GPIO_InitStruct);

/* CS??????????*/
SPI_FPGA_CS_HIGH();

 /* ????PA5 ?? PA6 ????????,???? */
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5 | GPIO_PIN_6, GPIO_PIN_RESET);
    GPIO_InitStruct.Pin = GPIO_PIN_5 | GPIO_PIN_6;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP; // ???????
    GPIO_InitStruct.Pull = GPIO_NOPULL;        // ????????
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    /* ???? PA10??PA11??PA12 ??????? */
    GPIO_InitStruct.Pin = GPIO_PIN_10 | GPIO_PIN_11 | GPIO_PIN_12;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT; // ??????
    GPIO_InitStruct.Pull = GPIO_NOPULL;     // ????????
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
