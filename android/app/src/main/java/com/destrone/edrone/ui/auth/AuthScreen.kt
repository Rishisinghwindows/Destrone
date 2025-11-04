package com.destrone.edrone.ui.auth

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.destrone.edrone.BuildConfig
import com.destrone.edrone.data.AuthState
import com.destrone.edrone.data.EDroneRepository
import com.destrone.edrone.model.UserRole
import kotlinx.coroutines.launch
import retrofit2.HttpException

@Composable
fun AuthScreen(
    repository: EDroneRepository,
    authState: AuthState,
    onAuthStart: () -> Unit,
    onAuthComplete: () -> Unit,
    onAuthError: (String) -> Unit,
) {
    var mobile by remember { mutableStateOf(authState.mobile.orEmpty()) }
    var otp by remember { mutableStateOf("") }
    var name by remember { mutableStateOf(authState.profileName.orEmpty()) }
    var role by remember {
        mutableStateOf(
            authState.selectedRole ?: authState.preferredRole ?: UserRole.FARMER,
        )
    }
    var otpRequested by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var demoOtp by remember { mutableStateOf<String?>(BuildConfig.DEMO_OTP) }
    var statusMessage by remember { mutableStateOf<String?>(null) }
    var isProcessing by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current
    val scrollState = rememberScrollState()
    val needsName = authState.profileName.isNullOrBlank()

    val backgroundBrush = remember {
        Brush.verticalGradient(
            colors = listOf(Color(0xFF0D2917), Color(0xFF0A1F13)),
        )
    }

    val welcomeTitle = remember(role) {
        if (role == UserRole.FARMER) "Welcome, Farmer!" else "Welcome, Drone Owner!"
    }
    val welcomeSubtitle = remember(role) {
        if (role == UserRole.FARMER) {
            "Log in to manage your field missions."
        } else {
            "Access your drone fleet and bookings."
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(backgroundBrush),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = 24.dp, vertical = 32.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            AuthHeader(title = welcomeTitle, subtitle = welcomeSubtitle)

            AuthRoleToggle(
                selected = role,
                onSelected = {
                    role = it
                    repository.setPreferredRole(it)
                },
            )

            MobileEntryCard(
                mobile = mobile,
                onMobileChange = { digits ->
                    mobile = digits.filter(Char::isDigit).take(10)
                },
                isLoading = isProcessing && !otpRequested,
                enabled = !isProcessing,
                buttonLabel = if (otpRequested) "Resend OTP" else "Send OTP",
                statusMessage = statusMessage,
                onSubmit = {
                    if (mobile.length < 10) {
                        errorMessage = "Enter a valid 10-digit mobile number"
                        return@MobileEntryCard
                    }
                    scope.launch {
                        try {
                            onAuthStart()
                            isProcessing = true
                            val response = repository.requestOtp(mobile)
                            demoOtp = response.demoOtp
                            otpRequested = true
                            statusMessage =
                                "We sent a code to +91 ${mobile.take(4)}••••${mobile.takeLast(2)}"
                            errorMessage = null
                            focusManager.clearFocus()
                        } catch (ex: Exception) {
                            val message = ex.userFriendly()
                            errorMessage = message
                            onAuthError(message)
                        } finally {
                            onAuthComplete()
                            isProcessing = false
                        }
                    }
                },
                onAutoFill = { mobile = "9876543210" },
            )

            if (otpRequested) {
                OtpVerificationCard(
                    name = name,
                    onNameChange = { name = it },
                    otp = otp,
                    onOtpChange = { digits -> otp = digits.filter(Char::isDigit).take(4) },
                    needsName = needsName,
                    demoOtp = demoOtp,
                    isLoading = isProcessing,
                    onVerify = {
                        if (otp.length < 4) {
                            errorMessage = "Enter the OTP sent to your device"
                            return@OtpVerificationCard
                        }
                        if (needsName && name.isBlank()) {
                            errorMessage = "Name is required for provisioning new profiles"
                            return@OtpVerificationCard
                        }
                        scope.launch {
                            try {
                                onAuthStart()
                                isProcessing = true
                                repository.verifyOtp(
                                    mobile = mobile,
                                    otp = otp,
                                    role = role,
                                    name = if (name.isBlank()) null else name,
                                    lat = null,
                                    lon = null,
                                )
                                errorMessage = null
                            } catch (ex: Exception) {
                                val message = ex.userFriendly()
                                errorMessage = message
                                onAuthError(message)
                            } finally {
                                onAuthComplete()
                                isProcessing = false
                            }
                        }
                    },
                    onChangeNumber = {
                        otpRequested = false
                        otp = ""
                        statusMessage = null
                        errorMessage = null
                        focusManager.clearFocus()
                    },
                )
            }

            if (errorMessage != null) {
                AuthErrorBanner(errorMessage!!)
            }

            Text(
                text = "Need help? Contact support",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.7f),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun AuthHeader(title: String, subtitle: String) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Surface(
            shape = CircleShape,
            color = Color.White.copy(alpha = 0.1f),
            modifier = Modifier
                .size(74.dp),
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    text = "OTP",
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            }
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall.copy(
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                ),
                textAlign = TextAlign.Center,
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = Color.White.copy(alpha = 0.7f),
                ),
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun AuthRoleToggle(
    selected: UserRole,
    onSelected: (UserRole) -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        UserRole.entries.forEach { role ->
            val isSelected = role == selected
            val background = if (isSelected) {
                Brush.horizontalGradient(
                    listOf(Color(0xFF47D65C), Color(0xFF2EA84A)),
                )
            } else {
                Brush.linearGradient(
                    listOf(Color.White.copy(alpha = 0.08f), Color.White.copy(alpha = 0.04f)),
                )
            }
            val textColor = if (isSelected) Color.Black else Color.White

            Surface(
                shape = RoundedCornerShape(20.dp),
                color = Color.Transparent,
                border = if (isSelected) null else BorderStroke(1.dp, Color.White.copy(alpha = 0.1f)),
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(20.dp))
                    .clickable { onSelected(role) },
            ) {
                Column(
                    modifier = Modifier
                        .background(background)
                        .padding(horizontal = 20.dp, vertical = 18.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = if (role == UserRole.FARMER) "Farmer" else "Drone Owner",
                        style = MaterialTheme.typography.titleSmall.copy(
                            color = textColor,
                            fontWeight = FontWeight.SemiBold,
                        ),
                    )
                    Text(
                        text = if (role == UserRole.FARMER) {
                            "Book drones & oversee missions"
                        } else {
                            "List drones & track bookings"
                        },
                        style = MaterialTheme.typography.bodySmall.copy(
                            color = textColor.copy(alpha = 0.8f),
                        ),
                    )
                }
            }
        }
    }
}

