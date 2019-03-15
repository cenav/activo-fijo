CREATE OR REPLACE PACKAGE PEVISA.pkg_activo_fijo_qry AS
    FUNCTION depreciacion_al(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN activo_fijo_depreciacion%ROWTYPE;

    FUNCTION ultima_depreciacion(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
    )
        RETURN activo_fijo_depreciacion%ROWTYPE;

    FUNCTION depre_acum_anual(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN NUMBER;

    FUNCTION depre_acum_anual_tot(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN NUMBER;

    FUNCTION mes_depreciado(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     DATE
    )
        RETURN BOOLEAN;

    FUNCTION get_adquisicion_mes(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN activo_fijo_mejora%ROWTYPE;

    FUNCTION tasacion_al(p_cod_activo_fijo activo_fijo_tasacion.cod_activo_fijo%TYPE, p_fecha activo_fijo_tasacion.fecha%TYPE)
        RETURN activo_fijo_tasacion%ROWTYPE;

    PROCEDURE tasacion_agrupado_al(
        p_cod_activo_fijo        activo_fijo_tasacion.cod_activo_fijo%TYPE
      , p_fecha                  activo_fijo_tasacion.fecha%TYPE
      , p_tasacion_s         OUT NUMBER
      , p_tasacion_d         OUT NUMBER
      , p_fecha_tasacion     OUT DATE
    );

    FUNCTION existe_depreciacion(
        p_tipo       activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda     activo_fijo_depreciacion.moneda%TYPE
      , p_ano        PLS_INTEGER
      , p_mes        PLS_INTEGER
    )
        RETURN BOOLEAN;

    FUNCTION existe_asiento_depreciacion(
        p_tipo       activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda     activo_fijo_depreciacion.moneda%TYPE
      , p_ano        PLS_INTEGER
      , p_mes        PLS_INTEGER
    )
        RETURN BOOLEAN;

    FUNCTION existe_baja(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE)
        RETURN BOOLEAN;

    FUNCTION valor_adquisicion_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER;

    FUNCTION valor_compra_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN NUMBER;

    FUNCTION valor_compra_agrupado_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER)
        RETURN NUMBER;

    FUNCTION valor_venta_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN NUMBER;

    FUNCTION valor_venta_agrupado_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER)
        RETURN NUMBER;

    FUNCTION valor_adquisicion(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER;

    FUNCTION valor_compra_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER;

    CURSOR cur_depreciacion(
        p_tipo       activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda     activo_fijo_depreciacion.moneda%TYPE
      , p_ano        PLS_INTEGER
      , p_mes        PLS_INTEGER
    ) IS
        SELECT d.cod_activo_fijo
             , a.cuenta_contable_depreciacion
             , a.cuenta_contable_gasto
             , a.centro_costo
             , d.porcentaje
             , d.depreciacion
             , d.depreciacion_acumulada
             , d.costo_neto
        FROM   activo_fijo_depreciacion d JOIN activo_fijo a ON d.cod_activo_fijo = a.cod_activo_fijo
        WHERE  d.cod_tipo_depreciacion = p_tipo
        AND    d.moneda = p_moneda
        AND    TO_NUMBER(TO_CHAR(d.fecha, 'YYYY')) = p_ano
        AND    TO_NUMBER(TO_CHAR(d.fecha, 'MM')) = p_mes;
END;