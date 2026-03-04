import 'package:flutter/material.dart';

class Myhome extends StatelessWidget {
  const Myhome ({super.key});

 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          child: Column(
            children: [
              const Center(
                child: Text(
                  'Welcome ',
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              Center(
                child: Image.network(
                  'https://th.bing.com/th/id/OIP.LiwUi8bvQ02j5J2u93PUxgHaDT?rs=1&pid=ImgDetMain',
                  height: 250,
                  width: 250,
                ),
              ),
               Center(
                child: Image.asset("assets/images/portable-samsung-galaxy-a05s-6128go.jpg",
                  height: 250,
                  width: 250,
                ),
              ),
            ],
          ),
        );
  }
}