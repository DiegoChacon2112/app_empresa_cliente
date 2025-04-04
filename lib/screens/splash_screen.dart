import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo MVK
            Image.asset(
              'assets/images/logo_mvk.png',
              height: 120,
              // Se a imagem não existir durante o desenvolvimento, use um placeholder
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      'Logo MVK',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 30),
            
            Text(
              'Área do Cliente MVK',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            
            SizedBox(height: 30),
            
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Carregando...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}