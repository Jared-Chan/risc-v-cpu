/*
 * FreeRTOS Kernel <DEVELOPMENT BRANCH>
 * Copyright (C) 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 *
 */

/*
 * This is a simple main that will start the FreeRTOS-Kernel and run a periodic task
 * that only delays if compiled with the template port, this project will do nothing.
 * For more information on getting started please look here:
 * https://www.freertos.org/Documentation/01-FreeRTOS-quick-start/01-Beginners-guide/02-Quick-start-guide
 */

/* FreeRTOS includes. */
#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>
#include <timers.h>
#include <semphr.h>

#include "util.h"

#define mainTASK_FREQUENCY_MS         pdMS_TO_TICKS( 1000UL )
#define mainTASK2_FREQUENCY_MS         pdMS_TO_TICKS( 2000UL )
#define mainTIMER_SEND_FREQUENCY_MS        pdMS_TO_TICKS( 1000UL )

uint8_t ucHeap[ configTOTAL_HEAP_SIZE ];

/*-----------------------------------------------------------*/

static void exampleTask( void * parameters ) __attribute__( ( noreturn ) );
static void exampleTask2( void * parameters ) __attribute__( ( noreturn ) );
static void prvTimerCallback( TimerHandle_t xTimerHandle );

/* A software timer that is started from the tick hook. */
static TimerHandle_t xTimer = NULL;

/*-----------------------------------------------------------*/

static void exampleTask( void * parameters )
{
    const TickType_t xBlockTime = mainTASK_FREQUENCY_MS;

    /* Unused parameters. */
    ( void ) parameters;

    for( ; ; )
    {
        /* Example Task Code */
        vTaskDelay( xBlockTime );
        // putstr since delay is long enough
        putstr( "1\n" );
    }
}

static void exampleTask2( void * parameters )
{
    const TickType_t xBlockTime = mainTASK2_FREQUENCY_MS;

    /* Unused parameters. */
    ( void ) parameters;

    for( ; ; )
    {
        /* Example Task Code */
        vTaskDelay( xBlockTime );
        // putstr since delay is long enough
        putstr( "2\n" );
    }
}

static void prvTimerCallback( TimerHandle_t xTimerHandle )
{
    /* Avoid compiler warnings resulting from the unused parameter. */
    ( void ) xTimerHandle;

    putstr( "3\n" );
}
/*-----------------------------------------------------------*/
int main( void )
{
    static StaticTask_t exampleTaskTCB;
    static StackType_t exampleTaskStack[ configMINIMAL_STACK_SIZE ];


    static StaticTask_t exampleTaskTCB2;
    static StackType_t exampleTaskStack2[ configMINIMAL_STACK_SIZE ];


    ( void ) putstr( "Example FreeRTOS Project\n" );

    ( void ) xTaskCreateStatic( exampleTask,
                                "example",
                                configMINIMAL_STACK_SIZE,
                                NULL,
                                configMAX_PRIORITIES - 2U,
                                &( exampleTaskStack[ 0 ] ),
                                &( exampleTaskTCB ) );


    ( void ) xTaskCreateStatic( exampleTask2,
                                "example2",
                                configMINIMAL_STACK_SIZE,
                                NULL,
                                configMAX_PRIORITIES - 3U,
                                &( exampleTaskStack2[ 0 ] ),
                                &( exampleTaskTCB2 ) );

    /*static StaticTimer_t exampleTimer;*/
    /*const TickType_t xTimerPeriod = mainTIMER_SEND_FREQUENCY_MS;*/
    /*xTimer = xTimerCreateStatic( "Timer",*/
    /*                       xTimerPeriod,*/
    /*                       pdTRUE,*/
    /*                       NULL,*/
    /*                       prvTimerCallback,*/
    /*                       &exampleTimer);*/
    /*xTimerStart( xTimer, 0 );*/


    /* Start the scheduler. */
    vTaskStartScheduler();

    for( ; ; )
    {
        /* Should not reach here. */
    }

    return 0;
}
/*-----------------------------------------------------------*/

#if ( configCHECK_FOR_STACK_OVERFLOW > 0 )

    void vApplicationStackOverflowHook( TaskHandle_t xTask,
                                        char * pcTaskName )
    {
        /* Check pcTaskName for the name of the offending task,
         * or pxCurrentTCB if pcTaskName has itself been corrupted. */
        putstr( "\r\n\r\nStack overflow in \r\n");
        putstr(pcTaskName );
        portDISABLE_INTERRUPTS();

        for( ; ; )
        {
        }
    }

#endif /* #if ( configCHECK_FOR_STACK_OVERFLOW > 0 ) */
/*-----------------------------------------------------------*/
void vAssertCalled( const char * pcFileName,
                    uint32_t ulLine )
{
    volatile uint32_t ulSetToNonZeroInDebuggerToContinue = 1;

    /* Called if an assertion passed to configASSERT() fails.  See
     * http://www.freertos.org/a00110.html#configASSERT for more information. */

    putstr( "ASSERT! Line ");
    putint( ( int ) ulLine, 10, false);
    putstr(", file ");
    putstr(pcFileName );
    putstr("\n");

    taskENTER_CRITICAL();
    {
        /* You can step out of this function to debug the assertion by using
         * the debugger to set ulSetToNonZeroInDebuggerToContinue to a non-zero
         * value. */
        while( ulSetToNonZeroInDebuggerToContinue == 0 )
        {
            __asm volatile ( "NOP" );
            __asm volatile ( "NOP" );
        }
    }
    taskEXIT_CRITICAL();
}
/*-----------------------------------------------------------*/
