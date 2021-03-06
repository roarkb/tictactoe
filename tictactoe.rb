#!/usr/bin/env ruby

#    T | I | C
#   ---+---+---
#    T | A | C
#   ---+---+---
#    T | O | E
#
#    Created by
#  Roark Brewster
#      (2013)
#
#
#  USAGE: './tictactoe.rb <optional arg1> <optional arg2>'
#  
#  arg1:
#    skip/s     => skip intro
#    player/p   => skip intro, choose X and go first
#    computer/c => skip intro, choose X and computer goes first
#    reset/r    => reset history
#    history/h  => display history
#    info/i     => game credits
#    help       => this menu
#
#  arg2:
#    debug      => display computer stats
#
#  end/exit/e   => surrender

HIST = ".history"
HIST_FH = File.open(HIST, "a")
X = "X"
O = "O"
E = " "
POSITIONS = %w[ a1 a2 a3 b1 b2 b3 c1 c2 c3 ]
CORNERS = %w[ a1 a3 c1 c3 ]
NON_CORNERS = %w[ a2 b1 b3 c2 ]
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

# display game history
def history
  h = File.open(HIST).map { |line| line.to_i }
  puts %Q{ history:
      player wins: #{h.count(0)}
    computer wins: #{h.count(1)}
            draws: #{h.count(2)}
       surrenders: #{h.count(3)}
  }
end

# end all games with this
def close_exit
  HIST_FH.close
  history
  exit
end

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
    abort EXIT_MSG
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

# assume player is X until chosen otherwise
def choose_sides
  if ask("Choose a side", "x", "o") == "o"
    $piece[:player] = O
    $piece[:computer] = X
  end
end

def end_game(msg)
  puts "\n!!! #{msg} !!!\n\n"
  
  # display computer stats in debug mode
  if ARGV[1] == "debug"
    puts "\n      computer stats:\n  --+----------------"
    $tally.each { |k,v| puts "  #{v} | #{k}" }
    puts
  end

  close_exit
end

# return any 3rd coordinates needed to complete 3 in a row
def one_to_win(char) # X or O
  moves = []

  state_wins.each_with_index do |e,i|
    if e.count(char) == 2 && e.count(E) == 1
      moves.push(POSITIONS[WINS[i][e.index(E)]])
    end
  end
  
  moves.uniq
end

# return 2nd and 3rd coordinates needed to complete 3 in a row
def two_to_win(char) # X or O
  moves = []
  
  state_wins.each_with_index do |row,i|
    if row.count(char) == 1 && row.count(E) == 2
      row.each do |space|
        if space == E
          moves.push(POSITIONS[WINS[i][row.index(E)]])
        end
      end
    end
  end
  
  moves.uniq
end

# extract all corner moves and return them, return original array if no corners
def favor_corners(moves) # array of moves: [ a1, b2, c3, ... ]
  a = []
  moves.each { |e| a.push(e) if CORNERS.include?(e) }

  if a.length == 0
    moves
  else
    a
  end
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
    abort EXIT_MSG
  end

  write(move, $piece[:player])
end

def computer_move
  s = $state
  c = $piece[:computer]
  p = $piece[:player]

  # block fork - if going second, move center if you can
  if s.count(p) == 1 && (s[4] == E)
    m = "b2"
    t = "block fork1"

  # continue block fork - make sure second move is not a corner if player has two diagnal opposite corners
  elsif s.count(p) == 2 && s.count(c) == 1 && s[4] == c && (s[0] == p && s[8] == p) || (s[2] == p && s[6] == p)
    m = random(NON_CORNERS)
    t = "block fork2"

  # go for the win
  elsif (moves = one_to_win(c)).length > 0
    m = random(favor_corners(moves))
    t = "win"

  # keep player from winning
  elsif (moves = one_to_win(p)).length > 0
    m = random(favor_corners(moves))
    t = "block player win"
  
  # go for two in a row
  elsif (moves = two_to_win(c)).length > 0
    m = random(favor_corners(moves))
    t = "two in a row"

  # keep player from attempting two in a row
  elsif (moves = two_to_win(p)).length > 0
    m = random(favor_corners(moves))
    t = "block player two in a row"

  # make random move
  else
    empties = []
    
    s.each_with_index do |e,i|
      if e == E
        empties.push(POSITIONS[i])
      end
    end

    m = random(empties)
    t = "random"
  end
 
  # move
  if ARGV[1] == "debug"
    puts "\ncomputer moves: #{m} (#{t})"
  else
    puts "\ncomputer moves: #{m}"
  end

  write(m, c)
  $tally[t] =+ 1
end

def turn
  yield
  board
  
  # check for winner
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

  # detect a draw
  draw_count = 0
 
  state_wins.each do |e|
    if e.count(X) > 0 && e.count(O) > 0
      draw_count += 1
    end
  end
  
  if draw_count >= 7
    HIST_FH.puts 2
    end_game("Draw")
  end
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

# main
case ARGV[0]
when "help"
  puts %Q{  
  USAGE: '#{__FILE__} <optional arg1> <optional arg2>'
  
  arg1:
    skip/s     => skip intro
    player/p   => skip intro, choose X and go first
    computer/c => skip intro, choose X and computer goes first
    reset/r    => reset history
    history/h  => display history  
    info/i     => game credits
    help       => this menu

  arg2:
    debug      => display computer stats

  end/exit/e   => surrender
  }

  exit
when "history", "h"
  puts
  history
  exit
when "reset", "r"
  HIST_FH.close
  File.delete(HIST)
  exit
when "info", "i"
  puts "\n   T | I | C\n  ---+---+---\n   T | A | C\n  ---+---+---\n   T | O | E\n\n"
  puts "   Created by\n Roark Brewster\n     (2013)\n\n" 
  exit
when "player", "p" # skip intro, player is X. player goes first
  play_starting_with(:player)
when "computer", "c" # skip intro, player is X, computer goes first
  play_starting_with(:computer)
when "skip", "s" # skip intro
  choose_sides
  play_and_choose_first
else
  system("clear")
  puts "\n  Welcome\n\n"
  sleep 1
  puts "     To\n\n"
  sleep 1
  puts "  T | I | C\n ---+---+---\n  T | A | C\n ---+---+---\n  T | O | E\n\n"
  sleep 1
  choose_sides
  play_and_choose_first
end
