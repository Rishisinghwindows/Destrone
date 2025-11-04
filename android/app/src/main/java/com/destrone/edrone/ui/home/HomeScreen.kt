package com.destrone.edrone.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.BorderStroke
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material.icons.outlined.BatteryChargingFull
import androidx.compose.material.icons.outlined.BookOnline
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.CurrencyRupee
import androidx.compose.material.icons.outlined.InvertColors
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.TravelExplore
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Widgets
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Info
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Brush
import coil.compose.AsyncImage
import com.destrone.edrone.data.AuthState
import com.destrone.edrone.data.EDroneRepository
import com.destrone.edrone.model.Booking
import com.destrone.edrone.model.BookingCreateRequest
import com.destrone.edrone.model.Drone
import com.destrone.edrone.model.UserRole
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.text.NumberFormat
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    repository: EDroneRepository,
    authState: AuthState,
    onLogout: () -> Unit,
    showBlockingIndicator: Boolean,
) {
    val activeRole = remember(authState.selectedRole, authState.preferredRole, authState.roles) {
        authState.selectedRole
            ?: authState.preferredRole
            ?: authState.roles.firstOrNull()
            ?: UserRole.FARMER
    }
    var selectedTab by remember { mutableStateOf(HomeTab.primary(activeRole)) }
    var error by remember { mutableStateOf<String?>(null) }
    var drones by remember { mutableStateOf<List<Drone>>(emptyList()) }
    var bookings by remember { mutableStateOf<List<Booking>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    fun refresh() {
        scope.launch {
            try {
                isLoading = true
                error = null
                when (selectedTab) {
                    HomeTab.Drones -> {
                        drones = if (activeRole == UserRole.OWNER) {
                            repository.listOwnerDrones()
                        } else {
                            repository.listDrones(sortBy = "price")
                        }
                    }

                    HomeTab.Bookings -> {
                        bookings = repository.listBookings()
                    }
                }
            } catch (ex: Exception) {
                error = ex.userFriendly()
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(activeRole) {
        selectedTab = HomeTab.primary(activeRole)
    }

    LaunchedEffect(activeRole, selectedTab) {
        refresh()
    }

    val isFarmer = activeRole == UserRole.FARMER
    val isFarmerDrones = isFarmer && selectedTab == HomeTab.Drones
    val isDarkTheme = MaterialTheme.colorScheme.background.luminance() < 0.5f

    Scaffold(
        topBar = {
            if (!isFarmerDrones) {
                TopAppBar(
                    title = {
                        Column {
                            Text(
                                text = when (activeRole) {
                                    UserRole.OWNER -> "Owner Console"
                                    UserRole.FARMER -> "Farmer Dashboard"
                                },
                                style = MaterialTheme.typography.titleLarge,
                            )
                            authState.profileName?.let {
                                Text(
                                    text = it,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                        }
                    },
                    actions = {
                        TextButton(onClick = onLogout) {
                            Text("Logout")
                        }
                    },
                )
            }
        },
        containerColor = if (isFarmerDrones) {
            FarmerPalette.background(isDarkTheme)
        } else {
            MaterialTheme.colorScheme.background
        },
        bottomBar = {
            if (isFarmer) {
                FarmerBottomBar(
                    selectedTab = selectedTab,
                    onTabSelected = { next ->
                        if (selectedTab != next) {
                            selectedTab = next
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        if (isFarmerDrones) {
            FarmerDroneCatalog(
                modifier = Modifier.padding(innerPadding),
                authState = authState,
                drones = drones,
                isLoading = isLoading,
                globalError = error,
                showBlockingIndicator = showBlockingIndicator,
                repository = repository,
                onRefresh = ::refresh,
            )
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(horizontal = 16.dp),
            ) {
                if (showBlockingIndicator) {
                    LinearProgressIndicator(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                    )
                }

                if (!isFarmer) {
                    TabRow(
                        selectedTabIndex = selectedTab.ordinal,
                        modifier = Modifier.padding(top = 12.dp),
                    ) {
                        HomeTab.entries.forEach { tab ->
                            Tab(
                                selected = selectedTab == tab,
                                onClick = {
                                    selectedTab = tab
                                },
                                text = { Text(tab.label(activeRole)) },
                            )
                        }
                    }
                }

                if (isLoading) {
                    Text(
                        modifier = Modifier.padding(16.dp),
                        text = "Loading...",
                    )
                }

                error?.let {
                    Text(
                        modifier = Modifier.padding(16.dp),
                        text = it,
                        color = MaterialTheme.colorScheme.error,
                    )
                }

                when (selectedTab) {
                    HomeTab.Drones -> {
                        if (activeRole == UserRole.OWNER) {
                            OwnerDroneCatalog(
                                modifier = Modifier.padding(top = 16.dp),
                                drones = drones,
                                isLoading = isLoading,
                                globalError = error,
                                showBlockingIndicator = showBlockingIndicator,
                                repository = repository,
                                onRefresh = ::refresh,
                            )
                        } else {
                            DronesList(
                                drones = drones,
                                role = activeRole,
                                onRefresh = ::refresh,
                                repository = repository,
                            )
                        }
                    }

                    HomeTab.Bookings -> BookingList(
                        bookings = bookings,
                        role = activeRole,
                        repository = repository,
                        onRefresh = ::refresh,
                    )
                }
            }
        }
    }
}

private object OwnerPalette {
    private val BackgroundTop = Color(0xFF0D2417)
    private val BackgroundBottom = Color(0xFF08170F)
    private val Surface = Color(0xFF15271C)
    private val Elevated = Color(0xFF1E3726)

    fun backgroundGradient(): Brush = Brush.verticalGradient(listOf(BackgroundTop, BackgroundBottom))
    fun surface(): Color = Surface
    fun elevatedSurface(): Color = Elevated
}

private object FarmerPalette {
    private val LightBackground = Color(0xFF0D2917)
    private val DarkBackground = Color(0xFF081811)
    private val LightSurface = Color(0xFF1E4D2B)
    private val DarkSurface = Color(0xFF12331F)
    private val LightElevated = Color(0xFF265C34)
    private val DarkElevated = Color(0xFF1A3E28)
    private val LightChip = Color(0xFF1F4027)
    private val DarkChip = Color(0xFF2A5534)
    private val Accent = Color(0xFF47D65C)
    private val AccentMuted = Color(0xFF309E3E)

    fun background(isDark: Boolean): Color = if (isDark) DarkBackground else LightBackground
    fun surface(isDark: Boolean): Color = if (isDark) DarkSurface else LightSurface
    fun elevatedSurface(isDark: Boolean): Color = if (isDark) DarkElevated else LightElevated
    fun chip(isDark: Boolean): Color = if (isDark) DarkChip else LightChip
    fun primary(): Color = Accent
    fun primaryMuted(): Color = AccentMuted
}

@Composable
private fun FarmerDroneCatalog(
    modifier: Modifier = Modifier,
    authState: AuthState,
    drones: List<Drone>,
    isLoading: Boolean,
    globalError: String?,
    showBlockingIndicator: Boolean,
    repository: EDroneRepository,
    onRefresh: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var bookingDialog by remember { mutableStateOf<Drone?>(null) }
    var localError by remember { mutableStateOf<String?>(null) }
    var quickFilter by remember { mutableStateOf(QuickFilterOption.All) }
    var startDate by remember { mutableStateOf(LocalDate.now()) }
    var endDate by remember { mutableStateOf(LocalDate.now().plusDays(5)) }

    val isDark = MaterialTheme.colorScheme.background.luminance() < 0.5f
    val combinedError = localError ?: globalError
    val profileName = authState.profileName?.takeIf { it.isNotBlank() } ?: "Farmer"
    val fallbackLocation = "Nashik, Maharashtra"
    val dateRangeLabel = remember(startDate, endDate) {
        val formatter = DateTimeFormatter.ofPattern("MMM d")
        "${formatter.format(startDate)} - ${formatter.format(endDate)}"
    }

    LaunchedEffect(isLoading, showBlockingIndicator) {
        if (isLoading || showBlockingIndicator) {
            localError = null
        }
    }

    LaunchedEffect(localError) {
        if (localError != null) {
            delay(2200)
            localError = null
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(FarmerPalette.background(isDark)),
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(0.dp),
        ) {
            item {
                FarmerHeroHeader(
                    name = profileName,
                    location = fallbackLocation,
                    isDark = isDark,
                )
            }
            item {
                FarmerDateRangeRow(
                    isDark = isDark,
                    label = dateRangeLabel,
                    onDateClick = {
                        // Placeholder: integrate real date picking when backend supports date filters.
                    },
                    onFilterClick = {
                        localError = null
                        localError = "Advanced filters coming soon."
                    },
                )
            }
            item {
                FarmerFilterRow(
                    isDark = isDark,
                    selected = quickFilter,
                    onOptionSelected = { option ->
                        if (option != quickFilter) {
                            quickFilter = option
                            localError = null
                            onRefresh()
                        }
                    },
                    onFilterClick = {
                        localError = null
                        localError = "Advanced filters coming soon."
                    },
                )
            }
            if (showBlockingIndicator) {
                item {
                    LinearProgressIndicator(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp, vertical = 12.dp),
                    )
                }
            } else if (isLoading) {
                item {
                    Text(
                        modifier = Modifier
                            .padding(horizontal = 24.dp, vertical = 12.dp),
                        text = "Loading drones near you...",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
            combinedError?.let { message ->
                item {
                    FarmerErrorBanner(message = message)
                }
            }
            if (!isLoading && drones.isEmpty()) {
                item {
                    Text(
                        modifier = Modifier
                            .padding(horizontal = 24.dp, vertical = 32.dp),
                        text = "No drones available right now. Try adjusting filters or refreshing soon.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            items(drones, key = { it.id }) { drone ->
                FarmerDroneCard(
                    drone = drone,
                    isDark = isDark,
                    onBook = {
                        bookingDialog = drone
                    },
                )
            }
            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }

        bookingDialog?.let { drone ->
            BookingDialog(
                drone = drone,
                onDismiss = { bookingDialog = null },
                onConfirm = { name, hours ->
                    scope.launch {
                        try {
                            repository.createBooking(
                                BookingCreateRequest(
                                    droneId = drone.id,
                                    farmerName = name.ifBlank { null },
                                    durationHours = hours,
                                ),
                            )
                            onRefresh()
                            bookingDialog = null
                            localError = null
                        } catch (ex: Exception) {
                            localError = ex.userFriendly()
                        }
                    }
                },
            )
        }
    }
}

@Composable
private fun OwnerDroneCatalog(
    modifier: Modifier = Modifier,
    drones: List<Drone>,
    isLoading: Boolean,
    globalError: String?,
    showBlockingIndicator: Boolean,
    repository: EDroneRepository,
    onRefresh: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var localError by remember { mutableStateOf<String?>(null) }
    var updating by remember { mutableStateOf<Int?>(null) }

    val combinedError = localError ?: globalError

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(OwnerPalette.backgroundGradient()),
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        text = "My Drones",
                        style = MaterialTheme.typography.headlineSmall.copy(
                            color = Color.White,
                            fontWeight = FontWeight.SemiBold,
                        ),
                    )
                    Text(
                        text = "Manage fleet availability and pricing",
                        style = MaterialTheme.typography.bodyMedium.copy(
                            color = Color.White.copy(alpha = 0.65f),
                        ),
                    )
                }
            }

            item {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = OwnerPalette.surface(),
                    tonalElevation = 6.dp,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Column(
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            Text(
                                text = "Add another drone",
                                style = MaterialTheme.typography.titleSmall.copy(
                                    color = Color.White,
                                    fontWeight = FontWeight.SemiBold,
                                ),
                            )
                            Text(
                                text = "Coming soon: upload specs and imagery",
                                style = MaterialTheme.typography.bodySmall.copy(
                                    color = Color.White.copy(alpha = 0.65f),
                                ),
                            )
                        }
                        Surface(
                            modifier = Modifier
                                .size(40.dp),
                            color = Color.White.copy(alpha = 0.12f),
                            shape = CircleShape,
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Add,
                                contentDescription = "Add drone",
                                tint = Color.White.copy(alpha = 0.8f),
                                modifier = Modifier.padding(10.dp),
                            )
                        }
                    }
                }
            }

            when {
                showBlockingIndicator -> {
                    item {
                        LinearProgressIndicator(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 12.dp),
                        )
                    }
                }

                isLoading -> {
                    item {
                        Text(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 12.dp),
                            text = "Fetching your fleet...",
                            style = MaterialTheme.typography.bodyMedium.copy(
                                color = Color.White.copy(alpha = 0.75f),
                            ),
                            textAlign = TextAlign.Center,
                        )
                    }
                }

                drones.isEmpty() -> {
                    item {
                        OwnerEmptyState()
                    }
                }
            }

            combinedError?.let { message ->
                item {
                    OwnerErrorBanner(message = message)
                }
            }

            items(drones, key = { it.id }) { drone ->
                OwnerDroneCard(
                    drone = drone,
                    isUpdating = updating == drone.id,
                    onUpdateStatus = { status ->
                        scope.launch {
                            try {
                                updating = drone.id
                                repository.updateAvailability(drone.id, status)
                                localError = null
                                onRefresh()
                            } catch (ex: Exception) {
                                localError = ex.userFriendly()
                            } finally {
                                updating = null
                            }
                        }
                    },
                )
            }

            item { Spacer(modifier = Modifier.height(48.dp)) }
        }
    }
}

@Composable
private fun OwnerEmptyState() {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 32.dp),
        shape = RoundedCornerShape(28.dp),
        color = OwnerPalette.surface(),
        tonalElevation = 4.dp,
        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.08f)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = Icons.Outlined.Info,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.6f),
                modifier = Modifier.size(40.dp),
            )
            Text(
                text = "No drones listed yet",
                style = MaterialTheme.typography.titleMedium.copy(
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                ),
                textAlign = TextAlign.Center,
            )
            Text(
                text = "Add your first drone to start receiving booking requests from farmers nearby.",
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = Color.White.copy(alpha = 0.7f),
                ),
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun OwnerErrorBanner(message: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 8.dp),
        shape = RoundedCornerShape(18.dp),
        color = Color(0xFFE57373),
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium.copy(
                color = Color(0xFF330000),
                fontWeight = FontWeight.SemiBold,
            ),
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        )
    }
}

