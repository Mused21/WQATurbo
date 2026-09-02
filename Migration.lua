---@class WQATurbo
local WQA = WQATurbo

-- WQAchievements -> WQA Turbo settings migration.
--
-- WoW only loads an addon's SavedVariables when that addon itself loads.
-- Because WQAchievements stores its database as WQADB in
-- WQAchievements.lua, WQA Turbo cannot read that file directly from disk.
--
-- If the old addon is installed but disabled, the migration flow temporarily
-- enables it, reloads the UI, imports WQADB before AceDB opens WQATurboDB,
-- disables WQAchievements again, and performs one final cleanup reload.

local OLD_ADDON = "WQAchievements"
local MIGRATION_VERSION = 1
local STATE_KEY = "_wqatMigration"

local function DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[DeepCopy(key, seen)] = DeepCopy(child, seen)
    end

    return copy
end

local function EnsureRawTurboDB()
    if type(WQATurboDB) ~= "table" then
        WQATurboDB = {}
    end

    return WQATurboDB
end

local function GetMigrationState()
    if type(WQATurboDB) ~= "table" then
        return nil
    end

    return rawget(WQATurboDB, STATE_KEY)
end

local function SourceVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(OLD_ADDON, "Version")
    end

    return nil
end

local function MarkImported(database, cleanupReload)
    database[STATE_KEY] = {
        version = MIGRATION_VERSION,
        completed = true,
        cleanupReload = cleanupReload == true,
        source = OLD_ADDON,
        sourceVersion = SourceVersion(),
        importedAt = time(),
    }
end

local function ImportLoadedDatabase(cleanupReload)
    if type(WQADB) ~= "table" then
        return false
    end

    local imported = DeepCopy(WQADB)
    MarkImported(imported, cleanupReload)

    -- Replace the raw SavedVariables table. AceDB will open this table on the
    -- next line of WQATurbo:OnInitialize(), or after the immediate reload when
    -- importing from an already-running UI.
    WQATurboDB = imported
    return true
end

function WQA:ApplyPendingWQAMigrationBeforeAceDB()
    local state = GetMigrationState()

    if type(state) ~= "table" or state.pending ~= true then
        return false
    end

    if type(WQADB) ~= "table" then
        -- WQAchievements was expected to load before us through OptionalDeps.
        -- Keep enough information to explain the failure once the UI is up.
        state.pending = false
        state.failed = true
        state.failureReason = "WQADB was not loaded"
        return false
    end

    if not ImportLoadedDatabase(true) then
        return false
    end

    -- The old addon is already loaded for this session, so disabling it only
    -- affects the next session. MaybeOfferWQAMigration() will do one final
    -- cleanup reload after WQA Turbo has successfully opened the imported DB.
    -- WQAchievements is temporarily loaded so WoW exposes WQADB, but we do not
    -- want its normal runtime to start in this migration session.
    --
    -- AceAddon initializes loaded addons before PLAYER_LOGIN and enables them
    -- at PLAYER_LOGIN. Disable the old AceAddon now, after WQADB is available,
    -- so its OnEnable() scanner/timers/popup never start.
    if type(WQAchievements) == "table" and WQAchievements.SetEnabledState then
        WQAchievements:SetEnabledState(false)
    end

    -- WQAchievements may already have registered its minimap icon during
    -- initialization. Hide that temporary icon until the cleanup reload.
    local oldIcon = LibStub("LibDBIcon-1.0", true)
    if oldIcon and oldIcon:IsRegistered("WQAchievements") then
        oldIcon:Hide("WQAchievements")
    end

    -- Also mark the old addon disabled in WoW so it is not loaded next time.
C_AddOns.DisableAddOn(OLD_ADDON, UnitName("player"))
    self._wqaMigrationImportedThisLoad = true

    return true
end

function WQA:DismissWQAMigrationOffer()
    local database = EnsureRawTurboDB()
    local state = database[STATE_KEY]

    if type(state) ~= "table" then
        state = {}
        database[STATE_KEY] = state
    end

    state.dismissed = true
    state.version = MIGRATION_VERSION
end

