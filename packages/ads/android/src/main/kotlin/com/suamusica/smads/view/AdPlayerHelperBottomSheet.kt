package com.suamusica.smads.view

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.jakewharton.rxbinding3.view.clicks
import com.suamusica.smads.R
import com.suamusica.smads.helpers.Navigator
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import kotlinx.android.synthetic.main.ad_player_help_bottom_sheet_content.view.buttonClose
import kotlinx.android.synthetic.main.ad_player_help_bottom_sheet_content.view.buttonPremiumUser

class AdPlayerHelperBottomSheet(private val onRedirectToPremium: () -> Unit) : BottomSheetDialogFragment() {

    private val compositeDisposable: CompositeDisposable = CompositeDisposable()
    private fun Disposable.compose() = compositeDisposable.add(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStyle(STYLE_NORMAL, R.style.CustomBottomSheetDialogTheme)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val view = inflater.inflate(R.layout.ad_player_help_bottom_sheet_content, container, false)
        setOnClickListeners(view)
        return view
    }

    override fun onDestroyView() {
        compositeDisposable.clear()
        super.onDestroyView()
    }

    private fun setOnClickListeners(view: View) {
        view.buttonClose.clicks()
                .observeOn(AndroidSchedulers.mainThread())
                ?.doOnNext { dismiss() }
                ?.subscribe()
                ?.compose()

        view.buttonPremiumUser.clicks()
                .observeOn(AndroidSchedulers.mainThread())
                ?.doOnNext { redirectToPremiumScreen() }
                ?.subscribe()
                ?.compose()
    }

    private fun redirectToPremiumScreen() {
        context?.let {
            Navigator.redirectToPremiumActivity(it) {
                dismiss()
                onRedirectToPremium.invoke()
            }
        }
    }
}