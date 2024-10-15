import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sgem/config/api/response.handler.dart';
import 'package:sgem/config/constants/config.dart';
import 'package:sgem/shared/modules/entrenamiento.modulo.dart';
import 'package:sgem/shared/modules/modulo.maestro.dart';
import 'dart:developer';

class ModuloMaestroService {
  final Dio dio = Dio();

  ModuloMaestroService() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
    ));
  }

  Future<ResponseHandler<List<ModuloMaestro>>> listarMaestros() async {
    const url = '${ConfigFile.apiUrl}/modulo/ListarModuloMaestro';

    try {
      final response = await dio.get(
        url,
        options: Options(
          followRedirects: false,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        List<ModuloMaestro> maestros = List<ModuloMaestro>.from(
          response.data.map((json) => ModuloMaestro.fromJson(json)),
        );
        return ResponseHandler.handleSuccess<List<ModuloMaestro>>(maestros);
      } else {
        return ResponseHandler(
          success: false,
          message: 'Error al listar modulos',
        );
      }
    } on DioException catch (e) {
      return ResponseHandler.handleFailure<List<ModuloMaestro>>(e);
    }
  }

  Future<ResponseHandler<List<EntrenamientoModulo>>>
      listarModulosPorEntrenamiento(int entrenamientoId) async {
    final url =
        '${ConfigFile.apiUrl}/modulo/ListarModulosPorEntrenamiento/$entrenamientoId';

    try {
      final response = await dio.get(
        url,
        options: Options(followRedirects: false),
      );

      if (response.statusCode == 200 && response.data != null) {
        List<EntrenamientoModulo> modulos = List<EntrenamientoModulo>.from(
          response.data.map((json) => EntrenamientoModulo.fromJson(json)),
        );
        return ResponseHandler.handleSuccess<List<EntrenamientoModulo>>(
            modulos);
      } else {
        return ResponseHandler(
          success: false,
          message: 'Error al listar los módulos por entrenamiento',
        );
      }
    } on DioException catch (e) {
      return ResponseHandler.handleFailure<List<EntrenamientoModulo>>(e);
    }
  }

  Future<ResponseHandler<bool>> eliminarModulo(
      EntrenamientoModulo modulo) async {
    const url = '${ConfigFile.apiUrl}/modulo/EliminarModulo';

    try {
      final response = await dio.delete(
        url,
        data: modulo.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return ResponseHandler.handleSuccess<bool>(true);
      } else {
        return ResponseHandler(
          success: false,
          message: 'Error al eliminar el módulo',
        );
      }
    } on DioException catch (e) {
      return ResponseHandler.handleFailure<bool>(e);
    }
  }

  Future<ResponseHandler<bool>> registrarModulo(
      EntrenamientoModulo entrenamientoModulo) async {
    log('Registrando nuevo modulo: ${jsonEncode(entrenamientoModulo.toJson())}');
    const url = '${ConfigFile.apiUrl}/modulo/RegistrarModulo';
    try {
      log('Registrando nuevo modulo: ${jsonEncode(entrenamientoModulo.toJson())}');
      final response = await dio.post(
        url,
        data: jsonEncode(entrenamientoModulo.toJson()),
        options: Options(
          followRedirects: false,
        ),
      );
      log("RESPONSE: $response");
      if (response.statusCode == 200 && response.data != null) {
        if (response.data) {
          return ResponseHandler.handleSuccess<bool>(true);
        } else {
          return ResponseHandler(
            success: false,
            message: response.data['Message'] ?? 'Error desconocido',
          );
        }
      } else {
        return ResponseHandler(
          success: false,
          message: 'Error al registrar modulo',
        );
      }
    } on DioException catch (e) {
      log('Error al registrar modulo. Datos: ${jsonEncode(entrenamientoModulo.toJson())}, Error: ${e.response?.data}');
      return ResponseHandler.handleFailure(e);
    }
  }

}
