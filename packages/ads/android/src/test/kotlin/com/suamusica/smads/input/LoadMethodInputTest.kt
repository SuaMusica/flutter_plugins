package com.suamusica.smads.input

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance

@Suppress("ClassName")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
internal class LoadMethodInputTest {

    private val urlKey = "__URL__"
    private val contentUrlKey = "__CONTENT__"

    @Nested
    inner class `Given a values map` {

        @Test
        fun `When it does not contain one of the mandatory argument Should throw NoSuchElementException`() {
            var argument = mapOf("" to "")
            assertThrows(NoSuchElementException::class.java) { LoadMethodInput(argument) }

            argument = mapOf(urlKey to "")
            assertThrows(NoSuchElementException::class.java) { LoadMethodInput(argument) }

            argument = mapOf(contentUrlKey to "")
            assertThrows(NoSuchElementException::class.java) { LoadMethodInput(argument) }
        }

        @Test
        fun `With valid params Should construct an instance of LoadMethodInput to use`() {
            val urlValueMock = "url"
            val contentUrlValueMock = "contentUrl"
            val argument = mapOf(urlKey to urlValueMock, contentUrlKey to contentUrlValueMock)
            val expectedResult = LoadMethodInput(url = urlValueMock, contentUrl = contentUrlValueMock)
            assertEquals(expectedResult, LoadMethodInput(argument))
        }
    }
}