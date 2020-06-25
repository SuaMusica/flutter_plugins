package br.com.suamusica.player

enum class ReleaseMode {
    RELEASE,
    LOOP,
    STOP;

    companion object {
        fun fromInt(value: Int) = when (value) {
            RELEASE.ordinal -> RELEASE
            LOOP.ordinal -> LOOP
            STOP.ordinal -> STOP
            else -> RELEASE
        }
    }
}