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
            assertThrows(IllegalStateException::class.java) { LoadMethodInput(argument) }

            argument = mapOf(urlKey to "")
            assertThrows(IllegalStateException::class.java) { LoadMethodInput(argument) }

            argument = mapOf(contentUrlKey to "")
            assertThrows(IllegalStateException::class.java) { LoadMethodInput(argument) }
        }

        @Test
        fun `With valid params Should construct an instance of LoadMethodInput to use`() {
            val argument = mapOf(urlKey to "", contentUrlKey to "")
            val expectedResult = LoadMethodInput("", "", mapOf())
            val result = LoadMethodInput(argument)
            assertEquals(expectedResult.adTagUrl, result.adTagUrl)
            assertEquals(expectedResult.contentUrl, result.contentUrl)
        }

        @Nested
        inner class `When the custom param tag is present in the last position` {

            @Test
            fun `And the tag already has parameters Should put the additional parameters at the end`() {
                val adTagUrlMock = "url?output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear"
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

                val expectedResult = "${adTagUrlMock}%26platform%3Dandroid%26Domain%3Dsuamusica%26age%3D36%26gender%3DgenderMock%26typead%3DtypeAdMock"
                assertEquals(expectedResult, LoadMethodInput(argument).adTagUrl)
            }

            @Test
            fun `And the tag has no parameters Should put the additional parameters`() {
                val adTagUrlMock = "url?output=vast&unviewed_position_start=1&cust_params="
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

                val expectedResult = "${adTagUrlMock}platform%3Dandroid%26Domain%3Dsuamusica%26age%3D36%26gender%3DgenderMock%26typead%3DtypeAdMock"
                assertEquals(expectedResult, LoadMethodInput(argument).adTagUrl)
            }
        }

        @Nested
        inner class `When the custom param tag is present but not in the last position` {

            @Test
            fun `Should return original url`() {
                val adTagUrlMock = "url&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
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

                assertEquals(adTagUrlMock, LoadMethodInput(argument).adTagUrl)
            }
        }

        @Test
        fun `When adTagUrl not contains a custom params Should return adTagUrl without query params`() {
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
            val expectedResult = "url"
            assertEquals(expectedResult, LoadMethodInput(argument).adTagUrl)
        }
    }
}