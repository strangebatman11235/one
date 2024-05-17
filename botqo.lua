-- Random Mover Bot
LatestGameState = LatestGameState or nil
InAction = InAction or false
Logs = Logs or {}

colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    reset = "\27[0m",
    gray = "\27[90m"
}

function addLog(msg, text)
    Logs[msg] = Logs[msg] or {}
    table.insert(Logs[msg], text)
end

function moveRandomly()
    local randomX = math.random(0, LatestGameState.GameWidth)
    local randomY = math.random(0, LatestGameState.GameHeight)
    ao.send({ Target = Game, Action = "Move", Player = ao.id, X = randomX, Y = randomY })
end

function attackNearestEnemy()
    local nearestEnemy = findNearestEnemy()

    if nearestEnemy then
        local attackEnergy = LatestGameState.Players[ao.id].energy
        print(colors.red .. "Attacking nearest enemy with energy: " .. attackEnergy .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerAttack", Player = ao.id, AttackEnergy = tostring(attackEnergy) })
        InAction = false
    end
end

function decideNextAction()
    if not InAction then
        InAction = true
        moveRandomly()
        attackNearestEnemy()
    end
end

Handlers.add("PrintAnnouncements", Handlers.utils.hasMatchingTag("Action", "Announcement"), function(msg)
    if (msg.Event == "Tick" or msg.Event == "Started-Game") and not InAction then
        InAction = true
        ao.send({ Target = Game, Action = "GetGameState" })
    elseif InAction then
        print("Previous action still in progress. Skipping.")
    end

    print(colors.green .. msg.Event .. ": " .. msg.Data .. colors.reset)
end)

Handlers.add("GetGameStateOnTick", Handlers.utils.hasMatchingTag("Action", "Tick"), function()
    if not InAction then
        InAction = true
        print(colors.gray .. "Getting game state..." .. colors.reset)
        ao.send({ Target = Game, Action = "GetGameState" })
    else
        print("Previous action still in progress. Skipping.")
    end
end)

Handlers.add("UpdateGameState", Handlers.utils.hasMatchingTag("Action", "GameState"), function(msg)
    local json = require("json")
    LatestGameState = json.decode(msg.Data)
    ao.send({ Target = ao.id, Action = "UpdatedGameState" })
    print("Game state updated.")
    decideNextAction()
end)

Handlers.add("decideNextAction", Handlers.utils.hasMatchingTag("Action", "UpdatedGameState"), function()
    if LatestGameState.GameMode ~= "Playing" then
        print("Game not started")
        InAction = false
        return
    end
    decideNextAction()
    ao.send({ Target = ao.id, Action = "Tick" })
end)
