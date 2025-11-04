package com.destrone.edrone.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OtpRequest(
    val mobile: String,
)

@Serializable
data class OtpResponse(
    val mobile: String,
    @SerialName("otp_sent") val otpSent: Boolean = true,
    @SerialName("demo_otp") val demoOtp: String? = null,
)

@Serializable
data class OtpVerifyRequest(
    val mobile: String,
    val otp: String,
    val role: String,
    val name: String? = null,
    val lat: Double? = null,
    val lon: Double? = null,
)

@Serializable
data class TokenResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("token_type") val tokenType: String,
    val role: String,
    val roles: List<String>,
    @SerialName("profile_name") val profileName: String? = null,
)
