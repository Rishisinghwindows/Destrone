package com.destrone.edrone.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Drone(
    val id: Int,
    val name: String,
    val type: String,
    val lat: Double,
    val lon: Double,
    val status: String,
    @SerialName("price_per_hr") val pricePerHour: Double,
    @SerialName("owner_id") val ownerId: Int,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("image_urls") val imageUrls: List<String>? = null,
    @SerialName("battery_mah") val batteryMah: Double? = null,
    @SerialName("capacity_liters") val capacityLiters: Double? = null,
)

@Serializable
data class DroneCreateRequest(
    val name: String,
    val type: String,
    val lat: Double,
    val lon: Double,
    @SerialName("price_per_hr") val pricePerHour: Double,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("image_urls") val imageUrls: List<String>? = null,
    @SerialName("battery_mah") val batteryMah: Double? = null,
    @SerialName("capacity_liters") val capacityLiters: Double? = null,
)

@Serializable
data class AvailabilityUpdate(
    val status: String,
)