@Composable
private fun OwnerDroneCard(
    drone: Drone,
    isUpdating: Boolean,
    onUpdateStatus: (String) -> Unit,
) {
    val gradient = Brush.verticalGradient(
        colors = listOf(
            OwnerPalette.elevatedSurface(),
            OwnerPalette.surface(),
        ),
    )
    val outline = Color.White.copy(alpha = 0.08f)
    val subtleColor = Color.White.copy(alpha = 0.65f)
    val priceLabel = "₹${drone.pricePerHour.formatCurrency()} / hour"

    Card(
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .background(gradient)
                .border(BorderStroke(1.dp, outline), RoundedCornerShape(22.dp)),
        ) {
            val imageUrl = drone.imageUrls?.firstOrNull() ?: drone.imageUrl
            imageUrl?.let { url ->
                AsyncImage(
                    model = url,
                    contentDescription = drone.name,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp)
                        .clip(RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)),
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 18.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(
                            text = drone.name,
                            style = MaterialTheme.typography.titleMedium.copy(
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold,
                            ),
                        )
                        Text(
                            text = drone.type,
                            style = MaterialTheme.typography.bodySmall.copy(color = subtleColor),
                        )
                    }
                    StatusBadge(status = drone.status)
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    StatBlock(
                        icon = Icons.Outlined.BatteryChargingFull,
                        headline = drone.batteryMah?.formatMetric("mAh") ?: estimateBatteryFallback(drone),
                        label = "Battery",
                        tint = subtleColor,
                    )
                    StatBlock(
                        icon = Icons.Outlined.InvertColors,
                        headline = drone.capacityLiters?.formatMetric("L") ?: estimateCapacityFallback(drone),
                        label = "Tank",
                        tint = subtleColor,
                    )
                }

                Divider(color = outline)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(
                            text = "Pricing",
                            style = MaterialTheme.typography.bodySmall.copy(color = subtleColor),
                        )
                        Text(
                            text = priceLabel,
                            style = MaterialTheme.typography.titleMedium.copy(
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                            ),
                        )
                    }
                    Text(
                        text = "Owner ID #${drone.ownerId}",
                        style = MaterialTheme.typography.bodySmall.copy(color = subtleColor),
                    )
                }

                OwnerStatusSelector(
                    current = drone.status,
                    isUpdating = isUpdating,
                    onUpdate = onUpdateStatus,
                )
            }
        }
    }
}

