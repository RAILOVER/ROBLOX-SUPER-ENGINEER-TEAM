--!strict
-- Ecran de chargement minimal: ReplicatedFirst est le seul endroit qui s'execute avant la replication complete.
local ReplicatedFirst = game:GetService("ReplicatedFirst")

ReplicatedFirst:RemoveDefaultLoadingScreen()
