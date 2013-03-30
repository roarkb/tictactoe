#!/usr/bin/env ruby

ARG1 = ARGV[0]
ARG2 = ARGV[1]
HIST = ".history"
HIST_FH = File.open(HIST, "a")

# end all games with this
def close_exit
  HIST_FH.close
  
  # display game history
  h = File.open(HIST).map { |line| line.to_i }
  puts %Q{ history:
      player wins: #{h.count(0)}
    computer wins: #{h.count(1)}
            draws: #{h.count(2)}
       surrenders: #{h.count(3)}
  }

  # TODO: or something like this but using printf
  #puts "history:"
  #
  #[ "player wins", "computer wins", "draws", "surrenders" ].each_with_index do |e,i|
  #  puts "    #{e}: #{h.count(i)}"
  #end

  exit
end

if ARG1 == "help" || ARG1 == "info"
  puts %Q{  
   USAGE: '#{__FILE__} <optional arg1> <optional arg2>'
  
  arg1:
    "skip"      => skip intro
    "player"    => skip intro, choose X and go first
    "computer"  => skip intro, choose X and computer goes first
    "help/info" => this menu

  arg2:
    "debug" => display computer stats

  "end/exit/e" will end the game
  }

  close_exit
end

if ARG1 == "reset"
  HIST_FH.close
  File.delete(HIST)
  exit
end

X = "X"
O = "O"
E = " "
POSITIONS = %w[ a1 a2 a3 b1 b2 b3 c1 c2 c3 ]
EXIT_MSG = "\n\nyou just can't seem to take tic-tac-toe seriously!\n\n"
GOODBYE_MSG = "\n\nGoodbye :(\n\n"
WINS = [ # all winning combinations 
  [ 0, 1, 2 ],
  [ 3, 4, 5 ],
  [ 6, 7, 8 ],
  [ 0, 3, 6 ],
  [ 1, 4, 7 ],
  [ 2, 5, 8 ],
  [ 0, 4, 8 ],
  [ 2, 4, 6 ]
]

# set default game state
$state = [ E, E, E, E, E, E, E, E, E ]
$piece = { :player => X, :computer => O }
$tally = { # for computer AI strategies
  "block fork1"               => 0,
  "block fork2"               => 0,
  "win"                       => 0,
  "block player win"          => 0,
  "two in a row"              => 0,
  "block player two in a row" => 0,
  "random"                    => 0,
}

# ask player a question and get one of two answers
def ask(question, a, b)
  print "#{question} (#{a}/#{b})> "
  r = $stdin.gets.strip

  4.times do
    unless r == a or r == b
      print "\nPlease type '#{a}' or '#{b}': "
      r = $stdin.gets.strip
    end
  end

  unless r == a or r == b
    puts EXIT_MSG
    close_exit
  end

  r
end

# display board with current game state
def board
  s = $state
  
  puts "
      1   2   3

  a   #{s[0]} | #{s[1]} | #{s[2]}
     ---+---+---
  b   #{s[3]} | #{s[4]} | #{s[5]}
     ---+---+---
  c   #{s[6]} | #{s[7]} | #{s[8]}
  "
end

def write(pos, char) # example: ("a1", $piece[:player])
  $state[POSITIONS.index(pos)] = char
end

# return random element from array
# (Array.sample not supported until ruby 1.9)
def random(array)
  array[rand(array.length)]
end

# map WINS to current $state
def state_wins
  WINS.map { |win| [ $state[win[0]], $state[win[1]], $state[win[2]] ] }
end

# TODO: add method to help translate coordinates to positions?

# assume player is X until chosen otherwise
def choose_sides
  if ask("Choose a side", "x", "o") == "o"
    $piece[:player] = O
    $piece[:computer] = X
  end
end

# display computer stats in debug mode
def stats
  puts "\n      computer stats:\n  --+------------"
  $tally.each { |k,v| puts "  #{v} | #{k}" }
  puts
end

def end_game(msg)
  puts "\n!!! #{msg} !!!\n\n"
  stats if ARG2 == "debug"
  close_exit
end

def check_for_winner
  winner = nil
  
  state_wins.each do |e|
    case e
    when [ X, X, X ]
      winner = $piece.invert[X]
    when [ O, O, O ]
      winner = $piece.invert[O]
    end
  end

  case winner
  when :player
    HIST_FH.puts 0
    end_game("You Win")
  when :computer
    HIST_FH.puts 1
    end_game("Computer Wins")
  end

  # is it a draw?
  # TODO: detect draw even sooner
  draw_count = 0
  
  state_wins.each do |e|
    if e.count(X) > 0 && e.count(O) > 0
      draw_count += 1
    end
  end
    
  HIST_FH.puts 2 if draw_count == 8
  end_game("Draw") if draw_count == 8
