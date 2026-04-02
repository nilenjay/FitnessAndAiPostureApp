import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/pose_detection/bloc/pose_bloc.dart';
import 'features/pose_detection/data/pose_repository.dart';
import 'features/chat/bloc/chat_bloc.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/workout_plans/bloc/workout_plan_bloc.dart';
import 'features/workout_plans/data/workout_plan_repository.dart';
import 'features/water_intake/bloc/water_intake_cubit.dart';
import 'features/water_intake/data/water_intake_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

  // Initialize notification service
  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthRepository _authRepository;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _authBloc = AuthBloc(authRepository: _authRepository)..add(AuthStarted());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<WorkoutPlanRepository>(create: (_) => WorkoutPlanRepository()),
        RepositoryProvider<PoseRepository>(create: (_) => PoseRepository()),
        RepositoryProvider<ChatRepository>(create: (_) => ChatRepository()),
        RepositoryProvider<WaterIntakeRepository>(create: (_) => WaterIntakeRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<PoseBloc>(
            create: (context) => PoseBloc(
              poseRepository: context.read<PoseRepository>(),
            ),
          ),
          BlocProvider<WorkoutPlanBloc>(
            create: (context) => WorkoutPlanBloc(
              repository: context.read<WorkoutPlanRepository>(),
            ),
          ),
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(
              repository: context.read<ChatRepository>(),
            ),
          ),
          BlocProvider<WaterIntakeCubit>(
            create: (context) => WaterIntakeCubit(
              repository: context.read<WaterIntakeRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'AI Posture Coach',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.createRouter(_authBloc),
        ),
      ),
    );
  }
}