@Composable
private fun StatusBadge(status: String) {
    val normalized = status.lowercase(Locale.US)
    val (label, tint) = when (normalized) {
        "available" -> "Available" to Color(0xFF47D65C)
        "booked", "rented" -> "Rented" to Color(0xFFFFB74D)
        "maintenance" -> "Maintenance" to Color(0xFF81A1AF)
        else -> status to Color.White.copy(alpha = 0.6f)
    }
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = tint.copy(alpha = 0.15f),
        border = BorderStroke(1.dp, tint.copy(alpha = 0.4f)),
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium.copy(color = tint, fontWeight = FontWeight.SemiBold),
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
        )
    }
}

@Composable
private fun OwnerStatusSelector(
    current: String,
    isUpdating: Boolean,
    onUpdate: (String) -> Unit,
) {
    val statuses = listOf("Available", "Booked", "Maintenance")
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        statuses.forEach { status ->
            val isSelected = current.equals(status, ignoreCase = true)
            val background = if (isSelected) Color(0xFF47D65C) else Color.White.copy(alpha = 0.1f)
            val contentColor = if (isSelected) Color.Black else Color.White.copy(alpha = 0.8f)
            Surface(
                shape = RoundedCornerShape(18.dp),
                color = background,
                border = if (isSelected) null else BorderStroke(1.dp, Color.White.copy(alpha = 0.12f)),
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(18.dp))
                    .clickable(enabled = !isSelected && !isUpdating) { onUpdate(status) },
            ) {
                Box(
                    modifier = Modifier
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    if (isUpdating && !isSelected) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            strokeWidth = 2.dp,
                            color = contentColor,
                        )
                    } else {
                        Text(
                            text = status,
                            style = MaterialTheme.typography.labelMedium.copy(
                                color = contentColor,
                                fontWeight = FontWeight.SemiBold,
                            ),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FarmerHeroHeader(
    name: String,
    location: String,
    isDark: Boolean,
) {
    val avatarBackground = FarmerPalette.elevatedSurface(isDark)
    val titleColor = Color.White
    val subtitleColor = Color.White.copy(alpha = 0.65f)
    val notificationBackground = FarmerPalette.surface(isDark)
    val notificationIconColor = Color.White

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            modifier = Modifier
                .size(58.dp),
            shape = CircleShape,
            color = avatarBackground,
        ) {
            AsyncImage(
                model = "https://lh3.googleusercontent.com/aida-public/AB6AXuBEzIrrkY85PGvvVg60jzGOXIPKofSTs0tfOYY2S27EgtnFdu3ybpzVii1s4-d1O8lHeqhLgogAztWLVzHyQGBMAgZWHWJh2HiEhovpLxKy4suYEcsXvDF2S0c0sZ9Q-RB4ok_KhT55LJ2k6su5nKDaUvzYcJaMGdzlxUGFgTAWDhCHB3So8mDtW-qy7W9xJgMv3siWfFcbRgwQDbyBctkArSz5gLrTa_N-y9b4kpuJAWccIXsOn3FKOp7WoWk2kFx41-Rh-01vpGuQ",
                contentDescription = "Farmer avatar",
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape),
            )
        }
        Column(
            modifier = Modifier
                .padding(start = 16.dp)
                .weight(1f),
        ) {
            Text(
                text = "Welcome, $name",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                color = titleColor,
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Icon(
                    imageVector = Icons.Outlined.LocationOn,
                    contentDescription = null,
                    tint = subtitleColor,
                    modifier = Modifier.size(16.dp),
                )
                Text(
                    text = location,
                    style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
                    color = subtitleColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Surface(
            modifier = Modifier
                .size(48.dp),
            shape = CircleShape,
            color = notificationBackground,
        ) {
            IconButton(onClick = {}) {
                Icon(
                    imageVector = Icons.Outlined.Notifications,
                    contentDescription = "Notifications",
                    tint = notificationIconColor,
                )
            }
        }
    }
}

@Composable
private fun FarmerDateRangeRow(
    isDark: Boolean,
    label: String,
    onDateClick: () -> Unit,
    onFilterClick: () -> Unit,
) {
    val cardColor = FarmerPalette.surface(isDark)
    val iconTint = Color.White
    val labelColor = Color.White

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(18.dp))
                .clickable(onClick = onDateClick),
            shape = RoundedCornerShape(18.dp),
            color = cardColor,
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 13.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Icon(
                        imageVector = Icons.Outlined.CalendarMonth,
                        contentDescription = null,
                        tint = iconTint,
                    )
                    Text(
                        text = label,
                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                        color = labelColor,
                    )
                }
                Icon(
                    imageVector = Icons.Outlined.ArrowDropDown,
                    contentDescription = "Change date",
                    tint = iconTint,
                )
            }
        }
        Surface(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(14.dp))
                .clickable(onClick = onFilterClick),
            shape = RoundedCornerShape(14.dp),
            color = cardColor,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = Icons.Outlined.Tune,
                    contentDescription = "Filters",
                    tint = iconTint,
                )
            }
        }
    }
}

