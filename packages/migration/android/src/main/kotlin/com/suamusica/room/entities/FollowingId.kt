package com.suamusica.room.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class FollowingId (
    @PrimaryKey() var id: String
)