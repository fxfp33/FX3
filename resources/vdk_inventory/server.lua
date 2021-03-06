--require "resources/mysql-async/lib/MySQL"

RegisterServerEvent("item:getItems")
RegisterServerEvent("item:updateQuantity")
RegisterServerEvent("item:setItem")
RegisterServerEvent("item:reset")
RegisterServerEvent("item:sell")
RegisterServerEvent("item:sellillegal")
RegisterServerEvent("player:giveItem")
RegisterServerEvent("player:swapMoney")
RegisterServerEvent("player:swapDirtyMoney")
RegisterServerEvent("player:getInfos")

local items = {}

AddEventHandler("item:getItems", function()
    items = {}
    local player = getPlayerID(source)
    -- for i = 0, 23 do
        MySQL.Async.fetchAll("SELECT * FROM user_inventory JOIN items ON `user_inventory`.`item_id` = `items`.`id` WHERE user_id = @username",
        {['@username'] = player },
        function(qItems)
            if (qItems) then
                for _, item in ipairs(qItems) do
                    t = { ["quantity"] = item.quantity, ["libelle"] = item.libelle, ["canUse"] = item.canUse }
                    table.insert(items, tonumber(item.item_id), t)
                end
            end
            TriggerClientEvent("gui:getItems", source, items)
        end)
    -- end
end)

AddEventHandler("item:setItem", function(item, quantity)
    local player = getPlayerID(source)
    MySQL.Async.execute("INSERT INTO user_inventory (`user_id`, `item_id`, `quantity`) VALUES (@player, @item, @qty)",
        {['@player'] = player, ['@item'] = item, ['@qty'] = quantity },
        function(rowsChanged)
            print(rowsChanged)
        end)
end)

AddEventHandler("item:updateQuantity", function(qty, id)
    local player = getPlayerID(source)
    MySQL.Async.execute("UPDATE user_inventory SET `quantity` = @qty WHERE `user_id` = @username AND `item_id` = @id",
    { ['@username'] = player, ['@qty'] = tonumber(qty), ['@id'] = tonumber(id) })
end)

AddEventHandler("item:reset", function()
    local player = getPlayerID(source)
    MySQL.Async.execute("UPDATE user_inventory SET `quantity` = @qty WHERE `user_id` = @username", { ['@username'] = player, ['@qty'] = 0 })
end)

AddEventHandler("item:sell", function(id, qty, price)
    TriggerEvent('es:getPlayerFromId', source, function(user)
        local player = user.identifier
        user:addMoney(tonumber(price))
    end)
end)

AddEventHandler("item:sellillegal", function(id, qty, price)
    TriggerEvent('es:getPlayerFromId', source, function(user)
        local player = user.identifier
        user:addDirty_Money(tonumber(price))
    end)
end)

-- AddEventHandler("player:giveItem", function(item, name, qty, target)
--     local player = getPlayerID(source)
--     local targetid = getPlayerID(target)
--     local executed_query = MySQL:executeQuery("SELECT SUM(quantity) as total FROM user_inventory WHERE user_id = '@username'", { ['@username'] = targetid })
--     local result = MySQL:getResults(executed_query, { 'total' })
--     local total = result[1].total
--     if (total + qty < 64) then
--         TriggerClientEvent("player:looseItem", source, item, qty)
--         TriggerClientEvent("player:receiveItem", target, item, qty)
--         TriggerClientEvent("es_freeroam:notify", target, "CHAR_MP_STRIPCLUB_PR", 1, "System", false, "Vous venez de recevoir " .. qty .. " " .. name)
--         TriggerClientEvent("es_freeroam:notify", source, "CHAR_MP_STRIPCLUB_PR", 1, "System", false, "Vous venez de donner " .. qty .. " " .. name)
--     else
--         TriggerClientEvent("es_freeroam:notify", source, "CHAR_MP_STRIPCLUB_PR", 1, "System", false, "quantité trop grande pour l'inventaire du joueur " .. qty .. " " .. name)
--     end
    
-- end)

AddEventHandler("player:giveItem", function(item, name, qty, target)
    local player = getPlayerID(source)
    local total = 0
    MySQL.Async.fetchAll("SELECT * FROM user_inventory JOIN items ON `user_inventory`.`item_id` = `items`.`id` WHERE user_id = @username",
        {['@username'] = target },
        function(qItems)
            
            if (qItems) then

                for _, item in ipairs(qItems) do
                    total = total + item.quantity
                end
            end
            if (total + qty <= 96) then
                TriggerClientEvent("player:looseItem", source, item, qty)
                TriggerClientEvent("player:receiveItem", target, item, qty)
                TriggerClientEvent("es_freeroam:notify", target, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de recevoir " .. qty .. " " .. name)
                TriggerClientEvent("es_freeroam:notify", source, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de donner " .. qty .. " " .. name)
            end
    end)
    

    
end)

AddEventHandler("player:swapMoney", function(amount, target)
    TriggerEvent('es:getPlayerFromId', source, function(user)
        local player = getPlayerID(source)
        if user.money - amount >= 0 then
            user:removeMoney(amount)
            TriggerEvent('es:getPlayerFromId', target, function(user) user:addMoney(amount) end)
            TriggerClientEvent("es_freeroam:notify", target, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de recevoir " .. amount .. " €")
            TriggerClientEvent("es_freeroam:notify", source, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de donner " .. amount .. " €")
        end
    end)
end)

AddEventHandler("player:swapDirtyMoney", function(amount, target)
    TriggerEvent('es:getPlayerFromId', source, function(user)
        local player = getPlayerID(source)
        if user.dirty_money - amount >= 0 then
            user:removeDirty_Money(amount)
            TriggerEvent('es:getPlayerFromId', target, function(user) user:addDirty_Money(amount) end)
            TriggerClientEvent("es_freeroam:notify", target, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de recevoir " .. amount .. " € en argent sale")
            TriggerClientEvent("es_freeroam:notify", source, "CHAR_MP_STRIPCLUB_PR", 1, "Mairie", false, "Vous venez de donner " .. amount .. " € en argent sale")
        end
    end)
end)
AddEventHandler("player:getInfos", function()
    MySQL.Async.fetchAll("SELECT name, number FROM users WHERE identifier = @player",
    {['@player'] = getPlayerID(source)},
    function(infos)
        nameSplit = stringSplit(infos[1].name, " ")
        local prenom = nameSplit[1]
        local nom = nameSplit[2]
        TriggerClientEvent("player:setInfos", source, prenom, nom, infos[1].number)
    end)
end)

-- get's the player id without having to use bugged essentials
function getPlayerID(source)
    local identifiers = GetPlayerIdentifiers(source)
    local player = getIdentifiant(identifiers)
    return player
end

-- gets the actual player id unique to the player,
-- independent of whether the player changes their screen name
function getIdentifiant(id)
    for _, v in ipairs(id) do
        return v
    end
end

function stringSplit(self, delimiter)
  local a = self:Split(delimiter)
  local t = {}

  for i = 0, #a - 1 do
     table.insert(t, a[i])
  end

  return t
end