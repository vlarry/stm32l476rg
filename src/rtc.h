#ifndef RTC_H
    #define RTC_H
    //--------------------
    #include "stm32l4xx.h"
    //-----------
    namespace rtc
    {
        enum
        {
            SECOND = RTC_ALRMAR_MSK1,
            MINUTE = RTC_ALRMAR_MSK2,
            HOUR   = RTC_ALRMAR_MSK3,
            DATE   = RTC_ALRMAR_MSK4,
            ALL    = SECOND | MINUTE | HOUR | DATE
        };

        struct time_t
        {
            uint8_t hour;
            uint8_t minute;
            uint8_t second;
        };

        struct date_t
        {
            uint8_t year;
            uint8_t week_day;
            uint8_t month;
            uint8_t day;
        };

        struct datetime_t
        {
            date_t date;
            time_t time;
        };

        void RTC_Init(void);
        void RTC_Time(time_t& time);
        void RTC_Date(date_t& date);
        void RTC_DateTime(datetime_t& datetime);
        void RTC_SetTime(const time_t& time);
        void RTC_SetDate(const date_t& date);
        void RTC_SetDateTime(const datetime_t& datetime);
        void RTC_SetAlarm(const datetime_t& datetime, const uint32_t alarm = ALL, const bool isWeekDay = false);
    }
#endif // RTC_H
