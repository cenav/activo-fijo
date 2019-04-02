CREATE OR REPLACE TRIGGER pevisa.tai_activo_fijo_kardex
    AFTER INSERT
    ON pevisa.activo_fijo
    FOR EACH ROW
    DISABLE
DECLARE
    -- Trigger que al crear un activo fijo, replica la creacion al maestro de articulos del kardex
    art   pcarticul%ROWTYPE;
    clase activo_fijo_clase%ROWTYPE;
BEGIN

    art.cod_art := :new.cod_activo_fijo;
    art.descripcion := substr(:new.descripcion, 0, 100);
    clase := api_activo_fijo_clase.ONEROW(:new.cod_clase);
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

    --     api_pcarticul.INS(art);
    sys.dbms_output.PUT_LINE(rpad('Articulo:', 12) || art.cod_art);
END;