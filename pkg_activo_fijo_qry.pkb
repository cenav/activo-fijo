CREATE OR REPLACE PACKAGE BODY PEVISA.pkg_activo_fijo_qry AS
    FUNCTION depreciacion_al(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        rec_afijo_depre    activo_fijo_depreciacion%ROWTYPE;
    BEGIN
        SELECT *
        INTO   rec_afijo_depre
        FROM   activo_fijo_depreciacion
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
        AND    moneda = p_moneda
        AND    fecha = (SELECT MAX(fecha)
                        FROM   activo_fijo_depreciacion
                        WHERE  cod_activo_fijo = p_cod_activo_fijo
                        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
                        AND    moneda = p_moneda
                        AND    fecha <= p_fecha);

        RETURN rec_afijo_depre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
            RAISE;
    END depreciacion_al;

    FUNCTION ultima_depreciacion(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
    )
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        rec_afijo_depre    activo_fijo_depreciacion%ROWTYPE;
    BEGIN
        SELECT *
        INTO   rec_afijo_depre
        FROM   activo_fijo_depreciacion
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
        AND    moneda = p_moneda
        AND    fecha = (SELECT MAX(fecha)
                        FROM   activo_fijo_depreciacion
                        WHERE  cod_activo_fijo = p_cod_activo_fijo
                        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
                        AND    moneda = p_moneda);

        RETURN rec_afijo_depre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
            RAISE;
    END ultima_depreciacion;

    FUNCTION depre_acum_anual(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN NUMBER IS
        l_depre    NUMBER;
        l_afijo    activo_fijo%ROWTYPE;
    BEGIN
        l_afijo := api_activo_fijo.onerow(p_cod_activo_fijo);

        IF NVL(l_afijo.fecha_baja, TO_DATE('01/01/9999', 'DD/MM/YYYY')) >= p_fecha THEN
            SELECT SUM(depreciacion) AS depre_acum_anual
            INTO   l_depre
            FROM   activo_fijo_depreciacion
            WHERE  cod_activo_fijo = p_cod_activo_fijo
            AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
            AND    moneda = p_moneda
            AND    fecha BETWEEN TRUNC(p_fecha, 'YYYY') AND p_fecha;
        ELSE
            l_depre := 0;
        END IF;

        RETURN l_depre;
    END depre_acum_anual;

    FUNCTION depre_acum_anual_tot(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     activo_fijo_depreciacion.fecha%TYPE
    )
        RETURN NUMBER IS
        l_depre    NUMBER;
    BEGIN
        SELECT SUM(depreciacion) AS depre_acum_anual
        INTO   l_depre
        FROM   activo_fijo_depreciacion_tot
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
        AND    moneda = p_moneda
        AND    fecha BETWEEN TRUNC(p_fecha, 'YYYY') AND p_fecha;

        RETURN l_depre;
    END depre_acum_anual_tot;

    FUNCTION mes_depreciado(
        p_cod_activo_fijo           activo_fijo.cod_activo_fijo%TYPE
      , p_cod_tipo_depreciacion     activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda                    activo_fijo_depreciacion.moneda%TYPE
      , p_fecha                     DATE
    )
        RETURN BOOLEAN IS
        l_count    PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   activo_fijo_depreciacion
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    cod_tipo_depreciacion = p_cod_tipo_depreciacion
        AND    moneda = p_moneda
        AND    TO_CHAR(fecha, 'YYYYMM') = TO_CHAR(p_fecha, 'YYYYMM');

        RETURN l_count > 0;
    END mes_depreciado;

    FUNCTION get_adquisicion_mes(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN activo_fijo_mejora%ROWTYPE IS
        rec_afm    activo_fijo_mejora%ROWTYPE;
    BEGIN
        SELECT *
        INTO   rec_afm
        FROM   activo_fijo_mejora
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    TO_NUMBER(TO_CHAR(fecha, 'yyyy')) >= p_ano
        AND    TO_NUMBER(TO_CHAR(fecha, 'mm')) >= p_mes;

        RETURN rec_afm;
    END get_adquisicion_mes;

    FUNCTION tasacion_al(p_cod_activo_fijo activo_fijo_tasacion.cod_activo_fijo%TYPE, p_fecha activo_fijo_tasacion.fecha%TYPE)
        RETURN activo_fijo_tasacion%ROWTYPE IS
        rec_afijo_tasacion    activo_fijo_tasacion%ROWTYPE;
    BEGIN
        SELECT *
        INTO   rec_afijo_tasacion
        FROM   activo_fijo_tasacion
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    fecha = (SELECT MAX(fecha)
                        FROM   activo_fijo_tasacion
                        WHERE  cod_activo_fijo = p_cod_activo_fijo
                        AND    fecha <= p_fecha);

        RETURN rec_afijo_tasacion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
            RAISE;
    END tasacion_al;

    PROCEDURE tasacion_agrupado_al(
        p_cod_activo_fijo        activo_fijo_tasacion.cod_activo_fijo%TYPE
      , p_fecha                  activo_fijo_tasacion.fecha%TYPE
      , p_tasacion_s         OUT NUMBER
      , p_tasacion_d         OUT NUMBER
      , p_fecha_tasacion     OUT DATE
    ) IS
        l_tasacion_s    NUMBER := 0;
        l_tasacion_d    NUMBER := 0;
        l_sol           NUMBER := 0;
        l_dol           NUMBER := 0;

        CURSOR cur_agrupado IS
            WITH agrupado AS
                     (SELECT     f.cod_activo_fijo
                               , f.descripcion AS desc_activo
                               , f.cod_adicion
                               , f.valor_adquisicion_s
                               , f.valor_adquisicion_d
                               , PRIOR f.descripcion AS desc_adicion
                               , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                      FROM       activo_fijo f
                      WHERE      NVL(f.fecha_adquisicion, TO_DATE('01/01/1900', 'DD/MM/YYYY')) <= p_fecha
                      START WITH f.cod_adicion IS NULL
                      CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
            SELECT *
            FROM   agrupado
            WHERE  raiz = p_cod_activo_fijo;
    BEGIN
        FOR rec IN cur_agrupado LOOP
            BEGIN
                SELECT valor_tasacion_s
                     , valor_tasacion_d
                     , fecha
                INTO   l_sol
                     , l_dol
                     , p_fecha_tasacion
                FROM   activo_fijo_tasacion
                WHERE  cod_activo_fijo = rec.cod_activo_fijo
                AND    fecha = (SELECT MAX(fecha)
                                FROM   activo_fijo_tasacion
                                WHERE  cod_activo_fijo = rec.cod_activo_fijo
                                AND    fecha <= p_fecha);
            EXCEPTION
                WHEN OTHERS THEN
                    l_sol := 0;
                    l_dol := 0;
            END;

            l_tasacion_s := l_tasacion_s + l_sol;
            l_tasacion_d := l_tasacion_d + l_dol;
        END LOOP;

        p_tasacion_s := l_tasacion_s;
        p_tasacion_d := l_tasacion_d;
    END tasacion_agrupado_al;

    FUNCTION existe_depreciacion(
        p_tipo       activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda     activo_fijo_depreciacion.moneda%TYPE
      , p_ano        PLS_INTEGER
      , p_mes        PLS_INTEGER
    )
        RETURN BOOLEAN IS
        l_no_importa    cur_depreciacion%ROWTYPE;
        l_existe        BOOLEAN := FALSE;
    BEGIN
        OPEN cur_depreciacion(p_tipo, p_moneda, p_ano, p_mes);

        FETCH cur_depreciacion INTO l_no_importa;

        l_existe := cur_depreciacion%FOUND;

        CLOSE cur_depreciacion;

        RETURN l_existe;
    END existe_depreciacion;

    FUNCTION existe_asiento_depreciacion(
        p_tipo       activo_fijo_depreciacion.cod_tipo_depreciacion%TYPE
      , p_moneda     activo_fijo_depreciacion.moneda%TYPE
      , p_ano        PLS_INTEGER
      , p_mes        PLS_INTEGER
    )
        RETURN BOOLEAN IS
        CURSOR cur_depreciacion IS
            SELECT 1
            FROM   activo_fijo_depreciacion
            WHERE  cod_tipo_depreciacion = p_tipo
            AND    moneda = p_moneda
            AND    TO_NUMBER(TO_CHAR(fecha, 'YYYY')) = p_ano
            AND    TO_NUMBER(TO_CHAR(fecha, 'MM')) = p_mes
            AND    (ano IS NOT NULL
            OR      mes IS NOT NULL
            OR      libro IS NOT NULL
            OR      voucher IS NOT NULL);

        l_existe        BOOLEAN := FALSE;
        l_no_importa    PLS_INTEGER;
    BEGIN
        OPEN cur_depreciacion;

        FETCH cur_depreciacion INTO l_no_importa;

        l_existe := cur_depreciacion%FOUND;

        CLOSE cur_depreciacion;

        RETURN l_existe;
    END existe_asiento_depreciacion;

    FUNCTION existe_baja(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE)
        RETURN BOOLEAN IS
        l_count    PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   activo_fijo
        WHERE  cod_activo_fijo = p_cod_activo_fijo
        AND    voucher_baja IS NULL;

        RETURN l_count > 0;
    END existe_baja;

    FUNCTION valor_adquisicion_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER IS
        l_valor_adquisicion    NUMBER := 0;
    BEGIN
        WITH agrupado AS
                 (SELECT     f.cod_activo_fijo
                           , f.descripcion AS desc_activo
                           , f.cod_adicion
                           , f.valor_adquisicion_s
                           , f.valor_adquisicion_d
                           , PRIOR f.descripcion AS desc_adicion
                           , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                  FROM       activo_fijo f
                  WHERE      NVL(f.fecha_adquisicion, TO_DATE('01/01/1900', 'DD/MM/YYYY')) <= p_fecha
                  START WITH f.cod_adicion IS NULL
                  CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
        SELECT CASE p_moneda WHEN 'S' THEN SUM(valor_adquisicion_s) WHEN 'D' THEN SUM(valor_adquisicion_d) ELSE 0 END AS valor_adquisicion
        INTO   l_valor_adquisicion
        FROM   agrupado
        WHERE  raiz = p_cod_activo_fijo;

        RETURN l_valor_adquisicion;
    END valor_adquisicion_agrupado;


    FUNCTION valor_compra_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN NUMBER IS
        l_valor_adquisicion    NUMBER := 0;
    BEGIN
        WITH agrupado AS
                 (SELECT     f.cod_activo_fijo
                           , f.descripcion AS desc_activo
                           , f.cod_adicion
                           , f.valor_adquisicion_s
                           , f.valor_adquisicion_d
                           , PRIOR f.descripcion AS desc_adicion
                           , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                  FROM       activo_fijo f
                  WHERE      TO_NUMBER(TO_CHAR(fecha_adquisicion, 'YYYY')) = p_ano
                  AND        TO_NUMBER(TO_CHAR(fecha_adquisicion, 'MM')) = p_mes
                  START WITH f.cod_adicion IS NULL
                  CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
        SELECT CASE p_moneda WHEN 'S' THEN NVL(SUM(valor_adquisicion_s), 0) WHEN 'D' THEN NVL(SUM(valor_adquisicion_d), 0) ELSE 0 END
                   AS valor_adquisicion
        INTO   l_valor_adquisicion
        FROM   agrupado
        WHERE  raiz = p_cod_activo_fijo;

        RETURN l_valor_adquisicion;
    END valor_compra_agrupado;

    FUNCTION valor_compra_agrupado_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER)
        RETURN NUMBER IS
        l_valor_adquisicion    NUMBER := 0;
    BEGIN
        WITH agrupado AS
                 (SELECT     f.cod_activo_fijo
                           , f.descripcion AS desc_activo
                           , f.cod_adicion
                           , f.valor_adquisicion_s
                           , f.valor_adquisicion_d
                           , PRIOR f.descripcion AS desc_adicion
                           , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                  FROM       activo_fijo f
                  WHERE      TO_NUMBER(TO_CHAR(fecha_adquisicion, 'YYYY')) = p_ano
                  START WITH f.cod_adicion IS NULL
                  CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
        SELECT CASE p_moneda WHEN 'S' THEN NVL(SUM(valor_adquisicion_s), 0) WHEN 'D' THEN NVL(SUM(valor_adquisicion_d), 0) ELSE 0 END
                   AS valor_adquisicion
        INTO   l_valor_adquisicion
        FROM   agrupado
        WHERE  raiz = p_cod_activo_fijo;

        RETURN l_valor_adquisicion;
    END valor_compra_agrupado_anual;

    FUNCTION valor_venta_agrupado(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER, p_mes PLS_INTEGER)
        RETURN NUMBER IS
        l_valor_adquisicion    NUMBER := 0;
    BEGIN
        WITH agrupado AS
                 (SELECT     f.cod_activo_fijo
                           , f.descripcion AS desc_activo
                           , f.cod_adicion
                           , f.valor_adquisicion_s
                           , f.valor_adquisicion_d
                           , sf_costo_neto_hist(f.cod_activo_fijo, 'NIF', 'S', f.fecha_baja) AS costo_neto_s
                           , sf_costo_neto_hist(f.cod_activo_fijo, 'NIF', 'D', f.fecha_baja) AS costo_neto_d
                           , PRIOR f.descripcion AS desc_adicion
                           , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                  FROM       activo_fijo f
                  WHERE      TO_NUMBER(TO_CHAR(fecha_baja, 'YYYY')) = p_ano
                  AND        TO_NUMBER(TO_CHAR(fecha_baja, 'MM')) = p_mes
                  START WITH f.cod_adicion IS NULL
                  CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
        SELECT CASE p_moneda WHEN 'S' THEN NVL(SUM(costo_neto_s), 0) WHEN 'D' THEN NVL(SUM(costo_neto_d), 0) ELSE 0 END AS valor_adquisicion
        INTO   l_valor_adquisicion
        FROM   agrupado
        WHERE  raiz = p_cod_activo_fijo;

        RETURN l_valor_adquisicion;
    END valor_venta_agrupado;

    FUNCTION valor_venta_agrupado_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_ano PLS_INTEGER)
        RETURN NUMBER IS
        l_valor_adquisicion    NUMBER := 0;
    BEGIN
        WITH agrupado AS
                 (SELECT     f.cod_activo_fijo
                           , f.descripcion AS desc_activo
                           , f.cod_adicion
                           , f.valor_adquisicion_s
                           , f.valor_adquisicion_d
                           , sf_costo_neto_hist(f.cod_activo_fijo, 'NIF', 'S', f.fecha_baja) AS costo_neto_s
                           , sf_costo_neto_hist(f.cod_activo_fijo, 'NIF', 'D', f.fecha_baja) AS costo_neto_d
                           , PRIOR f.descripcion AS desc_adicion
                           , CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                  FROM       activo_fijo f
                  WHERE      TO_NUMBER(TO_CHAR(fecha_baja, 'YYYY')) = p_ano
                  START WITH f.cod_adicion IS NULL
                  CONNECT BY PRIOR f.cod_activo_fijo = f.cod_adicion)
        SELECT CASE p_moneda WHEN 'S' THEN NVL(SUM(costo_neto_s), 0) WHEN 'D' THEN NVL(SUM(costo_neto_d), 0) ELSE 0 END AS valor_adquisicion
        INTO   l_valor_adquisicion
        FROM   agrupado
        WHERE  raiz = p_cod_activo_fijo;

        RETURN l_valor_adquisicion;
    END valor_venta_agrupado_anual;

    FUNCTION valor_adquisicion(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER AS
        l_valor_compra    NUMBER := 0;
        l_afijo           activo_fijo%ROWTYPE;
    BEGIN
        l_afijo := api_activo_fijo.onerow(p_cod_activo_fijo);

        IF NVL(l_afijo.fecha_baja, TO_DATE('01/01/9999', 'DD/MM/YYYY')) >= p_fecha THEN
            IF api_activo_fijo_compra.row_exists(p_cod_activo_fijo) THEN
                SELECT NVL(SUM(CASE p_moneda WHEN 'S' THEN importe_s WHEN 'D' THEN importe_d ELSE 0 END), 0)
                INTO   l_valor_compra
                FROM   activo_fijo_compra
                WHERE  cod_activo_fijo = p_cod_activo_fijo
                AND    fecha <= p_fecha;
            ELSE
                l_valor_compra := CASE p_moneda WHEN 'S' THEN l_afijo.valor_adquisicion_s WHEN 'D' THEN l_afijo.valor_adquisicion_d ELSE 0 END;
            END IF;
        ELSE
            l_valor_compra := 0;
        END IF;

        RETURN l_valor_compra;
    END;

    FUNCTION valor_compra_anual(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE, p_moneda VARCHAR2, p_fecha DATE)
        RETURN NUMBER AS
        l_valor_compra    NUMBER := 0;
        l_afijo           activo_fijo%ROWTYPE;
    BEGIN
        l_afijo := api_activo_fijo.onerow(p_cod_activo_fijo);

        IF NVL(l_afijo.fecha_baja, TO_DATE('01/01/9999', 'DD/MM/YYYY')) >= p_fecha THEN
            IF api_activo_fijo_compra.row_exists(p_cod_activo_fijo) THEN
                SELECT NVL(SUM(CASE p_moneda WHEN 'S' THEN importe_s WHEN 'D' THEN importe_d ELSE 0 END), 0)
                INTO   l_valor_compra
                FROM   activo_fijo_compra
                WHERE  cod_activo_fijo = p_cod_activo_fijo
                AND    fecha <= ADD_MONTHS(TRUNC(p_fecha, 'YEAR'), 12) - 1;
            ELSE
                IF TO_CHAR(l_afijo.fecha_adquisicion, 'YYYY') = TO_CHAR(p_fecha, 'YYYY') THEN
                    l_valor_compra := CASE p_moneda WHEN 'S' THEN l_afijo.valor_adquisicion_s WHEN 'D' THEN l_afijo.valor_adquisicion_d ELSE 0 END;
                END IF;
            END IF;
        ELSE
            l_valor_compra := 0;
        END IF;

        RETURN l_valor_compra;
    END;
END;