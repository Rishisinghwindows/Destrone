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
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface EDroneApi {
    @POST("/auth/request_otp")
    suspend fun requestOtp(
        @Body request: OtpRequest,
    ): OtpResponse

    @POST("/auth/verify_otp")
    suspend fun verifyOtp(
        @Body request: OtpVerifyRequest,
    ): TokenResponse

    @GET("/drones/")
    suspend fun listDrones(
        @Header("Authorization") token: String,
        @Query("lat") lat: Double? = null,
        @Query("lon") lon: Double? = null,
        @Query("max_dist_km") maxDistanceKm: Double? = null,
        @Query("min_price") minPrice: Double? = null,
        @Query("max_price") maxPrice: Double? = null,
        @Query("sort_by") sortBy: String? = null,
    ): List<Drone>

    @GET("/drones/{id}")
    suspend fun getDrone(
        @Header("Authorization") token: String,
        @Path("id") id: Int,
    ): Drone

    @POST("/drones/")
    suspend fun createDrone(
        @Header("Authorization") token: String,
        @Body request: DroneCreateRequest,
    ): Drone

    @PATCH("/drones/{id}/availability")
    suspend fun updateAvailability(
        @Header("Authorization") token: String,
        @Path("id") droneId: Int,
        @Body request: AvailabilityUpdate,
    ): Map<String, String>

    @GET("/owners/me/drones")
    suspend fun listOwnerDrones(
        @Header("Authorization") token: String,
    ): List<Drone>

    @GET("/bookings/")
    suspend fun listBookings(
        @Header("Authorization") token: String,
        @Query("status") status: String? = null,
    ): List<Booking>

    @POST("/bookings/")
    suspend fun createBooking(
        @Header("Authorization") token: String,
        @Body request: BookingCreateRequest,
    ): Booking

    @PATCH("/bookings/{id}")
    suspend fun updateBooking(
        @Header("Authorization") token: String,
        @Path("id") bookingId: Int,
        @Body request: BookingStatusUpdate,
    ): Map<String, String>
}
