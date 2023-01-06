require 'gosu'
require './effect.rb'

class Card
    attr_accessor :name, :targetType, :cost, :text, :bb, :selected, :playable, :effect
    def initialize(name)
		@name = name
		@targetType = ''	#me, player, allplayer, otherplayer, allotherplayer, enemy, allenemy, allother, all, card
        @cost = 1
        @atk = 0
        @defence = 0
		@heal = 0
        @divisor = 0
        @poison = 0
        @poisonMultiplier = 0
        @slackenerPeriod = 0
        @text = ''
        @bb = nil
        @playable = true
        @font = Gosu::Font.new(16)
        @state = nil
	    case name
        #For Player
        #damage
        when 'Sword'
			@targetType = 'enemy'
            @atk = 10
            @text = @name + " [atk " + @atk.to_s + "] [" + @cost.to_s + "]"
        when 'Wand'
			@targetType = 'enemy'
            @atk = 3
            @text = @name + " [atk " + @atk.to_s + "] [" + @cost.to_s + "]"
        when 'DivideBy2'
			@targetType = 'enemy'
            @divisor = 2
            @cost = 3
            @text = @name + " [The opponent's life will be divided by 2 when it can be] [" + @cost.to_s + "]"
        when 'DivideBy3'
			@targetType = 'enemy'
            @divisor = 3
            @cost = 3
            @text = @name + " [The opponent's life will be divided by 3 when it can be] [" + @cost.to_s + "]"
        #heal
        when 'MercyLight'
			@targetType = 'otherplayer'
            @heal = 10
			@cost = 2
            @text = @name + " [heal " + @heal.to_s + "] [" + @cost.to_s + "]"
        #defence
        when 'Shield'
			@targetType = 'me'
            @defence = 8
            @text = @name + " [def " + @defence.to_s + "] [" + @cost.to_s + "]"
        #poison
        when 'Poison'
            @targetType = 'enemy'
            @poison = 4
            @text = @name + " [poison " + @poison.to_s + "] [" + @cost.to_s + "]"
        when 'PoisonDouble'
            @targetType = 'enemy'
            @poisonMultiplier = 2
            @cost = 2
            @text = @name + " [The opponent's poison will be doubled] [" + @cost.to_s + "]"
        #slackener
        when 'Slackener1'
            @targetType = 'enemy'
            @slackenerPeriod = 1
            @cost = 2
            @text = @name + " [reduce 50% of atk in " + @slackenerPeriod.to_s + " turn] [" + @cost.to_s + "]"
        when 'Slackener2'
            @targetType = 'enemy'
            @slackenerPeriod = 2
            @cost = 3
            @text = @name + " [reduce 50% of atk in " + @slackenerPeriod.to_s + " turn] [" + @cost.to_s + "]"
        #For Enemy
        when 'CandleFlame'
			@targetType = 'enemy'
            @atk = 6
            @text = @name + " [atk " + @atk.to_s + "] [" + @cost.to_s + "]"
        when 'Flame'
			@targetType = 'enemy'
            @atk = 12
            @text = @name + " [atk " + @atk.to_s + "] [" + @cost.to_s + "]"
        when 'HellFlame'
			@targetType = 'enemy'
            @atk = 20
            @text = @name + " [atk " + @atk.to_s + "] [" + @cost.to_s + "]"
        end
    end
    def createEffect(player, targetArr)
        effectArr = [UseManaEffect.new(player, @cost)]
        targetArr.each do |target|
            if @atk != 0
                case @name
                when 'Sword'
                    effectArr.append(SwordEffect.new(player, target, @atk))
                when 'CandleFlame'
                    effectArr.append(CandleFlameEffect.new(player, target, @atk))
                end
            end
			if @defence != 0
                effectArr.append(ShieldEffect.new(target, @defence))
			end
        end
        effectArr
    end
	def play(player, targetArr)
		targetArr.each do |target|
			if @atk != 0
				#死者はスキップ
				if target.life > 0
                    if player.slackenerPeriod > 0 && @atk >= 2
                        atk = @atk / 2
                    else
                        atk = @atk
                    end
					if target.defence >= atk
						puts player.name + " が " + target.name + " に " + atk.to_s + " の攻撃。" + target.name + " は防御が " + (target.defence - atk).to_s + " に減少。"
						target.defence = target.defence - atk
					else
						puts player.name + " が " + target.name + " に " + atk.to_s + " の攻撃。" + target.name + " のlifeは " + (target.life + target.defence - atk).to_s + " に減少。"
						target.life = target.life + target.defence - atk
						target.defence = 0
					end
                else
                    puts target.name + " は既に死んでいた。"
				end
			end
            if @divisor != 0
                #死者はスキップ
                if target.life > 0
                    if target.life % @divisor == 0
						puts player.name + " が " + target.name + " のlifeを " + @divisor.to_s + " で除算攻撃。" + target.name + " のlifeは " + (target.life / @divisor).to_s + " に減少。"
                        target.life = target.life / @divisor
                    end
                else
                    puts target.name + " は既に死んでいた。"
                end
            end
			if @heal != 0
				#死者はスキップ
				if target.life > 0
                    #既にターゲットのlifeが最大値になっていればスキップ
                    if target.life < target.maxLife
                        if target.life + @heal > target.maxLife
                            puts player.name + " が " + target.name + " のlifeを " + (target.maxLife - target.life).to_s + " 回復し、lifeは " + target.maxLife.to_s + " になった。"
                            target.life = target.maxLife
                        else
                            puts player.name + " が " + target.name + " のlifeを " + @heal.to_s + " 回復し、lifeは " + (target.life + @heal).to_s + " になった。"
                            target.life = target.life + @heal
                        end
                    else
                        puts target.name + " のlifeは既に最大値になっていた。"
                    end
                else
                    puts target.name + " は既に死んでいた。"
				end
			end
			if @defence != 0
				puts player.name + " は防御を " + @defence.to_s + " 増加。"
				target.defence = target.defence + @defence
			end
            if @poison != 0
                puts player.name + " が " + target.name + " の毒を " + @poison.to_s + " 増加し、" + (target.poison + @poison).to_s + " になった。"
                target.poison = target.poison + @poison
            end
            if @poisonMultiplier != 0
                #無毒状態はスキップ
                if target.poison != 0
                    puts player.name + " が " + target.name + " の毒を " + @poisonMultiplier.to_s + " 倍にし、" + (target.poison * @poisonMultiplier).to_s + " になった。"
                    target.poison = target.poison * @poisonMultiplier
                else
                    puts target.name + " の体は毒に侵されていなかった。"
                end
            end
            if @slackenerPeriod != 0
                puts player.name + " が " + target.name + " の筋弛緩状態を " + @slackenerPeriod.to_s + " ターン分追加し、" + (target.slackenerPeriod + @slackenerPeriod).to_s + " ターンになった。"
                target.slackenerPeriod = target.slackenerPeriod + @slackenerPeriod
            end
		end
	end
    def calcSize
        [@font.text_width(text), @font.height]
    end
    def select
        @state = "selected"
    end
    def release
        @state = nil
    end
    def drawImage(times, mouse_x, mouse_y)
        x, y, w, h = @bb

        if @state == "selected"
            color = 0x88_EE82EE
            Gosu.draw_rect(x, y, w, h, color)
        end

        over = (x < mouse_x && mouse_x < x + w && y < mouse_y && mouse_y < y + h)
        if !@playable
            color = 0xFF_E6E6FA
        elsif over
            color = 0xFF_00FFFF
        else
            color = 0xFF_AFEEEE
        end

        @font.draw_text(text, x, y, 0, 1, 1, color)
    end
end
