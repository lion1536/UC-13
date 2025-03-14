import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(ChessApp());
}

class ChessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xadrez em Flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChessBoard(),
    );
  }
}

class ChessBoard extends StatefulWidget {
  @override
  _ChessBoardState createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  // Representação do tabuleiro (8x8)
  List<List<String>> board = List.generate(
    8,
    (i) => List.generate(8, (j) => ''),
  );

  // Posição da peça selecionada
  int selectedRow = -1;
  int selectedCol = -1;

  // Lista de movimentos possíveis
  List<List<bool>> possibleMoves = List.generate(
    8,
    (i) => List.generate(8, (j) => false),
  );

  // Turno atual (true = brancas, false = pretas)
  bool isWhiteTurn = true;

  // Mensagem de status (xeque, xeque-mate, etc.)
  String statusMessage = '';

  // Estado do roque (true = disponível, false = indisponível)
  bool whiteKingSideCastle = true;
  bool whiteQueenSideCastle = true;
  bool blackKingSideCastle = true;
  bool blackQueenSideCastle = true;

  // Indica se o jogo terminou
  bool isGameOver = false;

  // Lista de mensagens do jogo (como um console)
  List<String> gameLog = [];

  // Variável para controlar a promoção do peão
  bool isPromoting = false;
  int promotionRow = -1;
  int promotionCol = -1;

  // Variável para controle do en passant
  int enPassantRow = -1;
  int enPassantCol = -1;

  // Nível de dificuldade da IA (1 = fácil, 2 = médio, 3 = difícil)
  int aiDifficulty = 3;

