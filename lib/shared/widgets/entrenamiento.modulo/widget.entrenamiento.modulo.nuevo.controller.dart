import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../alert/widget.alert.dart';

class EntrenamientoModuloNuevoController extends GetxController {
  TextEditingController fechaInicioController = TextEditingController();
  TextEditingController fechaTerminoController = TextEditingController();
  TextEditingController responsableController = TextEditingController();

  TextEditingController notaTeoricaController =
      TextEditingController(text: '0');
  TextEditingController notaPracticaController =
      TextEditingController(text: '0');
  TextEditingController fechaExamenController = TextEditingController();

  TextEditingController totalHorasModuloController =
      TextEditingController(text: '0');
  TextEditingController horasAcumuladasController =
      TextEditingController(text: '0');
  TextEditingController horasMinestarController =
      TextEditingController(text: '0');

  List<String> errores = [];

  RxBool isSaving = false.obs;
  RxBool isLoadingResponsable = false.obs;

  void resetControllers() {
    fechaInicioController.clear();
    fechaTerminoController.clear();
    responsableController.clear();
    notaTeoricaController.clear();
    notaPracticaController.clear();
    fechaExamenController.clear();
    totalHorasModuloController.clear();
    horasAcumuladasController.clear();
    horasMinestarController.clear();

    errores.clear();

    isSaving.value= false;
    isLoadingResponsable.value=false;
  }
//Validaciones
  bool validar(BuildContext context) {
    bool respuesta = true;
    errores.clear();

    // Validación de la fecha de inicio
    if (fechaInicioController.text.isEmpty) {
      respuesta = false;
      errores.add("Debe seleccionar una fecha de inicio.");
    }

    // Validación de la fecha de término
    if (fechaTerminoController.text.isEmpty) {
      respuesta = false;
      errores.add("Debe seleccionar una fecha de término.");
    }

    // Validación de la nota teórica
    if (notaTeoricaController.text.isEmpty) {
      respuesta = false;
      errores.add("Debe ingresar una nota teórica.");
    } else {
      int? notaTeorica = int.tryParse(notaTeoricaController.text);
      if (notaTeorica == null || notaTeorica < 0) {
        respuesta = false;
        errores.add("La nota teórica debe ser un número mayor o igual a 0.");
      }
    }

    // Validación de la nota práctica (cambiado el mensaje)
    if (notaPracticaController.text.isEmpty) {
      respuesta = false;
      errores.add("Debe ingresar una nota práctica.");
    } else {
      int? notaPractica = int.tryParse(notaPracticaController.text);
      if (notaPractica == null || notaPractica < 0) {
        respuesta = false;
        errores.add("La nota práctica debe ser un número mayor o igual a 0.");
      }
    }

    // Validación de la fecha del examen
    if (fechaExamenController.text.isEmpty) {
      respuesta = false;
      errores.add("Debe seleccionar una fecha de examen.");
    }

    return respuesta;
  }

  Future<bool> registrarModulo(BuildContext context) async {
    if (!validar(context)) {
      _mostrarErroresValidacion(context, errores);
      return false;
    }

    try {
      return true;
    } catch (e) {
      return false;
    } finally {
      //return false;
    }
  }

  void _mostrarErroresValidacion(BuildContext context, List<String> errores) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MensajeValidacionWidget(errores: errores);
      },
    );
  }
}
