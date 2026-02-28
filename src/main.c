/**
 * @file main.c
 * @brief Main file for the stm32 template project
 * @author Cyprien Ménard
 * @date 23/02/2026
 * @see main.h
 * @copyright MIT (Cf. LICENSE)
 */

/* ********************************* Includes ******************************* */
#include "main.h"

/* ****************************** Private macros **************************** */

/** @brief Broche de la LED utilisateur sur le Nucleo-G431KB (PB8) */
#define USER_LED_PIN       GPIO_PIN_8
#define USER_LED_PORT      GPIOB

/** @brief Nombre de patterns dans la séquence de démonstration */
#define DEMO_PATTERN_COUNT 4U

/* ************************** Private type definition *********************** */

/* *********************** Private functions declarations ******************* */

/**
 * @brief Initialise la broche GPIO de la LED utilisateur
 */
static void demo_led_init(void);

/**
 * @brief Fait clignoter la LED avec un pattern SOS en morse
 * @details S = ...  O = ---  S = ...
 */
static void demo_blink_sos(void);

/* **************************** Private variables *************************** */

/** @brief Durée de base d'un "dot" morse en ms */
static const uint32_t MORSE_DOT_MS = 150U;

/** @brief Durée d'un "dash" morse en ms (3x dot) */
static const uint32_t MORSE_DASH_MS = 450U;

/** @brief Pause entre symboles morse en ms */
static const uint32_t MORSE_SYMBOL_GAP_MS = 150U;

/** @brief Pause entre lettres morse en ms (3x dot) */
static const uint32_t MORSE_LETTER_GAP_MS = 450U;

/** @brief Pause entre mots morse en ms (7x dot) */
static const uint32_t MORSE_WORD_GAP_MS = 1050U;

/* ************************ Private functions definitions ******************* */

static void demo_led_init(void)
{
    /* Activer l'horloge du port GPIOB */
    __HAL_RCC_GPIOB_CLK_ENABLE();

    GPIO_InitTypeDef gpio = {0};
    gpio.Pin = USER_LED_PIN;
    gpio.Mode = GPIO_MODE_OUTPUT_PP;
    gpio.Pull = GPIO_NOPULL;
    gpio.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(USER_LED_PORT, &gpio);

    /* LED éteinte par défaut */
    HAL_GPIO_WritePin(USER_LED_PORT, USER_LED_PIN, GPIO_PIN_RESET);
}

/**
 * @brief Émet un "dot" morse sur la LED
 */
static void morse_dot(void)
{
    HAL_GPIO_WritePin(USER_LED_PORT, USER_LED_PIN, GPIO_PIN_SET);
    HAL_Delay(MORSE_DOT_MS);
    HAL_GPIO_WritePin(USER_LED_PORT, USER_LED_PIN, GPIO_PIN_RESET);
    HAL_Delay(MORSE_SYMBOL_GAP_MS);
}

/**
 * @brief Émet un "dash" morse sur la LED
 */
static void morse_dash(void)
{
    HAL_GPIO_WritePin(USER_LED_PORT, USER_LED_PIN, GPIO_PIN_SET);
    HAL_Delay(MORSE_DASH_MS);
    HAL_GPIO_WritePin(USER_LED_PORT, USER_LED_PIN, GPIO_PIN_RESET);
    HAL_Delay(MORSE_SYMBOL_GAP_MS);
}

static void demo_blink_sos(void)
{
    /* S : . . . */
    morse_dot();
    morse_dot();
    morse_dot();
    HAL_Delay(MORSE_LETTER_GAP_MS);

    /* O : - - - */
    morse_dash();
    morse_dash();
    morse_dash();
    HAL_Delay(MORSE_LETTER_GAP_MS);

    /* S : . . . */
    morse_dot();
    morse_dot();
    morse_dot();
    HAL_Delay(MORSE_WORD_GAP_MS);
}

/* ************************ Public functions definitions ******************** */

/**
 * @brief Point d'entrée de l'application. Initialise le BSP puis fait
 *        clignoter la LED utilisateur en boucle (pattern SOS en morse).
 * @retval int Code de retour (jamais atteint en bare-metal)
 */
int main(void)
{
    /* Initialisation du BSP (HAL, horloges, périphériques CubeMX) */
    extern void bsp_init(void);
    bsp_init();

    /* Initialisation de la LED de démonstration */
    demo_led_init();

    /* Boucle principale : SOS en morse, indéfiniment */
    for (;;)
    {
        demo_blink_sos();
    }
}

/* ******************* Public callback functions definitions **************** */
