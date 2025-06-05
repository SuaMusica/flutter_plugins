package br.com.suamusica.player

enum class PlayerState {
    IDLE,
    BUFFERING,
    PLAYING,
    PAUSED,
    STOPPED,
    COMPLETED,
    ERROR,
    SEEK_END,
    BUFFER_EMPTY,
    ITEM_TRANSITION,
    STATE_READY,
    STATE_ENDED,
}