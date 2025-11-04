package com.destrone.edrone.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Booking(
    val id: Int,
    @SerialName("drone_id") val droneId: Int,
    @SerialName("farmer_name") val farmerName: String,
    @SerialName("farmer_mobile") val farmerMobile: String? = null,
    @SerialName("booking_date") val bookingDate: String,
    @SerialName("duration_hrs") val durationHours: Int,
    val status: String,
)

@Serializable
data class BookingCreateRequest(
    @SerialName("drone_id") val droneId: Int,
    @SerialName("farmer_name") val farmerName: String? = null,
    @SerialName("duration_hrs") val durationHours: Int,
)

@Serializable
data class BookingStatusUpdate(
    val status: String,
)
