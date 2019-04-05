CREATE OR REPLACE TRIGGER pevisa.tai_activo_fijo_kardex
    AFTER INSERT
    ON pevisa.activo_fijo
    FOR EACH ROW
DECLARE
    -- Trigger que al crear un activo fijo, replica la creacion al maestro de articulos del kardex
    art   pcarticul%ROWTYPE;
    clase activo_fijo_clase%ROWTYPE;
    mail pkg_types.correo;
BEGIN
    art.cod_art := :new.cod_activo_fijo;
    art.descripcion := substr(:new.descripcion, 0, 100);
    clase := api_activo_fijo_clase.onerow(:new.cod_clase);
    art.linea := clase.linea;
    art.und := 'UND';
    art.partida := '11111111';
    art.id := '1'; -- 1 = Producto Terminado
    art.cta := :new.cuenta_contable;
    art.refe := 'ACTIVO FIJO';
    art.cif := 0;
    art.fob := 0;
    art.fecha := sysdate;
    art.fecha_modi := sysdate;
    art.cod_planta := '.';
    art.linea_cos := '204';
    art.indicador := 'CL'; -- CL = Compra Local Producto Terminado
    art.cod_unx := :new.cod_activo_fijo;

    api_pcarticul.ins(art);

    mail.de := 'sistemas@pevisa.com.pe';
    mail.asunto := 'Creación de Activo Fijo ' || :new.cod_activo_fijo;
    mail.texto := 'Se ha creado el siguiente código desde el módulo de activo fijo' || chr(10) || chr(10);
    mail.texto := rtrim(mail.texto) || rpad('Código: ', 15) || :new.cod_activo_fijo || chr(10);
    mail.texto := rtrim(mail.texto) || rpad('Descripción: ', 15) || :new.descripcion || chr(10);
    enviar_correo(mail.de, 'yhernandez@pevisa.com.pe', mail.asunto, mail.texto);
    enviar_correo(mail.de, 'cnavarro@pevisa.com.pe', mail.asunto, mail.texto);
END;