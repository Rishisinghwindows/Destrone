package com.destrone.edrone.data

import com.destrone.edrone.model.AvailabilityUpdate
import com.destrone.edrone.model.Booking
import com.destrone.edrone.model.BookingCreateRequest
import com.destrone.edrone.model.BookingStatusUpdate
import com.destrone.edrone.model.Drone
import com.destrone.edrone.model.DroneCreateRequest
import com.destrone.edrone.model.OtpRequest
import com.destrone.edrone.model.OtpResponse
import com.destrone.edrone.model.OtpVerifyRequest
import com.destrone.edrone.model.TokenResponse
import com.destrone.edrone.model.UserRole

class EDroneRepository(
    private val api: EDroneApi,
    private val container: AppContainer,
) {
    suspend fun requestOtp(mobile: String): OtpResponse =
        api.requestOtp(OtpRequest(mobile = mobile))

    suspend fun verifyOtp(
        mobile: String,
        otp: String,
        role: UserRole,
        name: String?,
        lat: Double?,
        lon: Double?,
    ): TokenResponse {
        val response = api.verifyOtp(
            OtpVerifyRequest(
                mobile = mobile,
                otp = otp,
                role = role.wireValue,
                name = name,
                lat = lat,
                lon = lon,
            ),
        )

        val roles = response.roles.mapNotNull(UserRole::fromWire)
        container.updateAuthState {
            it.copy(
                token = response.accessToken,
                mobile = mobile,
                selectedRole = UserRole.fromWire(response.role) ?: role,
                preferredRole = UserRole.fromWire(response.role) ?: role,
                roles = if (roles.isEmpty()) listOf(role) else roles,
                profileName = response.profileName,
            )
        }
        return response
    }

    suspend fun listDrones(
        lat: Double? = null,
        lon: Double? = null,
        maxDistanceKm: Double? = null,
        minPrice: Double? = null,
        maxPrice: Double? = null,
        sortBy: String? = null,
    ): List<Drone> =
        api.listDrones(
            token = authHeader(),
            lat = lat,
            lon = lon,
            maxDistanceKm = maxDistanceKm,
            minPrice = minPrice,
            maxPrice = maxPrice,
            sortBy = sortBy,
        )

    suspend fun listOwnerDrones(): List<Drone> =
        api.listOwnerDrones(authHeader())

    suspend fun createDrone(request: DroneCreateRequest): Drone =
        api.createDrone(authHeader(), request)

    suspend fun updateAvailability(droneId: Int, status: String) =
        api.updateAvailability(authHeader(), droneId, AvailabilityUpdate(status))

    suspend fun listBookings(status: String? = null): List<Booking> =
        api.listBookings(authHeader(), status = status)

    suspend fun createBooking(request: BookingCreateRequest): Booking =
        api.createBooking(authHeader(), request)

    suspend fun updateBooking(bookingId: Int, status: String) =
        api.updateBooking(authHeader(), bookingId, BookingStatusUpdate(status))

    fun logout() {
        container.clearAuth()
    }

    fun setPreferredRole(role: UserRole) {
        container.setPreferredRole(role)
    }

    private fun authHeader(): String {
        val token = container.authState.value.token ?: error("Token required")
        return "Bearer $token"
    }
}
