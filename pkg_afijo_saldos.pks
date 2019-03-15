CREATE OR REPLACE PACKAGE PEVISA.pkg_afijo_saldos AS
    -- pkg_afijo_saldos genera un reporte mensual
    -- con los saldos de las cuentas de los activos fijos.
	TYPE total IS RECORD (
			valor_libros NUMBER
		, depre_acum	 NUMBER
		, valor_neto	 NUMBER
	);

    PROCEDURE genera_reporte(p_ano PLS_INTEGER, p_mes PLS_INTEGER);
    PROCEDURE elimina_reporte(p_ano PLS_INTEGER, p_mes PLS_INTEGER);
    FUNCTION sub_total(p_tipo VARCHAR2) RETURN total;
END pkg_afijo_saldos;