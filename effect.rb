require 'gosu'

class Effect
    attr_accessor :count, :over
    def initialize(sound_file, lifetime = 10)
        @sound = sound_file ? Gosu::Sample.new(sound_file) : nil
        @sound.play(volume=1, speed=1, looping=false) if @sound
        @count = 0
        @lifetime = lifetime
        @over = false
        @additionalEffectArr = nil
    end

    def update(mouse_locations)
        @count += 1
        if @count >= @lifetime
            execute()
            @over = true
        end
    end

    def execute()
    end

    def draw(times, mouse_x, mouse_y)
    end

    def addEffects(effect)
        @additionalEffectArr = [] if !@additionalEffectArr
        @additionalEffectArr.append(effect)
    end

    def additionalEffectArr
        @additionalEffectArr
    end
end

class NopEffect < Effect
    def initialize
        super(nil, 50)
    end
end

class UseManaEffect < Effect
    def initialize(ply, cost)
        super(nil) #super("./sounds/mana.mp3")
        @ply = ply
        @cost = cost
    end

    def execute()
        @ply.mana -= @cost
    end
end

class SlayedEffect < Effect
    def initialize(target)
        super("./sounds/slayed.mp3")
        @image = Gosu::Image.new("./images/slayed.png")
        @target = target
    end

    def draw(times, mouse_x, mouse_y)
        x, y, w, h = @target.bb
        rad = 2 * Math::PI * (times.to_i % 200) / 200.0
        angle = 30 * Math.sin(rad)
        scale_x = w / @image.width.to_f
        scale_y = h / @image.height.to_f
        @image.draw_rot(x + w / 2, y + h / 2, 0, angle, 0.5, 0.5, scale_x, scale_y)
    end
end

class ShieldEffect < Effect
    def initialize(ply, buff)
        super("./sounds/buff.mp3")
        @ply = ply
        @buff = buff
    end

    def execute()
        @ply.defence += @buff
    end
end

class SwordEffect < Effect
    def initialize(ply, target, atk)
        super("./sounds/sword.mp3")
        @ply = ply
        @target = target
        @atk = atk
    end

    def execute()
        if @target.life > 0
            atk = @atk
            atk = atk / 2 if @ply.slackenerPeriod > 0 && atk >= 2
            dmg = [0, atk - @target.defence].max
            @target.defence = [0, @target.defence - atk].max
            @target.life = [0, @target.life - dmg].max

            addEffects(SlayedEffect.new(@target)) if @target.life == 0
        end
    end
end

class CandleFlameEffect < Effect
    def initialize(ply, target, atk)
        super("./sounds/flame.mp3")
        @ply = ply
        @target = target
        @atk = atk
    end

    def execute()
        if @target.life > 0
            atk = @atk
            atk = atk / 2 if @ply.slackenerPeriod > 0 && atk >= 2
            dmg = [0, atk - @target.defence].max
            @target.defence = [0, @target.defence - atk].max
            @target.life = [0, @target.life - dmg].max

            addEffects(SlayedEffect.new(@target)) if @target.life == 0
        end
    end
end

class WinEffect < Effect
    def initialize
        super("./sounds/win.mp3")
    end
end

class LoseEffect < Effect
    def initialize
        super("./sounds/lose.mp3")
    end
end
