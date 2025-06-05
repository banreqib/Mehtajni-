import 'package:flutter/material.dart';
import 'app_drawer.dart';

class Ads extends StatelessWidget {
  const Ads({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color.fromARGB(255, 38, 95, 134)),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                size: 30,
                color: Color.fromARGB(255, 38, 95, 134),
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'للاعلان و التواصل',
                  style: TextStyle(
                    fontSize: 45,
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 240, 252, 255),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '0788855292 ',
                        style: TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 38, 95, 134),
                          fontFamily: 'Ruqaa',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '0777794585 ',
                        style: TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 38, 95, 134),
                          fontFamily: 'Ruqaa',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'سيتم عرض الاعلان في الصفحة الرئيسية  ',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 38, 95, 134),
                          fontFamily: 'Ruqaa',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
