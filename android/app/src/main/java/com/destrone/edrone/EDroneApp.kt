package com.destrone.edrone

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.destrone.edrone.R
import com.destrone.edrone.data.AuthState
import com.destrone.edrone.model.UserRole
import com.destrone.edrone.ui.auth.AuthScreen
import com.destrone.edrone.ui.home.HomeScreen
import kotlinx.coroutines.delay

@Composable
fun EDroneApp() {
    val container = LocalAppContainer.current
    val authState by container.authState.collectAsState()
    val showProgress = remember { mutableStateOf(false) }
    var splashVisible by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        delay(600)
        splashVisible = false
    }

    val destination = when {
        splashVisible -> AppDestination.Splash
        !authState.token.isNullOrEmpty() -> AppDestination.Home
        authState.preferredRole == null -> AppDestination.RoleSelect
        !authState.hasSeenOnboarding -> AppDestination.Onboarding
        else -> AppDestination.Auth
    }

    Crossfade(targetState = destination, label = "app_destination") { target ->
        when (target) {
            AppDestination.Splash -> SplashScreen()
            AppDestination.RoleSelect -> RoleSelectScreen(
                onRoleSelected = { role ->
                    container.updateAuthState {
                        it.copy(
                            preferredRole = role,
                            selectedRole = role,
                            hasSeenOnboarding = false,
                        )
                    }
                },
            )
            AppDestination.Onboarding -> OnboardingScreen(
                role = authState.preferredRole ?: UserRole.FARMER,
                onSkip = {
                    container.updateAuthState { state ->
                        state.copy(
                            hasSeenOnboarding = true,
                            selectedRole = state.selectedRole ?: state.preferredRole,
                        )
                    }
                },
                onFinished = {
                    container.updateAuthState { state ->
                        state.copy(
                            hasSeenOnboarding = true,
                            selectedRole = state.selectedRole ?: state.preferredRole,
                        )
                    }
                },
            )
            AppDestination.Auth -> AuthScreen(
                repository = container.repository,
                authState = authState,
                onAuthStart = { showProgress.value = true },
                onAuthComplete = { showProgress.value = false },
                onAuthError = { showProgress.value = false },
            )
            AppDestination.Home -> HomeScreen(
                repository = container.repository,
                authState = authState,
                onLogout = container.repository::logout,
                showBlockingIndicator = showProgress.value,
            )
        }
    }

    if (showProgress.value) {
        FullscreenProgress()
    }
}

private enum class AppDestination {
    Splash,
    RoleSelect,
    Onboarding,
    Auth,
    Home,
}

@Composable
private fun SplashScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    listOf(Color(0xFF0D2917), Color(0xFF12331F)),
                ),
            )
            .padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Surface(
            modifier = Modifier.size(96.dp),
            shape = CircleShape,
            color = Color.White.copy(alpha = 0.08f),
        ) {
            Image(
                painter = painterResource(id = R.drawable.ic_launcher_foreground),
                contentDescription = "EDrone logo",
                modifier = Modifier.padding(16.dp),
                alignment = Alignment.Center,
            )
        }
        Text(
            text = "AgriDrone Rentals",
            style = MaterialTheme.typography.headlineMedium,
            color = Color.White,
            modifier = Modifier.padding(top = 24.dp),
        )
        Text(
            text = "Precision agriculture on demand",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.White.copy(alpha = 0.7f),
        )
    }
}

@Composable
private fun RoleSelectScreen(
    onRoleSelected: (UserRole) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFF0D2917), Color(0xFF0A1F13)),
                ),
            )
            .padding(horizontal = 28.dp, vertical = 48.dp),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "AgriDrone Rentals",
                style = MaterialTheme.typography.headlineSmall.copy(color = Color.White),
            )
            Text(
                text = "Select how you’ll use the app",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.75f),
                modifier = Modifier.padding(top = 8.dp),
            )
        }

        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            RoleCard(
                title = "I am a Farmer",
                subtitle = "Discover drones nearby, compare pricing, and schedule missions.",
                gradient = Brush.horizontalGradient(
                    listOf(Color(0xFF47D65C), Color(0xFF2EA84A)),
                ),
                textColor = Color.Black,
                onClick = { onRoleSelected(UserRole.FARMER) },
            )
            RoleCard(
                title = "I am a Drone Owner",
                subtitle = "List your fleet, manage availability, and accept bookings.",
                gradient = Brush.linearGradient(
                    listOf(Color.White.copy(alpha = 0.06f), Color.White.copy(alpha = 0.12f)),
                ),
                textColor = Color.White,
                onClick = { onRoleSelected(UserRole.OWNER) },
            )
        }

        Text(
            text = "Need help? Tap here",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.White.copy(alpha = 0.7f),
            modifier = Modifier
                .fillMaxWidth()
                .clickable { }
                .padding(top = 12.dp),
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun RoleCard(
    title: String,
    subtitle: String,
    gradient: Brush,
    textColor: Color,
    onClick: () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(24.dp),
        color = Color.Transparent,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .clickable(onClick = onClick),
    ) {
        Column(
            modifier = Modifier
                .background(gradient)
                .padding(horizontal = 24.dp, vertical = 28.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium.copy(color = textColor, fontWeight = FontWeight.SemiBold),
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(color = textColor.copy(alpha = 0.8f)),
            )
        }
    }
}

