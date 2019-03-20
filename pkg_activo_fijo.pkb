CREATE OR REPLACE PACKAGE BODY pevisa.pkg_activo_fijo AS
    param paramaf%ROWTYPE;

    PROCEDURE reclasifica(p_cod_activo_fijo activo_fijo_reclasifica.cod_activo_fijo%TYPE
                         , p_cod_ubc_destino activo_fijo_reclasifica.cod_ubc_destino%TYPE
                         , p_cod_motivo activo_fijo_reclasifica.cod_motivo%TYPE
                         , p_detalle activo_fijo_reclasifica.detalle%TYPE
                         , p_fecha activo_fijo_reclasifica.fecha%TYPE) IS
        l_afijo activo_fijo%ROWTYPE;
        l_reclas activo_fijo_reclasifica%ROWTYPE;

        PROCEDURE valida IS
        BEGIN
            IF l_afijo.cod_activo_fijo IS NULL THEN
                errpkg.raise_error(pkg_activo_fijo_err.en_activo_no_existe);
            END IF;

            IF l_afijo.cod_ubicacion = p_cod_ubc_destino THEN
                errpkg.raise_error(pkg_activo_fijo_err.en_ubicaciones_iguales);
            END IF;
        END;

        PROCEDURE procesa_data IS
        BEGIN
            l_reclas.cod_activo_fijo := p_cod_activo_fijo;
            l_reclas.fecha := p_fecha;
            l_reclas.cod_motivo := p_cod_motivo;
            l_reclas.detalle := p_detalle;
            l_reclas.cod_ubc_origen := l_afijo.cod_ubicacion;
            l_reclas.cod_ubc_destino := p_cod_ubc_destino;
            l_reclas.creacion_usuario := USER;
            l_reclas.creacion_fecha := SYSDATE;
        END;

        PROCEDURE guarda_y_actualiza IS
        BEGIN
            l_afijo.cod_ubicacion := p_cod_ubc_destino;

            api_activo_fijo_reclasifica.ins(l_reclas);
            api_activo_fijo.upd(l_afijo);
        END;
    BEGIN
        l_afijo := api_activo_fijo.onerow(p_cod_activo_fijo);
        valida();
        procesa_data();
        guarda_y_actualiza();

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
                pkg_error.record_log('Codigo activo: ' || p_cod_activo_fijo);
            END IF;

            ROLLBACK;
            RAISE;
    END;

    FUNCTION esta_en_almacen(caf activo_fijo.cod_activo_fijo%TYPE) RETURN BOOLEAN IS
        c PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(*) INTO c
          FROM vw_almacen_activo_fijo a
         WHERE a.cod_art = caf;

        RETURN c > 0;
    END;

    PROCEDURE realiza_salida(caf activo_fijo.cod_activo_fijo%TYPE, fch activo_fijo.fecha_activacion%TYPE, kxg OUT kardex_g%ROWTYPE) IS
        kg kardex_g%ROWTYPE;
        kd kardex_d%ROWTYPE;
    BEGIN
        SELECT almacen_activo_fijo INTO kg.cod_alm FROM param_util;

        kg.tp_transac := pkg_activo_fijo_cst.c_salida_transac;
        kg.serie := pkg_activo_fijo_cst.c_salida_serie;
        kg.numero := api_kardex_g.next_numero(pkg_activo_fijo_cst.c_salida_transac, pkg_activo_fijo_cst.c_salida_serie);
        kg.fch_transac := fch;
        kg.tip_doc_ref := NULL; --todo
        kg.ser_doc_ref := NULL; --todo
        kg.nro_doc_ref := NULL; --todo
        kg.glosa := 'Salida por activacion de activo fijo ' || caf;
        kg.tp_relacion := 'C';
        kg.nro_lista := 1;
        kg.por_desc1 := 0;
        kg.por_desc2 := 0;
        kg.motivo := 1;
        kg.estado := 0;
        kg.origen := 'P';
        kg.ing_sal := 'S';
        kg.flg_impr := 0;
        kg.num_importa := 'SM :1 ' || kg.nro_doc_ref;

        api_kardex_g.ins(kg);

        kd.cod_alm := kg.cod_alm;
        kd.tp_transac := kg.tp_transac;
        kd.serie := kg.serie;
        kd.numero := kg.numero;
        kd.cod_art := caf;
        kd.cantidad := 1;
        kd.costo_s := 0;
        kd.costo_d := 0;
        kd.fch_transac := SYSDATE;
        kd.por_desc1 := 0;
        kd.por_desc2 := 0;
        kd.imp_vvb := 0;
        kd.estado := 0;
        kd.origen := 'P';
        kd.ing_sal := 'S';
        kd.pr_referencia := 'ACTIVACION ACTIVO FIJOw';

        api_kardex_d.ins(kd);
        kxg := kg;
    END;

    PROCEDURE valida_activacion(af activo_fijo%ROWTYPE, valor otm.T_VALOR) IS
    BEGIN
        IF af.porcentaje_nif IS NULL OR af.porcentaje_nif = 0 THEN
            raise_application_error(pkg_activo_fijo_err.en_cargar_porc, pkg_activo_fijo_err.em_cargar_porc || ' ' || af.cod_activo_fijo);
        END IF;

        IF NVL(valor.soles, 0) = 0 OR NVL(valor.dolares, 0) = 0 THEN
            raise_application_error(pkg_activo_fijo_err.en_cargar_adqui, pkg_activo_fijo_err.em_cargar_adqui || ' ' || af.cod_activo_fijo);
        END IF;
    END;

    PROCEDURE activar(caf activo_fijo.cod_activo_fijo%TYPE, fch activo_fijo.fecha_activacion%TYPE) IS
        af activo_fijo%ROWTYPE;
        kg kardex_g%ROWTYPE;
        valor otm.T_VALOR;
    BEGIN
        af := api_activo_fijo.onerow(caf);
        valor := valor_ingreso_almacen(caf);
        valida_activacion(af, valor);

        IF esta_en_almacen(caf) THEN
            realiza_salida(caf, fch, kg);
        END IF;

        af.cod_estado := pkg_activo_fijo_cst.c_estado_activado;
        af.fecha_activacion := fch;
        af.activacion_almacen := kg.cod_alm;
        af.activacion_tp_transac := kg.tp_transac;
        af.activacion_serie := kg.serie;
        af.activacion_numero := kg.numero;
        api_activo_fijo.upd(af);

        COMMIT;
    END;

    FUNCTION correlativo_subclase(p_padre activo_fijo.cod_adicion%TYPE, p_subclase activo_fijo.cod_subclase%TYPE) RETURN PLS_INTEGER IS
        correlativo PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(*) + 1 INTO correlativo
          FROM activo_fijo
         WHERE cod_adicion = p_padre
           AND cod_subclase = p_subclase;

        RETURN correlativo;
    END;

    FUNCTION valor_ingreso_almacen(p_afijo activo_fijo.cod_activo_fijo%TYPE) RETURN otm.T_VALOR IS
        valor otm.T_VALOR;
    BEGIN
        SELECT costo_s, costo_d INTO valor
          FROM kardex_d
         WHERE cod_alm = param.almacen_activo_fijo
           AND tp_transac = '11'
           AND cod_art = p_afijo;

        RETURN valor;
    EXCEPTION
        WHEN no_data_found THEN valor := NULL;
        WHEN dup_val_on_index THEN valor := NULL;
    END;
    BEGIN
    param := api_paramaf.onerow();
END pkg_activo_fijo;