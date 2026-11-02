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
-- Utilities
---------------------------------------------------------------

function SNEAKPEEK.next_card()
    if not (G and G.deck and G.deck.cards and #G.deck.cards > 0) then
        return nil
    end
    return G.deck.cards[#G.deck.cards]
end

function SNEAKPEEK.describe()
    if G.STAGE ~= G.STAGES.RUN then return "" end
    if not (G.GAME and G.GAME.blind and G.GAME.blind.in_blind) then return "" end

    local card = SNEAKPEEK.next_card()
    if not card then return "" end

    if card.ability and card.ability.effect == 'Stone Card' then
        return "Stone Card"
    end

    return card.base.name
end
