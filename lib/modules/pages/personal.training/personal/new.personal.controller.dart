import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sgem/config/api/api.personal.dart';
import 'package:sgem/config/api/api.archivo.dart';
import 'package:sgem/config/api/response.handler.dart';
import 'package:sgem/shared/modules/personal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sgem/shared/widgets/alert/widget.alert.dart';
import 'package:sgem/shared/widgets/save/widget.save.personal.confirmation.dart';

class NewPersonalController extends GetxController {
  final TextEditingController dniController = TextEditingController();
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController puestoTrabajoController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController apellidoPaternoController =
      TextEditingController();
  final TextEditingController apellidoMaternoController =
      TextEditingController();
  final TextEditingController gerenciaController = TextEditingController();
  final TextEditingController fechaIngresoController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController categoriaLicenciaController =
      TextEditingController();
  final TextEditingController codigoLicenciaController =
      TextEditingController();
  final TextEditingController fechaIngresoMinaController =
      TextEditingController();
  final TextEditingController fechaRevalidacionController =
      TextEditingController();
  final TextEditingController restriccionesController = TextEditingController();

  final PersonalService personalService = PersonalService();
  var selectedGuardiaKey = RxnInt();

  Personal? personalData;
  Rxn<Uint8List?> personalPhoto = Rxn<Uint8List?>();
  var estadoPersonal = 'Cesado'.obs;

  RxBool isOperacionMina = false.obs;
  RxBool isZonaPlataforma = false.obs;

  var documentoAdjuntoNombre = ''.obs;
  var documentoAdjuntoBytes = Rxn<Uint8List>();

  var archivosAdjuntos = <Map<String, dynamic>>[].obs;
  final ArchivoService archivoService = ArchivoService();

  RxBool isLoadingDni = false.obs;
  RxBool isSaving = false.obs;
  List<String> errores = [];

  Future<void> loadPersonalPhoto(int idOrigen) async {
    try {
      final photoResponse =
          await personalService.obtenerFotoPorCodigoOrigen(idOrigen);
      log(photoResponse.data.toString());

      if (photoResponse.success && photoResponse.data != null) {
        personalPhoto.value = photoResponse.data;
        log('Foto del personal cargada con éxito');
      } else {
        log('Error al cargar la foto: ${photoResponse.message}');
      }
    } catch (e) {
      log('Error al cargar la foto del personal: $e');
    }
  }

