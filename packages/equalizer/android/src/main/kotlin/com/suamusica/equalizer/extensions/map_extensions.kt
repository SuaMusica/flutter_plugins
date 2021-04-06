package com.suamusica.equalizer.extensions

@Suppress("UNCHECKED_CAST")
fun <T> Map<String, Any>.getRequired(key: String): T {
    val value = this[key] ?: throw IllegalStateException("key $key can not be null")
    return value as T
}

@Suppress("UNCHECKED_CAST")
fun <T> Map<String, Any>.getValueOrNull(key: String): T? {
    return this[key] as? T
}

@Suppress("UNCHECKED_CAST")
fun <T> Map<String, Any>.getValueOrDefault(key: String, or: () -> T): T {
    return (this[key] as? T) ?: or.invoke()
}