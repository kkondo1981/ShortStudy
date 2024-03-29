require 'gosu'

class Player
	attr_accessor :name, :life, :maxLife, :defence, :poison, :slackenerPeriod, :hand, :mana, :maxMana, :image, :bb, :targetable
	def initialize(name)
		@name = name
		@maxLife = 0
		@defence = 0
		@poison = 0
        @slackenerPeriod = 0    #筋弛緩状態のターン数
        @initMana = 3	#戦闘開始時のマナ数
		@initDeck = []
		@deck = []
		@hand = []
		@discardPile = []
		@initNumofHandCard = 0
		@initNumOfDrawCard = 4
		@bb = nil # boundiing box
		@y_add_period = 1000
		@name_font = Gosu::Font.new(20, {bold: true})
		@status_font = Gosu::Font.new(18)
		@draw_card = "below"
		@targetable = false
		@state = nil
		@image_dead = Gosu::Image.new("./images/grave.png")
	    case name
        when 'TestPlayer'
            @initNumOfDrawCard = 20
			@maxLife = 1000
            @initDeck.append(Card.new('Sword'))
            @initDeck.append(Card.new('Sword'))
            @initDeck.append(Card.new('Sword'))
            @initDeck.append(Card.new('Sword'))
            @initDeck.append(Card.new('Slackener1'))
            @initDeck.append(Card.new('Slackener2'))
#            @initDeck.append(Card.new('Wand'))
            @initDeck.append(Card.new('Shield'))
            @initDeck.append(Card.new('Shield'))
            @initDeck.append(Card.new('Shield'))
            @initDeck.append(Card.new('Shield'))
