--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    
    self.powerup = Powerup(3)
    self.brickKey = Powerup(10)

    self.recoverPoints = self.score + 10000
    self.paddleIncreasePoints = self.score + 5000

    -- give ball random starting velocity
    for k, ball in pairs(self.balls) do 
    ball.dx = math.random(-200, 200)
    ball.dy = math.random(-50, -60)
    end
    
    self.powerupFlag = false -- is powerup item visible
    self.powerupTimer = 0 
    self.powerupTarget = math.random(10, 30) -- seconds
    
    self.brickKeyFlag = false -- is brickKey item visible
    self.brickKeyTimer = 0 
    self.brickKeyTarget = math.random(30, 60) -- seconds
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    for k, ball in pairs(self.balls) do 
    	ball:update(dt)
    end
    
    --POWERUP
    -- powerup timer update
    self.powerupTimer = self.powerupTimer + dt
    -- if time is up create a powerup item
    if self.powerupTimer > self.powerupTarget then
    	self.powerupTarget = self.powerupTarget * 100
    	self.powerupFlag = true
    	self.powerup:reset()
    end
    -- if powerup item goes below bounds, remove it
    if self.powerup.y >= VIRTUAL_HEIGHT then
    	self.powerupFlag = false
    end
    
    -- if powerup item collide with paddle
    if self.powerupFlag and self.powerup:collides(self.paddle) then
        -- remove item ie. set flag false
        self.powerupFlag = false
        -- add two more balls
        for i = 1, 2 do 
		b = Ball(1)
		b = Ball(1)
		b.x = self.powerup.x
		b.dx = math.random(-200, 200)
		b.y = self.paddle.y - 8
		b.dy = math.random(-50, -60)
		b.skin = math.random(7)
		table.insert(self.balls, b)
        end
    end
    if self.powerupFlag then
    	self.powerup:update(dt)
    end
    
    --BRICKKEY
    -- brickKey timer update
    self.brickKeyTimer = self.brickKeyTimer + dt
    -- if time is up create a brickKey item
    if self.brickKeyTimer > self.brickKeyTarget then
    	self.brickKeyTarget = self.brickKeyTarget * 100
    	self.brickKeyFlag = true
    	self.brickKey:reset()
    end
    -- if brickKey item goes below bounds, remove it
    if self.brickKey.y >= VIRTUAL_HEIGHT then
    	self.brickKeyFlag = false
    end
    
    -- if brickKey item collide with paddle
    if self.brickKeyFlag and self.brickKey:collides(self.paddle) then
        -- remove item ie. set flag false
        self.brickKeyFlag = false
        -- remove brickLocks
        for k, brick in pairs(self.bricks) do
		brick.locked = false
        end
    end
    if self.brickKeyFlag then
    	self.brickKey:update(dt)
    end
    
    
    
    -- if ball collides with paddle
    for k, ball in pairs(self.balls) do     
    if ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
        end

        gSounds['paddle-hit']:play()
    end
    end
    
    -- detect collision across all bricks with the ball
    for k, ball in pairs(self.balls) do 
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then
	    if not brick.locked then
            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end
            
            -- if we have enough points, increase the size of paddle
            if self.score > self.paddleIncreasePoints then
                self.paddle:increaseSize()
                self.paddleIncreasePoints = 2 * self.paddleIncreasePoints

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()
                
                self.balls[1].inPlay = true

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.balls[1],
                    recoverPoints = self.recoverPoints
                })
            end
	    end
            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ball.x + 2 < brick.x and ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
    end

    -- if ball goes below bounds,ball is out
    for k, ball in pairs(self.balls) do 
    	if ball.y >= VIRTUAL_HEIGHT then
    		ball.inPlay = false
    	end
    end
    
    -- if all balls are out, revert to serve state and decrease health	
    if self:checkLost() then
        self.health = self.health - 1
        self.paddle:decreaseSize()
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render powerup item
    if self.powerupFlag then
    	self.powerup:render()
    end
    
    -- render brickKey item
    if self.brickKeyFlag then
    	self.brickKey:render()
    end
    
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    
    for k, ball in pairs(self.balls) do 
    	ball:render()
    end 
    
    
    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

function PlayState:checkLost()
    for k, ball in pairs(self.balls) do
        if ball.inPlay then
            return false
        end 
    end

    return true
end
