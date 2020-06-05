package com.suamusica.smads.output

enum class ErrorOutput(private val code: Int) {
    SCREEN_IS_LOCKED(-2),
    NO_CONNECTIVITY(-1);

    fun toResult(): Map<String, Int> = mapOf(ERROR_KEY to code)

    companion object {
        private const val ERROR_KEY = "error"
    }
}