  Future<void> buscarPersonalPorDni(String dni) async {
    if (dni.isEmpty) {
      _mostrarErroresValidacion(Get.context!, ['Ingrese un DNI válido.']);
      resetControllers();
      return;
    }
    try {
      isLoadingDni.value = true;
      final responseListar = await personalService.listarPersonalEntrenamiento(
        numeroDocumento: dni,
      );

      if (responseListar.success &&
          responseListar.data != null &&
          responseListar.data!.isNotEmpty) {
        _mostrarErroresValidacion(Get.context!,
            ['La persona ya se encuentra registrada en el sistema.']);
        return;
      }

      final responseBuscar = await personalService.buscarPersonalPorDni(dni);

      if (responseBuscar.success && responseBuscar.data != null) {
        personalData = responseBuscar.data;
        log('Personal encontrado: ${personalData!.toJson().toString()}');
        llenarControladores(personalData!);
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(
          content: Text('Personal no encontrado'),
          backgroundColor: Colors.red,
        ));
        resetControllers();
        log('Error al buscar el personal: ${responseBuscar.message}');
      }
    } catch (e) {
      log('Error inesperado al buscar el personal: $e');
    } finally {
      isLoadingDni.value = false;
    }
  }

  DateTime? parseDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(rawDate);
    } catch (e) {
      log('Error al parsear la fecha: $e');
      return null;
    }
  }

  void llenarControladores(Personal? personal) {
    if (personal != null) {
      loadPersonalPhoto(personal.inPersonalOrigen);
      dniController.text = personal.numeroDocumento;
      nombresController.text =
          '${personal.primerNombre} ${personal.segundoNombre}';
      puestoTrabajoController.text = personal.cargo;
      codigoController.text = personal.codigoMcp;
      apellidoPaternoController.text = personal.apellidoPaterno;
      apellidoMaternoController.text = personal.apellidoMaterno;
      gerenciaController.text = personal.gerencia;

      fechaIngresoController.text = personal.fechaIngreso != null
          ? formatDate(personal.fechaIngreso!)
          : '';

      fechaIngresoMinaController.text = personal.fechaIngresoMina != null
          ? formatDate(personal.fechaIngresoMina!)
          : '';

      fechaRevalidacionController.text = personal.licenciaVencimiento != null
          ? formatDate(personal.licenciaVencimiento!)
          : '';

      areaController.text = personal.area;
      categoriaLicenciaController.text = personal.licenciaCategoria;
      codigoLicenciaController.text = personal.licenciaConducir;
      restriccionesController.text = personal.restricciones;
      if (personal.guardia.key != 0) {
        selectedGuardiaKey.value = personal.guardia.key;
      } else {
        selectedGuardiaKey.value = null;
      }
      isOperacionMina.value = personal.operacionMina == 'S';
      isZonaPlataforma.value = personal.zonaPlataforma == 'S';

      if (personal.estado.nombre == 'Activo') {
        estadoPersonal.value = 'Activo';
      } else {
        estadoPersonal.value = 'Cesado';
      }
      obtenerArchivosRegistrados(1, personal.key);
    }
  }

  Future<bool> gestionarPersona({
    required String accion,
    String? motivoEliminacion,
    required BuildContext context,
  }) async {
    errores.clear();
    log('Gestionando persona con la acción: $accion');
    bool esValido = validate(context);
    if (!esValido) {
      _mostrarErroresValidacion(context, errores);
      return false;
    }
    try {
      isSaving.value = true;

      String _obtenerPrimerNombre(String nombres) {
        List<String> nombresSplit = nombres.split(' ');
        return nombresSplit.isNotEmpty ? nombresSplit.first : '';
      }

      String _obtenerSegundoNombre(String nombres) {
        List<String> nombresSplit = nombres.split(' ');
        return nombresSplit.length > 1 ? nombresSplit[1] : '';
      }

      String _verificarTexto(String texto) {
        return texto.isNotEmpty ? texto : '';
      }

      DateTime? _parsearFecha(String fechaTexto) {
        return fechaTexto.isNotEmpty
            ? DateFormat('yyyy-MM-dd').parse(fechaTexto)
            : null;
      }

      personalData!
        ..primerNombre = _obtenerPrimerNombre(nombresController.text)
        ..segundoNombre = _obtenerSegundoNombre(nombresController.text)
        ..apellidoPaterno = _verificarTexto(apellidoPaternoController.text)
        ..apellidoMaterno = _verificarTexto(apellidoMaternoController.text)
        ..cargo = _verificarTexto(puestoTrabajoController.text)
        ..fechaIngreso = _parsearFecha(fechaIngresoController.text)
        ..licenciaConducir = _verificarTexto(codigoLicenciaController.text)
        ..fechaIngresoMina = _parsearFecha(fechaIngresoMinaController.text)
        ..licenciaVencimiento = _parsearFecha(fechaRevalidacionController.text)
        ..guardia.key = selectedGuardiaKey.value ?? 0
        ..operacionMina = isOperacionMina.value ? 'S' : 'N'
        ..zonaPlataforma = isZonaPlataforma.value ? 'S' : 'N'
        ..restricciones = _verificarTexto(restriccionesController.text);

      if (accion == 'eliminar') {
        personalData!
          ..eliminado = 'S'
          ..motivoElimina = motivoEliminacion ?? 'Sin motivo'
          ..usuarioElimina = 'usuarioActual';
      }

      final response = await _accionPersona(accion);

      if (response.success) {
        log('Acción $accion realizada exitosamente');
        await registrarArchivos(dniController.text);
        if (accion == 'registrar' || accion == 'actualizar') {
          _mostrarMensajeGuardado(context);
        }

        return true;
      } else {
        log('Acción $accion fallida: ${response.message}');
        return false;
      }
    } catch (e) {
      log('Error al $accion persona: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<ResponseHandler<bool>> _accionPersona(String accion) async {
    log('Personal: ${personalData.toString()}');
    switch (accion) {
      case 'registrar':
        log('Registrar');
        return personalService.registrarPersona(personalData!);
      case 'actualizar':
        log('Actualizar');
        return personalService.actualizarPersona(personalData!);
      case 'eliminar':
        log('Eliminar');
        return personalService.eliminarPersona(personalData!);
      default:
        throw Exception('Acción no reconocida: $accion');
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  //Validaciones
  bool validate(BuildContext context) {
    /*
    if (dniController.text.isEmpty ||
        dniController.text.length != 8 ||
        !RegExp(r'^\d+$').hasMatch(dniController.text)) {
      errores.add('Debe ingresar un DNI válido.');
    }

    if (nombresController.text.isEmpty) {
      errores.add('El campo de nombres no puede estar vacío.');
    }
    if (apellidoPaternoController.text.isEmpty) {
      errores.add('El campo de apellido paterno no puede estar vacío.');
    }
    if (apellidoMaternoController.text.isEmpty) {
      errores.add('El campo de apellido materno no puede estar vacío.');
    }*/
    DateTime? fechaIngreso = parseDate(fechaIngresoController.text);
    DateTime? fechaIngresoMina = parseDate(fechaIngresoMinaController.text);

    if (fechaIngresoMina == null) {
      errores.add('Debe seleccionar una fecha de ingreso a la mina.');
    } else {
      if (fechaIngresoMina.isBefore(DateTime.now())) {
        errores.add(
            'La fecha de ingreso a la mina debe ser mayor a la fecha actual.');
      }

      if (fechaIngreso != null && fechaIngresoMina.isBefore(fechaIngreso)) {
        errores.add(
            'La fecha de ingreso a la mina debe ser mayor que la fecha de ingreso a la empresa.');
      }
    }

    if (codigoLicenciaController.text.isEmpty ||
        codigoLicenciaController.text.length != 9) {
      errores
          .add('El código de licencia debe tener 9 caracteres alfanuméricos.');
    }

    if (selectedGuardiaKey.value == null) {
      errores.add('Debe seleccionar una guardia.');
    }
    if (restriccionesController.text.length > 100) {
      errores
          .add('El campo de restricciones no debe exceder los 100 caracteres.');
    }
    if (errores.isNotEmpty) {
      return false;
    }
    return true;
  }

  Future<void> adjuntarDocumentos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx'],
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.bytes != null) {
            Uint8List fileBytes = file.bytes!;
            String fileName = file.name;

            archivosAdjuntos.add({
              'nombre': fileName,
              'bytes': fileBytes,
            });
            log('Documento adjuntado correctamente: $fileName');
          }
        }
      } else {
        log('No se seleccionaron archivos');
      }
    } catch (e) {
      log('Error al adjuntar documentos: $e');
    }
  }

  void eliminarArchivo(String nombreArchivo) {
    archivosAdjuntos
        .removeWhere((archivo) => archivo['nombre'] == nombreArchivo);
    log('Archivo $nombreArchivo eliminado');
  }

  Future<void> registrarArchivos(String dni) async {
    try {
      final personalResponse = await personalService
          .listarPersonalEntrenamiento(numeroDocumento: dni);

      if (personalResponse.success && personalResponse.data!.isNotEmpty) {
        int origenKey = personalResponse.data!.first.key;
        log('Key del personal obtenida: $origenKey');

        for (var archivo in archivosAdjuntos) {
          try {
            String datosBase64 = base64Encode(archivo['bytes']);
            String extension = archivo['nombre'].split('.').last;
            String mimeType = _determinarMimeType(extension);

            final response = await archivoService.registrarArchivo(
              key: 0,
              nombre: archivo['nombre'],
              extension: extension,
              mime: mimeType,
              datos: datosBase64,
              inTipoArchivo: 1,
              inOrigen: 1, // 1: TABLA Personal
              inOrigenKey: origenKey,
            );

            if (response.success) {
              log('Archivo ${archivo['nombre']} registrado con éxito');
            } else {
              log('Error al registrar archivo ${archivo['nombre']}: ${response.message}');
            }
          } catch (e) {
            log('Error al registrar archivo ${archivo['nombre']}: $e');
          }
        }
      } else {
        log('Error al obtener la key del personal');
      }
    } catch (e) {
      log('Error al registrar archivos: $e');
    }
  }

  Future<void> obtenerArchivosRegistrados(int idOrigen, int idOrigenKey) async {
    log('Obteniendo archivos registrados');
    log('idOrigen: $idOrigen, idOrigenKey: $idOrigenKey');
    try {
      final response = await archivoService.obtenerArchivosPorOrigen(
        idOrigen: idOrigen,
        idOrigenKey: idOrigenKey,
      );
      log('Response: ${response.data}');
      if (response.success && response.data != null) {
        archivosAdjuntos.clear();
        for (var archivo in response.data!) {
          List<int> datos = List<int>.from(archivo['Datos']);
          Uint8List archivoBytes = Uint8List.fromList(datos);

          archivosAdjuntos.add({
            'nombre': archivo['Nombre'],
            'bytes': archivoBytes,
          });

          log('Archivo ${archivo['Nombre']} obtenido con éxito');
        }
      } else {
        log('Error al obtener archivos: ${response.message}');
      }
    } catch (e) {
      log('Error al obtener archivos: $e');
    }
  }

  String _determinarMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  void _mostrarMensajeGuardado(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const MensajeGuardadoWidget();
      },
    );
  }

  void _mostrarErroresValidacion(BuildContext context, List<String> errores) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MensajeValidacionWidget(errores: errores);
      },
    );
  }

  void resetControllers() {
    dniController.clear();
    nombresController.clear();
    puestoTrabajoController.clear();
    codigoController.clear();
    apellidoPaternoController.clear();
    apellidoMaternoController.clear();
    gerenciaController.clear();
    fechaIngresoController.clear();
    areaController.clear();
    categoriaLicenciaController.clear();
    codigoLicenciaController.clear();
    fechaIngresoMinaController.clear();
    fechaRevalidacionController.clear();
    restriccionesController.clear();
    selectedGuardiaKey.value = null;
    personalPhoto.value = null;
    isOperacionMina.value = false;
    isZonaPlataforma.value = false;
    estadoPersonal.value = 'Activo';
    documentoAdjuntoNombre.value = '';
    documentoAdjuntoBytes.value = null;
    personalData = null;
  }
}