@Composable
private fun MobileEntryCard(
    mobile: String,
    onMobileChange: (String) -> Unit,
    isLoading: Boolean,
    enabled: Boolean,
    buttonLabel: String,
    statusMessage: String?,
    onSubmit: () -> Unit,
    onAutoFill: () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(28.dp),
        color = Color.White.copy(alpha = 0.06f),
        tonalElevation = 6.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(
                text = "Enter your mobile number to get an OTP.",
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = Color.White.copy(alpha = 0.7f),
                ),
            )

            TextField(
                value = mobile,
                onValueChange = onMobileChange,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                enabled = enabled,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                prefix = {
                    Text(
                        text = "+91 ",
                        color = Color.White.copy(alpha = 0.7f),
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                trailingIcon = {
                    Text(
                        text = "Demo",
                        color = Color.White.copy(alpha = 0.6f),
                        modifier = Modifier
                            .clickable(enabled = enabled) { onAutoFill() }
                            .padding(end = 12.dp),
                        style = MaterialTheme.typography.labelMedium,
                    )
                },
                textStyle = MaterialTheme.typography.titleMedium.copy(
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                ),
                colors = TextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    disabledTextColor = Color.White.copy(alpha = 0.4f),
                    focusedContainerColor = Color.White.copy(alpha = 0.1f),
                    unfocusedContainerColor = Color.White.copy(alpha = 0.07f),
                    disabledContainerColor = Color.White.copy(alpha = 0.04f),
                    cursorColor = Color.White,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    disabledIndicatorColor = Color.Transparent,
                    focusedPrefixColor = Color.White.copy(alpha = 0.7f),
                    unfocusedPrefixColor = Color.White.copy(alpha = 0.6f),
                    disabledPrefixColor = Color.White.copy(alpha = 0.4f),
                    focusedTrailingIconColor = Color.White.copy(alpha = 0.7f),
                    unfocusedTrailingIconColor = Color.White.copy(alpha = 0.6f),
                    disabledTrailingIconColor = Color.White.copy(alpha = 0.4f),
                ),
                shape = RoundedCornerShape(18.dp),
            )

            Button(
                onClick = onSubmit,
                enabled = !isLoading && mobile.length == 10,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF47D65C),
                    contentColor = Color.Black,
                    disabledContainerColor = Color.White.copy(alpha = 0.1f),
                    disabledContentColor = Color.White.copy(alpha = 0.4f),
                ),
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = Color.Black,
                    )
                } else {
                    Text(buttonLabel)
                }
            }

            statusMessage?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = Color.White.copy(alpha = 0.7f),
                    ),
                )
            }
        }
    }
}

