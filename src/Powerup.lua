--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Heikki Mattila

    Represents a powerup item which will decend gradually. It can be hit by 
    the player's paddle.
]]

Powerup = Class{}

function Powerup:init(item)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.item = item
    
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2

    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis
    self.dy = 20
    self.dx = 0

end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the item in the middle of the screen, with no movement.
]]
function Powerup:reset()
    self.x = math.random(4, VIRTUAL_WIDTH-20)
    self.y = 0 
    self.dx = 0
    self.dy = 20
end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow the item to bounce off walls
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.item],
        self.x, self.y)
end
