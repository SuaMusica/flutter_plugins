package com.suamusica.smads.output

import com.google.ads.interactivemedia.v3.api.AdEvent

data class AdEventOutput(
        val type: AdEventTypeOutput,
        val id: String = EMPTY_STRING,
        val title: String = EMPTY_STRING,
        val description: String = EMPTY_STRING,
        val system: String = EMPTY_STRING,
        val advertiserName: String = EMPTY_STRING,
        val contentType: String = EMPTY_STRING,
        val creativeAdID: String = EMPTY_STRING,
        val creativeID: String = EMPTY_STRING,
        val dealID: String = EMPTY_STRING,
        val duration: Int = 0,
        val position: Int = 0,
        val skippable: String = EMPTY_STRING,
        val skipTime: String = EMPTY_STRING
) {

    fun toResult(): Map<String, Any?> {
        return mapOf(
                TYPE_KEY to (type.suggestedName ?: type.name),
                ID_KEY to id,
                TITLE_KEY to title,
                DESCRIPTION_KEY to description,
                SYSTEM_KEY to system,
                ADVERTISER_NAME_KEY to advertiserName,
                CONTENT_TYPE_KEY to contentType,
                CREATIVE_AD_ID_KEY to creativeAdID,
                CREATIVE_ID_KEY to creativeID,
                DEAL_ID_KEY to dealID,
                DURATION_KEY to duration,
                POSITION_KEY to position,
                SKIPPABLE_KEY to skippable,
                SKIPTIME_KEY to skipTime

        )
    }

    companion object {
        private const val TYPE_KEY = "type"
        private const val ID_KEY = "ad.id"
        private const val TITLE_KEY = "ad.title"
        private const val DESCRIPTION_KEY = "ad.description"
        private const val SYSTEM_KEY = "ad.system"
        private const val ADVERTISER_NAME_KEY = "ad.advertiserName"
        private const val CONTENT_TYPE_KEY = "ad.contentType"
        private const val CREATIVE_AD_ID_KEY = "ad.creativeAdID"
        private const val CREATIVE_ID_KEY = "ad.creativeID"
        private const val DEAL_ID_KEY = "ad.dealID"

        private const val ERROR_CODE_KEY = "error.code"
        private const val ERROR_MESSAGE_KEY = "error.message"
        private const val DURATION_KEY = "duration"
        private const val POSITION_KEY = "position"
        private const val SKIPPABLE_KEY = "skippable"
        private const val SKIPTIME_KEY = "skiptime"

        private const val EMPTY_STRING = ""

        fun error(code: String, message: String): Map<String, String> {
            return mapOf(
                    TYPE_KEY to AdEventTypeOutput.ERROR.name,
                    ERROR_CODE_KEY to code,
                    ERROR_MESSAGE_KEY to message
            )
        }

        fun fromAdEvent(adEvent: AdEvent, duration: Int = 0, position: Int = 0): AdEventOutput {
            val ad = adEvent.ad
            val type = AdEventTypeOutput.getBy(adEvent.type)
            return ad?.let {
                AdEventOutput(
                        type = type,
                        id = it.adId,
                        title = it.title,
                        description = it.description,
                        system = it.adSystem,
                        advertiserName = it.advertiserName,
                        contentType = it.contentType,
                        creativeAdID = it.creativeAdId,
                        creativeID = it.creativeId,
                        dealID = it.dealId,
                        duration = duration,
                        position = position,
                        skippable = it.isSkippable.toString(),
                        skipTime = it.skipTimeOffset.toString()
                )
            } ?: AdEventOutput(type = type)
        }
    }
}