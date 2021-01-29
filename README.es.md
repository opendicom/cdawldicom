# cda2mwl

cda2mwl encuentra nuevas OT "solicitud" dicom cda y transforma el contenido del CDA en un worklist file (.wl) usada por dcmtk wlmscpfs para el servidor de lista de trabajo local.

Adicionalmente, cda2mwl guarda las solicitudes en un directorio para eventual reconciliación durante la etapa de coerción de imágenes que fueron creadas sin uso de la worklist 

## Sistema de archvivos de cda2mwl/audit

 ``` 
 /aaaammdd()
    /patientID()
        /StudyInstanceUID()
            solicitud.xml
            modality()/
 ```
 `
 Cuando se reciben los archivos correspondientes a la mwl, se realizan las operaciones siguientes:
 - extracción del StudyInstanceUID
 - si NO es un UID de salud.uy (empiezan con 2.16.858.2)
     - buscar dentro de aaaammdd el patientID correspondiente al del archivo
     - si existe examinar en un loop los SOPInstanceUID correspondientes
         - seleccionar el SOPInstanceUID que corresponde a la modalidad y es el más reciente
         - si existe, guardar la imagen DICOM en esta carpeta y crear un symlink a ella en la carpeta de la tarea de compressión