end

# return any 3rd coordinates needed to complete 3 in a row
def one_to_win(char) # X or O
  moves = []
  
  # TODO: this causes computer to overwrite existing spot!?
  #state_wins.each do |e|
  #  if e.count(char) == 2 && e.count(E) == 1
  #    moves.push(POSITIONS[e.index(E)])
  #  end
  #end
  
  # TODO: use state_wins method here
  WINS.each do |e|
    row = [ $state[e[0]], $state[e[1]], $state[e[2]] ]
    if row.count(char) == 2 && row.count(E) == 1
      moves.push(POSITIONS[e[row.index(E)]])
    end
  end

  moves.uniq
end

# return 2nd and 3rd coordinates needed to complete 3 in a row
def two_to_win(char) # X or O
  moves = []
  
  # TODO: use state_wins method here
  WINS.each do |win|
    row = [ $state[win[0]], $state[win[1]], $state[win[2]] ]
    if row.count(char) == 1 && row.count(E) == 2
      row.each do |space|
        if space == E
          moves.push(POSITIONS[win[row.index(space)]])
        end
      end
    end
  end

  moves.uniq
end

def player_move
  print "\nyour move> "
  move = $stdin.gets.strip
  v = 0
 
  if move == "end" || move == "exit" || move == "e"
    puts GOODBYE_MSG
    HIST_FH.puts 3
    close_exit
  end

  4.times do
    unless v == 1
      if move == "end" || move == "exit" || move == "e"
        puts GOODBYE_MSG
        HIST_FH.puts 3
        close_exit
      end

      if !POSITIONS.include?(move)
        print "\ninvalid move, try again> "
        move = $stdin.gets.strip
      elsif $state[POSITIONS.index(move)] != E
        print "\nplease choose an empty space> "
        move = $stdin.gets.strip
      else
        v = 1
      end
    end
  end

  unless v == 1
    puts EXIT_MSG
    close_exit
  end

  write(move, $piece[:player])
end

def computer_move
  s = $state
  c = $piece[:computer]
  p = $piece[:player]

  puts "\ncomputer move:"

  #TODO: fork attempt if go first

  # block fork - player goes first and moved a corner
  if s.count(p) == 1 && (s[0] == p || s[2] == p || s[6] == p || s[8] == p)
    write("b2", c)  
    $tally["block fork1"] =+ 1

  # continue block fork - make sure second move is not a corner if player has two opposite corners
  elsif s.count(p) == 2 && s.count(c) == 1 && s[4] == c && (s[0] == p && s[8] == p) || (s[2] == p && s[6] == p)
    write(random([ "a2", "b1", "b3", "c2" ]), c)
    $tally["block fork2"] =+ 1
  
  # go for the win
  elsif (moves = one_to_win(c)).length > 0
    write(random(moves), c)
    $tally["win"] =+ 1

  # keep player from winning
  # TODO: sometimes computer wont do this?!?
  elsif (moves = one_to_win(p)).length > 0
    write(random(moves), c)
    $tally["block player win"] += 1
  
  # go for two in a row
  elsif (moves = two_to_win(c)).length > 0
    write(random(moves), c)
    $tally["two in a row"] += 1

  # keep player from attempting two in a row
  elsif (moves = two_to_win(p)).length > 0
    write(random(moves), c)
    $tally["block player two in a row"] += 1

  # make random move
  else
    empties = []
    
    s.each_with_index do |e,i|
      if e == E
        empties.push(POSITIONS[i])
      end
    end

    write(random(empties), c)
    $tally["random"] += 1
  end
end

def intro
  system("clear")
  puts "\n  Welcome\n\n"
  sleep 1
  puts "     To\n\n"
  sleep 1
  puts "  T | I | C\n ---+---+---\n  T | A | C\n ---+---+---\n  T | O | E\n\n"
  sleep 1
end

def turn
  yield
  board
  check_for_winner
end

def play_starting_with(who) # :player, :computer
  case who
  when :player
    board
    
    loop do
      turn { player_move }
      turn { computer_move }
    end
  when :computer
    loop do
      turn { computer_move }
      turn { player_move }
    end
  end
end

def play_and_choose_first
  case ask("Do you wish to go first", "yes", "no")
  when "yes"
    play_starting_with(:player)
  when "no"
    play_starting_with(:computer)
  end
end

def main
  case ARG1
  when "player" # skip intro, player goes first and is X
    play_starting_with(:player)
  when "computer" # skip intro, computer goes first and is X
    play_starting_with(:computer)
  when "skip" # skip intro
    choose_sides
    play_and_choose_first
  else
    intro 
    choose_sides
    play_and_choose_first
  end 
end

main
