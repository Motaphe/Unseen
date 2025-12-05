// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unseen/firebase_options.dart';
import 'package:unseen/services/firestore_service.dart';

/// Script to seed Firestore with initial hunt data.
/// 
/// Usage:
///   flutter run lib/scripts/seed_firestore.dart
void main() async {
  // Initialize Flutter bindings (required for Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🌙 Initializing Firebase...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase initialized');
    print('📦 Seeding Firestore with hunt data...');
    print('');
    
    // Create FirestoreService and seed data
    final firestoreService = FirestoreService();
    
    // Seed all hunts
    print('🌙 Seeding "The Forgotten Ritual"...');
    await firestoreService.seedForgottenRitualHunt();
    print('   ✅ Nightmare difficulty - 5 clues - 30 min');
    
    print('🎵 Seeding "The Phantom\'s Lullaby"...');
    await firestoreService.seedPhantomsLullabyHunt();
    print('   ✅ Easy difficulty - 4 clues - 20 min');
    
    print('👻 Seeding "The Whispering Walls"...');
    await firestoreService.seedWhisperingWallsHunt();
    print('   ✅ Medium difficulty - 6 clues - 35 min');
    
    print('💀 Seeding "The Cursed Artifact"...');
    await firestoreService.seedCursedArtifactHunt();
    print('   ✅ Hard difficulty - 7 clues - 45 min');
    
    print('🏠 Seeding "The Dollhouse"...');
    await firestoreService.seedDollhouseHunt();
    print('   ✅ Nightmare difficulty - 6 clues - 40 min');
    
    print('📚 Seeding "The Midnight Library"...');
    await firestoreService.seedMidnightLibraryHunt();
    print('   ✅ Hard difficulty - 5 clues - 35 min');
    
    print('');
    print('✅ Successfully seeded all hunts!');
    print('📊 Summary:');
    print('   - Total hunts: 6');
    print('   - Easy: 1 hunt');
    print('   - Medium: 1 hunt');
    print('   - Hard: 2 hunts');
    print('   - Nightmare: 2 hunts');
    print('');
    print('🎯 You can now test the app with these hunts!');
    
  } catch (e, stackTrace) {
    print('❌ Error seeding Firestore:');
    print('   $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    exit(1);
  }
  
  exit(0);
}
