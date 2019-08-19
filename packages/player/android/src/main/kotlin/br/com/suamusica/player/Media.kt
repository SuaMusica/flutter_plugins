package br.com.suamusica.player

interface Media {
    val id: String;
    val name: String;
    val author: String;
    val url: String;
    val isLocal: Boolean;
    val coverUrl: String;
    val isVerified: Boolean;
    val shareUrl: String;
}