#            @initDeck.append(Card.new('MercyLight'))
#            @initDeck.append(Card.new('DivideBy2'))
#            @initDeck.append(Card.new('DivideBy3'))
#            @initDeck.append(Card.new('CandleFlame'))
#            @initDeck.append(Card.new('Flame'))
#            @initDeck.append(Card.new('HellFlame'))
        when 'Fighter'
			@maxLife = 50
			6.times do
				@initDeck.append(Card.new('Sword'))
			end
			4.times do
				@initDeck.append(Card.new('Shield'))
			end
			@image = Gosu::Image.new("./images/fighter.png")
			@y_add_period = 200
			@draw_card = "right"
        when 'Healer'
			@maxLife = 50
			4.times do
				@initDeck.append(Card.new('Wand'))
			end
			4.times do
				@initDeck.append(Card.new('Shield'))
			end
			2.times do
				@initDeck.append(Card.new('MercyLight'))
			end
			@y_add_period = 200
			@draw_card = "right"
        when 'A Ghost'
			@maxLife = 53
			@initMana = 1
			@initNumofHandCard = 0
			@initNumOfDrawCard = 1
			1.times do
				@initDeck.append(Card.new('Flame'))
			end
			@image = Gosu::Image.new("./images/ghost.png")
        when 'A Tiny Ghost'
			@maxLife = 15
			@initMana = 1
			@initNumofHandCard = 0
			@initNumOfDrawCard = 1
			1.times do
				@initDeck.append(Card.new('CandleFlame'))
			end
			@image = Gosu::Image.new("./images/tiny_ghost.png")
		when 'The King of Ghost'
			@maxLife = 101
			@initMana = 1
			@initNumofHandCard = 0
			@initNumOfDrawCard = 1
			1.times do
				@initDeck.append(Card.new('Flame'))
			end
			1.times do
				@initDeck.append(Card.new('HellFlame'))
			end
			@image = Gosu::Image.new("./images/king_ghost.png")
		end
		@life = @maxLife

		if !@image
			@image = Gosu::Image.new("./images/nil.png")
		end
	end
	def setBoundingBoxes(x, y, w, h)
		@bb = [x, y, w, h]
		x0, y0 = x, y

		y += h
		y += @name_font.height # for a name line
		y += @status_font.height # for a status line
		y += @status_font.height # for a field line
		
		if @draw_card == "right"
			x = x0 + w + 10
			y = y0
		end

		@hand.each_with_index {|crd, i|
			tw, th = crd.calcSize
			crd.bb = [x, y, tw, th]
			y += th
		}
	end
	def drawImage(times, mouse_x, mouse_y)
		return if !@bb

		image = @life > 0 ? @image : @image_dead

		x, y, w, h = @bb

		x0 = x
		y0 = y

		rad = 2 * Math::PI * ((times.to_i % @y_add_period) / @y_add_period.to_f)
		y_add = @life > 0 ? 10 * Math.sin(rad) : 0
		scale_x = w.to_f / image.width
		scale_y = h.to_f / image.height

		if @targetable || @state == "selected"
			alpha = 0x40 + 2 * y_add
            color = Gosu::Color.argb(alpha, 0xE0, 0xFF, 0xFF)
            Gosu.draw_rect(x, y, w, h, color)
        end

		image.draw(x, y + y_add, 0, scale_x, scale_y)
	
		y += h
		@name_font.draw_text(name, x, y, 0, 1, 1, 0xFF_FFC0CB)
		y += @name_font.height
		@status_font.draw_text(short_status_txt, x, y, 0, 1, 1, 0xFF_F0F0F0)
		y += @status_font.height
		@status_font.draw_text(short_field_txt, x, y, 0, 1, 1, 0xFF_F0F0F0)
		y += @status_font.height

		@hand.each_with_index {|crd, i|
			crd.drawImage(times, mouse_x, mouse_y)
		}
	end
	def battlePrep
		@maxMana = @initMana	#戦闘中でターン開始時のマナ数
		@mana = @maxMana
        @defence = 0
		@poison = 0
        @slackenerPeriod = 0
		@deck = @initDeck.dup
		@numOfHandCard = @initNumofHandCard
		@numOfDrawCard = @initNumOfDrawCard
		@deck.shuffle!
		@hand = []
		@discardPile = []
		@numOfHandCard.times do
			self.draw
		end
	end
	def turnBegin
		@mana = @maxMana
		@defence = 0
		@numOfDrawCard.times do
			self.draw
		end
	end
	def turnEnd
        if @poison > 0
			puts @name + " の体を毒が蝕んでいく。" + @name + " は " + @poison.to_s + " のダメージを受け、lifeが " + (@life - @poison).to_s + " に減少。"
			@life = @life - @poison
			@poison = @poison - 1
		end
		if @slackenerPeriod > 0
            @slackenerPeriod = @slackenerPeriod - 1
        end
		@hand.each do |crd|
			@discardPile.append(crd)
		end
		@hand = []
	end
	def draw
		if @deck.length == 0
			@deck = @discardPile.dup.shuffle!
			@discardPile = []
		end
		if @deck.length > 0
			@hand.append(@deck.shift)
		end
	end
	def discard(n)
		@discardPile.append(@hand.delete_at(n))
	end
	def discardByCard(crd)
		idx = -1
		@hand.each_with_index{|c, i|
			if c == crd
				idx = i
				break
			end
		}
		discard(idx) if idx >= 0
	end
	def status_txt
		@name + ' [Life ' + @life.to_s + ', Defence ' + @defence.to_s + ', Mana ' + @mana.to_s + '/' + @maxMana.to_s + ', Deck ' + @deck.length.to_s + ', Discard ' + @discardPile.length.to_s + ']'
	end
	def short_status_txt
		s = 'L:' + @life.to_s + ' D:' + @defence.to_s + ' M:' + @mana.to_s + '/' + @maxMana.to_s
		if @slackenerPeriod > 0
			s += ' S:' + @slackenerPeriod.to_s
		end
		s
	end
	def short_field_txt
		'Deck:' + @deck.length.to_s + ', Discard:' + @discardPile.length.to_s
	end
	def disp
		puts status_txt
        if @slackenerPeriod > 0
            puts 'Slackened in ' + @slackenerPeriod.to_s + ' turn'
        end
		i = 0
		@hand.each do |crd|
			i = i + 1
			puts "\t<" + i.to_s + "> " + crd.text
		end
	end
	def playable
		minHandCardCost = 10000
		@hand.each do |crd|
			if crd.cost < minHandCardCost
				minHandCardCost = crd.cost
			end
		end
		@life > 0 && @mana >= minHandCardCost
	end
	def select
        @state = "selected"
    end
    def release
        @state = nil
    end
end