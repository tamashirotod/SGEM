import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:sgem/shared/utils/Extensions/widgetExtensions.dart';
import 'package:sgem/shared/utils/pdf.view.controller.dart';
import 'package:sgem/shared/utils/pdfFuntions/pdf.descargar.dart';

Widget futureViewPdf(BuildContext context, Future<List<PdfPageImage?>>? futurePdf, double angleRotation) {
  final screenHeigth = MediaQuery.of(context).size.height;
  return  FutureBuilder(
    future: futurePdf,
    builder: (context, AsyncSnapshot<List<PdfPageImage?>> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting){
        return const Center(child: CircularProgressIndicator());
      }
      else if (snapshot.hasData && snapshot.data != null) {
        // Agrupamos las imágenes en pares
        List<List<PdfPageImage?>> rows = [];
        for (int i = 0; i < snapshot.data!.length; i += 2) {
          final range = i + 2 > snapshot.data!.length ? snapshot.data!.length : i + 2;
          rows.add(snapshot.data!.sublist(i, range));
        }
        return Column(
          children: [
            SizedBox(
              height: screenHeigth * 0.8,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rows.map((List<PdfPageImage?> row) {
                    return
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((PdfPageImage? pageImage) => pageImage != null
                              ? Center(
                                  child: Transform.rotate(
                                  angle: angleRotation,
                                  child: Image.memory(pageImage.bytes),
                                ),
                              ).padding(const EdgeInsets.all(10))
                              : const SizedBox.shrink(),
                          ).toList(),
                        ).padding(const EdgeInsets.all(10));
                    // );
                  }).toList(),
                ),
              ) 
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //onCancel;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: (){
                      descargarPaginasComoPdf(snapshot.data!);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Imprimir", style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ]
        );
              
      } else if (snapshot.hasError) {
        return Center(
          child: Text('Error al cargar el PDF: ${snapshot.error}'),
        );
      } else {
        return const Center( child: CircularProgressIndicator());
      } 
    },
  );
}


  
Widget rxFutureViewPdf(BuildContext context, PDFGeneratoController controller, double angleRotation) {
    final screenHeigth = MediaQuery.of(context).size.height;
    return Obx(() {
      if (controller.certificate.isEmpty){
        return const Center(child: CircularProgressIndicator());
      } else  {
          // Agrupamos las imágenes en pares
          List<List<PdfPageImage?>> rows = [];
          for (int i = 0; i < controller.certificate.length; i += 2) {
            final range = i + 2 > controller.certificate.length ? controller.certificate.length : i + 2;
            rows.add(controller.certificate.sublist(i, range));
          }
          return Column(
            children: [
              SizedBox(
                height: screenHeigth * 0.8,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rows.map((List<PdfPageImage?> row) {
                      return
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: row.map((PdfPageImage? pageImage) => pageImage != null
                                ? Center(
                                    child: Transform.rotate(
                                    angle: angleRotation,
                                    child: Image.memory(pageImage.bytes),
                                  ),
                                ).padding(const EdgeInsets.all(10))
                                : const SizedBox.shrink(),
                            ).toList(),
                          ).padding(const EdgeInsets.all(10));
                      // );
                    }).toList(),
                  ),
                ) 
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: (){
                        descargarPaginasComoPdf(controller.certificate);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text("Imprimir", style: TextStyle(color: Colors.white)),
                  )
                ],
              )
            ]
          );
         
      }
    //
    });
  }