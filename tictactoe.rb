#!/usr/bin/env ruby

X = "X"
O = "O"
E = " "
POSITIONS = %w[ a1 a2 a3 b1 b2 b3 c1 c2 c3 ]
EXIT_MSG = "\n\nyou just can't seem to take tic-tac-toe seriously!\n\n"
WINS = [ 
  [ 0, 1, 2 ],
  [ 3, 4, 5 ],
  [ 6, 7, 8 ],
  [ 0, 3, 6 ],
  [ 1, 4, 7 ],
  [ 2, 5, 8 ],
  [ 0, 4, 8 ],
  [ 2, 4, 6 ]
]

$state = [ E, E, E, E, E, E, E, E, E ]
$piece = { :player => X, :computer => O }

def ask(question, a, b)
  print "#{question} (#{a}/#{b})> "
  r = $stdin.gets.strip

  4.times do
    unless r == a or r == b
      print "\nPlease type '#{a}' or '#{b}': "
      r = $stdin.gets.strip
    end
  end

  abort EXIT_MSG unless r == a or r == b
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

def write(pos, char)
  $state[POSITIONS.index(pos)] = char
end

def state_to_grid
  s = $state

  [ 
    [ s[0], s[1], s[2] ], 
    [ s[3], s[4], s[5] ], 
    [ s[6], s[7], s[8] ]
  ]
end

# assume player is X until chosen otherwise
def choose_sides
  if ask("Choose a side", "x", "o") == "o"
    $piece[:player] = O
    $piece[:computer] = X
  end
end

def check_for_winner
  winner = nil
  
  WINS.each do |e|
    case [ $state[e[0]], $state[e[1]], $state[e[2]] ]
    when [ X, X, X ]
      winner = $piece.invert[X]
    when [ O, O, O ]
      winner = $piece.invert[O]
    end
  end

  case winner
  when :player
    abort "\n!!! You Win !!!\n\n"
  when :computer
    abort "\n!!! Computer Wins !!!\n\n"
  end

  if $state.include?(E) == false
    abort "\n!!! Stalemate !!!\n\n"
  end
end

# return any 3rd coordinates needed to complete 3 in a row
def two_to_win(char) # X or O
  moves = []

  WINS.each do |e|
    row = [ $state[e[0]], $state[e[1]], $state[e[2]] ]
    if row.count(char) == 2 && row.count(E) == 1
      moves.push(POSITIONS[e[row.index(E)]])
    end
  end

  moves.uniq
end

def player_move
  print "\nyour move> "
  move = $stdin.gets.strip
  v = 0
  
  4.times do
    unless v == 1

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

  abort EXIT_MSG unless v == 1

  write(move, $piece[:player])
  board
  check_for_winner
end

def computer_move
  # if computer goes first then make random move
  if $state.uniq.to_s == E
    write(POSITIONS[rand(POSITIONS.length)], $piece[:computer])
  end

  # go for the win?
  
  # keep player from winning?

  # go for random 2 in a row?
  
  # else make random move

  board
  check_for_winner
end

def main
  unless ARGV[0] == "debug"
    system("clear")
    puts "\n  Welcome\n\n"
    sleep 1
    puts "     To\n\n"
    sleep 1
    puts "  T | I | C\n ---+---+---\n  T | A | C\n ---+---+---\n  T | O | E\n\n"
    sleep 1
  end
    
  choose_sides

  case ask("Do you wish to go first", "yes", "no")
  when "yes"
    board
    
    loop do
      player_move
      computer_move
    end
  when "no"
    loop do
      computer_move
      player_move
    end
  end
end

#main
