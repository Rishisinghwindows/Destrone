package com.destrone.edrone.data

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import com.destrone.edrone.model.UserRole

class TokenStorage(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var token: String?
        get() = prefs.getString(KEY_TOKEN, null)
        set(value) = prefs.edit { putOrRemove(KEY_TOKEN, value) }

    var mobile: String?
        get() = prefs.getString(KEY_MOBILE, null)
        set(value) = prefs.edit { putOrRemove(KEY_MOBILE, value) }

    var selectedRole: UserRole?
        get() = prefs.getString(KEY_ROLE, null)?.let(UserRole::fromWire)
        set(value) = prefs.edit { putOrRemove(KEY_ROLE, value?.wireValue) }

    var preferredRole: UserRole?
        get() = prefs.getString(KEY_PREFERRED_ROLE, null)?.let(UserRole::fromWire)
        set(value) = prefs.edit { putOrRemove(KEY_PREFERRED_ROLE, value?.wireValue) }

    var availableRoles: List<UserRole>
        get() = prefs.getStringSet(KEY_ROLES, null)
            ?.mapNotNull(UserRole::fromWire)
            ?: emptyList()
        set(value) = prefs.edit {
            if (value.isEmpty()) remove(KEY_ROLES) else putStringSet(
                KEY_ROLES,
                value.map(UserRole::wireValue).toSet(),
            )
        }

    var profileName: String?
        get() = prefs.getString(KEY_PROFILE_NAME, null)
        set(value) = prefs.edit { putOrRemove(KEY_PROFILE_NAME, value) }

    var hasSeenOnboarding: Boolean
        get() = prefs.getBoolean(KEY_ONBOARDING, false)
        set(value) = prefs.edit { putBoolean(KEY_ONBOARDING, value) }

    fun clear() {
        prefs.edit {
            remove(KEY_TOKEN)
            remove(KEY_MOBILE)
            remove(KEY_ROLE)
            remove(KEY_PREFERRED_ROLE)
            remove(KEY_ROLES)
            remove(KEY_PROFILE_NAME)
            remove(KEY_ONBOARDING)
        }
    }

    private fun SharedPreferences.Editor.putOrRemove(
        key: String,
        value: String?,
    ) {
        if (value.isNullOrEmpty()) remove(key) else putString(key, value)
    }

    private companion object {
        const val PREFS_NAME = "edrone.prefs"
        const val KEY_TOKEN = "token"
        const val KEY_MOBILE = "mobile"
        const val KEY_ROLE = "role"
        const val KEY_PREFERRED_ROLE = "preferred_role"
        const val KEY_ROLES = "roles"
        const val KEY_PROFILE_NAME = "profile_name"
        const val KEY_ONBOARDING = "onboarding_complete"
    }
}
