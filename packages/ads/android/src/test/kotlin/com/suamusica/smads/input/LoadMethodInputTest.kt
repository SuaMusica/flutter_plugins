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
    private val ageKey = "age"
    private val genderKey = "gender"
    private val typeAdKey = "typead"

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
            val adTagUrlMock = "url"
            val contentUrlMock = "contentUrl"
            val ageMock = 36
            val genderMock = "genderMock"
            val typeAdMock = "typeAdMock"

            val argument = mapOf(
                    urlKey to adTagUrlMock,
                    contentUrlKey to contentUrlMock,
                    ageKey to ageMock,
                    genderKey to genderMock,
                    typeAdKey to typeAdMock
            )

            val expectedResult = LoadMethodInput(
                    adTagUrl = adTagUrlMock,
                    contentUrl = contentUrlMock,
                    age = ageMock,
                    gender = genderMock,
                    typeAd = typeAdMock
            )
            assertEquals(expectedResult, LoadMethodInput(argument))
        }
    }
}