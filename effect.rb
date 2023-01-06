require 'gosu'

class Effect
    attr_accessor :count, :over
    def initialize(sound_file, lifetime = 10)
        @sound = sound_file ? Gosu::Sample.new(sound_file) : nil
        @sound.play(volume=1, speed=1, looping=false) if @sound
        @bb = nil
        @image = nil
        @sub_images = nil
        @sub_w = nil
        @sub_h = nil
        @sub_per_count = 1.0
        @count = 0
        @lifetime = lifetime
        @over = false
        @additionalEffectArr = nil
    end

    def setImage(image_file, sub_w, sub_h, sub_per_count = 1.0)
        @image = Gosu::Image.new(image_file)
        @sub_w = sub_w
        @sub_h = sub_h
        @sub_per_count = sub_per_count

        nx = (@image.width / @sub_w).to_i
        ny = (@image.height / @sub_h).to_i

        @sub_images = []
        ny.times {|i|
            nx.times{|j|
                @sub_images.append(@image.subimage(@sub_w * j, @sub_h * i, @sub_w, @sub_h))
            }
        }
    end

    def setBoundingBox(bb)
        @bb = bb
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
        if @sub_images && @bb
            i = (@count * @sub_per_count).to_i
            return if i >= @sub_images.length

            x, y, w, h = @bb
            image = @sub_images[i]
            image.draw(x, y, 0, w / image.width.to_f, h / image.height.to_f)
        end
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
        super("./sounds/buff.mp3", 20)
        @ply = ply
        @buff = buff
        setImage("./effects/shield.png", 192, 192, 0.5)
        setBoundingBox(@ply.bb)
    end

    def execute()
        @ply.defence += @buff
    end
end

class SwordEffect < Effect
    def initialize(ply, target, atk)
        super("./sounds/sword.mp3", 20)
        @ply = ply
        @target = target
        @atk = atk
        setImage("./effects/sword.png", 192, 192, 0.5)
        setBoundingBox(@target.bb)
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

class FlameEffect < Effect
    def initialize(ply, target, atk)
        super("./sounds/flame.mp3", 20)
        @ply = ply
        @target = target
        @atk = atk
        setImage("./effects/flame.png", 192, 192, 0.5)
        setBoundingBox(@target.bb)
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

class HellFlameEffect < Effect
    def initialize(ply, target, atk)
        super("./sounds/hell_flame.mp3", 40)
        @ply = ply
        @target = target
        @atk = atk
        setImage("./effects/hell_flame.png", 192, 192, 0.5)
        setBoundingBox(@target.bb)
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
        super("./sounds/win.mp3", 100)
    end
end

class LoseEffect < Effect
    def initialize
        super("./sounds/lose.mp3", 100)
    end
end