  // Posições dos reis
  int whiteKingRow = -1, whiteKingCol = -1;
  int blackKingRow = -1, blackKingCol = -1;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    gameLog.add('Bem-vindo ao Xadrez em Flutter!');
  }

  // Inicializa o tabuleiro com as peças no lugar
  void _initializeBoard() {
    // Peças brancas
    board[0] = ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'];
    board[1] = List.filled(8, '♟');

    // Peças pretas
    board[6] = List.filled(8, '♙');
    board[7] = ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'];

    // Define as posições iniciais dos reis
    whiteKingRow = 7;
    whiteKingCol = 4;
    blackKingRow = 0;
    blackKingCol = 4;
  }

  // Função para mover uma peça
  void _movePiece(int row, int col) {
    if (isGameOver) return;

    if (selectedRow == -1 && selectedCol == -1) {
      if (board[row][col].isNotEmpty && _isCurrentPlayerPiece(row, col)) {
        setState(() {
          selectedRow = row;
          selectedCol = col;
          _calculatePossibleMoves(row, col);
        });
      }
    } else {
      if (possibleMoves[row][col]) {
        // Verifica se o movimento coloca o rei em xeque
        if (_isMoveValid(row, col)) {
          setState(() {
            // Verifica se é um movimento de roque
            if (board[selectedRow][selectedCol] == '♔' ||
                board[selectedRow][selectedCol] == '♚') {
              int deltaCol = col - selectedCol;
              if (deltaCol == 2) {
                // Roque do lado do rei (king-side)
                board[row][col - 1] = board[row][7];
                board[row][7] = '';
              } else if (deltaCol == -2) {
                // Roque do lado da rainha (queen-side)
                board[row][col + 1] = board[row][0];
                board[row][0] = '';
              }
              if (isWhiteTurn) {
                whiteKingSideCastle = false;
                whiteQueenSideCastle = false;
              } else {
                blackKingSideCastle = false;
                blackQueenSideCastle = false;
              }
            }

            // Verifica se a torre foi movida, desabilitando o roque
            if (board[selectedRow][selectedCol] == '♖' ||
                board[selectedRow][selectedCol] == '♜') {
              if (selectedCol == 0) {
                if (isWhiteTurn) {
                  whiteQueenSideCastle = false;
                } else {
                  blackQueenSideCastle = false;
                }
              } else if (selectedCol == 7) {
                if (isWhiteTurn) {
                  whiteKingSideCastle = false;
                } else {
                  blackKingSideCastle = false;
                }
              }
            }

            // Verifica se é um movimento en passant
            if ((board[selectedRow][selectedCol] == '♙' ||
                    board[selectedRow][selectedCol] == '♟') &&
                col == enPassantCol &&
                row == enPassantRow) {
              board[selectedRow][col] = ''; // Remove o peão capturado
            }

            // Move a peça
            String piece = board[selectedRow][selectedCol];
            board[row][col] = piece;
            board[selectedRow][selectedCol] = '';
            selectedRow = -1;
            selectedCol = -1;
            possibleMoves = List.generate(
              8,
              (i) => List.generate(8, (j) => false),
            );
            isWhiteTurn = !isWhiteTurn;

            // Adiciona a jogada ao log
            String moveNotation = _toChessNotation(row, col);
            gameLog.add(
              '${isWhiteTurn ? 'Pretas' : 'Brancas'} moveram $piece para $moveNotation',
            );

            // Verifica se o peão chegou ao final do tabuleiro para promoção
            if ((piece == '♙' && row == 0) || (piece == '♟' && row == 7)) {
              isPromoting = true;
              promotionRow = row;
              promotionCol = col;
            }

            // Atualiza a posição do en passant
            if ((piece == '♙' || piece == '♟') &&
                (row - selectedRow).abs() == 2) {
              enPassantRow = row + (piece == '♙' ? 1 : -1);
              enPassantCol = col;
            } else {
              enPassantRow = -1;
              enPassantCol = -1;
            }

            _checkForCheckOrCheckmate();

            // Se não for promoção e for a vez da IA, faz o movimento
            if (!isPromoting && !isWhiteTurn && !isGameOver) {
              _makeAIMove();
            }
          });
        } else {
          setState(() {
            gameLog.add('Movimento inválido: Rei em xeque!');
          });
        }
      } else {
        setState(() {
          selectedRow = -1;
          selectedCol = -1;
          possibleMoves = List.generate(
            8,
            (i) => List.generate(8, (j) => false),
          );
        });
      }
    }
  }

  // Verifica se o movimento é válido (não coloca o rei em xeque)
  bool _isMoveValid(int row, int col) {
    // Simula o movimento
    String piece = board[selectedRow][selectedCol];
    String capturedPiece = board[row][col];
    board[row][col] = piece;
    board[selectedRow][selectedCol] = '';

    // Verifica se o rei está em xeque após o movimento
    bool isKingInCheck = _isKingInCheck(isWhiteTurn);

    // Desfaz o movimento
    board[selectedRow][selectedCol] = piece;
    board[row][col] = capturedPiece;

    return !isKingInCheck;
  }

  // Função para promover o peão
  void _promotePawn(String piece) {
    setState(() {
      board[promotionRow][promotionCol] = piece;
      isPromoting = false;
      promotionRow = -1;
      promotionCol = -1;

      // Verifica se a IA deve jogar após a promoção
      if (!isWhiteTurn && !isGameOver) {
        _makeAIMove();
      }
    });
  }

  // Diálogo para escolher a peça de promoção
  void _showPromotionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Promover peão'),
          content: Text('Escolha a peça para promover:'),
          actions: [
            TextButton(
              onPressed: () => _promotePawn(isWhiteTurn ? '♕' : '♛'),
              child: Text('Rainha'),
            ),
            TextButton(
              onPressed: () => _promotePawn(isWhiteTurn ? '♖' : '♜'),
              child: Text('Torre'),
            ),
            TextButton(
              onPressed: () => _promotePawn(isWhiteTurn ? '♗' : '♝'),
              child: Text('Bispo'),
            ),
            TextButton(
              onPressed: () => _promotePawn(isWhiteTurn ? '♘' : '♞'),
              child: Text('Cavalo'),
            ),
          ],
        );
      },
    );
  }

  // Converte coordenadas para notação de xadrez (ex: 0,0 -> a8)
  String _toChessNotation(int row, int col) {
    String file = String.fromCharCode('a'.codeUnitAt(0) + col);
    int rank = 8 - row;
    return '$file$rank';
  }

  // Verifica se a peça pertence ao jogador atual
  bool _isCurrentPlayerPiece(int row, int col) {
    String piece = board[row][col];
    if (isWhiteTurn) {
      return piece == '♙' ||
          piece == '♖' ||
          piece == '♘' ||
          piece == '♗' ||
          piece == '♕' ||
          piece == '♔';
    } else {
      return piece == '♟' ||
          piece == '♜' ||
          piece == '♞' ||
          piece == '♝' ||
          piece == '♛' ||
          piece == '♚';
    }
  }

  // Calcula os movimentos possíveis para a peça selecionada
  void _calculatePossibleMoves(int row, int col) {
    String piece = board[row][col];
    possibleMoves = List.generate(8, (i) => List.generate(8, (j) => false));

    if (piece == '♙' || piece == '♟') {
      // Movimento dos peões
      int direction = (piece == '♙') ? -1 : 1;
      if (row + direction >= 0 && row + direction < 8) {
        if (board[row + direction][col].isEmpty) {
          possibleMoves[row + direction][col] = true;
        }
        // Captura diagonal
        if (col > 0 &&
            board[row + direction][col - 1].isNotEmpty &&
            !_isCurrentPlayerPiece(row + direction, col - 1)) {
          possibleMoves[row + direction][col - 1] = true;
        }
        if (col < 7 &&
            board[row + direction][col + 1].isNotEmpty &&
            !_isCurrentPlayerPiece(row + direction, col + 1)) {
          possibleMoves[row + direction][col + 1] = true;
        }
        // Primeiro movimento (duas casas)
        if ((row == 6 && piece == '♙') || (row == 1 && piece == '♟')) {
          if (board[row + 2 * direction][col].isEmpty) {
            possibleMoves[row + 2 * direction][col] = true;
          }
        }
        // En passant
        if (row == enPassantRow &&
            (col == enPassantCol - 1 || col == enPassantCol + 1)) {
          possibleMoves[enPassantRow][enPassantCol] = true;
        }
      }
    } else if (piece == '♖' || piece == '♜') {
      // Movimento da torre
      _calculateStraightMoves(row, col);
    } else if (piece == '♘' || piece == '♞') {
      // Movimento do cavalo
      _calculateKnightMoves(row, col);
    } else if (piece == '♗' || piece == '♝') {
      // Movimento do bispo
      _calculateDiagonalMoves(row, col);
    } else if (piece == '♕' || piece == '♛') {
      // Movimento da rainha
      _calculateStraightMoves(row, col);
      _calculateDiagonalMoves(row, col);
    } else if (piece == '♔' || piece == '♚') {
      // Movimento do rei
      _calculateKingMoves(row, col);
    }
  }

  // Movimentos do rei
  void _calculateKingMoves(int row, int col) {
    for (int i = row - 1; i <= row + 1; i++) {
      for (int j = col - 1; j <= col + 1; j++) {
        if (i >= 0 && i < 8 && j >= 0 && j < 8) {
          if (board[i][j].isEmpty || !_isCurrentPlayerPiece(i, j)) {
            possibleMoves[i][j] = true;
          }
        }
      }
    }

    // Verifica se o roque é possível
    if (isWhiteTurn) {
      if (whiteKingSideCastle && board[7][5].isEmpty && board[7][6].isEmpty) {
        possibleMoves[7][6] = true;
      }
      if (whiteQueenSideCastle &&
          board[7][1].isEmpty &&
          board[7][2].isEmpty &&
          board[7][3].isEmpty) {
        possibleMoves[7][2] = true;
      }
    } else {
      if (blackKingSideCastle && board[0][5].isEmpty && board[0][6].isEmpty) {
        possibleMoves[0][6] = true;
      }
      if (blackQueenSideCastle &&
          board[0][1].isEmpty &&
          board[0][2].isEmpty &&
          board[0][3].isEmpty) {
        possibleMoves[0][2] = true;
      }
    }
  }

  // Movimentos em linha reta (torre e rainha)
  void _calculateStraightMoves(int row, int col) {
    for (int i = row - 1; i >= 0; i--) {
      if (board[i][col].isEmpty) {
        possibleMoves[i][col] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, col)) {
          possibleMoves[i][col] = true;
        }
        break;
      }
    }
    for (int i = row + 1; i < 8; i++) {
      if (board[i][col].isEmpty) {
        possibleMoves[i][col] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, col)) {
          possibleMoves[i][col] = true;
        }
        break;
      }
    }
    for (int j = col - 1; j >= 0; j--) {
      if (board[row][j].isEmpty) {
        possibleMoves[row][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(row, j)) {
          possibleMoves[row][j] = true;
        }
        break;
      }
    }
    for (int j = col + 1; j < 8; j++) {
      if (board[row][j].isEmpty) {
        possibleMoves[row][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(row, j)) {
          possibleMoves[row][j] = true;
        }
        break;
      }
    }
  }

  // Movimentos diagonais (bispo e rainha)
  void _calculateDiagonalMoves(int row, int col) {
    for (int i = row - 1, j = col - 1; i >= 0 && j >= 0; i--, j--) {
      if (board[i][j].isEmpty) {
        possibleMoves[i][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, j)) {
          possibleMoves[i][j] = true;
        }
        break;
      }
    }
    for (int i = row - 1, j = col + 1; i >= 0 && j < 8; i--, j++) {
      if (board[i][j].isEmpty) {
        possibleMoves[i][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, j)) {
          possibleMoves[i][j] = true;
        }
        break;
      }
    }
    for (int i = row + 1, j = col - 1; i < 8 && j >= 0; i++, j--) {
      if (board[i][j].isEmpty) {
        possibleMoves[i][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, j)) {
          possibleMoves[i][j] = true;
        }
        break;
      }
    }
    for (int i = row + 1, j = col + 1; i < 8 && j < 8; i++, j++) {
      if (board[i][j].isEmpty) {
        possibleMoves[i][j] = true;
      } else {
        if (!_isCurrentPlayerPiece(i, j)) {
          possibleMoves[i][j] = true;
        }
        break;
      }
    }
  }

  // Movimentos do cavalo
  void _calculateKnightMoves(int row, int col) {
    List<List<int>> moves = [
      [row - 2, col - 1],
      [row - 2, col + 1],
      [row - 1, col - 2],
      [row - 1, col + 2],
      [row + 1, col - 2],
      [row + 1, col + 2],
      [row + 2, col - 1],
      [row + 2, col + 1],
    ];
    for (var move in moves) {
      int i = move[0], j = move[1];
      if (i >= 0 && i < 8 && j >= 0 && j < 8) {
        if (board[i][j].isEmpty || !_isCurrentPlayerPiece(i, j)) {
          possibleMoves[i][j] = true;
        }
      }
    }
  }

  // Verifica se o rei está em xeque
  bool _isKingInCheck(bool isWhiteKing) {
    int kingRow = isWhiteKing ? whiteKingRow : blackKingRow;
    int kingCol = isWhiteKing ? whiteKingCol : blackKingCol;

    // Verifica se alguma peça adversária pode atacar o rei
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (board[row][col].isNotEmpty &&
            _isCurrentPlayerPiece(row, col) == !isWhiteKing) {
          _calculatePossibleMoves(row, col);
          if (possibleMoves[kingRow][kingCol]) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Verifica se há xeque ou xeque-mate
  void _checkForCheckOrCheckmate() {
    bool isWhiteKing = isWhiteTurn;
    if (_isKingInCheck(isWhiteKing)) {
      setState(() {
        statusMessage =
            isWhiteKing
                ? 'Xeque! Rei branco em perigo!'
                : 'Xeque! Rei preto em perigo!';
      });

      // Verifica se é xeque-mate
      if (_isCheckmate(isWhiteKing)) {
        setState(() {
          statusMessage =
              isWhiteKing
                  ? 'Xeque-mate! Pretas venceram!'
                  : 'Xeque-mate! Brancas venceram!';
          isGameOver = true;
        });
      }
    } else {
      setState(() {
        statusMessage = '';
      });
    }
  }

  // Verifica se é xeque-mate
  bool _isCheckmate(bool isWhiteKing) {
    // Verifica se o rei tem movimentos válidos
    int kingRow = isWhiteKing ? whiteKingRow : blackKingRow;
    int kingCol = isWhiteKing ? whiteKingCol : blackKingCol;

    _calculateKingMoves(kingRow, kingCol);
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (possibleMoves[i][j]) {
          return false; // Ainda há movimentos válidos
        }
      }
    }

    return true; // Não há movimentos válidos (xeque-mate)
  }

  // IA mais avançada: Minimax com poda alfa-beta
  void _makeAIMove() {
    if (isGameOver) return;

    // Define a profundidade da busca com base na dificuldade
    int depth = aiDifficulty == 1 ? 2 : (aiDifficulty == 2 ? 3 : 4);

    // Executa o algoritmo Minimax
    Map<String, dynamic> bestMove = _minimax(
      depth,
      -double.infinity,
      double.infinity,
      false, // AI is the minimizing player
    );

    // Aplica o melhor movimento encontrado
    if (bestMove['move'] != null) {
      setState(() {
        int fromRow = bestMove['move']['fromRow'];
        int fromCol = bestMove['move']['fromCol'];
        int toRow = bestMove['move']['toRow'];
        int toCol = bestMove['move']['toCol'];

        // Move a peça
        String piece = board[fromRow][fromCol];
        board[toRow][toCol] = piece;
        board[fromRow][fromCol] = '';
        isWhiteTurn = true; // Passa a vez para o jogador humano

        // Adiciona a jogada ao log
        String moveNotation = _toChessNotation(toRow, toCol);
        gameLog.add('IA moveu $piece para $moveNotation');

        _checkForCheckOrCheckmate(); // Verifica xeque ou xeque-mate
      });
    }
  }

  // Algoritmo Minimax com poda alfa-beta
  Map<String, dynamic> _minimax(
    int depth,
    double alpha,
    double beta,
    bool maximizingPlayer,
  ) {
    if (depth == 0 || isGameOver) {
      return {'value': _evaluateBoard()};
    }

    Map<String, dynamic> bestMove = {
      'value': maximizingPlayer ? -double.infinity : double.infinity,
    };

    // Gera todos os movimentos possíveis para o jogador atual
    List<Map<String, int>> allMoves = _generateAllMoves(maximizingPlayer);

    for (var move in allMoves) {
      int row = move['fromRow']!;
      int col = move['fromCol']!;
      int i = move['toRow']!;
      int j = move['toCol']!;

      // Simula o movimento
      String piece = board[row][col];
      String capturedPiece = board[i][j];
      board[i][j] = piece;
      board[row][col] = '';

      // Chama recursivamente o Minimax
      Map<String, dynamic> currentMove = _minimax(
        depth - 1,
        alpha,
        beta,
        !maximizingPlayer,
      );
      currentMove['move'] = {
        'fromRow': row,
        'fromCol': col,
        'toRow': i,
        'toCol': j,
      };

      // Desfaz o movimento
      board[row][col] = piece;
      board[i][j] = capturedPiece;

      // Atualiza o melhor movimento
      if (maximizingPlayer) {
        if (currentMove['value'] > bestMove['value']) {
          bestMove = currentMove;
        }
        alpha = max(alpha, bestMove['value']);
      } else {
        if (currentMove['value'] < bestMove['value']) {
          bestMove = currentMove;
        }
        beta = min(beta, bestMove['value']);
      }

      // Poda alfa-beta
      if (beta <= alpha) {
        break;
      }
    }

    return bestMove;
  }

  // Gera todos os movimentos possíveis para o jogador atual
  List<Map<String, int>> _generateAllMoves(bool isWhite) {
    List<Map<String, int>> moves = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (board[row][col].isNotEmpty &&
            _isCurrentPlayerPiece(row, col) == isWhite) {
          _calculatePossibleMoves(row, col);
          for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
              if (possibleMoves[i][j]) {
                moves.add({
                  'fromRow': row,
                  'fromCol': col,
                  'toRow': i,
                  'toCol': j,
                });
              }
            }
          }
        }
      }
    }

    return moves;
  }

  // Avalia o tabuleiro para o algoritmo Minimax
  double _evaluateBoard() {
    double score = 0.0;
    Map<String, double> pieceValues = {
      '♙': 1.0,
      '♖': 5.0,
      '♘': 3.0,
      '♗': 3.0,
      '♕': 9.0,
      '♔': 100.0,
      '♟': -1.0,
      '♜': -5.0,
      '♞': -3.0,
      '♝': -3.0,
      '♛': -9.0,
      '♚': -100.0,
    };

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        String piece = board[row][col];
        if (pieceValues.containsKey(piece)) {
          score += pieceValues[piece]!;
        }
      }
    }

    // Adiciona avaliação de controle do centro e segurança do rei
    score += _evaluateCenterControl();
    score += _evaluateKingSafety();

    return score;
  }

  // Avalia o controle do centro do tabuleiro
  double _evaluateCenterControl() {
    double score = 0.0;
    List<List<int>> centerSquares = [
      [3, 3],
      [3, 4],
      [4, 3],
      [4, 4],
    ];

    for (var square in centerSquares) {
      int row = square[0];
      int col = square[1];
      String piece = board[row][col];

      if (piece.isNotEmpty) {
        if (_isCurrentPlayerPiece(row, col)) {
          score += 0.5; // Valor positivo para peças do jogador atual
        } else {
          score -= 0.5; // Valor negativo para peças do oponente
        }
      }
    }

    return score;
  }

  // Avalia a segurança do rei
  double _evaluateKingSafety() {
    double score = 0.0;

    // Avalia a segurança do rei branco
    if (_isKingInCheck(true)) {
      score -= 1.0; // Penalidade se o rei branco estiver em xeque
    }

    // Avalia a segurança do rei preto
    if (_isKingInCheck(false)) {
      score += 1.0; // Penalidade se o rei preto estiver em xeque
    }

    return score;
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      selectedRow = -1;
      selectedCol = -1;
      possibleMoves = List.generate(8, (i) => List.generate(8, (j) => false));
      isWhiteTurn = true;
      statusMessage = '';
      whiteKingSideCastle = true;
      whiteQueenSideCastle = true;
      blackKingSideCastle = true;
      blackQueenSideCastle = true;
      isGameOver = false;
      gameLog.clear();
      gameLog.add('Bem-vindo ao Xadrez em Flutter!');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Exibe o diálogo de promoção se necessário
    if (isPromoting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPromotionDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('Xadrez em Flutter')),
      body: Column(
        children: [
          // Tabuleiro com altura fixa
          Container(
            height: MediaQuery.of(context).size.width, // Tabuleiro quadrado
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                return GestureDetector(
                  onTap: () => _movePiece(row, col),
                  child: Container(
                    color:
                        (row + col) % 2 == 0 ? Colors.white : Colors.grey[400],
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            board[row][col],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isWhiteTurn && possibleMoves[row][col])
                          Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Mensagem de status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              statusMessage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          // Botão para reiniciar o jogo
          if (isGameOver)
            ElevatedButton(
              onPressed: _resetGame,
              child: Text('Reiniciar Jogo'),
            ),
          // Console de mensagens com scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:
                    gameLog
                        .map(
                          (log) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(log),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
