CREATE OR REPLACE PACKAGE PEVISA.pkg_activo_fijo_cst AS
    c_tributaria      CONSTANT VARCHAR2(3) := 'TRB';
    c_precios         CONSTANT VARCHAR2(3) := 'PRC';
    c_niif            CONSTANT VARCHAR2(3) := 'NIF';
    c_libro_deprec    CONSTANT VARCHAR2(2) := '09';
    c_libro_baja      CONSTANT VARCHAR2(2) := '05';
    c_libro_transf    CONSTANT VARCHAR2(2) := '05';
    c_estado_activado CONSTANT VARCHAR2(2) := '1';
    c_salida_transac  CONSTANT VARCHAR2(2) := '22';
    c_salida_serie    CONSTANT NUMBER := 1;
END;