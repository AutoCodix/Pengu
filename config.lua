--[[ Pengu config — pure settings. Sliders only write numbers here. ]]
local Config = {}

Config.Name = "Pengu"
Config.Version = "0.4.0"

-- Player
Config.SpeedEnabled = false
Config.WalkSpeed = 16
Config.JumpEnabled = false
Config.JumpPower = 50
Config.Flight = false
Config.FlightSpeed = 50
Config.CharSpin = false
Config.SpinSpeed = 12
Config.Noclip = false
Config.InfJump = false

-- Super Strength / Line (config only until RMB)
Config.SuperStrength = false
Config.StrengthValue = 400
Config.ThrowMult = 3.5
Config.FlingUp = false
Config.Slam = false
Config.VoidFling = false
Config.SpinFling = false
Config.GrabReach = false
Config.MaxGrabReach = 30
Config.ExtendLine = false
Config.ExtendSpeed = 1

-- Grab modes (applied with grab pipeline / RMB where relevant)
Config.GrabMode = "None" -- None|Invisible|Kill|Void|Kick|Spin|Fling|TeleportSpawn|Unstick
Config.ToggleGrabs = false

-- Auras
Config.FlingAura = false
Config.RagdollAura = false
Config.SitAura = false
Config.SpinAura = false
Config.BringAura = false
Config.VoidAura = false
Config.AuraRange = 25
Config.AuraCD = 0.4
Config.AuraMax = 3
Config.AuraIgnoreFriends = true
Config.ShowAuraRadius = false

-- Target
Config.NearestTarget = false
Config.TargetLock = false
Config.DistLimit = 200
Config.FriendWL = true

-- Blobman
Config.BlobLoop = false
Config.BlobGrabAll = false
Config.BlobAutoSit = false
Config.BlobFreeze = false

-- Defense
Config.AntiGrab = false
Config.AntiGrabGucci = false
Config.AntiGucci = false
Config.AntiGucciMode = "Normal"
Config.AntiGucciInterval = 0.15
Config.AntiGucciEmergencyOnly = true
Config.AntiBlobman = false
Config.AntiRagdoll = false
Config.InstantGetUp = false
Config.AntiSit = false
Config.AntiVoid = false
Config.DisableVoid = false
Config.AntiFling = false
Config.AntiBurn = false
Config.AntiLag = false
Config.AutoAntiLag = true
Config.AntiSticky = false
Config.AntiBanana = false
Config.AntiPaint = false
Config.AntiSnowball = false
Config.AntiPoison = false
Config.AntiExplosion = false
Config.AntiKick = false
Config.AntiInvis = false
Config.AutoReset = false
Config.NoclipBarrier = false
Config.CounterAttack = false
Config.CounterMode = "Fling"
-- UNSUPPORTED
Config.AntiNetworkOwnership = false
Config.NetOwnerSpam = false
Config.BreakPCLD = false

-- Camera (native third person via PlayerController)
Config.ThirdPerson = false
Config.TPDistance = 8
Config.TPMinZoom = 0.5
Config.TPMaxZoom = 32
Config.FOV = 70

-- Visual
Config.PlayerESP = false
Config.DistESP = false
Config.HealthESP = false
Config.TargetESP = false
Config.Rainbow = false
Config.ESPMaxDist = 400

-- World
Config.Fullbright = false
Config.NoFog = false
Config.NoShadows = false
Config.CustomTime = false
Config.ClockTime = 14

-- Lists
Config.WhitelistEnabled = true
Config.AutoWLFriends = true

-- UI
Config.RainbowUI = false
Config.MenuKey = Enum.KeyCode.RightControl
Config.SkipIntro = false
Config.NotifEnabled = true
Config.Accent = Color3.fromRGB(119, 0, 255)

return Config
