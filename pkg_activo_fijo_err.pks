CREATE OR REPLACE PACKAGE PEVISA.pkg_activo_fijo_err IS
    exc_activo_no_existe               EXCEPTION;
    en_activo_no_existe       CONSTANT INTEGER := -20100;
    PRAGMA EXCEPTION_INIT (exc_activo_no_existe
                         , -20100);

    exc_ubicaciones_iguales            EXCEPTION;
    en_ubicaciones_iguales    CONSTANT INTEGER := -20101;
    PRAGMA EXCEPTION_INIT (exc_ubicaciones_iguales
                         , -20101);

    exc_existe_asiento_depre           EXCEPTION;
    en_existe_asiento_depre   CONSTANT INTEGER := -20102;
    PRAGMA EXCEPTION_INIT (exc_existe_asiento_depre
                         , -20102);

    exc_no_existe_depreciacion         EXCEPTION;
    en_no_existe_depreciacion CONSTANT INTEGER := -20103;
    PRAGMA EXCEPTION_INIT (exc_no_existe_depreciacion
                         , -20103);

    exc_no_existe_ctacble              EXCEPTION;
    en_no_existe_ctacble      CONSTANT INTEGER := -20104;
    PRAGMA EXCEPTION_INIT (exc_no_existe_ctacble
                         , -20104);

    exc_existe_baja                    EXCEPTION;
    en_existe_baja            CONSTANT INTEGER := -20105;
    PRAGMA EXCEPTION_INIT (exc_existe_baja
                         , -20105);

    ex_cargar_porc                     EXCEPTION;
    en_cargar_porc            CONSTANT INTEGER := -20106;
    em_cargar_porc            CONSTANT VARCHAR2(100) := 'Debe cargar los porcentajes de depreciacion';
    PRAGMA EXCEPTION_INIT (ex_cargar_porc
                         , -20106);

    ex_cargar_adqui                    EXCEPTION;
    en_cargar_adqui           CONSTANT INTEGER := -20107;
    em_cargar_adqui           CONSTANT VARCHAR2(100) := 'Debe cargar el valor de adquisicion';
    PRAGMA EXCEPTION_INIT (ex_cargar_adqui
                         , -20107);
END pkg_activo_fijo_err;