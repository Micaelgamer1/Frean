--[[
    EmotesR6Fix.lua
    Patch standalone para o Emotes.lua (7yd7 | Universal Emote Script)

    NÃO edita o Emotes.lua — basta executar este script DEPOIS dele,
    na mesma sessão do executor, que ele passa a observar o personagem
    e corrige o congelamento em R6.

    -----------------------------------------------------------------
    POR QUE O BONECO CONGELA EM R6
    -----------------------------------------------------------------
    Emotes do catálogo do Roblox são animações feitas exclusivamente
    pro esqueleto R15 (é requisito da própria Roblox pra publicar um
    emote no Marketplace) — elas usam nomes de junta que só existem no
    R15 (UpperTorso, LeftUpperArm etc.).

    Quando o Emotes.lua toca um desses IDs num personagem R6 — seja
    via humanoid:PlayEmoteAndGetAnimTrackById (playRandomEmote) ou via
    Animator:LoadAnimation (playEmote) — a track carrega e entra com
    prioridade Action, o que tira o idle/walk padrão (prioridade
    Idle/Movement) de controle. Só que, como a track não tem keyframe
    pra nenhuma junta do R6, nada se move: o resultado é o boneco preso
    na pose de repouso (T-pose/A-pose "dura"), porque literalmente
    nenhuma animação está controlando o rig.

    Isso é uma limitação do próprio dado do catálogo (feito só pra
    R15) — não dá pra fazer esse emote realmente animar um R6, pois a
    animação não conhece as juntas dele. O que este script resolve de
    verdade é a trava: detecta assim que ela acontece e devolve o
    controle pro idle/walk padrão quase na hora, em vez de deixar o
    boneco preso.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Prioridades que o Emotes.lua usa pra emotes/animações (ver "Action"
-- em playEmote / playRandomEmote / playAnimationPreview no original)
local EMOTE_PRIORITIES = {
    [Enum.AnimationPriority.Action] = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true,
}

local function notify(title, content)
    local ok, genv = pcall(getgenv)
    if ok and genv and genv.Notify then
        pcall(genv.Notify, { Title = title, Content = content, Duration = 4 })
    end
end

local function restoreDefaultAnimate(character)
    local animate = character:FindFirstChild("Animate")
    if animate then
        -- mesmo truque que o próprio Emotes.lua usa internamente pra
        -- forçar o Animate padrão a reinicializar e retomar idle/walk
        animate.Disabled = true
        animate.Disabled = false
    end
end

local function watchCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    humanoid.AnimationPlayed:Connect(function(track)
        if humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end
        if not EMOTE_PRIORITIES[track.Priority] then return end

        -- pequena folga pra track realmente iniciar antes de parar
        task.wait(0.15)

        pcall(function() track:Stop() end)
        restoreDefaultAnimate(character)

        notify(
            "7yd7 | Emote",
            "⚠️ Esse emote é feito só pra R15 e não anima no R6 — idle restaurado"
        )
    end)
end

if player.Character then
    watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)
