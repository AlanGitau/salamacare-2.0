import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signup/loginScreen.dart';

class Firstpage extends StatelessWidget {
  const Firstpage({super.key});

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[ 
              Center(
              child: SvgPicture.asset('assets/images/undraw_doctor_kw-5-l.svg',
              height: 180,
              width:180 ,
              ),
              ),
              const SizedBox(height: 30,),
                
              Text('Salama care',
              style: GoogleFonts.pacifico(
                textStyle: const TextStyle(
                  fontSize: 40,
                )
              ),
              ),
                
              const SizedBox(height: 10,),
                
              Text('Welcome to Salama Care, your partner in health',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 20,
                )
              ),
              ),
                
              const SizedBox(height: 10,),
                
              Text('Book appointments with top specialists, Get reminders for upcoming visits and Access your medical records anytime',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 15,
                )
              ),
              ),
              
                
              const SizedBox(height: 25,),
                
            ElevatedButton(onPressed:(){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context)=>const Loginscreen())
              );
              //navigates to the log in screen
            }, 
              style:ElevatedButton.styleFrom(
                elevation: 5,
              ),
              child: const Text('Get started'),
              
              )
            ]
          ),
        ),
        
      ),
    );
  }
}