@Composable
private fun OnboardingScreen(
    role: UserRole,
    onSkip: () -> Unit,
    onFinished: () -> Unit,
) {
    val slides = rememberSlides(role)
    var index by remember(role) { mutableStateOf(0) }
    val current = slides[index]

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0C1F12))
            .padding(top = 24.dp, bottom = 36.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            horizontalArrangement = Arrangement.End,
        ) {
            Text(
                text = "Skip",
                color = Color.White.copy(alpha = 0.7f),
                modifier = Modifier.clickable { onSkip() },
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Surface(
            shape = RoundedCornerShape(28.dp),
            color = Color.Black,
            tonalElevation = 6.dp,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
        ) {
            Column(
                modifier = Modifier.padding(bottom = 28.dp),
            ) {
                AsyncImage(
                    model = current.imageUrl,
                    contentDescription = current.title,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(280.dp)
                        .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)),
                    contentScale = ContentScale.Crop,
                )

                Column(
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Text(
                        text = current.title,
                        style = MaterialTheme.typography.headlineSmall.copy(color = Color.White),
                    )
                    Text(
                        text = current.subtitle,
                        style = MaterialTheme.typography.bodyMedium.copy(color = Color.White.copy(alpha = 0.7f)),
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        slides.forEachIndexed { i, _ ->
                            val isSelected = i == index
                            Box(
                                modifier = Modifier
                                    .height(6.dp)
                                    .weight(if (isSelected) 1.2f else 0.6f)
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(
                                        if (isSelected) Color(0xFF47D65C) else Color.White.copy(alpha = 0.2f),
                                    ),
                            )
                        }
                    }

                    Button(
                        onClick = {
                            if (index < slides.lastIndex) {
                                index += 1
                            } else {
                                onFinished()
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF47D65C),
                            contentColor = Color.Black,
                        ),
                        shape = RoundedCornerShape(18.dp),
                    ) {
                        Text(if (index < slides.lastIndex) "Next" else "Get started")
                    }
                }
            }
        }
    }
}

private data class OnboardingSlide(
    val id: String,
    val title: String,
    val subtitle: String,
    val imageUrl: String,
)

@Composable
private fun rememberSlides(role: UserRole): List<OnboardingSlide> = remember(role) {
    when (role) {
        UserRole.FARMER -> listOf(
            OnboardingSlide(
                id = "farmer_1",
                title = "Find the right drone",
                subtitle = "Browse verified fleets near you, compare pricing, and pick the best match for your fields.",
                imageUrl = "https://images.unsplash.com/photo-1523966211575-eb4a01e7dd51?auto=format&fit=crop&w=1200&q=80",
            ),
            OnboardingSlide(
                id = "farmer_2",
                title = "Track every booking",
                subtitle = "Stay updated on mission status, pilot ETA, and post-flight summaries from one dashboard.",
                imageUrl = "https://images.unsplash.com/photo-1472145246862-b24cf25c4a36?auto=format&fit=crop&w=1200&q=80",
            ),
            OnboardingSlide(
                id = "farmer_3",
                title = "Maximise your yield",
                subtitle = "Use aerial insights to treat problem zones and plan precision spraying runs in minutes.",
                imageUrl = "https://images.unsplash.com/photo-1516685018646-549198525c1b?auto=format&fit=crop&w=1200&q=80",
            ),
        )
        UserRole.OWNER -> listOf(
            OnboardingSlide(
                id = "owner_1",
                title = "List your fleet",
                subtitle = "Add drone specs, pricing, and availability so farmers can discover your services instantly.",
                imageUrl = "https://images.unsplash.com/photo-1527430253228-e93688616381?auto=format&fit=crop&w=1200&q=80",
            ),
            OnboardingSlide(
                id = "owner_2",
                title = "Stay mission ready",
                subtitle = "Approve incoming bookings, update status in real time, and keep clients in the loop.",
                imageUrl = "https://images.unsplash.com/photo-1473186505569-9c61870c11f9?auto=format&fit=crop&w=1200&q=80",
            ),
            OnboardingSlide(
                id = "owner_3",
                title = "Grow your business",
                subtitle = "Build trusted partnerships, earn repeat missions, and expand into new regions effortlessly.",
                imageUrl = "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80",
            ),
        )
    }
}

@Composable
private fun FullscreenProgress() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CircularProgressIndicator()
        Text(
            text = "Working...",
            modifier = Modifier.padding(top = 12.dp),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
