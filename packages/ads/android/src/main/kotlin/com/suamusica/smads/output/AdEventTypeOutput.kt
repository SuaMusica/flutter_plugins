package com.suamusica.smads.output

import com.google.ads.interactivemedia.v3.api.AdEvent

enum class AdEventTypeOutput(val suggestedName: String? = null) {
    ALL_ADS_COMPLETED,
    CLICKED,
    COMPLETED,
    CUEPOINTS_CHANGED,
    FIRST_QUARTILE,
    LOG,
    AD_BREAK_READY,
    MIDPOINT,
    SKIPPED,
    STARTED,
    TAPPED,
    THIRD_QUARTILE,
    LOADED,
    AD_BREAK_STARTED,
    AD_BREAK_ENDED,
    AD_PERIOD_STARTED,
    AD_PERIOD_ENDED,
    CONTENT_PAUSE_REQUESTED,
    CONTENT_RESUME_REQUESTED,
    PAUSED,
    RESUMED,
    SKIPPABLE_STATE_CHANGED,
    ICON_TAPPED,
    AD_PROGRESS,
    AD_BUFFERING,

    ERROR,
    UNKNOWN("unknown");

    companion object {
        fun getBy(adEventType: AdEvent.AdEventType): AdEventTypeOutput =
                when (adEventType) {
                    AdEvent.AdEventType.ALL_ADS_COMPLETED -> ALL_ADS_COMPLETED
                    AdEvent.AdEventType.CLICKED -> CLICKED
                    AdEvent.AdEventType.COMPLETED -> COMPLETED
                    AdEvent.AdEventType.CUEPOINTS_CHANGED -> CUEPOINTS_CHANGED
                    AdEvent.AdEventType.FIRST_QUARTILE -> FIRST_QUARTILE
                    AdEvent.AdEventType.LOG -> LOG
                    AdEvent.AdEventType.AD_BREAK_READY -> AD_BREAK_READY
                    AdEvent.AdEventType.MIDPOINT -> MIDPOINT
                    AdEvent.AdEventType.SKIPPED -> SKIPPED
                    AdEvent.AdEventType.STARTED -> STARTED
                    AdEvent.AdEventType.TAPPED -> TAPPED
                    AdEvent.AdEventType.THIRD_QUARTILE -> THIRD_QUARTILE
                    AdEvent.AdEventType.LOADED -> LOADED
                    AdEvent.AdEventType.AD_BREAK_STARTED -> AD_BREAK_STARTED
                    AdEvent.AdEventType.AD_BREAK_ENDED -> AD_BREAK_ENDED
                    AdEvent.AdEventType.AD_PERIOD_STARTED -> AD_PERIOD_STARTED
                    AdEvent.AdEventType.AD_PERIOD_ENDED -> AD_PERIOD_ENDED
                    AdEvent.AdEventType.CONTENT_PAUSE_REQUESTED -> CONTENT_PAUSE_REQUESTED
                    AdEvent.AdEventType.CONTENT_RESUME_REQUESTED -> CONTENT_RESUME_REQUESTED
                    AdEvent.AdEventType.PAUSED -> PAUSED
                    AdEvent.AdEventType.RESUMED -> RESUMED
                    AdEvent.AdEventType.SKIPPABLE_STATE_CHANGED -> SKIPPABLE_STATE_CHANGED
                    AdEvent.AdEventType.ICON_TAPPED -> ICON_TAPPED
                    AdEvent.AdEventType.AD_PROGRESS -> AD_PROGRESS
                    AdEvent.AdEventType.AD_BUFFERING -> AD_BUFFERING
                    else -> UNKNOWN
                }
    }
}