-- Sneak Peek: shows the next card of the deck.

SNEAKPEEK = SNEAKPEEK or {}

---------------------------------------------------------------
-- Joker
---------------------------------------------------------------

SMODS.Joker {
    key = 'sneakpeek',
    rarity = 2,
    cost = 3,
    discovered = true,
    unlocked = true,
    blueprint_compat = false,

    loc_vars = function(self, info_queue, card)
        local text = SNEAKPEEK.describe()
        if text == "" then return {} end
        return { key = self.key .. '_active', vars = { text } }
    end,

    update = function(self, card, dt)
        if G.STAGE ~= G.STAGES.RUN then return end
        if not (G.jokers and card.area == G.jokers) then return end

        local top = SNEAKPEEK.next_card()
        local id = top and top.sort_id or 0

        if card.peekdeck_last_id ~= id then
            card.peekdeck_last_id = id
            if card.states.hover.is then
                card:stop_hover()
                card:hover()
            end
        end
    end,
}

---------------------------------------------------------------
-- Voucher
---------------------------------------------------------------

SMODS.Voucher {
    key = 'sneakpeek',
    discovered = true,
    unlocked = true,

    redeem = function(self, card)
        sendInfoMessage("Voucher redeemed", "SneakPeek")
    end,
}

-- How far the card sticks out above the pile, in game units
-- (G.CARD_H is ~3.2).
SNEAKPEEK.offset_y = 0.7
SNEAKPEEK.offset_x = 0.1

SNEAKPEEK.revealed = nil -- the card the game will draw next

-- Computed once per frame, so Card:draw only has to compare two references.
local game_update_ref = Game.update
function Game:update(dt)
    game_update_ref(self, dt)
    if SNEAKPEEK.voucher_active() and SNEAKPEEK.can_peek() then
        SNEAKPEEK.revealed = SNEAKPEEK.next_card()
    else
        SNEAKPEEK.revealed = nil
    end
end

local function each_child(card, fn)
    for _, child in pairs(card.children) do
        if type(child) == 'table' and child.VT then fn(child) end
    end
end

local function freeze(card, offset_x, offset_y)
    local saved = {
        y = card.VT.y,
        x = card.VT.x,
        r = card.VT.r,
        ambient_tilt = card.ambient_tilt,
        facing = card.facing,
        sprite_facing = card.sprite_facing,
        children = {},
    }
    each_child(card, function(c)
        saved.children[c] = { y = c.VT.y, x = c.VT.x, r = c.VT.r }
        c.VT.y = c.VT.y - offset_y
        c.VT.x = c.VT.x - offset_x
        c.VT.r = 0
    end)
    card.VT.y = card.VT.y - offset_y
    card.VT.x = card.VT.x - offset_x
    card.VT.r = 0
    card.ambient_tilt = 0
    card.facing, card.sprite_facing = 'front', 'front'
    return saved
end

local function unfreeze(card, saved)
    for c, s in pairs(saved.children) do
        c.VT.y, c.VT.x, c.VT.r = s.y, s.x, s.r
    end
    card.VT.y = saved.y
    card.VT.x = saved.x
    card.VT.r = saved.r
    card.ambient_tilt = saved.ambient_tilt
    card.facing, card.sprite_facing = saved.facing, saved.sprite_facing
end


-- After the deck is drawn, draw the revealed card again, face up and shifted up.
local cardarea_draw_ref = CardArea.draw
function CardArea:draw()
    local card = SNEAKPEEK.revealed
    if self ~= G.deck or not card then
        return cardarea_draw_ref(self)
    end

    -- Draw the face-up copy first: the pile is drawn over it,
    -- so only the lifted strip sticks out above the deck.
    local saved = freeze(card, SNEAKPEEK.offset_x, SNEAKPEEK.offset_y)
    card:draw()
    unfreeze(card, saved)

    cardarea_draw_ref(self)
end

---------------------------------------------------------------
-- Utilities
---------------------------------------------------------------

function SNEAKPEEK.next_card()
    if not (G and G.deck and G.deck.cards and #G.deck.cards > 0) then
        return nil
    end
    return G.deck.cards[#G.deck.cards]
end

function SNEAKPEEK.describe()
    if not SNEAKPEEK.can_peek() then return "" end

    local card = SNEAKPEEK.next_card()
    if not card then return "" end

    if card.ability and card.ability.effect == 'Stone Card' then
        return "Stone Card"
    end

    return card.base.name
end

-- True when the next card may be shown (in a run, in a blind, deck not empty).
function SNEAKPEEK.can_peek()
    if G.STAGE ~= G.STAGES.RUN then return false end
    if not (G.GAME and G.GAME.blind and G.GAME.blind.in_blind) then return false end
    return SNEAKPEEK.next_card() ~= nil
end

function SNEAKPEEK.voucher_active()
    return (G.GAME and G.GAME.used_vouchers and G.GAME.used_vouchers['v_sneakpeek_sneakpeek']) and true or false
end