private enum class QuickFilterOption(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
) {
    All("All", Icons.Outlined.Public),
    Nearby("Nearby", Icons.Outlined.LocationOn),
    Budget("Budget", Icons.Outlined.CurrencyRupee),
}

@Composable
private fun FarmerFilterRow(
    isDark: Boolean,
    selected: QuickFilterOption,
    onOptionSelected: (QuickFilterOption) -> Unit,
    onFilterClick: () -> Unit,
) {
    val options = remember { QuickFilterOption.values().toList() }

    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(options) { option ->
            FarmerQuickFilterChip(
                option = option,
                selected = option == selected,
                isDark = isDark,
                onClick = { onOptionSelected(option) },
            )
        }
        item {
            Surface(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .clickable(onClick = onFilterClick),
                color = FarmerPalette.surface(isDark),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Outlined.Tune,
                        contentDescription = "Open filters",
                        tint = Color.White,
                    )
                }
            }
        }
    }
}

@Composable
private fun FarmerQuickFilterChip(
    option: QuickFilterOption,
    selected: Boolean,
    isDark: Boolean,
    onClick: () -> Unit,
) {
    val background = if (selected) {
        FarmerPalette.primary()
    } else {
        FarmerPalette.chip(isDark)
    }
    val contentColor = if (selected) {
        Color.Black
    } else {
        Color.White
    }

    Surface(
        shape = RoundedCornerShape(18.dp),
        color = background,
        tonalElevation = if (selected) 4.dp else 0.dp,
    ) {
        Row(
            modifier = Modifier
                .clickable(onClick = onClick)
                .padding(horizontal = 18.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(
                imageVector = option.icon,
                contentDescription = null,
                tint = contentColor,
                modifier = Modifier.size(18.dp),
            )
            Text(
                text = option.label,
                color = contentColor,
                style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.SemiBold),
            )
        }
    }
}

