#include "rtc.h"
//----------------------
void rtc::RTC_Init(void)
{
    RCC->APB1ENR1 |= RCC_APB1ENR1_PWREN;
    PWR->CR1 |= PWR_CR1_DBP;
    RCC->BDCR |= RCC_BDCR_BDRST;
    RCC->BDCR &= ~RCC_BDCR_BDRST;
    RCC->BDCR |= RCC_BDCR_LSEON;
    while(!(RCC->BDCR & RCC_BDCR_LSERDY)){}
    RCC->BDCR = (RCC->BDCR & ~RCC_BDCR_RTCSEL) | RCC_BDCR_RTCSEL_0 | RCC_BDCR_RTCEN;
    RTC->WPR = 0xCA;
    RTC->WPR = 0x53;
    RTC->ISR |= RTC_ISR_INIT;
    while(!(RTC->ISR & RTC_ISR_INITF)){}
    RTC->PRER = 0x007F00FF;
    RTC->CR &= ~RTC_CR_FMT;
    RTC->ISR &= ~RTC_ISR_INIT;
    RTC->WPR = 0xFF;
    PWR->CR1 &= ~PWR_CR1_DBP;
}
//--------------------------------
void rtc::RTC_Time(time_t& time)
{
    uint32_t temp = (RTC->TR >> 16)&0x3F;
    time.hour = (temp >> 4)*10 + (temp&0x0F);
    temp = (RTC->TR >> 8)&0x7F;
    time.minute = (temp >> 4)*10 + (temp&0x0F);
    temp = RTC->TR&0x7F;
    time.second = (temp >> 4)*10 + (temp&0x0F);
}
//--------------------------------
void rtc::RTC_Date(date_t& date)
{
    uint32_t temp = (RTC->DR >> 16)&0xFF;
    date.year = (temp >> 4)*10 + (temp&0x0F);
    date.week_day = (RTC->DR >> 13)&0x07;
    temp = (RTC->DR >> 8)&0x1F;
    date.month = (temp >> 4)*10 + (temp&0x0F);
    temp = (RTC->DR&0x3F);
    date.day = (temp >> 4)*10 + (temp&0x0F);
}
//----------------------------------------------
void rtc::RTC_SetTime(const rtc::time_t& time)
{
    PWR->CR1 |= PWR_CR1_DBP;
    RTC->WPR = 0xCA;
    RTC->WPR = 0x53;
    RTC->ISR |= RTC_ISR_INIT;
    while(!(RTC->ISR & RTC_ISR_INITF)){}
    RTC->PRER = 0x007F00FF;
    RTC->TR = ((((time.hour/10)&0x03) << 20) | (((time.hour%10)&0x0F) << 16)) | ((((time.minute/10)&0x07) << 12) | (((time.minute%10)&0x0F) << 8)) |
              ((((time.second/10)&0x07) << 4) | ((time.second%10)&0x0F));
    RTC->CR &= ~RTC_CR_FMT;
    RTC->ISR &= ~RTC_ISR_INIT;
    RTC->WPR = 0xFF;
    PWR->CR1 &= ~PWR_CR1_DBP;
}
//--------------------------------------------
void rtc::RTC_SetDate(const rtc::date_t& date)
{
    PWR->CR1 |= PWR_CR1_DBP;
    RTC->WPR = 0xCA;
    RTC->WPR = 0x53;
    RTC->ISR |= RTC_ISR_INIT;
    while(!(RTC->ISR & RTC_ISR_INITF)){}
    RTC->PRER = 0x007F00FF;
    RTC->DR = ((((date.year/10)&0x0F) << 20) | (((date.year%10)&0x0F) << 16)) | ((date.week_day&0x07) << 13) | ((((date.month/10)&0x01) << 12) |
              (((date.month%10)&0x0F) << 8)) | ((((date.day/10)&0x03) << 4) | ((date.day%10)&0x0F));
    RTC->CR &= ~RTC_CR_FMT;
    RTC->ISR &= ~RTC_ISR_INIT;
    RTC->WPR = 0xFF;
    PWR->CR1 &= ~PWR_CR1_DBP;
}
//---------------------------------------------------------------------------
void rtc::RTC_SetAlarm(const rtc::datetime_t &datetime, rtc::AlarmType alarm)
{
    PWR->CR1 |= PWR_CR1_DBP;
    RTC->WPR = 0xCA;
    RTC->WPR = 0x53;
    RTC->CR &= ~RTC_CR_ALRAE;
    while(!(RTC->ISR & RTC_ISR_ALRAWF)){}

    uint8_t day = ((datetime.date.day/10) << 4) | (datetime.date.day%10);
    uint8_t hour = ((datetime.time.hour/10) << 4) | (datetime.time.hour%10);
    uint8_t minute = ((datetime.time.minute/10) << 4) | (datetime.time.minute%10);
    uint8_t second = ((datetime.time.second/10) << 4) | (datetime.time.second%10);

    RTC->ALRMAR = ALL;
    RTC->ALRMAR |= ((day << 24) | (hour << 16) | (minute << 8) | second);
    RTC->ALRMAR &= ~alarm;
    RTC->CR |= RTC_CR_ALRAE;
    RTC->WPR = 0xFF;
    PWR->CR1 &= ~PWR_CR1_DBP;
}
