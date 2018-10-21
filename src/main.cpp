#include "stm32l4xx.h"
#include "rtc.h"
//------------------------------
void init_pll80_hsi16_3v3(void);
void init_gpio(void);
void init_tim6(void);
void init_exti(void);
//--------
int main()
{
    init_pll80_hsi16_3v3();
    rtc::RTC_Init();
    init_gpio();
//    init_tim6();
    init_exti();

    rtc::RTC_SetTime(rtc::time_t({ 20, 0, 0 }));
    rtc::RTC_SetDate(rtc::date_t({ 18, 2, 10, 16 }));
    rtc::datetime_t alarm_datetime = rtc::datetime_t({ rtc::date_t({ 18, 2, 10, 16 }), rtc::time_t({ 20, 3, 10 }) });

    rtc::RTC_SetAlarm(alarm_datetime, rtc::SECOND | rtc::DATE, true);

    while(1)
    {
        rtc::datetime_t datetime;
        rtc::RTC_DateTime(datetime);

        if(RTC->ISR & RTC_ISR_ALRAF)
        {
            if(GPIOA->ODR & GPIO_ODR_OD5)
                GPIOA->BSRR |= GPIO_BSRR_BR5;
            else
                GPIOA->BSRR |= GPIO_BSRR_BS5;

            PWR->CR1 |= PWR_CR1_DBP;
            RTC->ISR &= ~RTC_ISR_ALRAF;
            PWR->CR1 &= ~PWR_CR1_DBP;
        }
    };
}
//-----------------------------
void init_pll80_hsi16_3v3(void)
{
    RCC->CR |= RCC_CR_HSION; // enable HSI
    while(!(RCC->CR & RCC_CR_HSIRDY)){}

    RCC->CFGR &= ~RCC_CFGR_SW;
    RCC->CFGR |= RCC_CFGR_SW_HSI;
    while(!(RCC->CFGR & RCC_CFGR_SWS_HSI)){}

    RCC->CR &= ~RCC_CR_PLLON; // disable PLL
    while(RCC->CR & RCC_CR_PLLRDY){}

    RCC->CR &= ~RCC_CR_MSION; // disable MSI
    while(RCC->CR & RCC_CR_MSIRDY){}

    FLASH->ACR = (FLASH->ACR & ~FLASH_ACR_LATENCY) | FLASH_ACR_LATENCY_4WS; // change latency flash

    RCC->PLLCFGR  = (RCC->PLLCFGR & ~RCC_PLLCFGR_PLLSRC) | RCC_PLLCFGR_PLLSRC_HSI; // clock source is HSI16
    RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLM; // division factor input clock is one (16MHz)
    RCC->PLLCFGR  = (RCC->PLLCFGR & ~RCC_PLLCFGR_PLLN) | RCC_PLLCFGR_PLLN_3 | RCC_PLLCFGR_PLLN_1; // multiplication factor is ten (80Mhz)
    RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLR; // division factor for PLLCLK is two (40MHz system clock)
    RCC->CR |= RCC_CR_PLLON; // enalbe PLL
    while(!(RCC->CR & RCC_CR_PLLRDY)){}
    RCC->PLLCFGR |= RCC_PLLCFGR_PLLREN; // PLLCLK output enable
    RCC->CFGR |= RCC_CFGR_SW_PLL; // PLL selected as system clock
    while(!(RCC->CFGR & RCC_CFGR_SWS_PLL)){}
}
//------------------
void init_gpio(void)
{
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    GPIOA->MODER &= ~GPIO_MODER_MODE5;
    GPIOA->MODER |= GPIO_MODER_MODE5_0;
    GPIOA->OTYPER &= ~GPIO_OTYPER_OT5;
    GPIOA->OSPEEDR &= ~GPIO_OSPEEDER_OSPEEDR5;
    GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR5;
    GPIOA->PUPDR &= ~GPIO_PUPDR_PUPD5;
}
//------------------
void init_tim6(void)
{
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;

    TIM6->PSC   = 40000 - 1;
    TIM6->ARR   = 1000 - 1;
    TIM6->EGR  |= TIM_EGR_UG;
    TIM6->SR   &= ~TIM_SR_UIF;
    TIM6->EGR  &= ~TIM_EGR_UG;
    TIM6->DIER |= TIM_DIER_UIE;
    TIM6->CR1  |= TIM_CR1_CEN;

    NVIC_EnableIRQ(TIM6_DAC_IRQn);
    NVIC_SetPriority(TIM6_DAC_IRQn, 1);
}
//------------------
void init_exti(void)
{
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;

    GPIOC->MODER &= ~GPIO_MODER_MODE13;
    GPIOC->PUPDR  = (GPIOC->PUPDR & ~GPIO_PUPDR_PUPDR13) | GPIO_PUPDR_PUPDR13_0;

    EXTI->EMR1  |= EXTI_EMR1_EM13;
    EXTI->FTSR1 |= EXTI_FTSR1_FT13;
}
//---------------------------------------
extern "C" void TIM6_DAC_IRQHandler(void)
{
    if((TIM6->SR & TIM_SR_UIF) == TIM_SR_UIF)
    {
        if(GPIOA->ODR & GPIO_ODR_OD5)
            GPIOA->BSRR |= GPIO_BSRR_BR5;
        else
            GPIOA->BSRR |= GPIO_BSRR_BS5;

        TIM6->SR &= ~TIM_SR_UIF;
    }
}
