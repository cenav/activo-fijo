CREATE OR REPLACE PACKAGE pevisa.pkg_activo_fijo AS
    PROCEDURE reclasifica(p_cod_activo_fijo activo_fijo_reclasifica.cod_activo_fijo%TYPE
                         , p_cod_ubc_destino activo_fijo_reclasifica.cod_ubc_destino%TYPE
                         , p_cod_motivo activo_fijo_reclasifica.cod_motivo%TYPE
                         , p_detalle activo_fijo_reclasifica.detalle%TYPE
                         , p_fecha activo_fijo_reclasifica.fecha%TYPE);
    PROCEDURE activar(caf activo_fijo.cod_activo_fijo%TYPE, fch activo_fijo.fecha_activacion%TYPE);

    FUNCTION correlativo_subclase(p_padre activo_fijo.cod_adicion%TYPE, p_subclase activo_fijo.cod_subclase%TYPE) RETURN PLS_INTEGER;

    FUNCTION valor_ingreso_almacen(p_afijo activo_fijo.cod_activo_fijo%TYPE) RETURN otm.T_VALOR;

    FUNCTION fecha_adquisicion(caf activo_fijo.cod_activo_fijo%TYPE) RETURN DATE;
END pkg_activo_fijo;