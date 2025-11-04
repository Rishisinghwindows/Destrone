package com.destrone.edrone.model

enum class UserRole(val wireValue: String) {
    FARMER("farmer"),
    OWNER("owner");

    val displayName: String
        get() = name.lowercase().replaceFirstChar { it.titlecase() }

    companion object {
        fun fromWire(value: String?): UserRole? =
            entries.firstOrNull { it.wireValue == value }
    }
}