function WQA:StartWQAMigration()
    if not C_AddOns.DoesAddOnExist(OLD_ADDON) then
        print("|cff00ccffWQA Turbo|r: WQAchievements is not installed.")
        print("Install or restore WQAchievements first, then run |cffffffff/wqat import|r again.")
        return
    end

    -- Best case: the old addon is already enabled and therefore WQADB is
    -- available right now. Import it, disable the old addon for the next
    -- session, and reload directly into WQA Turbo.
    if type(WQADB) == "table" then
        if not ImportLoadedDatabase(false) then
            print("|cff00ccffWQA Turbo|r: Could not import WQAchievements settings.")
            return
        end

        C_AddOns.DisableAddOn(OLD_ADDON, UnitName("player"))
        print("|cff00ccffWQA Turbo|r: Settings imported. Reloading UI...")
        C_UI.Reload()
        return
    end

    -- WQAchievements exists but is disabled, so WoW has not loaded WQADB.
    -- Persist a tiny pending marker, enable the old addon for this character,
    -- then reload. OptionalDeps makes the old addon load before WQA Turbo.
    local database = EnsureRawTurboDB()
    database[STATE_KEY] = {
        version = MIGRATION_VERSION,
        pending = true,
        source = OLD_ADDON,
    }

    C_AddOns.EnableAddOn(OLD_ADDON, UnitName("player"))

    print("|cff00ccffWQA Turbo|r: Temporarily enabling WQAchievements to read its settings.")
    print("|cff00ccffWQA Turbo|r: The UI will reload and finish the migration automatically.")
    C_UI.Reload()
end

function WQA:ShowWQAMigrationPrompt(force)
    local state = GetMigrationState()

    if not force and type(state) == "table" then
        if state.completed or state.dismissed or state.pending then
            return
        end
    end

    if not C_AddOns.DoesAddOnExist(OLD_ADDON) then
        if force then
            print("|cff00ccffWQA Turbo|r: WQAchievements is not installed.")
            print("Install or restore it first, then run |cffffffff/wqat import|r.")
        end
        return
    end

    StaticPopup_Show("WQATURBO_IMPORT_WQA")
end

function WQA:MaybeOfferWQAMigration()
    local state = GetMigrationState()

    if self._wqaMigrationImportedThisLoad then
        print("|cff00ccffWQA Turbo|r: WQAchievements settings imported successfully.")
        print("|cff00ccffWQA Turbo|r: Import complete. A UI reload is recommended to fully unload WQAchievements.")

        -- Clear this before ReloadUI so the final session does not reload
        -- again. WQAchievements has already been disabled for this character.
        state = GetMigrationState()
        if type(state) == "table" then
            state.cleanupReload = false
        end

        StaticPopup_Show("WQATURBO_MIGRATION_RELOAD")
        return
    end

    if type(state) == "table" and state.failed then
        print("|cff00ccffWQA Turbo|r: Settings migration could not read WQAchievements' SavedVariables.")
        print("Make sure WQAchievements can load, then run |cffffffff/wqat import|r to retry.")
        state.failed = nil
        state.failureReason = nil
        return
    end

    self:ShowWQAMigrationPrompt(false)
end

StaticPopupDialogs["WQATURBO_MIGRATION_RELOAD"] = {
    text = "WQAchievements settings were imported successfully.\n\nWQAchievements has been disabled. Reload the UI now to fully unload the old addon?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function()
        -- Reload is protected and must be called directly from a hardware
        -- event. StaticPopup button clicks satisfy that requirement.
        C_UI.Reload()
    end,
    OnCancel = function()
        print("|cff00ccffWQA Turbo|r: Migration is complete. WQAchievements will be fully unloaded on your next UI reload or login.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}
StaticPopupDialogs["WQATURBO_IMPORT_WQA"] = {
    text = "WQA Turbo found WQAchievements.\n\nImport its settings into WQA Turbo?\n\nThis replaces your current WQA Turbo settings. WQAchievements will be disabled for this character after the import.",
    button1 = "Import",
    button2 = "Not now",
    OnAccept = function()
        WQATurbo:StartWQAMigration()
    end,
    OnCancel = function()
        WQATurbo:DismissWQAMigrationOffer()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
