require 'gosu'

require './chooser.rb'
require './effect.rb'

class GM
	attr_accessor :plyArr, :enmArr, :turn, :state
	def initialize(plyArr, enmArr)
		@plyArr = plyArr
		@enmArr = enmArr
		@effectArr = nil
		@state = nil
		@chooser = nil
		@chosenPlayer = nil
		@chosenCard = nil
		@targetArr = nil
		@turn = nil
		@passed = false
		@message_font = Gosu::Font.new(30, {bold: true})
	end
    def offenceArr
        @turn == "player" ? @plyArr : @enmArr
    end
    def defenceArr
        @turn == "player" ? @enmArr : @plyArr
    end
	def allPlyArr
		@plyArr + @enmArr
	end
	def releaseAll
		allPlyArr.each{|ply|
			ply.release
			ply.hand.each{|crd|
				crd.release
			}
		}
	end
	def setBoundingBoxes
		@enmArr.each_with_index{|enm, i|
			x = 50 + 200 * i
			y = 50
			if enm.name == "The King of Ghost"
				w = h = 150
			else
				w = h = 100
			end
			enm.setBoundingBoxes(x, y, w, h)
		}

		@plyArr.each_with_index{|ply, i|
			x = 50
			y = 300 + 220 * i
			w = h = 150
			ply.setBoundingBoxes(x, y, w, h)
		}
	end
	def draw(times, mouse_x, mouse_y)
		return if !@state

		if @turn == "over"
			message = ""
			case @battleEndFlg
			when "win"
				message = "Player win!!!"
			when "lose"
				message = "Enemy win..."
			when "draw"
				message = "Draw..."
			end
			@message_font.draw_text(message, 5, 5, 0, 1, 1, 0xFF_FFFFFF)
		end

		@enmArr.each_with_index{|enm, i|
			enm.drawImage(times + i * 100, mouse_x, mouse_y)
		}
		@plyArr.each_with_index{|ply, i|
			ply.drawImage(times + i * 100, mouse_x, mouse_y)
		}

		if @trun != "over"
			@chooser.draw(times, mouse_x, mouse_y) if @chooser
			@effectArr[0].draw(times, mouse_x, mouse_y) if @effectArr && @effectArr.length > 0
		end
	end
	def changeState(state)
		# initialize state
		case state
		when "show_effect"
			@plyArr.each{|ply| ply.targetable = false}
			@enmArr.each{|enm| enm.targetable = false}
		when "select_skill"
			@chooser = nil
			@chosenPlayer = nil
			@chosenCard = nil
			@targetArr = nil
		when "enemy_attack"
			@currentEnemy = nil
			@chosenCard = nil
			@targetArr = nil
		end
		@state = state
	end
	def updateSelectSkill(mouse_locations)
		return if @turn == "over"

		@battleEndFlg = judgeBattleEnd
		if @battleEndFlg != ""
			@turn = "over"
			@effectArr = [@battleEndFlg == "win" ? WinEffect.new() : LoseEffect.new()]
			changeState("show_effect")
			return
		end

		if !@chooser
			@chooser = SkillChooser.new(self)
			releaseAll
		end

		if !@chooser.possible
			if @passed
				@state = nil
			else
				@turn = @turn == "player" ? "enemy" : "player"
				@passed = true
				@chooser = SkillChooser.new(self)
			end
		elsif @chooser.getChosen
			@chosenPlayer = @chooser.chosenPlayer
			@chosenCard = @chooser.chosenCard			
			@chooser = nil
			changeState("select_target")
		end
	end
	def updateSelectTarget(mouse_locations)
		if !@chooser
			@chooser = createTargetChooser(self, @chosenPlayer, @chosenCard.targetType)
		elsif @chooser.getChosen
			@targetArr = @chooser.targetArr
			@chosenPlayer.discardByCard(@chosenCard)
			@effectArr = @chosenCard.createEffect(@chosenPlayer, @targetArr)
			@effectArr.append(NopEffect.new) if @turn == "enemy"
			@chooser = nil
			changeState("show_effect")
		end
	end
	def updateShowEffect(mouse_locations)
		if @effectArr && @effectArr.length > 0
			eff = @effectArr[0]
			eff.update(mouse_locations)
			if eff.over
				@effectArr = @effectArr + eff.additionalEffectArr if eff.additionalEffectArr
				@effectArr = @effectArr.drop(1)
			end
		else
			@effectArr = nil
			changeState("select_skill")
		end
	end
	def update(mouse_locations)
		return if ["win", "lose", "draw"].include?(@state)
		
		if @turn == "over" && !@effectArr
			changeState(@battleEndFlg)
			return
		end

		if !@state
			battlePrep
			turnBegin
			changeState("select_skill")
		end

		setBoundingBoxes

		if mouse_locations && @chooser
			@chooser.choose(mouse_locations)
		end

		case @state
		when "select_skill"
			updateSelectSkill(mouse_locations)
		when "select_target"
			updateSelectTarget(mouse_locations)
		when "show_effect"
			updateShowEffect(mouse_locations)
		end
	end
	def displayScene
		puts "■相手の状況"
		i = 0
		@enmArr.each do |enm|
			print "<" + dec_to_a(i) + "> "
			enm.disp
			puts
			i = i + 1
		end
		puts "■自分の状況"
		i = 0
		@plyArr.each do |ply|
			print "<" + dec_to_A(i) + "> "
			ply.disp
			puts
			i = i + 1
		end
	end
	private def dec_to_a(num)	#0->a, 25->z
		(num > 25 ? dec26(num / 26) : '') + ('a'.ord + num % 26).chr
	end
	private def dec_to_A(num)	#0->A, 25->Z
		(num > 25 ? dec26(num / 26) : '') + ('A'.ord + num % 26).chr
	end
	def targeting(ply, targetType)
		#まず入力なしで特定できるケースを先に終わらせる
		#@targetType = ''	#me, player, allplayer, otherplayer, allotherplayer, enemy, allenemy, allother, all, card
		case targetType
		when "me"
			return [ply]
		when "player"
			if @plyArr.length == 1
				return [@plyArr[0]]
			elsif @plyArr.length == 2
				if @plyArr[0] == ply
					return [@plyArr[1]]
				elsif @plyArr[1] == ply
					return [@plyArr[0]]
				else
					puts "fatal error in targeting"
					exit
				end
			end
		when "allplayer"
			return @plyarr
		when "otherplayer"
			if @plyArr.length == 1
				#otherplayerが存在しない
				return nil
			elsif @plyArr.length == 2
				if @plyArr[0] == ply
					return [@plyArr[1]]
				elsif @plyArr[1] == ply
					return [@plyArr[0]]
				else
					puts "fatal error in targeting"
					exit
				end
			end
		when "allotherplayer"
			if @plyArr.length == 1
				#otherplayerが存在しない
				return nil
			elsif @plyArr.length == 2
				if @plyArr[0] == ply
					return [@plyArr[1]]
				elsif @plyArr[1] == ply
					return [@plyArr[0]]
				else
					puts "fatal error in targeting"
					exit
				end
			else
				rtn = []
				@plyArr.each do |player|
					if player != ply
						rtn.append(player)
					end
				end
				return rtn
			end
		when "enemy"
			if @enmArr.length == 1
				return [@enmArr[0]]
			end
		when "allenemy"
			return @enmArr
		when "allother"
			rtn = []
			@plyArr.each do |player|
				if player != ply
					rtn.append(player)
				end
			end
			@enmArr.each do |enemy|
				rtn.append(enemy)
			end
			return rtn
		when "all"
			rtn = []
			@plyArr.each do |player|
				rtn.append(player)
			end
			@enmArr.each do |enemy|
				rtn.append(enemy)
			end
			return rtn
		end
		#入力必要なケース
		rtn = []
		puts "プレイしたいカードの対象<id>を入力してください"
		strInput = gets.strip
		case strInput
		when /^[0-9]+$/
			if targetType == "card"
				i = 0
				ply.hand.each do |crd|
					i = i + 1
					if i.to_s == strInput
						rtn.append(crd)
					end
				end
			end
		when /^[a-z]+$/
			if targetType == "enemy"
				i = 0
				@enmArr.each do |enm|
					if dec_to_a(i).to_s == strInput
						rtn.append(enm)
					end
					i = i + 1
				end
			end
		when /^[A-Z]+$/
			if targetType == "player"
				i = 0
				@plyArr.each do |player|
					if dec_to_A(i).to_s == strInput
						rtn.append(player)
					end
					i = i + 1
				end
			elsif targetType == "otherplayer"
				i = 0
				@plyArr.each do |player|
					if player != ply
						if dec_to_A(i).to_s == strInput
							rtn.append(player)
						end
					end
					i = i + 1
				end
			end
		end
		if rtn.length == 0
			return nil
		else
			return rtn
		end
	end
	#バトル処理
	def battlePrep
		@enmArr.each do |enm|
			enm.battlePrep
		end
		@plyArr.each do |ply|
			ply.battlePrep
		end
		@battleEndFlg = ""
	end
	#ターン開始処理
	def turnBegin
		@plyArr.each do |ply|
			ply.turnBegin
		end
		@enmArr.each do |enm|
			enm.turnBegin
		end
		@turn = "player"
		@passed = false
		changeState("select_skill")
	end
	def battleOneTurn
		#ターン
		@plyArr.each do |ply|
			minHandCardCost = 10000
			ply.hand.each do |crd|
				if crd.cost < minHandCardCost
					minHandCardCost = crd.cost
				end
			end
			while ply.mana >= minHandCardCost && ply.hand.length > 0 && ply.life > 0
				self.displayScene
				puts "■行動指示: " + ply.name
				puts "プレイするHandの<id>を入力してください(0→Skip)"
				#入力受付
				strInput = gets.strip
				#入力解釈
				if strInput == "0"
					#ターンエンド
					break
				end
				i = 0
				ply.hand.each do |crd|
					i = i + 1
					if i.to_s == strInput
						if ply.mana >= crd.cost
							targetArr = self.targeting(ply, crd.targetType)
							if targetArr != nil
								ply.mana = ply.mana - crd.cost
								crd.play(ply, targetArr)
								ply.discard(i - 1)
								#勝敗判定
								(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
								break if @battleEndFlg != ""
							else
								puts "有効な対象指定がなされなかったためカードプレイをスキップします"
							end
						end
					end
				end
				#勝敗判定
				(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
				break if @battleEndFlg != ""
				puts
				minHandCardCost = 10000
				ply.hand.each do |crd|
					if crd.cost < minHandCardCost
						minHandCardCost = crd.cost
					end
				end
			end
			#勝敗判定
			(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
			break if @battleEndFlg != ""
			ply.turnEnd
			#勝敗判定
			(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
			break if @battleEndFlg != ""
		end
		#勝敗判定
		(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
		return if @battleEndFlg != ""
		@enmArr.each do |enm|
			minHandCardCost = 10000
			enm.hand.each do |crd|
				if crd.cost < minHandCardCost
					minHandCardCost = crd.cost
				end
			end
			while enm.mana >= minHandCardCost && enm.hand.length > 0 && enm.life > 0
				self.displayScene
				enm.hand.each do |crd|
					if enm.mana >= crd.cost
						enm.mana = enm.mana - crd.cost
						case crd.targetType
						when 'me'
							crd.play(enm, [enm])
						when 'enemy'
							#本来はここでターゲットが複数ありうる場合選択する処理が入る
							crd.play(enm, [@plyArr[0]])
						end
						enm.discard(0)
						#勝敗判定
						(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
						break if @battleEndFlg != ""
					end
				end
				#勝敗判定
				(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
				break if @battleEndFlg != ""
				puts
				minHandCardCost = 10000
				enm.hand.each do |crd|
					if crd.cost < minHandCardCost
						minHandCardCost = crd.cost
					end
				end
			end
			#勝敗判定
			(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
			break if @battleEndFlg != ""
			enm.turnEnd
			#勝敗判定
			(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
			break if @battleEndFlg != ""
		end
		#勝敗判定
		(@battleEndFlg = judgeBattleEnd) if @battleEndFlg == "" 
		return if @battleEndFlg != ""
	end
	#戻り値: String→"", "Player勝利", "Player敗北", "相打ち"
	def battle
		#戦闘準備
		battlePrep
		#戦闘開始
		while @battleEndFlg == "" do
			battleOneTurn
		end
		puts @battleEndFlg
		@battleEndFlg
	end
	#バトル終了条件判定
	#戻り値: String→"", "Player勝利", "Player敗北", "相打ち"
	def judgeBattleEnd
		@battleEndFlg = ""
		flgAllEnemyDead = true
		@enmArr.each do |enm|
			if enm.life > 0
				flgAllEnemyDead = false
			end
		end
		flgAllPlayerDead = true
		@plyArr.each do |ply|
			if ply.life > 0
				flgAllPlayerDead = false
			end
		end
		if flgAllEnemyDead == true && flgAllPlayerDead == false
			@battleEndFlg = "win"
		elsif flgAllEnemyDead == false && flgAllPlayerDead == true
			@battleEndFlg = "lose"
		elsif flgAllEnemyDead == true && flgAllPlayerDead == true
			@battleEndFlg = "draw"
		else
			@battleEndFlg = ""
		end
		@battleEndFlg
	end
end