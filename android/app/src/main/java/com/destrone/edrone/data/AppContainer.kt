package com.destrone.edrone.data

import android.content.Context
import com.destrone.edrone.BuildConfig
import com.destrone.edrone.model.UserRole
import kotlinx.serialization.json.Json
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.serialization.ExperimentalSerializationApi
import okhttp3.MediaType.Companion.toMediaType
import java.util.concurrent.TimeUnit

class AppContainer(context: Context) {
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    val tokenStorage = TokenStorage(context)

    private val authStateFlow = MutableStateFlow(
        AuthState(
            token = tokenStorage.token,
            mobile = tokenStorage.mobile,
            selectedRole = tokenStorage.selectedRole,
            preferredRole = tokenStorage.preferredRole,
            roles = tokenStorage.availableRoles,
            profileName = tokenStorage.profileName,
            hasSeenOnboarding = tokenStorage.hasSeenOnboarding,
        ),
    )

    val authState: StateFlow<AuthState> = authStateFlow.asStateFlow()

    private val retrofit: Retrofit = buildRetrofit()
    val api: EDroneApi = retrofit.create(EDroneApi::class.java)
    val repository = EDroneRepository(api, this)

    fun updateAuthState(block: (AuthState) -> AuthState) {
        authStateFlow.update { previous ->
            val next = block(previous)
            tokenStorage.token = next.token
            tokenStorage.mobile = next.mobile
            tokenStorage.selectedRole = next.selectedRole
            tokenStorage.preferredRole = next.preferredRole
            tokenStorage.availableRoles = next.roles
            tokenStorage.profileName = next.profileName
            tokenStorage.hasSeenOnboarding = next.hasSeenOnboarding
            next
        }
    }

    fun clearAuth() {
        tokenStorage.clear()
        authStateFlow.value = AuthState()
    }

    fun setPreferredRole(role: UserRole) {
        updateAuthState { it.copy(preferredRole = role) }
    }

    private fun buildRetrofit(): Retrofit {
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        val headerInterceptor = Interceptor { chain ->
            val request = chain.request().newBuilder()
                .header("Accept", "application/json")
                .build()
            chain.proceed(request)
        }

        val client = OkHttpClient.Builder()
            .addInterceptor(headerInterceptor)
            .addInterceptor(logging)
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .build()

        return Retrofit.Builder()
            .baseUrl(BuildConfig.BASE_URL)
            .client(client)
            .addConverterFactory(jsonConverterFactory())
            .build()
    }

    @OptIn(ExperimentalSerializationApi::class)
    private fun jsonConverterFactory() =
        json.asConverterFactory("application/json".toMediaType())
}

data class AuthState(
    val token: String? = null,
    val mobile: String? = null,
    val selectedRole: UserRole? = null,
    val preferredRole: UserRole? = null,
    val roles: List<UserRole> = emptyList(),
    val profileName: String? = null,
    val hasSeenOnboarding: Boolean = false,
)
