import 'package:flutter/material.dart';

void main() {
  runApp(MemoryGame());
}

class MemoryGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JogoMemoria(),
    );
  }
}

class JogoMemoria extends StatefulWidget {
  @override
  _JogoMemoriaState createState() => _JogoMemoriaState();
}

class _JogoMemoriaState extends State<JogoMemoria> {
  List<String> emojis = [
    '🐶',
    '🐶',
    '🐱',
    '🐱',
    '🐭',
    '🐭',
    '🐹',
    '🐹',
    '🐰',
    '🐰',
    '🦊',
    '🦊',
    '🐻',
    '🐻',
    '🐼',
    '🐼',
    '🐨',
    '🐨',
    '🐯',
    '🐯',
    '🦁',
    '🦁',
    '🐮',
    '🐮',
    '🐷',
    '🐷',
    '🐸',
    '🐸',
    '🐵',
    '🐵',
    '🐔',
    '🐔',
    '🐧',
    '🐧',
    '🐦',
    '🐦',
    '🐤',
    '🐤',
    '🦆',
    '🦆',
    '🦅',
    '🦅',
    '🦉',
    '🦉',
    '🦇',
    '🦇',
    '🐺',
    '🐺',
    '🐗',
    '🐗',
    '🐴',
    '🐴',
  ];

  List<bool> cartasViradas = [];

  List<int> cartasSelecionadas = [];

  int paresEncontrados = 0;

  @override
  void initState() {
    super.initState();
    emojis.shuffle();
    cartasViradas = List<bool>.filled(emojis.length, false);
  }

  void _virarCarta(int index) {
    setState(() {
      if (cartasViradas[index] || cartasSelecionadas.length == 2) return;

      cartasViradas[index] = true;
      cartasSelecionadas.add(index);

      if (cartasSelecionadas.length == 2) {
        if (emojis[cartasSelecionadas[0]] == emojis[cartasSelecionadas[1]]) {
          paresEncontrados++;
          cartasSelecionadas.clear();

          if (paresEncontrados == emojis.length ~/ 2) {
            _mostrarMensagemVitoria();
          }
        } else {
          Future.delayed(Duration(milliseconds: 800), () {
            setState(() {
              cartasViradas[cartasSelecionadas[0]] = false;
              cartasViradas[cartasSelecionadas[1]] = false;
              cartasSelecionadas.clear();
            });
          });
        }
      }
    });
  }

  void _mostrarMensagemVitoria() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Parabéns! Você venceu.'),
          content: Text('Você encontrou todos os pares!'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  emojis.shuffle();
                  cartasViradas = List<bool>.filled(emojis.length, false);
                  paresEncontrados = 0;
                  cartasSelecionadas.clear();
                });
                Navigator.of(context).pop();
              },
              child: Text('Jogar novamente'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Memory Game')),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _virarCarta(index),
            child: Container(
              decoration: BoxDecoration(
                color: cartasViradas[index] ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  cartasViradas[index] ? emojis[index] : '',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
