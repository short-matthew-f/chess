class Piece
  attr_accessor :pos, :color 
  attr_reader :board
  
  def self.un_pos(pos)
    letters = ('A'..'H').to_a
    "#{letters[pos[1]]}#{8-pos[0]}"
  end
  
  def initialize(pos, color, board)
    @pos, @color, @board = pos, color, board
    @board[pos] = self
  end
  
  def to_s
    pieces = {
      King      => { black: "♚", white: "♔" },
      Queen     => { black: "♛", white: "♕" },
      Rook      => { black: "♜", white: "♖" },
      Bishop    => { black: "♝", white: "♗" },
      Knight    => { black: "♞", white: "♘" },
      Pawn      => { black: "♟", white: "♙" }
    }
    pieces[self.class][self.color]    
  end

  def is_empty?(pos)
    Board.squares.include?(pos) && board[pos] == nil
  end
  
  def holds_enemy?(pos)
    Board.squares.include?(pos) && !is_empty?(pos) && board[pos].color != self.color 
  end
  
  def targets
    Board.squares.select do |pos|
      is_empty?(pos) || holds_enemy?(pos)
    end
  end
  
  def attackable_positions
    self.moves
  end
  
  def puts_in_check?(pos)
    new_board = self.board.dup
    new_board.move_to(pos, new_board[self.pos]).in_check?(self.color)
  end
end

class SteppingPiece < Piece
  def moves
    # returns an array of positions that are valid for this piece
    result = targets
    
    result.select do |pos|
      self.class::DELTAS
        .include?([pos[0]-self.pos[0], pos[1]-self.pos[1]])
    end
  end
end

class Knight < SteppingPiece
  DELTAS = [
    [1, 2], [2, 1], [2, -1], [1, -2],
    [-1, -2], [-2, -1], [-2, 1], [-1, 2]
  ]
end

class King < SteppingPiece
  DELTAS = [
    [0, 1], [1, 1], [1, 0], [1, -1],
    [0, -1], [-1, -1], [-1, 0], [-1, 1]
  ]
end

class SlidingPiece < Piece
  def initialize(pos, color, board)
    super(pos, color, board)
  end

  def moves
    result = []
    
    self.class::DELTAS.each do |delta|
      current_pos = [self.pos[0]+delta[0], self.pos[1]+delta[1]]
      while 
        Board.squares.include?(current_pos) &&
          (is_empty?(current_pos) || holds_enemy?(current_pos))
        
        result << current_pos     
        break if holds_enemy?(current_pos)
        
        current_pos = [current_pos[0]+delta[0], current_pos[1]+delta[1]]
      end
    end
    result
  end  
  
end

class Queen < SlidingPiece
  DELTAS = [
    [0, 1], [1, 1], [1, 0], [1, -1],
    [0, -1], [-1, -1], [-1, 0], [-1, 1]
  ]
end

class Rook < SlidingPiece
  DELTAS = [
    [0, 1], [1, 0],
    [0, -1], [-1, 0]
  ]  
end

class Bishop < SlidingPiece
  DELTAS = [
    [1, 1], [1, -1],
    [-1, -1], [-1, 1]
  ] 
end

class Pawn < Piece
  
  def initialize(pos, color, board)
    super(pos, color, board)
  end
  
  def direction
    (self.color == :white) ? [-1,0] : [1,0]
  end
  
  def attackable_positions
    direction = (self.color == :white) ? -1 : 1
    
    diagonal_one = [self.pos[0] + direction, self.pos[1] - 1]
    diagonal_two = [self.pos[0] + direction, self.pos[1] + 1]
    
    [diagonal_one, diagonal_two].select { |attack| holds_enemy?(attack) }
  end
  
  def moved?
    (self.color == :white) ? (self.pos[0] != 6) : (self.pos[0] != 1)
  end
  
  def moves
    result = []
    direction = (self.color == :white) ? -1 : 1
    
    one_forward = [direction + self.pos[0], self.pos[1]]
    two_forward = [2 * direction + self.pos[0], self.pos[1]]
    
    # this checks the square in front, and then if it is empty and we've
    # not moved, checks the next one too
    if is_empty?(one_forward)
      
      result << one_forward
      
      if !self.moved? && is_empty?(two_forward)
        result << two_forward
      end
    end
    
    (result + attackable_positions)
  end
end