@Composable
private fun FarmerDroneCard(
    drone: Drone,
    isDark: Boolean,
    onBook: () -> Unit,
) {
    val imageUrl = drone.imageUrls?.firstOrNull() ?: drone.imageUrl
    val isAvailable = drone.status.equals("Available", ignoreCase = true)
    val gradient = Brush.verticalGradient(
        colors = listOf(
            FarmerPalette.elevatedSurface(isDark),
            FarmerPalette.surface(isDark),
        ),
    )
    val outlineColor = Color.White.copy(alpha = 0.08f)
    val subtleColor = Color.White.copy(alpha = 0.65f)
    val primary = FarmerPalette.primary()

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent,
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
    ) {
        Column(
            modifier = Modifier
                .background(gradient)
                .border(
                    width = 1.dp,
                    color = outlineColor,
                    shape = RoundedCornerShape(20.dp),
                ),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)),
            ) {
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = drone.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.linearGradient(
                                    listOf(
                                        FarmerPalette.primary().copy(alpha = 0.6f),
                                        FarmerPalette.primaryMuted().copy(alpha = 0.4f),
                                    ),
                                ),
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.TravelExplore,
                            contentDescription = null,
                            tint = Color.Black.copy(alpha = 0.6f),
                            modifier = Modifier.size(48.dp),
                        )
                    }
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 18.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = drone.type.uppercase(Locale.US),
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = subtleColor,
                    )
                    Text(
                        text = drone.status,
                        style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold),
                        color = if (isAvailable) FarmerPalette.primary() else Color(0xFFFFB74D),
                    )
                }

                Text(
                    text = drone.name,
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    StatBlock(
                        icon = Icons.Outlined.BatteryChargingFull,
                        headline = drone.batteryMah?.formatMetric("mAh") ?: estimateBatteryFallback(drone),
                        label = "Battery",
                        tint = subtleColor,
                    )
                    StatBlock(
                        icon = Icons.Outlined.InvertColors,
                        headline = drone.capacityLiters?.formatMetric("L") ?: estimateCapacityFallback(drone),
                        label = "Tank",
                        tint = subtleColor,
                    )
                }

                Divider(color = outlineColor)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(
                            text = "Price",
                            style = MaterialTheme.typography.bodySmall,
                            color = subtleColor,
                        )
                        Text(
                            text = "₹${drone.pricePerHour.formatCurrency()} / hour",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = Color.White,
                        )
                    }
                    Button(
                        onClick = onBook,
                        enabled = isAvailable,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isAvailable) primary else FarmerPalette.surface(isDark),
                            contentColor = if (isAvailable) Color.Black else subtleColor,
                            disabledContainerColor = FarmerPalette.surface(isDark).copy(alpha = 0.6f),
                            disabledContentColor = subtleColor,
                        ),
                        modifier = Modifier.height(44.dp),
                    ) {
                        Text(if (isAvailable) "Book Now" else "Unavailable")
                    }
                }
            }
        }
    }
}

