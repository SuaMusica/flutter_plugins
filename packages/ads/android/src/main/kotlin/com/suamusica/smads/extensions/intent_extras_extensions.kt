package com.suamusica.smads.extensions

import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.view.AdPlayerActivityExtras

fun LoadMethodInput.toAddPayerActivityExtras(): AdPlayerActivityExtras {
    return AdPlayerActivityExtras(
            adTagUrl = this.adTagUrl,
            contentUrl = this.contentUrl,
            age = this.age,
            gender = this.gender,
            typeAd = this.typeAd
    )
}