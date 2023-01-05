require './player.rb'
require './card.rb'
require './gm.rb'

#ゲーム初期化
plyArr = []
#plyArr.append(Player.new("TestPlayer"))
plyArr.append(Player.new("Fighter"))
#plyArr.append(Player.new("Healer"))
#1面
puts
puts
puts "Please defeat A Ghost"
puts "Press ENTER key to continue"
gets
enmArr = []
enmArr.append(Player.new("A Ghost"))
gm = GM.new(plyArr, enmArr)
if gm.battle != "Player勝利"
	puts "再挑戦してください"
	exit
end
#2面
puts
puts
puts "Please defeat Tiny Ghosts"
puts "Press ENTER key to continue"
gets
enmArr = []
3.times do
	enmArr.append(Player.new("A Tiny Ghost"))
end

gm = GM.new(plyArr, enmArr)
if gm.battle != "Player勝利"
	puts "再挑戦してください"
	exit
end
#3面
puts
puts
puts "Please defeat The King of Ghost"
puts "Press ENTER key to continue"
gets
enmArr = []
enmArr.append(Player.new("The King of Ghost"))
gm = GM.new(plyArr, enmArr)
if gm.battle != "Player勝利"
	puts "再挑戦してください"
	exit
end
#クリア
puts "ゲームクリア"
