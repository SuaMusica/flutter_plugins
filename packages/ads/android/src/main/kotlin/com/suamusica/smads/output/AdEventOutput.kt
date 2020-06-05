package com.suamusica.smads.output

data class AdEventOutput(
        val type: AdEventType,
        val id: String,
        val title: String,
        val description: String,
        val system: String,
        val advertiserName: String,
        val contentType: String,
        val creativeAdID: String,
        val creativeID: String,
        val dealID: String
) {

    fun toResult(): Map<String, String> {
        return mapOf(
                TYPE_KEY to type.name,
                ID_KEY to id,
                TITLE_KEY to title,
                DESCRIPTION_KEY to description,
                SYSTEM_KEY to system,
                ADVERTISER_NAME_KEY to advertiserName,
                CONTENT_TYPE_KEY to contentType,
                CREATIVE_AD_ID_KEY to creativeAdID,
                CREATIVE_ID_KEY to creativeID,
                DEAL_ID_KEY to dealID
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

        fun error(code: String, message: String): Map<String, String> {
            return mapOf(
                    TYPE_KEY to AdEventType.ERROR.name,
                    ERROR_CODE_KEY to code,
                    ERROR_MESSAGE_KEY to message
            )
        }
    }
}