CREATE OR REPLACE PACKAGE BODY depreciacion AS
    -- Variables globales
    g_periodo_ano PLS_INTEGER;
    g_periodo_mes PLS_INTEGER;
    g_fecha_ini DATE;
    g_fecha_fin DATE;

    -- Inicializa variables que se van a utilizar en el programa
    PROCEDURE init(p_periodo_ano PLS_INTEGER, p_periodo_mes PLS_INTEGER) IS
    BEGIN
        g_periodo_ano := p_periodo_ano;
        g_periodo_mes := p_periodo_mes;
        g_fecha_ini := TO_DATE(p_periodo_ano || p_periodo_mes, 'YYYYMM');
        g_fecha_fin := LAST_DAY(TO_DATE(p_periodo_ano || p_periodo_mes, 'YYYYMM'));
    END;

    FUNCTION existe_saldo_por_depreciar(p_valor_adquisicion NUMBER, p_valor_residual NUMBER, p_depreciacion_acumulada NUMBER)
        RETURN BOOLEAN IS
    BEGIN
        RETURN NVL(p_valor_adquisicion, 0) - NVL(p_valor_residual, 0) - NVL(p_depreciacion_acumulada, 0) > 0;
    END;

    FUNCTION dado_de_baja(p_fecha_baja DATE) RETURN BOOLEAN IS
    BEGIN
        RETURN p_fecha_baja IS NOT NULL AND g_fecha_fin > p_fecha_baja;
    END;

    FUNCTION periodo_depreciable(p_fecha_inicio_depreciacion DATE) RETURN BOOLEAN IS
    BEGIN
        RETURN g_fecha_fin > last_day(p_fecha_inicio_depreciacion);
    END;

    PROCEDURE guarda_depreciacion(p_afijo_depre activo_fijo_depreciacion%ROWTYPE) IS
    BEGIN
        api_activo_fijo_depreciacion.ins(p_afijo_depre);
    END;

    FUNCTION calcula_valores_niif(p_activo_fijo activo_fijo%ROWTYPE
                                 , p_tasacion activo_fijo_tasacion%ROWTYPE
                                 , p_depre_acumulada_anterior NUMBER
                                 , p_moneda VARCHAR2)
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        l_afijo_depre activo_fijo_depreciacion%ROWTYPE;
        l_depre_anual NUMBER := 0;
        l_depre_mensual NUMBER := 0;
        l_valor_tasacion NUMBER := 0;
        l_valor_residual NUMBER := 0;
    BEGIN
        l_afijo_depre.cod_activo_fijo := p_activo_fijo.cod_activo_fijo;
        l_afijo_depre.cod_tipo_depreciacion := pkg_activo_fijo_cst.c_niif;
        l_afijo_depre.moneda := p_moneda;
        l_afijo_depre.fecha := g_fecha_fin;
        l_afijo_depre.porcentaje := p_tasacion.porcentaje_nif;
        l_valor_tasacion := CASE p_moneda WHEN 'S' THEN p_tasacion.detalle_tasacion_s WHEN 'D' THEN p_tasacion.detalle_tasacion_d END;
        l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;
        l_depre_anual := ROUND(p_tasacion.porcentaje_nif * (l_valor_tasacion - l_valor_residual) / 100, 2);
        l_depre_mensual := ROUND(l_depre_anual / 12, 2);
        l_afijo_depre.depreciacion_anual := l_depre_anual;
        l_afijo_depre.depreciacion := l_depre_mensual;
        l_afijo_depre.depreciacion_acumulada := l_depre_mensual + NVL(p_depre_acumulada_anterior, 0);
        l_afijo_depre.costo_neto := l_valor_tasacion - l_afijo_depre.depreciacion_acumulada;

        RETURN l_afijo_depre;
    END;

    FUNCTION calcula_valores_niif_no_tasado(p_activo_fijo activo_fijo%ROWTYPE, p_depre_acumulada_anterior NUMBER, p_moneda VARCHAR2)
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        l_afijo_depre activo_fijo_depreciacion%ROWTYPE;
        l_depre_anual NUMBER := 0;
        l_depre_mensual NUMBER := 0;
        l_valor_adqui NUMBER := 0;
        l_valor_residual NUMBER := 0;
        c_porc_niif CONSTANT NUMBER := 10;
    BEGIN
        l_afijo_depre.cod_activo_fijo := p_activo_fijo.cod_activo_fijo;
        l_afijo_depre.cod_tipo_depreciacion := pkg_activo_fijo_cst.c_niif;
        l_afijo_depre.moneda := p_moneda;
        l_afijo_depre.fecha := g_fecha_fin;
        l_afijo_depre.porcentaje := NVL(p_activo_fijo.porcentaje_nif, c_porc_niif);
        l_valor_adqui := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
        l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;
        l_depre_anual := ROUND(c_porc_niif * (l_valor_adqui - l_valor_residual) / 100, 2);
        l_depre_mensual := ROUND(l_depre_anual / 12, 2);
        l_afijo_depre.depreciacion_anual := l_depre_anual;
        l_afijo_depre.depreciacion := l_depre_mensual;
        l_afijo_depre.depreciacion_acumulada := l_depre_mensual + NVL(p_depre_acumulada_anterior, 0);
        l_afijo_depre.costo_neto := l_valor_adqui - l_afijo_depre.depreciacion_acumulada;

        RETURN l_afijo_depre;
    END;

    FUNCTION calcula_tasa(p_activo_fijo activo_fijo%ROWTYPE, p_activo_fijo_padre activo_fijo%ROWTYPE) RETURN NUMBER IS
        l_tasa NUMBER := 0;
        l_tasacion_padre activo_fijo_tasacion%ROWTYPE;
        l_anos_depre NUMBER := 0;
        l_anos_transcurridos NUMBER := 0;
    BEGIN
        IF NVL(p_activo_fijo.porcentaje_nif, 0) != 0 THEN
            l_tasa := p_activo_fijo.porcentaje_nif;
        ELSE
            l_tasacion_padre := pkg_activo_fijo_qry.tasacion_al(p_activo_fijo_padre.cod_activo_fijo, g_fecha_fin);

            IF l_tasacion_padre.cod_activo_fijo IS NOT NULL THEN
                l_anos_depre :=
                    ROUND(l_tasacion_padre.valor_tasacion_s / (l_tasacion_padre.valor_tasacion_s * l_tasacion_padre.porcentaje_nif / 100));
                l_anos_transcurridos := ROUND((p_activo_fijo.fecha_activacion - l_tasacion_padre.fecha) / 365);
            ELSE
                l_anos_depre :=
                    ROUND(
                            p_activo_fijo_padre.valor_adquisicion_s
                            / (p_activo_fijo_padre.valor_adquisicion_s * p_activo_fijo_padre.porcentaje_tributario / 100)
                        );
                l_anos_transcurridos := ROUND((p_activo_fijo.fecha_activacion - p_activo_fijo_padre.fecha_activacion) / 365);
            END IF;

            l_tasa := 100 / (l_anos_depre - l_anos_transcurridos);
        END IF;

        RETURN l_tasa;
    END;

    FUNCTION calcula_valores_niif_hijos(p_activo_fijo activo_fijo%ROWTYPE, p_depre_acumulada_anterior NUMBER, p_moneda VARCHAR2)
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        l_afijo_depre activo_fijo_depreciacion%ROWTYPE;
        l_activo_fijo_padre activo_fijo%ROWTYPE;
        l_depre_anual NUMBER := 0;
        l_depre_mensual NUMBER := 0;
        l_valor_tasacion NUMBER := 0;
        l_valor_residual NUMBER := 0;
        l_activo_padre VARCHAR2(30);
        l_tasa NUMBER := 0;
    BEGIN
        BEGIN
              WITH qry AS
                       (SELECT f.cod_activo_fijo, CONNECT_BY_ROOT f.cod_activo_fijo AS raiz
                          FROM activo_fijo f
                         START WITH f.cod_adicion IS NULL
                       CONNECT BY PRIOR f.cod_activo_fijo = cod_adicion)
            SELECT raiz INTO l_activo_padre
              FROM qry
             WHERE cod_activo_fijo = p_activo_fijo.cod_activo_fijo;
        EXCEPTION
            WHEN OTHERS THEN
                l_activo_padre := NULL;
        END;

        l_activo_fijo_padre := api_activo_fijo.onerow(l_activo_padre);
        l_tasa := calcula_tasa(p_activo_fijo, l_activo_fijo_padre);

        l_afijo_depre.cod_activo_fijo := p_activo_fijo.cod_activo_fijo;
        l_afijo_depre.cod_tipo_depreciacion := pkg_activo_fijo_cst.c_niif;
        l_afijo_depre.moneda := p_moneda;
        l_afijo_depre.fecha := g_fecha_fin;
        l_afijo_depre.porcentaje := l_tasa;
        l_valor_tasacion :=
            CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
        l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;
        l_depre_anual := ROUND(l_tasa * (l_valor_tasacion - l_valor_residual) / 100, 2);
        l_depre_mensual := ROUND(l_depre_anual / 12, 2);
        l_afijo_depre.depreciacion_anual := l_depre_anual;
        l_afijo_depre.depreciacion := l_depre_mensual;
        l_afijo_depre.depreciacion_acumulada := l_depre_mensual + NVL(p_depre_acumulada_anterior, 0);
        l_afijo_depre.costo_neto := l_valor_tasacion - l_afijo_depre.depreciacion_acumulada;

        RETURN l_afijo_depre;
    END;

    PROCEDURE deprecia_niif(p_activo_fijo activo_fijo%ROWTYPE, p_tasacion activo_fijo_tasacion%ROWTYPE, p_moneda VARCHAR2) IS
        l_depre_anterior activo_fijo_depreciacion%ROWTYPE;
        l_depre_actual activo_fijo_depreciacion%ROWTYPE;
        l_valor_tasacion NUMBER := 0;
        l_valor_adqui NUMBER := 0;
        l_valor_residual NUMBER := 0;
        es_tasado BOOLEAN := p_tasacion.cod_activo_fijo IS NOT NULL;
    BEGIN
        IF es_tasado THEN
            l_depre_anterior :=
                pkg_activo_fijo_qry.depreciacion_al(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin);
            --l_valor_tasacion := CASE p_moneda WHEN 'S' THEN p_tasacion.valor_tasacion_s WHEN 'D' THEN p_tasacion.valor_tasacion_d END;
            l_valor_tasacion := CASE p_moneda WHEN 'S' THEN p_tasacion.detalle_tasacion_s WHEN 'D' THEN p_tasacion.detalle_tasacion_d END;
            l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;

            IF existe_saldo_por_depreciar(l_valor_tasacion, l_valor_residual, l_depre_anterior.depreciacion_acumulada)
                AND periodo_depreciable(p_tasacion.fecha)
                AND NOT pkg_activo_fijo_qry.mes_depreciado(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin)
                AND NOT dado_de_baja(p_activo_fijo.fecha_baja) THEN
                l_depre_actual := calcula_valores_niif(p_activo_fijo, p_tasacion, l_depre_anterior.depreciacion_acumulada, p_moneda);
                guarda_depreciacion(l_depre_actual);
            END IF;
        ELSE
            l_depre_anterior :=
                pkg_activo_fijo_qry.depreciacion_al(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin);
            l_valor_adqui :=
                CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
            l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;

            IF existe_saldo_por_depreciar(l_valor_adqui, l_valor_residual, l_depre_anterior.depreciacion_acumulada)
                AND periodo_depreciable(p_activo_fijo.fecha_activacion)
                AND NOT pkg_activo_fijo_qry.mes_depreciado(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin)
                AND NOT dado_de_baja(p_activo_fijo.fecha_baja) THEN
                l_depre_actual := calcula_valores_niif_no_tasado(p_activo_fijo, l_depre_anterior.depreciacion_acumulada, p_moneda);
                guarda_depreciacion(l_depre_actual);
            END IF;
        END IF;
    END;

    PROCEDURE deprecia_niif_hijos(p_activo_fijo activo_fijo%ROWTYPE, p_moneda VARCHAR2) IS
        l_depre_anterior activo_fijo_depreciacion%ROWTYPE;
        l_depre_actual activo_fijo_depreciacion%ROWTYPE;
        l_valor_tasacion NUMBER := 0;
        l_valor_residual NUMBER := 0;
    BEGIN
        l_depre_anterior :=
            pkg_activo_fijo_qry.depreciacion_al(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin);
        l_valor_tasacion :=
            CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
        l_valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;

        IF existe_saldo_por_depreciar(l_valor_tasacion, l_valor_residual, l_depre_anterior.depreciacion_acumulada)
            AND periodo_depreciable(p_activo_fijo.fecha_activacion)
            AND NOT pkg_activo_fijo_qry.mes_depreciado(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_niif, p_moneda, g_fecha_fin)
            AND NOT dado_de_baja(p_activo_fijo.fecha_baja) THEN
            l_depre_actual := calcula_valores_niif_hijos(p_activo_fijo, l_depre_anterior.depreciacion_acumulada, p_moneda);
            guarda_depreciacion(l_depre_actual);
        END IF;
    END;

    FUNCTION calcula_valores_tributaria(p_activo_fijo activo_fijo%ROWTYPE
                                       , p_depre_anterior activo_fijo_depreciacion%ROWTYPE
                                       , p_moneda VARCHAR2)
        RETURN activo_fijo_depreciacion%ROWTYPE IS
        depre activo_fijo_depreciacion%ROWTYPE;
        depre_anual NUMBER := 0;
        depre_mensual NUMBER := 0;
        valor_adqui NUMBER := 0;
        valor_residual NUMBER := 0;
    BEGIN
        depre.cod_activo_fijo := p_activo_fijo.cod_activo_fijo;
        depre.cod_tipo_depreciacion := pkg_activo_fijo_cst.c_tributaria;
        depre.moneda := p_moneda;
        depre.fecha := g_fecha_fin;
        depre.porcentaje := p_activo_fijo.porcentaje_tributario;
        valor_adqui := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
        valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;
        depre_anual := ROUND(p_activo_fijo.porcentaje_tributario * (valor_adqui - valor_residual) / 100, 2);
        depre_mensual := ROUND(depre_anual / 12, 2);
        IF p_depre_anterior.costo_neto < depre_mensual THEN
            depre_mensual := p_depre_anterior.costo_neto;
        END IF;
        depre.depreciacion_anual := depre_anual;
        depre.depreciacion := depre_mensual;
        depre.depreciacion_acumulada := depre_mensual + NVL(p_depre_anterior.depreciacion_acumulada, 0);
        depre.costo_neto := valor_adqui - depre.depreciacion_acumulada;

        RETURN depre;
    END;

    PROCEDURE deprecia_tributaria(p_activo_fijo activo_fijo%ROWTYPE, p_moneda VARCHAR2) IS
        depre_anterior activo_fijo_depreciacion%ROWTYPE;
        depre_actual activo_fijo_depreciacion%ROWTYPE;
        valor_adqui NUMBER := 0;
        valor_residual NUMBER := 0;
    BEGIN
        depre_anterior :=
            pkg_activo_fijo_qry.depreciacion_al(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_tributaria, p_moneda, g_fecha_fin);
        valor_adqui := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_adquisicion_s WHEN 'D' THEN p_activo_fijo.valor_adquisicion_d END;
        valor_residual := CASE p_moneda WHEN 'S' THEN p_activo_fijo.valor_residual_s WHEN 'D' THEN p_activo_fijo.valor_residual_d END;

        IF existe_saldo_por_depreciar(valor_adqui, valor_residual, depre_anterior.depreciacion_acumulada)
            AND periodo_depreciable(p_activo_fijo.fecha_activacion)
            AND
           NOT pkg_activo_fijo_qry.mes_depreciado(p_activo_fijo.cod_activo_fijo, pkg_activo_fijo_cst.c_tributaria, p_moneda, g_fecha_fin)
            AND NOT dado_de_baja(p_activo_fijo.fecha_baja) THEN
            depre_actual := calcula_valores_tributaria(p_activo_fijo, depre_anterior, p_moneda);
            guarda_depreciacion(depre_actual);
        END IF;
    END;

    PROCEDURE valida_activo(p_cod_activo_fijo activo_fijo.cod_activo_fijo%TYPE) IS
    BEGIN
        IF NOT api_activo_fijo_cuenta.row_exists(p_cod_activo_fijo, pkg_activo_fijo_cst.c_niif, 'S')
            OR NOT api_activo_fijo_cuenta.row_exists(p_cod_activo_fijo, pkg_activo_fijo_cst.c_tributaria, 'S') THEN
            errpkg.raise_error(pkg_activo_fijo_err.en_no_existe_ctacble,
                               'No se cargaron cuentas contables para el codigo ' || p_cod_activo_fijo);
        END IF;
    END;

    PROCEDURE procesa(p_periodo_ano PLS_INTEGER, p_periodo_mes PLS_INTEGER) IS
        l_activo_fijo activo_fijo%ROWTYPE;
        l_activo_tasacion activo_fijo_tasacion%ROWTYPE;

        -- Por cada activo fijo debe hacerse la depreciacion en SOLES y DOLARES
        CURSOR cr_proceso IS
            SELECT a.cod_activo_fijo, m.id_moneda
              FROM activo_fijo a
                   CROSS JOIN moneda m
             WHERE m.id_moneda IN ('S', 'D')
               AND a.cod_estado BETWEEN '1' AND '8'
               AND a.depreciable = 'S'
               --AND a.cod_activo_fijo IN ('MQ2MATR-070-INST2', 'MQ2MATR-070-INST3')
             ORDER BY a.cod_activo_fijo;
    BEGIN
        init(p_periodo_ano, p_periodo_mes);

        FOR r IN cr_proceso LOOP
            valida_activo(r.cod_activo_fijo);

            -- Ejecuta query solo cuando el codigo de activo fijo cambie
            IF r.cod_activo_fijo != NVL(l_activo_fijo.cod_activo_fijo, 'NULO') THEN
                l_activo_fijo := api_activo_fijo.onerow(r.cod_activo_fijo);
                l_activo_tasacion := pkg_activo_fijo_qry.tasacion_al(r.cod_activo_fijo, g_fecha_fin);
            END IF;

            deprecia_niif(l_activo_fijo, l_activo_tasacion, r.id_moneda);
            deprecia_tributaria(l_activo_fijo, r.id_moneda);
        END LOOP;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_error.record_log('Error calculo de depreciacion');
            ROLLBACK;
            RAISE;
    END;

    PROCEDURE elimina(p_periodo_ano PLS_INTEGER, p_periodo_mes PLS_INTEGER) IS
    BEGIN
        DELETE
          FROM activo_fijo_depreciacion
         WHERE to_number(to_char(fecha, 'YYYY')) = p_periodo_ano
           AND to_number(to_char(fecha, 'MM')) = p_periodo_mes;

        DELETE
          FROM activo_fijo_depreciacion_tot
         WHERE to_number(to_char(fecha, 'YYYY')) = p_periodo_ano
           AND to_number(to_char(fecha, 'MM')) = p_periodo_mes;
    END;
END depreciacion;