@Composable
private fun StatBlock(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    headline: String,
    label: String,
    tint: Color,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(18.dp),
            )
            Text(
                text = headline,
                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                color = Color.White,
            )
        }
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = tint,
        )
    }
}

@Composable
private fun FarmerErrorBanner(message: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.errorContainer,
        contentColor = MaterialTheme.colorScheme.onErrorContainer,
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        )
    }
}

@Composable
private fun FarmerBottomBar(
    selectedTab: HomeTab,
    onTabSelected: (HomeTab) -> Unit,
) {
    val isDark = MaterialTheme.colorScheme.background.luminance() < 0.5f
    val items = listOf(
        FarmerNavItem("Drone List", Icons.Outlined.Widgets, HomeTab.Drones),
        FarmerNavItem("Bookings", Icons.Outlined.BookOnline, HomeTab.Bookings),
        FarmerNavItem("Settings", Icons.Outlined.Settings, null),
        FarmerNavItem("Profile", Icons.Outlined.Person, null),
    )

    NavigationBar(
        containerColor = FarmerPalette.surface(isDark).copy(alpha = 0.9f),
        tonalElevation = 0.dp,
    ) {
        items.forEach { item ->
            val isSelected = item.tab == selectedTab && item.tab != null
            NavigationBarItem(
                selected = isSelected,
                onClick = {
                    item.tab?.let(onTabSelected)
                },
                icon = {
                    Icon(
                        imageVector = item.icon,
                        contentDescription = item.label,
                    )
                },
                label = {
                    Text(
                        text = item.label,
                        style = MaterialTheme.typography.labelMedium,
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = Color.Black,
                    selectedTextColor = Color.Black,
                    indicatorColor = FarmerPalette.primary(),
                    unselectedIconColor = Color.White.copy(alpha = 0.6f),
                    unselectedTextColor = Color.White.copy(alpha = 0.6f),
                ),
            )
        }
    }
}

private fun Double.formatMetric(unit: String): String {
    val formatter = NumberFormat.getNumberInstance(Locale("en", "IN")).apply {
        maximumFractionDigits = 0
        minimumFractionDigits = 0
    }
    return formatter.format(this) + " $unit"
}

private fun estimateBatteryFallback(drone: Drone): String {
    val normalized = drone.name.lowercase(Locale.US)
    return when {
        normalized.contains("agri-bot x4") -> "9,500 mAh"
        normalized.contains("fieldmapper pro") -> "7,000 mAh"
        normalized.contains("seedstorm x1") -> "12,000 mAh"
        else -> {
            val base = 6500 + (drone.id % 6) * 500
            base.toDouble().formatMetric("mAh")
        }
    }
}

private fun estimateCapacityFallback(drone: Drone): String {
    val normalized = drone.name.lowercase(Locale.US)
    return when {
        normalized.contains("agri-bot x4") -> "40 L"
        normalized.contains("fieldmapper pro") -> "20 L"
        normalized.contains("seedstorm x1") -> "50 L"
        else -> {
            val litres = 15 + (drone.id % 4) * 5
            litres.toDouble().formatMetric("L")
        }
    }
}

private data class FarmerNavItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val tab: HomeTab?,
)