@Composable
private fun OtpVerificationCard(
    name: String,
    onNameChange: (String) -> Unit,
    otp: String,
    onOtpChange: (String) -> Unit,
    needsName: Boolean,
    demoOtp: String?,
    isLoading: Boolean,
    onVerify: () -> Unit,
    onChangeNumber: () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(28.dp),
        color = Color.White.copy(alpha = 0.06f),
        tonalElevation = 6.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(
                text = "Verify OTP",
                style = MaterialTheme.typography.titleMedium.copy(
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                ),
            )

            if (needsName) {
                TextField(
                    value = name,
                    onValueChange = onNameChange,
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    label = { Text("Full name") },
                    colors = TextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        cursorColor = Color.White,
                        focusedContainerColor = Color.White.copy(alpha = 0.1f),
                        unfocusedContainerColor = Color.White.copy(alpha = 0.07f),
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        focusedLabelColor = Color.White.copy(alpha = 0.8f),
                        unfocusedLabelColor = Color.White.copy(alpha = 0.6f),
                    ),
                    shape = RoundedCornerShape(18.dp),
                )
            }

            Text(
                text = "Enter the code we sent to your device.",
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = Color.White.copy(alpha = 0.7f),
                ),
            )

            OtpInputRow(value = otp, length = 4, onValueChange = onOtpChange)

            demoOtp?.let {
                Text(
                    text = "Demo OTP: $it",
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = Color.White.copy(alpha = 0.65f),
                    ),
                )
            }

            Button(
                onClick = onVerify,
                enabled = otp.length == 4 && !isLoading,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White,
                    contentColor = Color(0xFF0D2917),
                    disabledContainerColor = Color.White.copy(alpha = 0.2f),
                    disabledContentColor = Color.White.copy(alpha = 0.5f),
                ),
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = Color(0xFF0D2917),
                    )
                } else {
                    Text("Verify OTP")
                }
            }

            TextButton(onClick = onChangeNumber) {
                Text("Use a different number")
            }
        }
    }
}

@Composable
private fun OtpInputRow(
    value: String,
    length: Int,
    onValueChange: (String) -> Unit,
) {
    val focusRequester = remember { FocusRequester() }
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        textStyle = TextStyle(color = Color.Transparent),
        cursorBrush = SolidColor(Color.Transparent),
        modifier = Modifier
            .fillMaxWidth()
            .focusRequester(focusRequester),
        decorationBox = { inner ->
            Box(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { focusRequester.requestFocus() },
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    repeat(length) { index ->
                        val char = value.getOrNull(index)?.toString().orEmpty()
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(56.dp)
                                .clip(RoundedCornerShape(14.dp))
                                .background(Color.White.copy(alpha = 0.12f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = char,
                                style = MaterialTheme.typography.titleMedium.copy(
                                    color = Color.White,
                                    fontWeight = FontWeight.SemiBold,
                                ),
                            )
                        }
                    }
                }
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .alpha(0f),
                ) {
                    inner()
                }
            }
        },
    )

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }
}

@Composable
private fun AuthErrorBanner(message: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 4.dp),
        color = Color(0xFFE57373),
        shape = RoundedCornerShape(16.dp),
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium.copy(color = Color(0xFF330000)),
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        )
    }
}

private fun Exception.userFriendly(): String = when (this) {
    is HttpException -> {
        val message = response()?.errorBody()?.string()
        message ?: "Server error (${code()})"
    }
    else -> localizedMessage ?: "Something went wrong. Please retry."
}
