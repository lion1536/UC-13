import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(ClickGame());
}

class ClickGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Click Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JogoClique(),
    );
  }
}

class JogoClique extends StatefulWidget {
  @override
  _JogoCliqueState createState() => _JogoCliqueState();
}

class _JogoCliqueState extends State<JogoClique> {
  int _pontuacao = 0;
  int _tempoRestante = 30;
  bool _jogoRodando = false;
  Random _random = Random();
  double _posicaoX = 0;
  double _posicaoY = 0;

  void _iniciarJogo() {
    setState(() {
      _pontuacao = 0;
      _tempoRestante = 30;
      _jogoRodando = true;
      _moverBotao();
      _contadorTempo();
    });
  }

  void _moverBotao() {
    if (_jogoRodando) {
      setState(() {
        _posicaoX =
            _random.nextDouble() * (MediaQuery.of(context).size.width - 100);
        _posicaoY =
            _random.nextDouble() * (MediaQuery.of(context).size.height - 100);
      });
    }
  }

  void _contadorTempo() {
    Future.delayed(Duration(seconds: 1), () {
      if (_tempoRestante > 0 && _jogoRodando) {
        setState(() {
          _tempoRestante--;
        });
        _contadorTempo();
      } else {
        setState(() {
          _jogoRodando = false;
        });
      }
    });
  }

  void _aumentarPontuacao() {
    if (_jogoRodando) {
      setState(() {
        _pontuacao++;
        _moverBotao();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Click Game')),
      body: Stack(
        children: [
          Positioned(
            left: _posicaoX,
            top: _posicaoY,
            child: GestureDetector(
              onTap: _aumentarPontuacao,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red,
                child: Text(
                  'Clique!',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              'Pontuação: $_pontuacao',
              style: TextStyle(fontSize: 24),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              'Tempo: $_tempoRestante',
              style: TextStyle(fontSize: 24),
            ),
          ),
          if (!_jogoRodando)
            Center(
              child: ElevatedButton(
                onPressed: _iniciarJogo,
                child: Text('Iniciar Jogo'),
              ),
            ),
        ],
      ),
    );
  }
}
