import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'app_exception.dart';
export 'app_exception.dart';

String errorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'E-mail ou senha inválidos. Confira e tente novamente.',
      'email-already-in-use' => 'Este e-mail já possui uma conta. Faça login.',
      'invalid-email' => 'Informe um e-mail válido.',
      'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
      'network-request-failed' || 'unavailable' =>
        'Sem acesso ao servidor. Suas alterações locais estão preservadas.',
      'too-many-requests' || 'resource-exhausted' =>
        'Muitas solicitações. Aguarde um pouco e tente novamente.',
      'permission-denied' =>
        'Acesso negado. Confira sua sessão e as regras do Firestore.',
      'operation-not-allowed' =>
        'O login por e-mail ainda não foi habilitado no Firebase.',
      'user-disabled' => 'Esta conta foi desativada.',
      'unauthenticated' => 'Sua sessão expirou. Entre novamente.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
  }
  if (error is TimeoutException) {
    return 'O servidor demorou a responder. Tente novamente; os dados locais foram mantidos.';
  }
  if (error is SocketException) return 'Sem conexão com a internet.';
  if (error is FormatException) return 'O servidor retornou dados inesperados.';
  if (error is AppException) return error.message;
  return 'Não foi possível concluir a operação. Tente novamente.';
}