private enum class HomeTab {
    Drones,
    Bookings;

    fun label(role: UserRole): String = when (this) {
        Drones -> if (role == UserRole.OWNER) "My drones" else "Available drones"
        Bookings -> if (role == UserRole.OWNER) "Incoming bookings" else "My bookings"
    }

    companion object {
        fun primary(role: UserRole): HomeTab = if (role == UserRole.OWNER) Drones else Drones
    }
}

@Composable
private fun DronesList(
    drones: List<Drone>,
    role: UserRole,
    onRefresh: () -> Unit,
    repository: EDroneRepository,
) {
    val scope = rememberCoroutineScope()
    var error by remember { mutableStateOf<String?>(null) }
    var bookingDialog by remember { mutableStateOf<Drone?>(null) }

    error?.let {
        Text(
            modifier = Modifier.padding(vertical = 12.dp),
            text = it,
            color = MaterialTheme.colorScheme.error,
        )
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(drones, key = { it.id }) { drone ->
            DroneCard(
                drone = drone,
                showActions = role == UserRole.FARMER,
                onBook = {
                    bookingDialog = drone
                },
            )
        }
    }

    bookingDialog?.let { drone ->
        BookingDialog(
            drone = drone,
            onDismiss = { bookingDialog = null },
            onConfirm = { name, hours ->
                scope.launch {
                    try {
                        repository.createBooking(
                            BookingCreateRequest(
                                droneId = drone.id,
                                farmerName = name.ifBlank { null },
                                durationHours = hours,
                            ),
                        )
                        bookingDialog = null
                        onRefresh()
                        error = null
                    } catch (ex: Exception) {
                        error = ex.userFriendly()
                    }
                }
            },
        )
    }
}

