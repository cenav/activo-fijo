CREATE OR REPLACE TRIGGER pevisa.tai_activo_fijo_kardex
    AFTER INSERT
    ON pevisa.activo_fijo
    FOR EACH ROW
    DISABLE
DECLARE
    art pcarticul%ROWTYPE;
BEGIN
    art.cod_art := :new.cod_activo_fijo;
    art.descripcion := substr(:new.descripcion, 0, 100);
    art.linea := '2049'; --TODO
    art.und := 'UND';
    art.partida := '11111111';
    art.id := '1';
    art.cta := :new.cuenta_contable;
    art.refe := 'ACTIVO FIJO';
    art.cif := 0;
    art.fob := 0;
    art.calm := 550.5952; --TODO
    art.fecha := sysdate; -- TODO
    art.der := 550.5952; -- TODO
    art.fecha_modi := sysdate; -- TODO
    art.cod_planta := '.';
    art.linea_cos := '204'; --TODO
    art.indicador := 'CL'; --TODO
    art.cod_unx := :new.cod_activo_fijo;

--     api_pcarticul.INS(art);

    sys.dbms_output.PUT_LINE(rpad('Articulo:', 12) || art.cod_art);
END;