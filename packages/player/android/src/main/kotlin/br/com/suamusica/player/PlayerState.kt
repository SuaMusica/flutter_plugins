package br.com.suamusica.player

enum class PlayerState {
    IDLE,
    BUFFERING,
    PLAYING,
    PAUSED,
    STOPPED,
    COMPLETED,
    ERROR,
}