@Composable
private fun DroneCard(
    drone: Drone,
    showActions: Boolean,
    onBook: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(drone.name, style = MaterialTheme.typography.titleMedium)
            Text(
                text = "${drone.type} - Rs ${"%.0f".format(drone.pricePerHour)} per hr",
                style = MaterialTheme.typography.bodyMedium,
            )
            Text(
                text = "Status: ${drone.status}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            drone.imageUrl?.let { url ->
                AsyncImage(
                    model = url,
                    contentDescription = null,
                    modifier = Modifier
                        .padding(top = 12.dp)
                        .fillMaxWidth(),
                )
            }

            if (showActions) {
                Button(
                    modifier = Modifier.padding(top = 12.dp),
                    onClick = onBook,
                ) {
                    Text("Book this drone")
                }
            }
        }
    }
}

@Composable
private fun BookingList(
    bookings: List<Booking>,
    role: UserRole,
    repository: EDroneRepository,
    onRefresh: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var error by remember { mutableStateOf<String?>(null) }

    error?.let {
        Text(
            modifier = Modifier.padding(vertical = 12.dp),
            text = it,
            color = MaterialTheme.colorScheme.error,
        )
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(bookings, key = { it.id }) { booking ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Booking #${booking.id}",
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = "Drone ID: ${booking.droneId}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                    Text(
                        text = "When: ${booking.readableDate()}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                    booking.farmerMobile?.let {
                        Text(
                            text = "Farmer: ${booking.farmerName} ($it)",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }

                    Text(
                        text = "Status: ${booking.status}",
                        fontWeight = FontWeight.SemiBold,
                        color = when (booking.status) {
                            "Accepted" -> Color(0xFF2E7D32)
                            "Rejected" -> Color(0xFFC62828)
                            else -> MaterialTheme.colorScheme.primary
                        },
                    )

                    if (role == UserRole.OWNER) {
                        Row(
                            modifier = Modifier.padding(top = 12.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            listOf("Accepted", "Rejected", "Pending").forEach { status ->
                                TextButton(
                                    onClick = {
                                        scope.launch {
                                            try {
                                                repository.updateBooking(booking.id, status)
                                                onRefresh()
                                                error = null
                                            } catch (ex: Exception) {
                                                error = ex.userFriendly()
                                            }
                                        }
                                    },
                                ) {
                                    Text(status)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BookingDialog(
    drone: Drone,
    onDismiss: () -> Unit,
    onConfirm: (String, Int) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf("2") }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Button(onClick = {
                val duration = hours.toIntOrNull()
                if (duration == null || duration <= 0) {
                    error = "Enter a valid duration (hours)"
                    return@Button
                }
                onConfirm(name, duration)
            }) {
                Text("Confirm booking")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
        title = { Text("Book ${drone.name}") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Set booking details for ${drone.name}.")
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Farmer name (optional)") },
                    singleLine = true,
                )
                OutlinedTextField(
                    value = hours,
                    onValueChange = { input ->
                        hours = input.filter(Char::isDigit).take(2)
                    },
                    label = { Text("Duration (hours)") },
                    singleLine = true,
                )
                error?.let {
                    Text(it, color = MaterialTheme.colorScheme.error)
                }
            }
        },
)
}

private fun Double.formatCurrency(): String {
    val formatter = NumberFormat.getNumberInstance(Locale("en", "IN"))
    return formatter.format(this)
}

private fun Exception.userFriendly(): String = when (this) {
    is HttpException -> {
        response()?.errorBody()?.string() ?: "Server error (${code()})"
    }

    else -> localizedMessage ?: "Unexpected error"
}

private fun Booking.readableDate(): String = try {
    val instant = Instant.parse(bookingDate)
    val zoned = instant.atZone(ZoneId.systemDefault())
    DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm").format(zoned)
} catch (_: Exception) {
    bookingDate
}
