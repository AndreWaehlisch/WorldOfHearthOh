local addonName, addonTable = ...;

local AceLibs = { "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0",  "AceHook-3.0", "AceSerializer-3.0", "AceTimer-3.0", };

WoHo = LibStub("AceAddon-3.0"):NewAddon(addonName, unpack(AceLibs));