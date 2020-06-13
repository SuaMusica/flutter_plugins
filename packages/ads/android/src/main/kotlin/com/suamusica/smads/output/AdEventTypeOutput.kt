package com.suamusica.smads.output

import com.google.ads.interactivemedia.v3.api.AdEvent

enum class AdEventTypeOutput(val suggestedName: String? = null) {
    ALL_ADS_COMPLETED,
    CLICKED,
    COMPLETE,
    CUEPOINTS_CHANGED,
    FIRST_QUARTILE,
    LOG,
    AD_BREAK_READY,
    MIDPOINT,
    PAUSE,
    RESUME,
    SKIPPED,
    STARTED,
    TAPPED,
    THIRD_QUARTILE,
    LOADED,
    AD_BREAK_STARTED,
    AD_BREAK_ENDED,
    AD_PERIOD_STARTED,
    AD_PERIOD_ENDED,
    ERROR,
    UNKNOWN("unknown");

    companion object {
        fun getBy(adEventType: AdEvent.AdEventType): AdEventTypeOutput =
                when (adEventType) {
                    AdEvent.AdEventType.ALL_ADS_COMPLETED -> ALL_ADS_COMPLETED
                    AdEvent.AdEventType.CLICKED -> CLICKED
                    AdEvent.AdEventType.COMPLETED -> COMPLETE
                    AdEvent.AdEventType.CUEPOINTS_CHANGED -> CUEPOINTS_CHANGED
                    AdEvent.AdEventType.FIRST_QUARTILE -> FIRST_QUARTILE
                    AdEvent.AdEventType.LOG -> LOG
                    AdEvent.AdEventType.MIDPOINT -> MIDPOINT
                    AdEvent.AdEventType.PAUSED -> PAUSE
                    AdEvent.AdEventType.RESUMED -> RESUME
                    AdEvent.AdEventType.SKIPPED -> SKIPPED
                    AdEvent.AdEventType.STARTED -> STARTED
                    AdEvent.AdEventType.TAPPED -> TAPPED
                    AdEvent.AdEventType.THIRD_QUARTILE -> THIRD_QUARTILE
                    AdEvent.AdEventType.LOADED -> LOADED
                    AdEvent.AdEventType.AD_BREAK_READY -> AD_BREAK_READY
                    AdEvent.AdEventType.AD_BREAK_STARTED -> AD_BREAK_STARTED
                    AdEvent.AdEventType.AD_BREAK_ENDED -> AD_BREAK_ENDED
                    AdEvent.AdEventType.AD_PERIOD_STARTED -> AD_PERIOD_STARTED
                    AdEvent.AdEventType.AD_PERIOD_ENDED -> AD_PERIOD_ENDED
                    else -> UNKNOWN
                }
    }
}