CREATE OR REPLACE PROCEDURE PEVISA.sp_genera_asiento_depreciacion(p_tipo VARCHAR2, p_moneda VARCHAR2, p_fecha DATE, po_voucher OUT VARCHAR2) AS
    -- Constantes
    c_libro             CONSTANT VARCHAR2(2) := pkg_activo_fijo_cst.c_libro_deprec;
    c_pase_ctacte       CONSTANT VARCHAR2(1) := 'S';
    c_fecha_registro    CONSTANT DATE := SYSDATE;

    -- Variables Globales
    g_ano                        movglos.ano%TYPE;
    g_mes                        movglos.mes%TYPE;
    g_voucher                    movglos.voucher%TYPE;
    --g_cambio                     cambdol.import_cam%TYPE;

    PROCEDURE inicializa IS
        l_delim    CONSTANT VARCHAR2(3) := ' - ';
    BEGIN
        g_ano      := TO_NUMBER(TO_CHAR(p_fecha, 'YYYY'));
        g_mes      := TO_NUMBER(TO_CHAR(p_fecha, 'MM'));
        g_voucher  := api_movglos.nuevo_numero(g_ano, g_mes, c_libro);
        --g_cambio   := api_cambdol.onerow(p_fecha, pkg_asiento.c_tipo_cambio).import_cam;
        po_voucher := g_ano || l_delim || g_mes || l_delim || c_libro || l_delim || g_voucher;
    END inicializa;

    PROCEDURE valida IS
    BEGIN
        IF NOT pkg_activo_fijo_qry.existe_depreciacion(p_tipo, p_moneda, g_ano, g_mes) THEN
            errpkg.raise_error(pkg_activo_fijo_err.en_no_existe_depreciacion);
        END IF;

        IF pkg_activo_fijo_qry.existe_asiento_depreciacion(p_tipo, p_moneda, g_ano, g_mes) THEN
            errpkg.raise_error(pkg_activo_fijo_err.en_existe_asiento_depre);
        END IF;
    END valida;

    PROCEDURE calc_cabecera IS
        l_movglos    movglos%ROWTYPE;
    BEGIN
        l_movglos.ano              := g_ano;
        l_movglos.mes              := g_mes;
        l_movglos.libro            := c_libro;
        l_movglos.voucher          := g_voucher;
        l_movglos.glosa            := pkg_asiento.glosa('DEPRECIACION', g_ano, g_mes);
        l_movglos.fecha            := p_fecha;
        l_movglos.tipo_cambio      := pkg_asiento.c_tipo_cambio;
        l_movglos.estado           := pkg_asiento.c_estado;
        l_movglos.sistema          := 'CONT';
        l_movglos.pase_ctacte      := c_pase_ctacte;
        l_movglos.pase_cta_cte_pro := c_pase_ctacte;
        l_movglos.moneda           := p_moneda;
        l_movglos.usuario          := USER;
        l_movglos.fec_reg          := c_fecha_registro;
        l_movglos.nro_planilla     := TO_CHAR(p_fecha, 'DD/MM/YYYY');

        api_movglos.ins(l_movglos);
    END calc_cabecera;

    PROCEDURE calc_cuenta_depreciacion(p_depreciacion pkg_activo_fijo_qry.cur_depreciacion%ROWTYPE) IS
        l_movdeta    movdeta%ROWTYPE;
    BEGIN
        l_movdeta.ano             := g_ano;
        l_movdeta.mes             := g_mes;
        l_movdeta.libro           := c_libro;
        l_movdeta.voucher         := g_voucher;
        l_movdeta.cuenta          := p_depreciacion.cuenta_contable_depreciacion;
        l_movdeta.tipo_cambio     := pkg_asiento.c_tipo_cambio;
        l_movdeta.tipo_referencia := '00';
        l_movdeta.serie           := '0000';
        l_movdeta.nro_referencia  := '0000000';
        l_movdeta.fecha           := p_fecha;
        l_movdeta.detalle         := p_depreciacion.cod_activo_fijo;
        l_movdeta.cargo_s         := 0;
        l_movdeta.cargo_d         := 0;
        l_movdeta.abono_s         := p_depreciacion.depreciacion;
        l_movdeta.abono_d         := api_activo_fijo_depreciacion.onerow(p_depreciacion.cod_activo_fijo, p_tipo, 'D', p_fecha).depreciacion;
        l_movdeta.estado          := pkg_asiento.c_estado;
        l_movdeta.columna         := api_plancta.onerow(l_movdeta.cuenta).col_compras;
        l_movdeta.generado        := api_plancta.genera_automaticos(l_movdeta.cuenta);
        l_movdeta.usuario         := USER;
        l_movdeta.fec_reg         := c_fecha_registro;
        l_movdeta.f_vencto        := p_fecha;
        l_movdeta.cambio          := ROUND(l_movdeta.abono_s / l_movdeta.abono_d, 3);
        l_movdeta.file_cta_cte    := 'N';

        api_movdeta.ins(l_movdeta);
    END calc_cuenta_depreciacion;

    PROCEDURE calc_cuenta_gasto(p_depreciacion pkg_activo_fijo_qry.cur_depreciacion%ROWTYPE) IS
        l_movdeta    movdeta%ROWTYPE;
    BEGIN
        l_movdeta.ano             := g_ano;
        l_movdeta.mes             := g_mes;
        l_movdeta.libro           := c_libro;
        l_movdeta.voucher         := g_voucher;
        l_movdeta.cuenta          := p_depreciacion.cuenta_contable_gasto;
        l_movdeta.tipo_cambio     := pkg_asiento.c_tipo_cambio;
        l_movdeta.tipo_relacion   := 'U';
        l_movdeta.relacion        := p_depreciacion.centro_costo;
        l_movdeta.tipo_referencia := '00';
        l_movdeta.serie           := '0000';
        l_movdeta.nro_referencia  := '0000000';
        l_movdeta.fecha           := p_fecha;
        l_movdeta.detalle         := p_depreciacion.cod_activo_fijo;
        l_movdeta.cargo_s         := p_depreciacion.depreciacion;
        l_movdeta.cargo_d         := api_activo_fijo_depreciacion.onerow(p_depreciacion.cod_activo_fijo, p_tipo, 'D', p_fecha).depreciacion;
        l_movdeta.abono_s         := 0;
        l_movdeta.abono_d         := 0;
        l_movdeta.estado          := pkg_asiento.c_estado;
        l_movdeta.columna         := api_plancta.onerow(l_movdeta.cuenta).col_compras;
        l_movdeta.generado        := api_plancta.genera_automaticos(l_movdeta.cuenta);
        l_movdeta.usuario         := USER;
        l_movdeta.fec_reg         := c_fecha_registro;
        l_movdeta.f_vencto        := p_fecha;
        l_movdeta.cambio          := ROUND(l_movdeta.cargo_s / l_movdeta.cargo_d, 3);
        l_movdeta.file_cta_cte    := 'N';

        api_movdeta.ins(l_movdeta);
    END calc_cuenta_gasto;

    PROCEDURE guarda_numero_voucher IS
    BEGIN
        UPDATE activo_fijo_depreciacion
        SET    ano     = g_ano
             , mes     = g_mes
             , libro   = c_libro
             , voucher = g_voucher
        WHERE  cod_tipo_depreciacion = p_tipo
        AND    moneda = p_moneda
        AND    TO_NUMBER(TO_CHAR(fecha, 'YYYY')) = g_ano
        AND    TO_NUMBER(TO_CHAR(fecha, 'MM')) = g_mes;
    END guarda_numero_voucher;
BEGIN
    inicializa();
    valida();
    calc_cabecera();

    FOR rec IN pkg_activo_fijo_qry.cur_depreciacion(p_tipo, p_moneda, g_ano, g_mes) LOOP
        calc_cuenta_depreciacion(rec);
        calc_cuenta_gasto(rec);
    END LOOP;

    guarda_numero_voucher();

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            pkg_error.record_log('Fecha: ' || p_fecha || ' Moneda: ' || p_moneda);
        END IF;

        ROLLBACK;
        RAISE;
END;
