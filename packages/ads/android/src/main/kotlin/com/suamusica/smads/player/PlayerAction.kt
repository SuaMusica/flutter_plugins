package com.suamusica.smads.player

sealed class PlayerAction {
  object Play : PlayerAction()
  object Pause : PlayerAction()
  object Stop : PlayerAction()
  object Next : PlayerAction()
  object Previous : PlayerAction()
  sealed class Randomize : PlayerAction() {
    object On : Randomize()
    object Off : Randomize()
  }
  sealed class Repeat : PlayerAction() {
    object All : Repeat()
    object One : Repeat()
    object Off : Repeat()
  }
}
